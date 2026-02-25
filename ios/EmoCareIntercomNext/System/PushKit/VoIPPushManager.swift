import PushKit
import UIKit

class VoIPPushManager: NSObject, PKPushRegistryDelegate {
    static let shared = VoIPPushManager()
    
    private let pushRegistry = PKPushRegistry(queue: nil)
    private var deviceToken: Data?
    
    override init() {
        super.init()
        pushRegistry.delegate = self
        print("✅ VoIPPushManager initialized")
    }
    
    // MARK: - Public Methods
    
    func registerForVoIPPush() {
        pushRegistry.desiredPushTypes = [.voIP]
        print("✅ VoIP push registration requested")
    }
    
    func registerDevice() async {
        guard let token = deviceToken else {
            print("❌ No VoIP token available for registration")
            return
        }
        
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        
        // TODO: Supabaseにデバイストークンを登録
        do {
            try await registerTokenWithServer(tokenString)
            print("✅ Device registered with token: \(tokenString.prefix(20))...")
        } catch {
            print("❌ Failed to register device: \(error)")
        }
    }
    
    func unregisterDevice() async {
        guard let token = deviceToken else {
            print("❌ No VoIP token for unregistration")
            return
        }
        
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        
        // TODO: Supabaseからデバイストークンを削除
        do {
            try await unregisterTokenWithServer(tokenString)
            print("✅ Device unregistered")
        } catch {
            print("❌ Failed to unregister device: \(error)")
        }
    }
    
    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        
        deviceToken = pushCredentials.token
        let tokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        
        print("✅ VoIP push token received: \(tokenString.prefix(20))...")
        
        // 自動的にサーバーに登録
        Task {
            await registerDevice()
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        
        print("⚠️ VoIP push token invalidated")
        deviceToken = nil
        
        // サーバーから登録解除
        Task {
            await unregisterDevice()
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) async {
        guard type == .voIP else { return }
        
        print("📥 VoIP push received: \(payload.dictionaryPayload)")
        
        // プッシュペイロードを解析
        await handleIncomingPush(payload: payload.dictionaryPayload)
    }
    
    // MARK: - Private Methods
    
    private func handleIncomingPush(payload: [AnyHashable: Any]) async {
        // 通話招待ペイロードを解析
        guard let channelId = payload["channel_id"] as? String,
              let callIdString = payload["call_id"] as? String,
              let callId = UUID(uuidString: callIdString) else {
            print("❌ Invalid VoIP push payload")
            return
        }
        
        let isEmergency = payload["is_emergency"] as? Bool ?? false
        let callerName = payload["caller_name"] as? String ?? "EmoCare Intercom"
        
        print("✅ Processing incoming call: channel=\(channelId), callId=\(callId), emergency=\(isEmergency)")
        
        // CallKitに着信を報告
        await CallManager.shared.reportIncomingCall(
            channelId: channelId,
            callId: callId,
            isEmergency: isEmergency
        )
        
        // 通話履歴に記録
        await recordIncomingCall(
            channelId: channelId,
            callId: callId,
            callerName: callerName,
            isEmergency: isEmergency
        )
    }
    
    private func recordIncomingCall(channelId: String, callId: UUID, callerName: String, isEmergency: Bool) async {
        // TODO: 通話履歴をローカル・サーバーに記録
        print("✅ Incoming call recorded: \(callId)")
    }
    
    private func registerTokenWithServer(_ token: String) async throws {
        // TODO: Supabase API呼び出しでトークン登録
        // モック実装
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        print("✅ Token registered with server (mock)")
    }
    
    private func unregisterTokenWithServer(_ token: String) async throws {
        // TODO: Supabase API呼び出しでトークン削除
        // モック実装
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        print("✅ Token unregistered from server (mock)")
    }
}

// MARK: - VoIP Push Payload Models

struct VoIPPushPayload {
    let channelId: String
    let callId: UUID
    let callerName: String
    let isEmergency: Bool
    let timestamp: Date
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let channelId = dictionary["channel_id"] as? String,
              let callIdString = dictionary["call_id"] as? String,
              let callId = UUID(uuidString: callIdString) else {
            return nil
        }
        
        self.channelId = channelId
        self.callId = callId
        self.callerName = dictionary["caller_name"] as? String ?? "EmoCare Intercom"
        self.isEmergency = dictionary["is_emergency"] as? Bool ?? false
        
        if let timestampString = dictionary["timestamp"] as? String,
           let timestampInterval = Double(timestampString) {
            self.timestamp = Date(timeIntervalSince1970: timestampInterval)
        } else {
            self.timestamp = Date()
        }
    }
}