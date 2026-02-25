import SwiftUI

struct ChannelDetailView: View {
    let channel: Channel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var liveKitService = LiveKitService.shared
    @StateObject private var pttManager = PTTManager.shared
    @StateObject private var callManager = CallManager.shared
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var isConnectedToVoice = false
    @State private var showingSettings = false
    @State private var participants: [ChannelParticipant] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー情報
                ChannelHeaderView()
                
                // 音声接続状態
                VoiceConnectionStatusView()
                
                // 参加者一覧
                ParticipantsListView()
                
                Spacer()
                
                // PTTボタン（音声接続時のみ）
                if isConnectedToVoice {
                    PTTControlView()
                }
                
                // 通話コントロール
                CallControlsView()
            }
            .navigationTitle(channel.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("閉じる") { dismiss() },
                trailing: settingsButton
            )
        }
        .task {
            await loadChannelDetails()
        }
        .onChange(of: liveKitService.isConnected) { _, isConnected in
            isConnectedToVoice = isConnected
        }
        .sheet(isPresented: $showingSettings) {
            ChannelSettingsView(channel: channel)
        }
    }
    
    // MARK: - Channel Header
    @ViewBuilder
    private func ChannelHeaderView() -> some View {
        VStack(spacing: 16) {
            // チャンネルアイコン
            ZStack {
                Circle()
                    .fill(channel.isEmergencyChannel ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: channel.isEmergencyChannel ? "cross.case.fill" : "rectangle.3.group.fill")
                    .font(.system(size: 30))
                    .foregroundColor(channel.isEmergencyChannel ? .red : .blue)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text(channel.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if channel.isEmergencyChannel {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if !channel.description.isEmpty {
                    Text(channel.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Voice Connection Status
    @ViewBuilder
    private func VoiceConnectionStatusView() -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isConnectedToVoice ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
                .scaleEffect(isConnectedToVoice ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isConnectedToVoice)
            
            Text(isConnectedToVoice ? "音声接続中" : "音声未接続")
                .font(.headline)
                .foregroundColor(isConnectedToVoice ? .green : .secondary)
            
            Spacer()
            
            if liveKitService.isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.separator),
            alignment: .bottom
        )
    }
    
    // MARK: - Participants List
    @ViewBuilder
    private func ParticipantsListView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("参加者")
                    .font(.headline)
                
                Spacer()
                
                Text("\(participants.count)人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if participants.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("現在参加者はいません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(participants) { participant in
                        ParticipantRowView(participant: participant)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - PTT Control
    @ViewBuilder
    private func PTTControlView() -> some View {
        VStack(spacing: 16) {
            Text("Push to Talk")
                .font(.headline)
                .foregroundColor(.secondary)
            
            PTTButton(channelId: channel.id)
            
            if pttManager.isPTTActive {
                VStack(spacing: 8) {
                    Text("録音中...")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    ProgressView(value: Double(pttManager.getCurrentRecordingDuration()), total: 30.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(width: 200)
                    
                    Text("残り: \(Int(pttManager.getRemainingRecordingTime()))秒")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("長押しして話す")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Call Controls
    @ViewBuilder
    private func CallControlsView() -> some View {
        HStack(spacing: 20) {
            // 音声接続/切断ボタン
            Button(action: {
                Task {
                    if isConnectedToVoice {
                        await disconnectFromVoice()
                    } else {
                        await connectToVoice()
                    }
                }
            }) {
                HStack {
                    Image(systemName: isConnectedToVoice ? "phone.down" : "phone")
                        .font(.title3)
                    Text(isConnectedToVoice ? "切断" : "接続")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isConnectedToVoice ? Color.red : Color.green)
                .cornerRadius(12)
            }
            .disabled(liveKitService.isConnecting)
            
            // 通話ボタン
            Button(action: {
                Task {
                    await callManager.startCall(to: channel.id, isEmergency: channel.isEmergencyChannel)
                }
            }) {
                HStack {
                    Image(systemName: channel.isEmergencyChannel ? "phone.fill.badge.plus" : "phone.circle")
                        .font(.title3)
                    Text("通話")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(channel.isEmergencyChannel ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .disabled(callManager.isInCall)
        }
        .padding()
    }
    
    // MARK: - Settings Button
    @ViewBuilder
    private var settingsButton: some View {
        if authManager.user?.role == .admin || authManager.user?.role == .manager {
            Button("設定") {
                showingSettings = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadChannelDetails() async {
        // チャンネル参加者情報を取得
        await loadParticipants()
        
        // チャンネル音声接続状態を確認
        await checkVoiceConnection()
    }
    
    private func loadParticipants() async {
        // TODO: Supabaseからチャンネル参加者を取得
        // モック実装
        await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        let mockParticipants = [
            ChannelParticipant(
                id: "user-001",
                name: "田中 看護師",
                role: .staff,
                isOnline: true,
                isSpeaking: false,
                joinedAt: Date().addingTimeInterval(-1800)
            ),
            ChannelParticipant(
                id: "user-002", 
                name: "佐藤 管理者",
                role: .manager,
                isOnline: true,
                isSpeaking: true,
                joinedAt: Date().addingTimeInterval(-900)
            )
        ]
        
        await MainActor.run {
            self.participants = mockParticipants
        }
    }
    
    private func checkVoiceConnection() async {
        isConnectedToVoice = liveKitService.isConnected
    }
    
    private func connectToVoice() async {
        do {
            // TODO: Supabaseから音声トークンを取得
            let token = "mock-voice-token"
            let url = "wss://mock-livekit-server"
            
            try await liveKitService.connect(url: url, token: token, roomName: channel.id)
            await liveKitService.optimizeForVoIP()
            
            print("✅ Connected to voice for channel: \(channel.name)")
            
        } catch {
            print("❌ Failed to connect to voice: \(error)")
        }
    }
    
    private func disconnectFromVoice() async {
        await liveKitService.disconnect()
        print("✅ Disconnected from voice")
    }
}

// MARK: - Participant Row View
struct ParticipantRowView: View {
    let participant: ChannelParticipant
    
    var body: some View {
        HStack(spacing: 12) {
            // ユーザーアバター
            Circle()
                .fill(participant.role.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(participant.name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(participant.role.color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(participant.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if participant.isSpeaking {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Text(participant.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // オンライン状態
            Circle()
                .fill(participant.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Channel Participant Model
struct ChannelParticipant: Identifiable {
    let id: String
    let name: String
    let role: UserRole
    let isOnline: Bool
    let isSpeaking: Bool
    let joinedAt: Date
}

// MARK: - User Role Extension
extension UserRole {
    var color: Color {
        switch self {
        case .admin: return .red
        case .manager: return .orange
        case .staff: return .blue
        }
    }
}

#Preview {
    ChannelDetailView(
        channel: Channel.mockChannels()[0]
    )
    .environmentObject(AuthenticationManager())
}