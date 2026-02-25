import SwiftUI
import CallKit
import AVFoundation
import Combine

@MainActor
class CallManager: NSObject, ObservableObject {
    static let shared = CallManager()
    
    @Published var isInCall = false
    @Published var currentCall: Call?
    @Published var callState: CallState = .idle
    @Published var errorMessage: String?
    
    private let callController = CXCallController()
    private let provider: CXProvider
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        // CallKit Provider設定
        let configuration = CXProviderConfiguration(localizedName: "EmoCare Intercom")
        configuration.supportsVideo = false
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.iconTemplateImageData = UIImage(systemName: "phone.circle")?.pngData()
        
        provider = CXProvider(configuration: configuration)
        
        super.init()
        
        provider.setDelegate(self, queue: nil)
        
        print("✅ CallManager initialized")
    }
    
    // MARK: - Public Methods
    
    func initialize() async throws {
        // CallManager初期化処理
        await AudioManager.shared.configureAudioSession()
        print("✅ CallManager initialization completed")
    }
    
    func startCall(to channelId: String, isEmergency: Bool = false) async {
        guard !isInCall else {
            print("❌ Already in call")
            return
        }
        
        do {
            // 新しい通話を作成
            let call = Call(
                id: UUID(),
                channelId: channelId,
                direction: .outgoing,
                isEmergency: isEmergency,
                startTime: Date()
            )
            
            // CallKitに発信要求
            let handle = CXHandle(type: .generic, value: channelId)
            let startCallAction = CXStartCallAction(call: call.id, handle: handle)
            let transaction = CXTransaction(action: startCallAction)
            
            try await callController.request(transaction)
            
            // 状態更新
            await MainActor.run {
                self.currentCall = call
                self.callState = .dialing
                self.isInCall = true
            }
            
            // 実際の音声接続を開始
            await connectVoice(call: call)
            
            print("✅ Call started to channel: \(channelId)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "通話開始に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to start call: \(error)")
        }
    }
    
    func answerCall(callId: UUID) async {
        guard let call = currentCall, call.id == callId else {
            print("❌ Call not found for answering")
            return
        }
        
        do {
            // CallKitに応答
            let answerAction = CXAnswerCallAction(call: callId)
            let transaction = CXTransaction(action: answerAction)
            try await callController.request(transaction)
            
            // 状態更新
            await MainActor.run {
                self.callState = .connected
            }
            
            // 音声接続
            await connectVoice(call: call)
            
            print("✅ Call answered: \(callId)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "通話応答に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to answer call: \(error)")
        }
    }
    
    func endCall() async {
        guard let call = currentCall else {
            print("❌ No active call to end")
            return
        }
        
        do {
            // CallKitに終了要求
            let endAction = CXEndCallAction(call: call.id)
            let transaction = CXTransaction(action: endAction)
            try await callController.request(transaction)
            
            // 音声切断
            await disconnectVoice()
            
            // 状態リセット
            await MainActor.run {
                self.currentCall = nil
                self.callState = .idle
                self.isInCall = false
            }
            
            print("✅ Call ended: \(call.id)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "通話終了に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to end call: \(error)")
        }
    }
    
    func reportIncomingCall(channelId: String, callId: UUID, isEmergency: Bool = false) {
        // 着信をCallKitに報告
        let handle = CXHandle(type: .generic, value: channelId)
        let update = CXCallUpdate()
        update.remoteHandle = handle
        update.hasVideo = false
        update.localizedCallerName = isEmergency ? "緊急通話" : "EmoCare Intercom"
        
        provider.reportNewIncomingCall(with: callId, update: update) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Failed to report incoming call: \(error)")
                    self?.errorMessage = "着信の表示に失敗しました"
                } else {
                    // 新しい着信通話を記録
                    let call = Call(
                        id: callId,
                        channelId: channelId,
                        direction: .incoming,
                        isEmergency: isEmergency,
                        startTime: Date()
                    )
                    self?.currentCall = call
                    self?.callState = .ringing
                    self?.isInCall = true
                    print("✅ Incoming call reported: \(channelId)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func connectVoice(call: Call) async {
        // TODO: LiveKit音声接続を実装
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機（模擬）
        
        await MainActor.run {
            self.callState = .connected
        }
        
        print("✅ Voice connected for call: \(call.id)")
    }
    
    private func disconnectVoice() async {
        // TODO: LiveKit音声切断を実装
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機（模擬）
        
        print("✅ Voice disconnected")
    }
}

// MARK: - CXProviderDelegate

extension CallManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        print("✅ CallKit provider reset")
        Task { @MainActor in
            self.currentCall = nil
            self.callState = .idle
            self.isInCall = false
        }
    }
    
    nonisolated func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("✅ CallKit start call action")
        action.fulfill()
    }
    
    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("✅ CallKit answer call action")
        action.fulfill()
    }
    
    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("✅ CallKit end call action")
        action.fulfill()
    }
    
    nonisolated func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("✅ CallKit audio session activated")
        Task {
            await AudioManager.shared.activateAudioSession()
        }
    }
    
    nonisolated func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("✅ CallKit audio session deactivated")
        Task {
            await AudioManager.shared.deactivateAudioSession()
        }
    }
}

// MARK: - Models

struct Call: Identifiable {
    let id: UUID
    let channelId: String
    let direction: CallDirection
    let isEmergency: Bool
    let startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

enum CallDirection {
    case incoming
    case outgoing
}

enum CallState {
    case idle
    case dialing
    case ringing
    case connected
    case ended
    case failed
    
    var displayText: String {
        switch self {
        case .idle: return "待機中"
        case .dialing: return "発信中"
        case .ringing: return "着信中"
        case .connected: return "通話中"
        case .ended: return "終了"
        case .failed: return "失敗"
        }
    }
}
