import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var callManager: CallManager
    
    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: appState.isLoading)
        .alert("エラー", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotationAngle = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // アプリアイコン
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            
            Text("EmoCare Intercom")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("初期化中...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject private var callManager: CallManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // チャンネル一覧
            ChannelsView()
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("チャンネル")
                }
                .tag(0)
            
            // 通話履歴
            CallHistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("履歴")
                }
                .tag(1)
            
            // 設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .overlay(
            // 通話中オーバーレイ
            Group {
                if callManager.isInCall {
                    CallOverlayView()
                        .transition(.move(edge: .bottom))
                        .zIndex(1000)
                }
            }
        )
        .animation(.spring(), value: callManager.isInCall)
    }
}

// Placeholder views removed - using actual implementations from Features/

struct CallOverlayView: View {
    @EnvironmentObject private var callManager: CallManager
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("通話中")
                    .fontWeight(.semibold)
                Spacer()
                Button("終了") {
                    callManager.endCall()
                }
                .foregroundColor(.red)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationManager())
        .environmentObject(CallManager())
        .environmentObject(AudioManager())
}