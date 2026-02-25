import SwiftUI
import Combine

@MainActor
class CallHistoryViewModel: ObservableObject {
    @Published var calls: [CallRecord] = []
    @Published var filteredCalls: [CallRecord] = []
    @Published var statistics = CallStatistics()
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var currentFilter: CallHistoryFilter = .all
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    
    init() {
        setupSearchBinding()
        print("✅ CallHistoryViewModel initialized")
    }
    
    deinit {
        refreshTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadCallHistory() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            guard let user = AuthenticationManager().user else {
                throw CallHistoryError.userNotAuthenticated
            }
            
            let loadedCalls = try await SupabaseService.shared.fetchCallHistory(userId: user.id)
            
            await MainActor.run {
                self.calls = loadedCalls.sorted { $0.startTime > $1.startTime }
                self.applyCurrentFilter()
                self.updateStatistics()
            }
            
            print("✅ Loaded \(loadedCalls.count) call records")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "通話履歴の読み込みに失敗しました: \(error.localizedDescription)"
            }
            print("❌ Failed to load call history: \(error)")
        }
    }
    
    func refreshCallHistory() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        refreshTask?.cancel()
        refreshTask = Task {
            await loadCallHistory()
        }
        
        await refreshTask?.value
    }
    
    func searchCalls(query: String) {
        searchQuery = query
        applyCurrentFilter()
    }
    
    func applyFilter(_ filter: CallHistoryFilter) {
        currentFilter = filter
        applyCurrentFilter()
    }
    
    func deleteCallRecord(_ call: CallRecord) async throws {
        guard let user = AuthenticationManager().user else {
            throw CallHistoryError.userNotAuthenticated
        }
        
        // 管理者権限チェック（必要に応じて）
        guard user.role == .admin || call.callerId == user.id else {
            throw CallHistoryError.insufficientPermissions
        }
        
        // TODO: Supabaseから通話記録を削除
        await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        await MainActor.run {
            self.calls.removeAll { $0.id == call.id }
            self.applyCurrentFilter()
            self.updateStatistics()
        }
        
        print("✅ Deleted call record: \(call.id)")
    }
    
    func getCallDetails(_ callId: String) async throws -> CallDetails {
        // TODO: Supabaseから詳細な通話情報を取得
        await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        // モック実装
        return CallDetails(
            id: callId,
            participants: [
                CallParticipant(userId: "user-001", name: "田中 看護師", joinTime: Date(), leaveTime: nil),
                CallParticipant(userId: "user-002", name: "佐藤 管理者", joinTime: Date().addingTimeInterval(30), leaveTime: Date().addingTimeInterval(180))
            ],
            audioQuality: CallAudioQuality(
                averageLatency: 45.2,
                packetLoss: 0.02,
                jitterBuffer: 12.5
            ),
            transcript: nil // 将来の機能
        )
    }
    
    // MARK: - Private Methods
    
    private func setupSearchBinding() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyCurrentFilter()
            }
            .store(in: &cancellables)
    }
    
    private func applyCurrentFilter() {
        var filtered = calls
        
        // テキスト検索フィルター
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { call in
                // チャンネル名での検索（実際の実装では ChannelsViewModel から取得）
                return call.channelId.lowercased().contains(query) ||
                       call.id.lowercased().contains(query)
            }
        }
        
        // カテゴリフィルター
        switch currentFilter {
        case .all:
            break // すべて表示
        case .voip:
            filtered = filtered.filter { $0.callType == .voip }
        case .ptt:
            filtered = filtered.filter { $0.callType == .ptt }
        case .emergency:
            filtered = filtered.filter { $0.isEmergency }
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.startTime) }
        case .week:
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            filtered = filtered.filter { $0.startTime > weekAgo }
        }
        
        filteredCalls = filtered
    }
    
    private func updateStatistics() {
        let now = Date()
        let calendar = Calendar.current
        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        
        let todayCalls = calls.filter { calendar.isDateInToday($0.startTime) }.count
        let weekCalls = calls.filter { $0.startTime > weekAgo }.count
        let emergencyCalls = calls.filter { $0.isEmergency }.count
        
        // 平均通話時間の計算
        let completedCalls = calls.filter { $0.endTime != nil }
        let totalDuration = completedCalls.reduce(0) { $0 + $1.duration }
        let averageDuration = completedCalls.isEmpty ? 0 : totalDuration / completedCalls.count
        
        statistics = CallStatistics(
            todayCalls: todayCalls,
            weekCalls: weekCalls,
            emergencyCalls: emergencyCalls,
            averageDuration: averageDuration
        )
    }
    
    // MARK: - Export and Sharing
    
    func exportCallHistory(format: ExportFormat, dateRange: DateRange) async throws -> URL {
        guard !calls.isEmpty else {
            throw CallHistoryError.noDataToExport
        }
        
        let filteredCalls = filterCallsByDateRange(dateRange)
        
        switch format {
        case .csv:
            return try await generateCSVReport(calls: filteredCalls)
        case .pdf:
            return try await generatePDFReport(calls: filteredCalls)
        }
    }
    
    private func filterCallsByDateRange(_ range: DateRange) -> [CallRecord] {
        let now = Date()
        let startDate: Date
        
        switch range {
        case .today:
            startDate = Calendar.current.startOfDay(for: now)
        case .week:
            startDate = now.addingTimeInterval(-7 * 24 * 3600)
        case .month:
            startDate = now.addingTimeInterval(-30 * 24 * 3600)
        case .all:
            return calls
        }
        
        return calls.filter { $0.startTime >= startDate }
    }
    
    private func generateCSVReport(calls: [CallRecord]) async throws -> URL {
        // TODO: CSV生成の実装
        // モック実装
        let csvContent = generateMockCSV(calls: calls)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let csvURL = documentsPath.appendingPathComponent("call_history_\(Date().timeIntervalSince1970).csv")
        
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        return csvURL
    }
    
    private func generatePDFReport(calls: [CallRecord]) async throws -> URL {
        // TODO: PDF生成の実装
        // モック実装
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsPath.appendingPathComponent("call_history_\(Date().timeIntervalSince1970).pdf")
        
        // 空のPDFファイルを作成（モック）
        try Data().write(to: pdfURL)
        return pdfURL
    }
    
    private func generateMockCSV(calls: [CallRecord]) -> String {
        var csv = "日時,チャンネル,通話タイプ,継続時間,緊急フラグ,状態\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for call in calls {
            let dateString = dateFormatter.string(from: call.startTime)
            let durationString = "\(call.duration)秒"
            let typeString = call.callType == .voip ? "音声通話" : "PTT"
            let emergencyString = call.isEmergency ? "緊急" : "通常"
            let statusString = call.endTime != nil ? "完了" : "失敗"
            
            csv += "\(dateString),\(call.channelId),\(typeString),\(durationString),\(emergencyString),\(statusString)\n"
        }
        
        return csv
    }
}

