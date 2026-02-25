import SwiftUI
import Combine

@MainActor
class ChannelsViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var filteredChannels: [Channel] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    
    init() {
        setupSearchBinding()
        print("✅ ChannelsViewModel initialized")
    }
    
    deinit {
        refreshTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadChannels() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            guard let user = AuthenticationManager.shared.user else {
                throw ChannelsError.userNotAuthenticated
            }
            
            let facilityId = user.facilityId ?? "global-facility"
            
            let loadedChannels = try await SupabaseService.shared.fetchChannels(facilityId: facilityId)
            
            await MainActor.run {
                self.channels = loadedChannels.sorted { lhs, rhs in
                    // 緊急チャンネルを上部に表示
                    if lhs.isEmergencyChannel != rhs.isEmergencyChannel {
                        return lhs.isEmergencyChannel
                    }
                    return lhs.name < rhs.name
                }
                self.applySearchFilter()
            }
            
            print("✅ Loaded \(loadedChannels.count) channels")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "チャンネルの読み込みに失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to load channels: \(error)")
        }
    }
    
    func refreshChannels() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        refreshTask?.cancel()
        refreshTask = Task {
            await loadChannels()
        }
        
        await refreshTask?.value
    }
    
    func searchChannels(query: String) {
        searchQuery = query
        applySearchFilter()
    }
    
    func createChannel(name: String, description: String, isEmergency: Bool) async throws {
        guard let user = AuthenticationManager.shared.user else {
            throw ChannelsError.userNotAuthenticated
        }
        
        let facilityId = user.facilityId ?? "global-facility"
        
        // 権限チェック
        guard user.role == .admin || user.role == .manager else {
            throw ChannelsError.insufficientPermissions
        }
        
        let newChannel = Channel(
            id: UUID().uuidString,
            name: name,
            description: description,
            facilityId: facilityId,
            isEmergencyChannel: isEmergency,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // TODO: Supabaseにチャンネル作成API呼び出し
        // 現在はモック実装
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        
        await MainActor.run {
            self.channels.append(newChannel)
            self.channels.sort { lhs, rhs in
                if lhs.isEmergencyChannel != rhs.isEmergencyChannel {
                    return lhs.isEmergencyChannel
                }
                return lhs.name < rhs.name
            }
            self.applySearchFilter()
        }
        
        print("✅ Created channel: \(name)")
    }
    
    func deleteChannel(_ channel: Channel) async throws {
        guard let user = AuthenticationManager.shared.user else {
            throw ChannelsError.userNotAuthenticated
        }
        
        // 権限チェック
        guard user.role == .admin || user.role == .manager else {
            throw ChannelsError.insufficientPermissions
        }
        
        // 緊急チャンネルは削除不可
        guard !channel.isEmergencyChannel else {
            throw ChannelsError.cannotDeleteEmergencyChannel
        }
        
        // TODO: Supabaseからチャンネル削除API呼び出し
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        await MainActor.run {
            self.channels.removeAll { $0.id == channel.id }
            self.applySearchFilter()
        }
        
        print("✅ Deleted channel: \(channel.name)")
    }
    
    func updateChannel(_ channel: Channel, name: String, description: String) async throws {
        guard let user = AuthenticationManager.shared.user else {
            throw ChannelsError.userNotAuthenticated
        }
        
        // 権限チェック
        guard user.role == .admin || user.role == .manager else {
            throw ChannelsError.insufficientPermissions
        }
        
        // TODO: Supabaseでチャンネル更新API呼び出し
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        await MainActor.run {
            if let index = self.channels.firstIndex(where: { $0.id == channel.id }) {
                var updatedChannel = self.channels[index]
                updatedChannel.name = name
                updatedChannel.description = description
                updatedChannel.updatedAt = Date()
                
                self.channels[index] = updatedChannel
                self.applySearchFilter()
            }
        }
        
        print("✅ Updated channel: \(name)")
    }
    
    // MARK: - Private Methods
    
    private func setupSearchBinding() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySearchFilter()
            }
            .store(in: &cancellables)
    }
    
    private func applySearchFilter() {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredChannels = channels
        } else {
            let query = searchQuery.lowercased()
            filteredChannels = channels.filter { channel in
                channel.name.lowercased().contains(query) ||
                channel.description.lowercased().contains(query)
            }
        }
    }
    
    // MARK: - Channel Management
    
    func getChannelByID(_ channelId: String) -> Channel? {
        return channels.first { $0.id == channelId }
    }
    
    func getEmergencyChannels() -> [Channel] {
        return channels.filter { $0.isEmergencyChannel }
    }
    
    func getRegularChannels() -> [Channel] {
        return channels.filter { !$0.isEmergencyChannel }
    }
    
    func isUserAllowedToManageChannels() -> Bool {
        guard let user = AuthenticationManager.shared.user else { return false }
        return user.role == .admin || user.role == .manager
    }
    
    func getChannelParticipantCount(_ channelId: String) async -> Int {
        // TODO: Supabaseから参加者数を取得
        // モック実装
        return Int.random(in: 0...5)
    }
}

