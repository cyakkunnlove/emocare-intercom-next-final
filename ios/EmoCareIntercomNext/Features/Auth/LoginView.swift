import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var isLoggingIn = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    HeaderView()
                    
                    // ログインフォーム
                    LoginFormView()
                    
                    // ログインボタン
                    LoginButtonView()

                    // エラー表示
                    LoginErrorView()
                    
                    // フッター
                    FooterView()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(spacing: 16) {
            // アプリアイコン
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.3), radius: 10)
            
            VStack(spacing: 8) {
                Text("EmoCare Intercom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("施設内コミュニケーション")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Login Form
    @ViewBuilder
    private func LoginFormView() -> some View {
        VStack(spacing: 20) {
            // メールアドレス入力
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                    
                    TextField("メールアドレスを入力", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            
            // パスワード入力
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                    
                    Group {
                        if showingPassword {
                            TextField("パスワードを入力", text: $password)
                        } else {
                            SecureField("パスワードを入力", text: $password)
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        Task {
                            await performLogin()
                        }
                    }
                    
                    Button(action: { showingPassword.toggle() }) {
                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Login Button
    @ViewBuilder
    private func LoginButtonView() -> some View {
        Button(action: {
            Task {
                await performLogin()
            }
        }) {
            HStack {
                if isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isLoggingIn ? "ログイン中..." : "ログイン")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isLoginButtonEnabled ? Color.blue : Color.gray
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: isLoginButtonEnabled ? .blue.opacity(0.3) : .clear, radius: 8)
        }
        .disabled(!isLoginButtonEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoginButtonEnabled)
    }

    @ViewBuilder
    private func LoginErrorView() -> some View {
        if let errorMessage = authManager.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Footer
    @ViewBuilder
    private func FooterView() -> some View {
        VStack(spacing: 16) {
            Text("問題が発生した場合は管理者にお問い合わせください")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("Version 1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("© 2026 EmoCare")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isLoginButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoggingIn && !authManager.isLoading
    }
    
    // MARK: - Private Methods
    private func performLogin() async {
        // フォーカスを外す
        focusedField = nil
        
        // バリデーション
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authManager.errorMessage = "メールアドレスを入力してください"
            return
        }
        
        guard !password.isEmpty else {
            authManager.errorMessage = "パスワードを入力してください"
            return
        }
        
        isLoggingIn = true
        defer { isLoggingIn = false }
        
        do {
            try await authManager.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            // エラーはAuthenticationManagerで処理される
            print("❌ Login failed: \(error)")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
