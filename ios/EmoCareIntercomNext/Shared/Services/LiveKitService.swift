import Foundation
import LiveKit
import AVFoundation

@MainActor
class LiveKitService: ObservableObject {
    static let shared = LiveKitService()
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var participants: [Participant] = []
    @Published var errorMessage: String?
    
    private var room: Room?
    private var localParticipant: LocalParticipant?
    
    init() {
        print("✅ LiveKitService initialized")
    }
    
    // MARK: - Connection Management
    
    func connect(url: String, token: String, roomName: String) async throws {
        guard !isConnecting else {
            print("❌ Already connecting to LiveKit")
            return
        }
        
        await MainActor.run {
            self.isConnecting = true
            self.errorMessage = nil
        }
        
        do {
            // LiveKit接続オプション設定
            let connectOptions = ConnectOptions(
                autoSubscribe: true,
                publishOnlyMode: nil
            )
            
            // Roomオプション設定（低遅延・高品質音声）
            let roomOptions = RoomOptions(
                defaultCameraCaptureOptions: CameraCaptureOptions(
                    dimensions: .h480_640
                ),
                defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(),
                defaultAudioCaptureOptions: AudioCaptureOptions(
                    // 高音質・低遅延設定
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true,
                    typingNoiseDetection: true
                ),
                adaptiveStream: true,
                dynacast: true,
                e2eeOptions: nil
            )
            
            // Room作成・接続
            let room = try await Room.connect(
                url: url,
                token: token,
                connectOptions: connectOptions,
                roomOptions: roomOptions
            )
            
            await MainActor.run {
                self.room = room
                self.localParticipant = room.localParticipant
                self.isConnected = true
                self.isConnecting = false
                self.connectionState = .connected
                self.updateParticipants()
            }
            
            // Room イベント監視開始
            await setupRoomEventListeners()
            
            print("✅ LiveKit connected to room: \(roomName)")
            
        } catch {
            await MainActor.run {
                self.isConnecting = false
                self.errorMessage = "音声接続に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to connect to LiveKit: \(error)")
            throw LiveKitError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() async {
        guard let room = room else {
            print("❌ No active LiveKit room to disconnect")
            return
        }
        
        await room.disconnect()
        
        await MainActor.run {
            self.room = nil
            self.localParticipant = nil
            self.isConnected = false
            self.connectionState = .disconnected
            self.participants = []
        }
        
        print("✅ LiveKit disconnected")
    }
    
    // MARK: - Audio Control
    
    func setMicrophoneEnabled(_ enabled: Bool) async throws {
        guard let localParticipant = localParticipant else {
            throw LiveKitError.notConnected
        }
        
        try await localParticipant.setMicrophone(enabled: enabled)
        print("✅ Microphone \(enabled ? "enabled" : "disabled")")
    }
    
    func toggleMicrophone() async throws {
        guard let localParticipant = localParticipant else {
            throw LiveKitError.notConnected
        }
        
        let currentlyEnabled = localParticipant.isMicrophoneEnabled()
        try await setMicrophoneEnabled(!currentlyEnabled)
    }
    
    func setSpeakerEnabled(_ enabled: Bool) async throws {
        // スピーカー設定はAudioManagerと連携
        await AudioManager.shared.setAudioRoute(enabled ? .speaker : .earpiece)
        print("✅ Speaker \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Push-to-Talk Support
    
    func startPushToTalk() async throws {
        try await setMicrophoneEnabled(true)
        print("✅ PTT started")
    }
    
    func endPushToTalk() async throws {
        try await setMicrophoneEnabled(false)
        print("✅ PTT ended")
    }
    
    // MARK: - Event Handling
    
    private func setupRoomEventListeners() async {
        guard let room = room else { return }
        
        // 参加者変更監視
        room.$allParticipants.sink { [weak self] participants in
            Task { @MainActor in
                self?.participants = Array(participants.values)
                print("✅ Participants updated: \(participants.count)")
            }
        }
        
        // 接続状態監視
        room.$connectionState.sink { [weak self] state in
            Task { @MainActor in
                self?.connectionState = state
                
                switch state {
                case .connected:
                    self?.isConnected = true
                    print("✅ LiveKit connection state: connected")
                case .disconnected:
                    self?.isConnected = false
                    print("⚠️ LiveKit connection state: disconnected")
                case .connecting, .reconnecting:
                    print("🔄 LiveKit connection state: \(state)")
                @unknown default:
                    print("⚠️ LiveKit connection state: unknown")
                }
            }
        }
        
        // 音声トラック監視
        room.localParticipant?.$trackPublications.sink { publications in
            let audioTrackCount = publications.values.filter { $0.kind == .audio }.count
            print("✅ Local audio tracks: \(audioTrackCount)")
        }
    }
    
    private func updateParticipants() {
        guard let room = room else { return }
        self.participants = Array(room.allParticipants.values)
    }
    
    // MARK: - Quality Optimization
    
    func optimizeForVoIP() async {
        guard let room = room else { return }
        
        // VoIP通話向け最適化設定
        await room.localParticipant?.setTrackSubscriptionPermissions(allParticipantsAllowed: true)
        
        // 適応的ストリーミング有効化
        if let engine = room.engine {
            // 低遅延最適化
            engine.adaptiveStream = true
            engine.dynacast = true
        }
        
        print("✅ LiveKit optimized for VoIP")
    }
    
    // MARK: - Statistics
    
    func getConnectionStatistics() async -> ConnectionStatistics? {
        guard let room = room else { return nil }
        
        // 接続統計情報を取得
        // TODO: LiveKit統計API使用
        return ConnectionStatistics(
            connectionTime: Date().timeIntervalSince1970,
            audioLatency: 50.0, // ms
            packetLoss: 0.01 // 1%
        )
    }
}

// MARK: - Models

struct ConnectionStatistics {
    let connectionTime: TimeInterval
    let audioLatency: Double // milliseconds
    let packetLoss: Double // percentage
}

enum LiveKitError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case audioConfigurationFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "LiveKitに接続されていません"
        case .connectionFailed(let message):
            return "接続に失敗しました: \(message)"
        case .audioConfigurationFailed:
            return "音声設定に失敗しました"
        case .permissionDenied:
            return "音声アクセス権限が拒否されました"
        }
    }
}

// MARK: - Extensions

extension ConnectionState {
    var displayText: String {
        switch self {
        case .disconnected: return "切断"
        case .connecting: return "接続中"
        case .connected: return "接続済み"
        case .reconnecting: return "再接続中"
        @unknown default: return "不明"
        }
    }
}