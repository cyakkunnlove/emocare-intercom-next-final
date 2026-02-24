import SwiftUI
import PushKit
import CallKit

@main
struct EmoCareIntercomNextApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var callManager = CallManager()
    @StateObject private var audioManager = AudioManager()
    
    init() {
        // アプリ起動時の初期化
        setupAppearance()
        setupPushNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .environmentObject(callManager)
                .environmentObject(audioManager)
                .onAppear {
                    // アプリ表示時の処理
                    initializeApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                    // アプリ起動完了時の処理
                    handleAppLaunch()
                }
        }
    }
    
    private func setupAppearance() {
        // アプリのビジュアル設定
        UINavigationBar.appearance().tintColor = UIColor(Color.primary)
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
    private func setupPushNotifications() {
        // VoIP Push通知の初期設定
        VoIPPushManager.shared.registerForVoIPPush()
    }
    
    private func initializeApp() {
        // アプリ初期化処理
        Task {
            await authManager.checkAuthStatus()
            await appState.initialize()
        }
    }
    
    private func handleAppLaunch() {
        // 起動完了時の追加処理
        print("✅ EmoCare Intercom Next launched successfully")
    }
}

// MARK: - App State Management
@MainActor
class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func initialize() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // アプリ初期化処理
            try await performInitialization()
            isInitialized = true
        } catch {
            errorMessage = "初期化に失敗しました: \(error.localizedDescription)"
        }
    }
    
    private func performInitialization() async throws {
        // 各種サービスの初期化
        try await AudioManager.shared.initialize()
        try await CallManager.shared.initialize()
        
        // 設定の読み込み
        await loadAppSettings()
        
        print("✅ App initialization completed")
    }
    
    private func loadAppSettings() async {
        // アプリ設定の読み込み
        // TODO: Supabaseからユーザー設定を取得
    }
}