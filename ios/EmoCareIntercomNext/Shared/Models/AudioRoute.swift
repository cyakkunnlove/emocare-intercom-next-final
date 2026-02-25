import Foundation
import AVFoundation

enum AudioRoute: String, CaseIterable {
    case earpiece = "earpiece"
    case speaker = "speaker"
    case bluetooth = "bluetooth"
    case headphones = "headphones"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .earpiece:
            return "イヤピース"
        case .speaker:
            return "スピーカー"
        case .bluetooth:
            return "Bluetooth"
        case .headphones:
            return "ヘッドフォン"
        case .unknown:
            return "不明"
        }
    }
    
    var icon: String {
        switch self {
        case .earpiece:
            return "iphone"
        case .speaker:
            return "speaker.wave.2"
        case .bluetooth:
            return "bluetooth"
        case .headphones:
            return "headphones"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    static func from(audioSession: AVAudioSession) -> AudioRoute {
        guard let currentRoute = audioSession.currentRoute.outputs.first else {
            return .unknown
        }
        
        switch currentRoute.portType {
        case .builtInReceiver:
            return .earpiece
        case .builtInSpeaker:
            return .speaker
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return .bluetooth
        case .headphones, .headsetMic:
            return .headphones
        default:
            return .unknown
        }
    }
}

// MARK: - Audio Route Manager Extension
extension AudioManager {
    func updateAudioRoute() {
        let route = AudioRoute.from(audioSession: audioSession)
        
        DispatchQueue.main.async {
            self.audioRoute = route
            self.isSpeakerEnabled = (route == .speaker)
        }
        
        print("✅ Audio route updated: \(route.displayName)")
    }
    
    func setAudioRoute(_ route: AudioRoute) async {
        do {
            switch route {
            case .speaker:
                try audioSession.overrideOutputAudioPort(.speaker)
            case .earpiece:
                try audioSession.overrideOutputAudioPort(.none)
            case .bluetooth, .headphones:
                // Bluetooth/ヘッドフォンは自動で切り替わる
                try audioSession.overrideOutputAudioPort(.none)
            case .unknown:
                break
            }
            
            await MainActor.run {
                updateAudioRoute()
            }
            
            print("✅ Audio route set to: \(route.displayName)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "音声ルート変更に失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to set audio route: \(error)")
        }
    }
}