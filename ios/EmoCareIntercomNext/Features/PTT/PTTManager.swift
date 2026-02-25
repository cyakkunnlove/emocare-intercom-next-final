import SwiftUI
import AVFoundation
import Combine

@MainActor
class PTTManager: ObservableObject {
    static let shared = PTTManager()
    
    @Published var isPTTActive = false
    @Published var isRecording = false
    @Published var recordingLevel: Float = 0.0
    @Published var currentChannelId: String?
    @Published var errorMessage: String?
    
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // PTT設定
    private let maxRecordingDuration: TimeInterval = 30.0 // 30秒上限
    private let minRecordingDuration: TimeInterval = 0.5  // 0.5秒最小
    private var recordingStartTime: Date?
    
    init() {
        setupAudioLevelMonitoring()
        print("✅ PTTManager initialized")
    }
    
    // MARK: - PTT Control
    
    func startPTT(channelId: String) async {
        guard !isPTTActive else {
            print("❌ PTT already active")
            return
        }
        
        // 権限チェック
        guard await checkMicrophonePermission() else {
            errorMessage = "マイクの使用が許可されていません"
            return
        }
        
        // 音声セッション準備
        await AudioManager.shared.configureForPTT()
        
        do {
            // LiveKit音声開始
            try await LiveKitService.shared.startPushToTalk()
            
            await MainActor.run {
                self.isPTTActive = true
                self.isRecording = true
                self.currentChannelId = channelId
                self.recordingStartTime = Date()
                self.errorMessage = nil
            }
            
            // 録音レベル監視開始
            startRecordingLevelMonitoring()
            
            // 最大録音時間タイマー
            startMaxDurationTimer()
            
            print("✅ PTT started for channel: \(channelId)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "PTT開始に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to start PTT: \(error)")
        }
    }
    
    func endPTT() async {
        guard isPTTActive else {
            print("❌ PTT not active")
            return
        }
        
        // 最小録音時間チェック
        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            if duration < minRecordingDuration {
                print("⚠️ Recording too short (\(duration)s), extending...")
                try? await Task.sleep(nanoseconds: UInt64((minRecordingDuration - duration) * 1_000_000_000))
            }
        }
        
        do {
            // LiveKit音声停止
            try await LiveKitService.shared.endPushToTalk()
            
            await MainActor.run {
                self.isPTTActive = false
                self.isRecording = false
                self.recordingLevel = 0.0
                self.currentChannelId = nil
                self.recordingStartTime = nil
            }
            
            // タイマー停止
            stopRecordingLevelMonitoring()
            stopMaxDurationTimer()
            
            // 音声セッション復帰
            await AudioManager.shared.restoreFromPTT()
            
            print("✅ PTT ended")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "PTT終了に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to end PTT: \(error)")
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private func setupAudioLevelMonitoring() {
        // 音声レベル監視の基盤設定
        print("✅ Audio level monitoring setup completed")
    }
    
    private func startRecordingLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingLevel()
            }
        }
    }
    
    private func stopRecordingLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        recordingLevel = 0.0
    }
    
    private func updateRecordingLevel() {
        // TODO: AVAudioRecorderまたはLiveKitから音声レベルを取得
        // 現在はモック実装
        if isPTTActive {
            recordingLevel = Float.random(in: 0.0...1.0)
        } else {
            recordingLevel = 0.0
        }
    }
    
    // MARK: - Duration Management
    
    private func startMaxDurationTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("⚠️ PTT max duration reached, auto-ending")
                await self?.endPTT()
            }
        }
    }
    
    private func stopMaxDurationTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Permission Management
    
    private func checkMicrophonePermission() async -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        
        switch audioSession.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            // 権限リクエスト
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
    
    // MARK: - Channel Management
    
    func isConnectedToChannel(_ channelId: String) -> Bool {
        return LiveKitService.shared.isConnected && currentChannelId == channelId
    }
    
    func canStartPTT(in channelId: String) -> Bool {
        return LiveKitService.shared.isConnected &&
               !isPTTActive &&
               isConnectedToChannel(channelId)
    }
    
    // MARK: - Statistics
    
    func getCurrentRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0.0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func getRemainingRecordingTime() -> TimeInterval {
        let current = getCurrentRecordingDuration()
        return max(0.0, maxRecordingDuration - current)
    }
}

// MARK: - Audio Manager Extension for PTT

extension AudioManager {
    func configureForPTT() async {
        do {
            // PTT用の音声設定
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            
            // より低遅延の設定
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms
            try audioSession.setActive(true)
            
            print("✅ Audio session configured for PTT")
            
        } catch {
            print("❌ Failed to configure PTT audio session: \(error)")
        }
    }
    
    func restoreFromPTT() async {
        // PTTから通常通話モードに復帰
        await configureAudioSession()
        print("✅ Audio session restored from PTT")
    }
}

// MARK: - PTT UI Components

struct PTTButton: View {
    @StateObject private var pttManager = PTTManager.shared
    let channelId: String
    
    @State private var isPressed = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(pttManager.isPTTActive ? Color.red : Color.blue)
                    .frame(width: isPressed ? 120 : 100, height: isPressed ? 120 : 100)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
                    .shadow(color: pttManager.isPTTActive ? .red.opacity(0.5) : .blue.opacity(0.3), radius: 10)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                
                if pttManager.isPTTActive {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pttManager.recordingLevel > 0.5 ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: pttManager.recordingLevel)
                }
            }
        }
        .buttonStyle(PTTButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        hapticFeedback.impactOccurred()
                        Task {
                            await pttManager.startPTT(channelId: channelId)
                        }
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        hapticFeedback.impactOccurred()
                        Task {
                            await pttManager.endPTT()
                        }
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pttManager.isPTTActive)
    }
}

struct PTTButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    PTTButton(channelId: "test-channel")
}