// MARK: - Models

struct CallStatistics {
    let todayCalls: Int
    let weekCalls: Int
    let emergencyCalls: Int
    let averageDuration: Int // seconds
    
    init(todayCalls: Int = 0, weekCalls: Int = 0, emergencyCalls: Int = 0, averageDuration: Int = 0) {
        self.todayCalls = todayCalls
        self.weekCalls = weekCalls
        self.emergencyCalls = emergencyCalls
        self.averageDuration = averageDuration
    }
    
    var averageDurationString: String {
        if averageDuration < 60 {
            return "\(averageDuration)秒"
        } else {
            let minutes = averageDuration / 60
            let seconds = averageDuration % 60
            return "\(minutes)分\(seconds)秒"
        }
    }
}

struct CallDetails {
    let id: String
    let participants: [CallParticipant]
    let audioQuality: CallAudioQuality
    let transcript: String?
}

struct CallParticipant {
    let userId: String
    let name: String
    let joinTime: Date
    let leaveTime: Date?
    
    var duration: TimeInterval? {
        guard let leaveTime = leaveTime else { return nil }
        return leaveTime.timeIntervalSince(joinTime)
    }
}

struct CallAudioQuality {
    let averageLatency: Double // milliseconds
    let packetLoss: Double // percentage (0.0-1.0)
    let jitterBuffer: Double // milliseconds
}

enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .pdf: return "PDF"
        }
    }
}

enum DateRange: String, CaseIterable {
    case today = "today"
    case week = "week"
    case month = "month"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .today: return "今日"
        case .week: return "今週"
        case .month: return "今月"
        case .all: return "すべて"
        }
    }
}

// MARK: - Errors

enum CallHistoryError: LocalizedError {
    case userNotAuthenticated
    case insufficientPermissions
    case callRecordNotFound
    case noDataToExport
    case exportFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "ユーザーが認証されていません"
        case .insufficientPermissions:
            return "操作する権限がありません"
        case .callRecordNotFound:
            return "通話記録が見つかりません"
        case .noDataToExport:
            return "エクスポートするデータがありません"
        case .exportFailed(let message):
            return "エクスポートに失敗しました: \(message)"
        case .networkError:
            return "ネットワーク接続を確認してください"
        }
    }
}