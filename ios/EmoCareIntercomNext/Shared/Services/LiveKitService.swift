import Foundation
import Combine

@MainActor
class LiveKitService: ObservableObject {
    static let shared = LiveKitService()

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var participants: [String] = []
    @Published var errorMessage: String?

    private var microphoneEnabled = false
    private var connectedRoomName: String?

    init() {
        print("✅ LiveKitService initialized (mock)")
    }

    // MARK: - Connection Management

    func connect(url: String, token: String, roomName: String) async throws {
        guard !isConnecting else { return }

        isConnecting = true
        connectionState = .connecting
        errorMessage = nil

        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isConnecting = false
            connectionState = .disconnected
            throw LiveKitError.connectionFailed("URLまたはトークンが空です")
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        isConnecting = false
        isConnected = true
        connectionState = .connected
        connectedRoomName = roomName
        participants = ["現在のユーザー"]
        print("✅ LiveKit mock connected to room: \(roomName)")
    }

    func disconnect() async {
        isConnecting = false
        isConnected = false
        connectionState = .disconnected
        participants = []
        connectedRoomName = nil
        microphoneEnabled = false
        print("✅ LiveKit mock disconnected")
    }

    // MARK: - Audio Control

    func setMicrophoneEnabled(_ enabled: Bool) async throws {
        guard isConnected else {
            throw LiveKitError.notConnected
        }
        microphoneEnabled = enabled
        await AudioManager.shared.setMicrophoneEnabled(enabled)
        print("✅ Microphone \(enabled ? "enabled" : "disabled")")
    }

    func toggleMicrophone() async throws {
        try await setMicrophoneEnabled(!microphoneEnabled)
    }

    func setSpeakerEnabled(_ enabled: Bool) async throws {
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

    // MARK: - Quality Optimization

    func optimizeForVoIP() async {
        guard isConnected else { return }
        print("✅ LiveKit mock optimized for VoIP")
    }

    // MARK: - Statistics

    func getConnectionStatistics() async -> ConnectionStatistics? {
        guard isConnected else { return nil }
        return ConnectionStatistics(
            connectionTime: Date().timeIntervalSince1970,
            audioLatency: 50.0,
            packetLoss: 0.01
        )
    }
}

// MARK: - Models

struct ConnectionStatistics {
    let connectionTime: TimeInterval
    let audioLatency: Double
    let packetLoss: Double
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting

    var displayText: String {
        switch self {
        case .disconnected: return "切断"
        case .connecting: return "接続中"
        case .connected: return "接続済み"
        case .reconnecting: return "再接続中"
        }
    }
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
