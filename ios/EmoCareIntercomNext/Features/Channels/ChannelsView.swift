import SwiftUI

struct ChannelsView: View {
    @StateObject private var viewModel = ChannelsViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var callManager: CallManager
    @State private var showingChannelDetail = false
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    @State private var showingCreateChannel = false
    
    var body: some View {
        // 端末ごとの safe area からタブバー領域を動的に算出する
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let bottomInset = TabbedScreenLayout.contentBottomInset(safeAreaBottom: safeAreaBottom)

            NavigationView {
                VStack(spacing: 0) {
                    ScreenHeader()

                    // 検索バー
                    SearchBar()
                    
                    // チャンネルリスト
                    ChannelsList(bottomInset: bottomInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationBarHidden(true)
                .overlay(alignment: .bottomTrailing) {
                    // タブバー高さを考慮して + ボタンを重ならない位置へ配置する
                    if authManager.user?.role == .admin || authManager.user?.role == .manager {
                        CreateChannelFloatingButton()
                            .padding(.trailing, TabbedScreenLayout.floatingButtonTrailingInset)
                            .padding(.bottom, TabbedScreenLayout.floatingButtonBottomInset(safeAreaBottom: safeAreaBottom))
                    }
                }
                .refreshable {
                    await viewModel.refreshChannels()
                }
                .task {
                    await viewModel.loadChannels()
                }
                .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
            .sheet(isPresented: $showingChannelDetail) {
                if let channel = selectedChannel {
                    ChannelDetailView(channel: channel)
                }
            }
            .sheet(isPresented: $showingCreateChannel) {
                CreateChannelView()
            }
        }
    }

    @ViewBuilder
    private func ScreenHeader() -> some View {
        HStack {
            Text("チャンネル")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal, TabbedScreenLayout.headerHorizontalPadding)
        .padding(.top, TabbedScreenLayout.headerTopPadding)
        .padding(.bottom, TabbedScreenLayout.headerBottomPadding)
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private func SearchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("チャンネルを検索", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    viewModel.searchChannels(query: newValue)
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, TabbedScreenLayout.headerHorizontalPadding)
        .padding(.top, TabbedScreenLayout.sectionTopSpacing)
    }
    
    // MARK: - Channels List
    @ViewBuilder
    private func ChannelsList(bottomInset: CGFloat) -> some View {
        Group {
            if viewModel.isLoading && viewModel.channels.isEmpty {
                LoadingStateView()
            } else if viewModel.channels.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredChannels) { channel in
                            ChannelRowView(
                                channel: channel,
                                onTap: {
                                    selectedChannel = channel
                                    showingChannelDetail = true
                                },
                                onCallTap: {
                                    Task {
                                        await callManager.startCall(to: channel.id, isEmergency: channel.isEmergencyChannel)
                                    }
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, TabbedScreenLayout.headerHorizontalPadding)
                    .padding(.bottom, TabbedScreenLayout.floatingButtonListClearance)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: bottomInset)
        }
    }
    
    // MARK: - Loading State
    @ViewBuilder
    private func LoadingStateView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("チャンネルを読み込み中...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("チャンネルがありません")
                    .font(.title2)
                    .fontWeight(.semibold)

                if searchText.isEmpty {
                    Text("管理者にお問い合わせください")
                        .foregroundColor(.secondary)
                } else {
                    Text("'\(searchText)' に一致するチャンネルが見つかりません")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if searchText.isEmpty && (authManager.user?.role == .admin || authManager.user?.role == .manager) {
                Button("最初のチャンネルを作成") {
                    showingCreateChannel = true
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal)
        .padding(.top, 24)
    }
    
    // MARK: - Floating Create Button
    @ViewBuilder
    private func CreateChannelFloatingButton() -> some View {
        Button(action: {
            showingCreateChannel = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Channel Row View
struct ChannelRowView: View {
    let channel: Channel
    let onTap: () -> Void
    let onCallTap: () -> Void
    
    @StateObject private var participantsManager = ChannelParticipantsManager()
    
    var body: some View {
        HStack(spacing: 16) {
            // チャンネルアイコン
            ChannelIconView(channel: channel)
            
            // チャンネル情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(channel.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if channel.isEmergencyChannel {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if participantsManager.activeParticipants > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.wave.2.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("\(participantsManager.activeParticipants)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if !channel.description.isEmpty {
                    Text(channel.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("最終更新: \(formatLastUpdated(channel.updatedAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 通話ボタン
            Button(action: onCallTap) {
                Image(systemName: channel.isEmergencyChannel ? "phone.fill.badge.plus" : "phone")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(channel.isEmergencyChannel ? Color.red : Color.green)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(channel.isEmergencyChannel ? Color.red.opacity(0.3) : Color.blue.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
        .task {
            await participantsManager.startMonitoring(channelId: channel.id)
        }
        .onDisappear {
            participantsManager.stopMonitoring()
        }
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - Channel Icon View
struct ChannelIconView: View {
    let channel: Channel
    
    var body: some View {
        ZStack {
            Circle()
                .fill(channel.isEmergencyChannel ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(channel.isEmergencyChannel ? .red : .blue)
        }
    }
    
    private var iconName: String {
        if channel.isEmergencyChannel {
            return "cross.case.fill"
        } else {
            return "rectangle.3.group.fill"
        }
    }
}

// MARK: - Channel Participants Manager
@MainActor
class ChannelParticipantsManager: ObservableObject {
    @Published var activeParticipants: Int = 0
    
    private var channelId: String?
    private var task: Task<Void, Never>?
    
    func startMonitoring(channelId: String) async {
        stopMonitoring()
        
        self.channelId = channelId
        
        task = Task {
            // チャンネル参加者を監視
            for await update in await SupabaseService.shared.subscribeToChannelUpdates(channelId: channelId) {
                switch update {
                case .memberJoined:
                    activeParticipants += 1
                case .memberLeft:
                    activeParticipants = max(0, activeParticipants - 1)
                default:
                    break
                }
            }
        }
        
        // 初期参加者数を取得
        await updateParticipantCount()
    }
    
    func stopMonitoring() {
        task?.cancel()
        task = nil
        activeParticipants = 0
    }
    
    private func updateParticipantCount() async {
        guard let channelId = channelId else { return }
        
        // TODO: Supabaseから現在の参加者数を取得
        // モック実装
        activeParticipants = Int.random(in: 0...3)
    }
}

#Preview {
    NavigationView {
        ChannelsView()
    }
    .environmentObject(AuthenticationManager())
    .environmentObject(CallManager.shared)
}
