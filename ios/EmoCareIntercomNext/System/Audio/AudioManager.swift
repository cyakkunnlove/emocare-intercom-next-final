import AVFoundation
import Combine

@MainActor
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isAudioActive = false
    @Published var isMicrophoneEnabled = false
    @Published var isSpeakerEnabled = false
    @Published var audioRoute: AudioRoute = .earpiece
    @Published var errorMessage: String?
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSessionNotifications()
        print("✅ AudioManager initialized")
    }
    
    // MARK: - Public Methods
    
    func initialize() async throws {
        try await configureAudioSession()
        print("✅ AudioManager initialization completed")
    }
    
    func configureAudioSession() async {
        do {
            // VoIP用のオーディオセッション設定
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            
            // サンプルレートと品質設定
            try audioSession.setPreferredSampleRate(48000)
            try audioSession.setPreferredIOBufferDuration(0.01) // 10ms for low latency
            
            print("✅ Audio session configured for VoIP")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "音声設定に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    func activateAudioSession() async {
        do {
            try audioSession.setActive(true)
            
            await MainActor.run {
                self.isAudioActive = true
                self.updateAudioRoute()
            }
            
            print("✅ Audio session activated")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "音声セッションの有効化に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to activate audio session: \(error)")
        }
    }
    
    func deactivateAudioSession() async {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            await MainActor.run {
                self.isAudioActive = false
                self.isMicrophoneEnabled = false
                self.isSpeakerEnabled = false
            }
            
            print("✅ Audio session deactivated")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "音声セッションの無効化に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
    
    func setMicrophoneEnabled(_ enabled: Bool) async {
        guard isAudioActive else {
            print("❌ Cannot change microphone state: audio session not active")
            return
        }
        
        // TODO: LiveKit音声クライアントでマイクON/OFF
        await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機（模擬）
        
        await MainActor.run {
            self.isMicrophoneEnabled = enabled
        }
        
        print("✅ Microphone \(enabled ? "enabled" : "disabled")")
    }
    
    func setSpeakerEnabled(_ enabled: Bool) async {
        guard isAudioActive else {
            print("❌ Cannot change speaker state: audio session not active")
            return
        }
        
        do {
            if enabled {
                // スピーカーフォン有効
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                // デフォルト出力（レシーバー/イヤホン）
                try audioSession.overrideOutputAudioPort(.none)
            }
            
            await MainActor.run {
                self.isSpeakerEnabled = enabled
                self.updateAudioRoute()
            }
            
            print("✅ Speaker \(enabled ? "enabled" : "disabled")")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "スピーカー設定の変更に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to change speaker state: \(error)")
        }
    }
    
    func switchToBluetoothIfAvailable() async {
        guard isAudioActive else { return }
        
        let availableInputs = audioSession.availableInputs ?? []
        let bluetoothInput = availableInputs.first { input in
            input.portType == .bluetoothHFP || input.portType == .bluetoothA2DP
        }
        
        if let bluetoothInput = bluetoothInput {
            do {
                try audioSession.setPreferredInput(bluetoothInput)
                await MainActor.run {
                    self.updateAudioRoute()
                }
                print("✅ Switched to Bluetooth audio")
            } catch {
                print("❌ Failed to switch to Bluetooth: \(error)")
            }
        }
    }
    
    // MARK: - PTT Support
    
    func startPTTRecording() async {
        await setMicrophoneEnabled(true)
        // TODO: PTT録音開始処理
        print("✅ PTT recording started")
    }
    
    func stopPTTRecording() async {
        await setMicrophoneEnabled(false)
        // TODO: PTT録音停止・送信処理
        print("✅ PTT recording stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSessionNotifications() {
        // オーディオルート変更通知
        NotificationCenter.default
            .publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleAudioRouteChange(notification)
                }
            }
            .store(in: &cancellables)
        
        // 割り込み通知
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleAudioInterruption(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioRouteChange(_ notification: Notification) {
        updateAudioRoute()
        
        if let userInfo = notification.userInfo,
           let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
           let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) {
            
            print("🔄 Audio route changed: \(reason)")
            
            switch reason {
            case .newDeviceAvailable:
                Task {
                    await switchToBluetoothIfAvailable()
                }
            case .oldDeviceUnavailable:
                // デバイスが切断された場合の処理
                break
            default:
                break
            }
        }
    }
    
    private func handleAudioInterruption(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
           let type = AVAudioSession.InterruptionType(rawValue: typeValue) {
            
            switch type {
            case .began:
                print("🔇 Audio interruption began")
                // 割り込み開始時の処理
            case .ended:
                print("🔊 Audio interruption ended")
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // 音声セッションを再開
                        Task {
                            await activateAudioSession()
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    private func updateAudioRoute() {
        let currentRoute = audioSession.currentRoute
        
        if currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP }) {
            audioRoute = .bluetooth
        } else if currentRoute.outputs.contains(where: { $0.portType == .headphones || $0.portType == .bluetoothLE }) {
            audioRoute = .wiredHeadphones
        } else if currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            audioRoute = .speaker
        } else {
            audioRoute = .earpiece
        }
        
        print("🎧 Audio route updated to: \(audioRoute)")
    }
}

// MARK: - Audio Route

enum AudioRoute {
    case earpiece
    case speaker
    case wiredHeadphones
    case bluetooth
    
    var displayName: String {
        switch self {
        case .earpiece: return "レシーバー"
        case .speaker: return "スピーカー"
        case .wiredHeadphones: return "ヘッドフォン"
        case .bluetooth: return "Bluetooth"
        }
    }
    
    var icon: String {
        switch self {
        case .earpiece: return "iphone"
        case .speaker: return "speaker.wave.2"
        case .wiredHeadphones: return "headphones"
        case .bluetooth: return "beats.headphones"
        }
    }
}