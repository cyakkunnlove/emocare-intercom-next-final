import Foundation

// MARK: - Channel Model
struct Channel: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    let facilityId: String
    let isEmergencyChannel: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return name.isEmpty ? "未設定チャンネル" : name
    }
    
    var shortDescription: String {
        if description.isEmpty {
            return isEmergencyChannel ? "緊急時専用チャンネル" : "通信チャンネル"
        }
        return description.count > 50 ? String(description.prefix(50)) + "..." : description
    }
    
    var iconName: String {
        return isEmergencyChannel ? "cross.case.fill" : "rectangle.3.group.fill"
    }
    
    var iconColor: Color {
        return isEmergencyChannel ? .red : .blue
    }
    
    // MARK: - Mock Data
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

// MARK: - CallRecord Model
struct CallRecord: Codable, Identifiable, Hashable {
    let id: String
    let channelId: String
    let callerId: String
    var callerName: String?
    let startTime: Date
    var endTime: Date?
    var duration: Int // seconds
    let callType: CallType
    let isEmergency: Bool
    var isSuccessful: Bool
    
    // MARK: - Computed Properties
    
    var durationFormatted: String {
        if duration == 0 {
            return "0秒"
        } else if duration < 60 {
            return "\(duration)秒"
        } else if duration < 3600 {
            let minutes = duration / 60
            let seconds = duration % 60
            return seconds > 0 ? "\(minutes)分\(seconds)秒" : "\(minutes)分"
        } else {
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            return minutes > 0 ? "\(hours)時間\(minutes)分" : "\(hours)時間"
        }
    }
    
    var startTimeFormatted: String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isToday(startTime) {
            formatter.timeStyle = .short
            return "今日 \(formatter.string(from: startTime))"
        } else if calendar.isYesterday(startTime) {
            formatter.timeStyle = .short
            return "昨日 \(formatter.string(from: startTime))"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(startTime) == true {
            formatter.dateFormat = "E HH:mm"
            return formatter.string(from: startTime)
        } else {
            formatter.dateFormat = "M/d HH:mm"
            return formatter.string(from: startTime)
        }
    }
    
    var callStatusIcon: String {
        if !isSuccessful {
            return "phone.down.circle.fill"
        } else if callType == .voip {
            return isEmergency ? "phone.circle.fill" : "phone.circle"
        } else {
            return "mic.circle"
        }
    }
    
    var callStatusColor: Color {
        if !isSuccessful {
            return .red
        } else if isEmergency {
            return .red
        } else {
            return .green
        }
    }
    
    // MARK: - Mock Data
    static func mockCallRecords() -> [CallRecord] {
        let channelIds = Channel.mockChannels().map { $0.id }
        let callerNames = ["田中看護師", "佐藤管理者", "山田スタッフ", "鈴木主任", "高橋師長"]
        
        var records: [CallRecord] = []
        let now = Date()
        
        for i in 0..<20 {
            let startTime = now.addingTimeInterval(-Double(i * 3600 + Int.random(in: 0...3600)))
            let duration = Int.random(in: 30...600)
            let isSuccessful = Int.random(in: 1...10) > 2 // 80% success rate
            
            records.append(CallRecord(
                id: "call-\(i)",
                channelId: channelIds.randomElement()!,
                callerId: "user-\(Int.random(in: 1...5))",
                callerName: callerNames.randomElement(),
                startTime: startTime,
                endTime: isSuccessful ? startTime.addingTimeInterval(TimeInterval(duration)) : nil,
                duration: isSuccessful ? duration : 0,
                callType: [CallType.voip, CallType.ptt].randomElement()!,
                isEmergency: Int.random(in: 1...10) == 1, // 10% emergency
                isSuccessful: isSuccessful
            ))
        }
        
        return records.sorted { $0.startTime > $1.startTime }
    }
}

// MARK: - CallType Enum
enum CallType: String, Codable, CaseIterable {
    case voip = "voip"
    case ptt = "ptt"
    
    var displayName: String {
        switch self {
        case .voip: return "通話"
        case .ptt: return "PTT"
        }
    }
    
    var icon: String {
        switch self {
        case .voip: return "phone"
        case .ptt: return "mic"
        }
    }
}

// MARK: - CallHistoryFilter Enum
enum CallHistoryFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case week = "week"
    case month = "month"
    case emergency = "emergency"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .all: return "すべて"
        case .today: return "今日"
        case .week: return "今週"
        case .month: return "今月"
        case .emergency: return "緊急"
        case .failed: return "失敗"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "calendar.today"
        case .week: return "calendar"
        case .month: return "calendar.month"
        case .emergency: return "exclamationmark.triangle"
        case .failed: return "phone.down"
        }
    }
}

// MARK: - CallStatistics Struct
struct CallStatistics {
    var totalCalls: Int = 0
    var todayCalls: Int = 0
    var weekCalls: Int = 0
    var emergencyCalls: Int = 0
    var averageDuration: TimeInterval = 0
    var successRate: Double = 0
    
    var averageDurationFormatted: String {
        if averageDuration == 0 {
            return "0分"
        } else if averageDuration < 60 {
            return "\(Int(averageDuration))秒"
        } else {
            let minutes = Int(averageDuration / 60)
            return "\(minutes)分"
        }
    }
    
    var successRateFormatted: String {
        return String(format: "%.1f%%", successRate * 100)
    }
    
    // MARK: - Mock Data
    static func mock() -> CallStatistics {
        return CallStatistics(
            totalCalls: Int.random(in: 50...200),
            todayCalls: Int.random(in: 0...15),
            weekCalls: Int.random(in: 10...50),
            emergencyCalls: Int.random(in: 0...5),
            averageDuration: TimeInterval.random(in: 120...400),
            successRate: Double.random(in: 0.8...0.95)
        )
    }
}

// MARK: - User Model Extensions
extension User {
    var displayName: String {
        return name ?? email.components(separatedBy: "@").first ?? "ユーザー"
    }
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(displayName.prefix(2))
        }
    }
}

extension UserRole {
    var color: Color {
        switch self {
        case .admin: return .red
        case .manager: return .orange
        case .staff: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "crown.fill"
        case .manager: return "person.badge.key.fill"
        case .staff: return "person.fill"
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func formatRelative() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)日前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: self)
        }
    }
    
    func formatCallTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isToday(self) {
            return "今日 \(formatter.string(from: self))"
        } else if calendar.isYesterday(self) {
            return "昨日 \(formatter.string(from: self))"
        } else {
            formatter.dateFormat = "M/d HH:mm"
            return formatter.string(from: self)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let systemGray6 = Color(.systemGray6)
    static let systemBackground = Color(.systemBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let separator = Color(.separator)
}