// MARK: - Channels Error

enum ChannelsError: LocalizedError {
    case userNotAuthenticated
    case facilityNotFound
    case insufficientPermissions
    case channelNotFound
    case cannotDeleteEmergencyChannel
    case invalidChannelData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "ユーザーが認証されていません"
        case .facilityNotFound:
            return "施設情報が見つかりません"
        case .insufficientPermissions:
            return "チャンネル管理の権限がありません"
        case .channelNotFound:
            return "チャンネルが見つかりません"
        case .cannotDeleteEmergencyChannel:
            return "緊急チャンネルは削除できません"
        case .invalidChannelData:
            return "チャンネルデータが無効です"
        case .networkError:
            return "ネットワーク接続を確認してください"
        }
    }
}

// MARK: - Channel Model Extensions

extension Channel {
    static func mockChannels() -> [Channel] {
        let facilityId = "facility-001"
        let now = Date()
        
        return [
            Channel(
                id: "emergency-channel",
                name: "緊急連絡",
                description: "緊急時専用チャンネル",
                facilityId: facilityId,
                isEmergencyChannel: true,
                createdAt: now.addingTimeInterval(-86400 * 7), // 1週間前
                updatedAt: now.addingTimeInterval(-3600) // 1時間前
            ),
            Channel(
                id: "nurse-station-1f",
                name: "1階ナースステーション",
                description: "1階の看護師連絡用",
                facilityId: facilityId,
                isEmergencyChannel: false,
                createdAt: now.addingTimeInterval(-86400 * 5), // 5日前
                updatedAt: now.addingTimeInterval(-1800) // 30分前
            ),
            Channel(
                id: "nurse-station-2f",
                name: "2階ナースステーション",
                description: "2階の看護師連絡用",
                facilityId: facilityId,
                isEmergencyChannel: false,
                createdAt: now.addingTimeInterval(-86400 * 5), // 5日前
                updatedAt: now.addingTimeInterval(-900) // 15分前
            ),
            Channel(
                id: "kitchen",
                name: "厨房",
                description: "食事準備・配膳連絡用",
                facilityId: facilityId,
                isEmergencyChannel: false,
                createdAt: now.addingTimeInterval(-86400 * 3), // 3日前
                updatedAt: now.addingTimeInterval(-7200) // 2時間前
            ),
            Channel(
                id: "management",
                name: "管理者連絡",
                description: "施設管理者専用チャンネル",
                facilityId: facilityId,
                isEmergencyChannel: false,
                createdAt: now.addingTimeInterval(-86400 * 10), // 10日前
                updatedAt: now.addingTimeInterval(-600) // 10分前
            )
        ]
    }
}
