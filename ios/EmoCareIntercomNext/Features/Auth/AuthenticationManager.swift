import SwiftUI
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 保存された認証状態をチェック
        checkSavedAuthState()
    }
    
    // MARK: - Public Methods
    
    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Supabaseからユーザー情報を取得
            if let savedUser = try await SupabaseService.shared.getCurrentUser() {
                self.user = savedUser
                self.isAuthenticated = true
                print("✅ User authenticated: \(savedUser.email)")
            } else {
                self.isAuthenticated = false
                print("❌ No authenticated user found")
            }
        } catch {
            print("❌ Auth check failed: \(error)")
            self.errorMessage = "認証状態の確認に失敗しました"
        }
    }
    
    func login(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let user = try await SupabaseService.shared.signIn(email: email, password: password)
            
            await MainActor.run {
                self.user = user
                self.isAuthenticated = true
            }
            
            // ログイン成功後の処理
            await postLoginSetup()
            
            print("✅ Login successful for: \(email)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = AuthError.loginFailed(error.localizedDescription).localizedDescription
            }
            throw error
        }
    }
    
    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await SupabaseService.shared.signOut()
            
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
            }
            
            // ログアウト後のクリーンアップ
            await postLogoutCleanup()
            
            print("✅ Logout successful")
            
        } catch {
            print("❌ Logout failed: \(error)")
            self.errorMessage = "ログアウトに失敗しました"
        }
    }
    
    // MARK: - Private Methods
    
    private func checkSavedAuthState() {
        // Supabaseセッションの有無を直接確認
        Task {
            await checkAuthStatus()
        }
    }
    
    private func postLoginSetup() async {
        // ログイン後の初期設定
        do {
            // VoIP通知の登録
            await VoIPPushManager.shared.registerDevice()
            
            // ユーザー設定の読み込み
            try await loadUserSettings()
            
        } catch {
            print("❌ Post-login setup failed: \(error)")
        }
    }
    
    private func postLogoutCleanup() async {
        // ログアウト後のクリーンアップ
        await VoIPPushManager.shared.unregisterDevice()
        KeychainHelper.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: "user_settings")
    }
    
    private func loadUserSettings() async throws {
        // ユーザー設定の読み込み
        // TODO: Supabaseからユーザー設定を取得
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let facilityId: String?
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
}

enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case staff = "staff"
    case manager = "manager"
    
    var displayName: String {
        switch self {
        case .admin: return "管理者"
        case .staff: return "スタッフ"
        case .manager: return "施設管理者"
        }
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidCredentials
    case loginFailed(String)
    case logoutFailed(String)
    case tokenExpired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "メールアドレスとパスワードを入力してください"
        case .loginFailed(let message):
            return "ログインに失敗しました: \(message)"
        case .logoutFailed(let message):
            return "ログアウトに失敗しました: \(message)"
        case .tokenExpired:
            return "認証の有効期限が切れました。再度ログインしてください"
        case .networkError:
            return "ネットワーク接続を確認してください"
        }
    }
}
