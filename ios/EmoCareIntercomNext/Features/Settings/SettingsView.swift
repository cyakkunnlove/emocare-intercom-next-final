import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var audioManager: AudioManager
    @State private var showingLogoutConfirmation = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScreenHeader()

                List {
                    // ユーザー情報セクション
                    UserInfoSection()
                    
                    // 音声設定セクション
                    AudioSettingsSection()
                    
                    // アプリ設定セクション
                    AppSettingsSection()
                    
                    // アカウント管理セクション
                    AccountSection()
                    
                    // 情報セクション
                    InfoSection()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationBarHidden(true)
            .alert("ログアウト", isPresented: $showingLogoutConfirmation) {
                Button("キャンセル", role: .cancel) { }
                Button("ログアウト", role: .destructive) {
                    Task {
                        await authManager.logout()
                    }
                }
            } message: {
                Text("ログアウトしてもよろしいですか？")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    @ViewBuilder
    private func ScreenHeader() -> some View {
        HStack {
            Text("設定")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - User Info Section
    @ViewBuilder
    private func UserInfoSection() -> some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.user?.name ?? "ユーザー")
                        .font(.headline)
                    
                    Text(authManager.user?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.user?.role.displayName ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text("ユーザー情報")
        }
    }
    
    // MARK: - Audio Settings Section
    @ViewBuilder
    private func AudioSettingsSection() -> some View {
        Section {
            // 現在のオーディオルート
            HStack {
                Image(systemName: audioManager.audioRoute.icon)
                    .foregroundColor(.green)
                Text("オーディオルート")
                Spacer()
                Text(audioManager.audioRoute.displayName)
                    .foregroundColor(.secondary)
            }
            
            // スピーカーフォン設定
            HStack {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.orange)
                Text("スピーカーフォン")
                Spacer()
                Toggle("", isOn: .constant(audioManager.isSpeakerEnabled))
                    .disabled(!audioManager.isAudioActive)
            }
            
            // マイクテスト
            Button(action: {
                Task {
                    if audioManager.isMicrophoneEnabled {
                        await audioManager.setMicrophoneEnabled(false)
                    } else {
                        await audioManager.setMicrophoneEnabled(true)
                    }
                }
            }) {
                HStack {
                    Image(systemName: audioManager.isMicrophoneEnabled ? "mic.fill" : "mic")
                        .foregroundColor(audioManager.isMicrophoneEnabled ? .red : .gray)
                    Text("マイクテスト")
                    Spacer()
                    Text(audioManager.isMicrophoneEnabled ? "ON" : "OFF")
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!audioManager.isAudioActive)
            
        } header: {
            Text("音声設定")
        } footer: {
            Text("通話中のみ音声設定を変更できます")
        }
    }
    
    // MARK: - App Settings Section
    @ViewBuilder
    private func AppSettingsSection() -> some View {
        Section {
            // 通知設定
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.blue)
                    Text("通知設定")
                }
            }
            
            // プライバシー設定
            NavigationLink(destination: PrivacySettingsView()) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.purple)
                    Text("プライバシー")
                }
            }
            
            // データ使用量
            NavigationLink(destination: DataUsageView()) {
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.green)
                    Text("データ使用量")
                }
            }
            
        } header: {
            Text("アプリ設定")
        }
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func AccountSection() -> some View {
        Section {
            // パスワード変更
            NavigationLink(destination: ChangePasswordView()) {
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.orange)
                    Text("パスワード変更")
                }
            }
            
            // ログアウト
            Button(action: {
                showingLogoutConfirmation = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Text("ログアウト")
                        .foregroundColor(.red)
                }
            }
            
        } header: {
            Text("アカウント管理")
        }
    }
    
    // MARK: - Info Section
    @ViewBuilder
    private func InfoSection() -> some View {
        Section {
            // ヘルプ
            NavigationLink(destination: HelpView()) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                    Text("ヘルプ")
                }
            }
            
            // お問い合わせ
            NavigationLink(destination: ContactView()) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.green)
                    Text("お問い合わせ")
                }
            }
            
            // アプリについて
            Button(action: {
                showingAbout = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("アプリについて")
                        .foregroundColor(.primary)
                }
            }
            
        } header: {
            Text("情報")
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // アプリアイコン
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("EmoCare Intercom Next")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text("LINEレベル品質を目指すVoIPインターコムアプリ")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text("© 2026 EmoCare")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("次世代介護施設向けコミュニケーションアプリ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("閉じる") { dismiss() })
        }
    }
}

// MARK: - Placeholder Views
struct NotificationSettingsView: View {
    var body: some View {
        Text("通知設定")
            .navigationTitle("通知設定")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("プライバシー設定")
            .navigationTitle("プライバシー")
    }
}

struct DataUsageView: View {
    var body: some View {
        Text("データ使用量")
            .navigationTitle("データ使用量")
    }
}

struct ChangePasswordView: View {
    var body: some View {
        Text("パスワード変更")
            .navigationTitle("パスワード変更")
    }
}

struct HelpView: View {
    var body: some View {
        Text("ヘルプ")
            .navigationTitle("ヘルプ")
    }
}

struct ContactView: View {
    var body: some View {
        Text("お問い合わせ")
            .navigationTitle("お問い合わせ")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AudioManager())
}
