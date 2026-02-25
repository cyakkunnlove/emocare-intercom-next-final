import Foundation
import Combine
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    // EmoCare本体と同じSupabaseプロジェクトを利用
    private let supabaseClient: SupabaseClient

    private init() {
        self.supabaseClient = SupabaseClient(
            supabaseURL: URL(string: "https://vivhqjpmkorbxebtncxi.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpdmhxanBta29yYnhlYnRuY3hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NzIyMjgsImV4cCI6MjA2NTU0ODIyOH0.7ex5q2skY1bhBMkGS_FfR4wwjRs3uOadcngMHtvTLOk"
        )
    }

    // MARK: - Authentication

    func getCurrentUser() async throws -> User? {
        do {
            let session = try await supabaseClient.auth.session
            let userId = session.user.id.uuidString
            let fallbackEmail = session.user.email ?? ""

            if let profileUser = try await fetchUserProfile(userId: userId, fallbackEmail: fallbackEmail) {
                return profileUser
            }

            return User(
                id: userId,
                email: fallbackEmail,
                name: nil,
                facilityId: nil,
                role: .staff,
                createdAt: Date(),
                updatedAt: Date()
            )
        } catch {
            return nil
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(normalizedEmail) else {
            throw SupabaseError.invalidEmail
        }

        guard normalizedPassword.count >= 6 else {
            throw SupabaseError.weakPassword
        }

        do {
            let response = try await supabaseClient.auth.signIn(
                email: normalizedEmail,
                password: normalizedPassword
            )

            let session = try await supabaseClient.auth.session
            KeychainHelper.saveAuthToken(session.accessToken)

            let userId = response.user.id.uuidString
            let fallbackEmail = response.user.email ?? normalizedEmail

            if let profileUser = try await fetchUserProfile(userId: userId, fallbackEmail: fallbackEmail) {
                return profileUser
            }

            return User(
                id: userId,
                email: fallbackEmail,
                name: nil,
                facilityId: nil,
                role: .staff,
                createdAt: Date(),
                updatedAt: Date()
            )
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("invalid login credentials") || message.contains("email") || message.contains("password") {
                throw SupabaseError.invalidCredentials
            }
            throw SupabaseError.serverError(error.localizedDescription)
        }
    }

    func signOut() async throws {
        try await supabaseClient.auth.signOut()
        KeychainHelper.clearAuthToken()
        print("✅ Signed out successfully")
    }

    // MARK: - Database Operations

    func fetchChannels(facilityId: String) async throws -> [Channel] {
        // Intercom専用テーブル未整備のため、当面はアプリ側チャンネルを返す
        return [
            Channel(
                id: "channel-001",
                name: "1階ナースステーション",
                description: "1階の看護師室",
                facilityId: facilityId,
                isEmergencyChannel: false,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Channel(
                id: "channel-002",
                name: "緊急連絡",
                description: "緊急時専用チャンネル",
                facilityId: facilityId,
                isEmergencyChannel: true,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }

    func fetchCallHistory(userId: String) async throws -> [CallRecord] {
        // Intercom専用通話テーブル未整備のため、当面はモックを返す
        return [
            CallRecord(
                id: "call-001",
                channelId: "channel-001",
                callerId: userId,
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-3500),
                duration: 60,
                callType: .voip,
                isEmergency: false
            )
        ]
    }

    // MARK: - Realtime Subscriptions

    func subscribeToChannelUpdates(channelId: String) async -> AsyncStream<ChannelUpdate> {
        return AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    continuation.yield(.memberJoined("mock-user"))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func fetchUserProfile(userId: String, fallbackEmail: String) async throws -> User? {
        let response = try await supabaseClient.database
            .from("users")
            .select("id,email,first_name,last_name,role,facility_id,created_at,updated_at")
            .eq("id", value: userId)
            .limit(1)
            .execute()

        guard
            let json = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
            let row = json.first
        else {
            return nil
        }

        let firstName = row["first_name"] as? String ?? ""
        let lastName = row["last_name"] as? String ?? ""
        let fullName = "\(lastName)\(firstName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let name: String? = fullName.isEmpty ? nil : fullName

        let email = (row["email"] as? String) ?? fallbackEmail
        let role = mapRole(row["role"] as? String)
        let facilityId = row["facility_id"] as? String
        let createdAt = parseDate(row["created_at"])
        let updatedAt = parseDate(row["updated_at"])

        return User(
            id: userId,
            email: email,
            name: name,
            facilityId: facilityId,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func mapRole(_ value: String?) -> UserRole {
        switch value {
        case "system_admin":
            return .admin
        case "facility_manager":
            return .manager
        default:
            return .staff
        }
    }

    private func parseDate(_ value: Any?) -> Date {
        if let dateString = value as? String {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return Date()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Models

struct Channel: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    let facilityId: String
    let isEmergencyChannel: Bool
    let createdAt: Date
    var updatedAt: Date
}

struct CallRecord: Codable, Identifiable {
    let id: String
    let channelId: String
    let callerId: String
    let startTime: Date
    let endTime: Date?
    let duration: Int
    let callType: CallType
    let isEmergency: Bool
}

enum CallType: String, Codable {
    case voip = "voip"
    case ptt = "ptt"
}

enum ChannelUpdate {
    case memberJoined(String)
    case memberLeft(String)
    case callStarted(String)
    case callEnded(String)
    case emergencyActivated
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case networkError
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "有効なメールアドレスを入力してください"
        case .weakPassword:
            return "パスワードは6文字以上で入力してください"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .networkError:
            return "ネットワーク接続を確認してください"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}
