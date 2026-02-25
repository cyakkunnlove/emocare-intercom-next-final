import SwiftUI

struct CreateChannelView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var viewModel = CreateChannelViewModel()
    
    @State private var channelName = ""
    @State private var channelDescription = ""
    @State private var isEmergencyChannel = false
    @State private var showingPermissionAlert = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    HeaderView()
                    
                    // フォーム
                    ChannelFormView()
                    
                    // 緊急チャンネル設定
                    EmergencyChannelToggleView()
                    
                    // 作成ボタン
                    CreateButtonView()
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("新規チャンネル")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") { dismiss() },
                trailing: EmptyView()
            )
        }
        .alert("権限不足", isPresented: $showingPermissionAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("チャンネル作成には管理者権限が必要です")
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await checkPermissions()
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: isEmergencyChannel ? "cross.case.fill" : "rectangle.3.group.fill")
                .font(.system(size: 60))
                .foregroundColor(isEmergencyChannel ? .red : .blue)
                .animation(.easeInOut(duration: 0.3), value: isEmergencyChannel)
            
            VStack(spacing: 8) {
                Text(isEmergencyChannel ? "緊急チャンネル作成" : "チャンネル作成")
                    .font(.title2)
                    .fontWeight(.bold)
                    .animation(.easeInOut(duration: 0.3), value: isEmergencyChannel)
                
                Text(isEmergencyChannel ? 
                     "緊急時専用の優先通信チャンネルを作成します" :
                     "新しい通信チャンネルを作成します"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: isEmergencyChannel)
            }
        }
    }
    
    // MARK: - Form View
    @ViewBuilder
    private func ChannelFormView() -> some View {
        VStack(spacing: 20) {
            // チャンネル名入力
            VStack(alignment: .leading, spacing: 8) {
                Text("チャンネル名")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("例: 1階ナースステーション", text: $channelName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($focusedField, equals: .name)
                    .onSubmit {
                        focusedField = .description
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .name ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
            
            // 説明入力
            VStack(alignment: .leading, spacing: 8) {
                Text("説明 (任意)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $channelDescription)
                    .frame(minHeight: 80, maxHeight: 140)
                    .focused($focusedField, equals: .description)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .description ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
        }
    }
    
    // MARK: - Emergency Channel Toggle
    @ViewBuilder
    private func EmergencyChannelToggleView() -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("緊急チャンネル")
                        .font(.headline)
                    
                    Text("緊急時専用の優先チャンネルとして設定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEmergencyChannel)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }
            .padding()
            .background(isEmergencyChannel ? Color.red.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEmergencyChannel ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.3), value: isEmergencyChannel)
            
            if isEmergencyChannel {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("緊急チャンネルは削除できません。慎重に作成してください。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: isEmergencyChannel)
            }
        }
    }
    
    // MARK: - Create Button
    @ViewBuilder
    private func CreateButtonView() -> some View {
        Button(action: {
            Task {
                await createChannel()
            }
        }) {
            HStack {
                if viewModel.isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(viewModel.isCreating ? "作成中..." : "チャンネル作成")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isCreateButtonEnabled ? (isEmergencyChannel ? Color.red : Color.blue) : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: isCreateButtonEnabled ? (isEmergencyChannel ? .red.opacity(0.3) : .blue.opacity(0.3)) : .clear, radius: 8)
        }
        .disabled(!isCreateButtonEnabled)
        .animation(.easeInOut(duration: 0.2), value: isCreateButtonEnabled)
    }
    
    // MARK: - Computed Properties
    
    private var isCreateButtonEnabled: Bool {
        !channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isCreating &&
        hasPermission
    }
    
    private var hasPermission: Bool {
        guard let user = authManager.user else { return false }
        return user.role == .admin || user.role == .manager
    }
    
    // MARK: - Methods
    
    private func checkPermissions() async {
        if !hasPermission {
            showingPermissionAlert = true
        }
    }
    
    private func createChannel() async {
        guard hasPermission else {
            showingPermissionAlert = true
            return
        }
        
        let trimmedName = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = channelDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // バリデーション
        guard !trimmedName.isEmpty else {
            viewModel.errorMessage = "チャンネル名を入力してください"
            return
        }
        
        guard trimmedName.count <= 50 else {
            viewModel.errorMessage = "チャンネル名は50文字以内で入力してください"
            return
        }
        
        guard trimmedDescription.count <= 200 else {
            viewModel.errorMessage = "説明は200文字以内で入力してください"
            return
        }
        
        do {
            await viewModel.createChannel(
                name: trimmedName,
                description: trimmedDescription,
                isEmergency: isEmergencyChannel
            )
            
            // 成功時は画面を閉じる
            dismiss()
            
        } catch {
            print("❌ Failed to create channel: \(error)")
        }
    }
}

// MARK: - Create Channel ViewModel

@MainActor
class CreateChannelViewModel: ObservableObject {
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    func createChannel(name: String, description: String, isEmergency: Bool) async {
        guard !isCreating else { return }
        
        isCreating = true
        errorMessage = nil
        
        defer { isCreating = false }
        
        do {
            let channelsViewModel = ChannelsViewModel()
            try await channelsViewModel.createChannel(
                name: name,
                description: description,
                isEmergency: isEmergency
            )
            
            print("✅ Channel created successfully: \(name)")
            
        } catch {
            errorMessage = "チャンネル作成に失敗しました: \(error.localizedDescription)"
            print("❌ Failed to create channel: \(error)")
        }
    }
}

// MARK: - Channel Settings View

struct ChannelSettingsView: View {
    let channel: Channel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var viewModel = ChannelSettingsViewModel()
    
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var showingDeleteConfirmation = false
    @State private var showingEditForm = false
    
    init(channel: Channel) {
        self.channel = channel
        self._editedName = State(initialValue: channel.name)
        self._editedDescription = State(initialValue: channel.description)
    }
    
    var body: some View {
        NavigationView {
            List {
                // チャンネル情報セクション
                ChannelInfoSection()
                
                // 統計情報セクション
                StatisticsSection()
                
                // 管理セクション（管理者のみ）
                if hasManagementPermission {
                    ManagementSection()
                }
            }
            .navigationTitle("チャンネル設定")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("閉じる") { dismiss() }
            )
        }
        .sheet(isPresented: $showingEditForm) {
            EditChannelView()
        }
        .alert("チャンネル削除", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                Task {
                    await deleteChannel()
                }
            }
        } message: {
            Text("チャンネル「\(channel.name)」を削除してもよろしいですか？この操作は取り消せません。")
        }
        .task {
            await viewModel.loadStatistics(for: channel.id)
        }
    }
    
    @ViewBuilder
    private func ChannelInfoSection() -> some View {
        Section {
            HStack {
                Image(systemName: channel.isEmergencyChannel ? "cross.case.fill" : "rectangle.3.group.fill")
                    .foregroundColor(channel.isEmergencyChannel ? .red : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.headline)
                    
                    if !channel.description.isEmpty {
                        Text(channel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if channel.isEmergencyChannel {
                        Text("緊急チャンネル")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
            }
        } header: {
            Text("チャンネル情報")
        }
    }
    
    @ViewBuilder
    private func StatisticsSection() -> some View {
        Section {
            HStack {
                Text("総通話数")
                Spacer()
                Text("\(viewModel.statistics.totalCalls)回")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("今日の通話")
                Spacer()
                Text("\(viewModel.statistics.todayCalls)回")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("平均通話時間")
                Spacer()
                Text(formatDuration(viewModel.statistics.averageDuration))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("最終利用")
                Spacer()
                Text(formatLastUsed(viewModel.statistics.lastUsed))
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("利用統計")
        }
    }
    
    @ViewBuilder
    private func ManagementSection() -> some View {
        Section {
            Button("チャンネル編集") {
                showingEditForm = true
            }
            
            if !channel.isEmergencyChannel {
                Button("チャンネル削除", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        } header: {
            Text("管理")
        } footer: {
            if channel.isEmergencyChannel {
                Text("緊急チャンネルは削除できません")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func EditChannelView() -> some View {
        NavigationView {
            Form {
                TextField("チャンネル名", text: $editedName)
                TextEditor(text: $editedDescription)
                    .frame(minHeight: 80, maxHeight: 140)
            }
            .navigationTitle("チャンネル編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") { showingEditForm = false },
                trailing: Button("保存") {
                    Task {
                        await saveChanges()
                    }
                }
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private var hasManagementPermission: Bool {
        guard let user = authManager.user else { return false }
        return user.role == .admin || user.role == .manager
    }
    
    private func saveChanges() async {
        // TODO: チャンネル更新API呼び出し
        showingEditForm = false
    }
    
    private func deleteChannel() async {
        // TODO: チャンネル削除API呼び出し
        dismiss()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes)分"
    }
    
    private func formatLastUsed(_ date: Date?) -> String {
        guard let date = date else { return "未使用" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Channel Settings ViewModel

@MainActor
class ChannelSettingsViewModel: ObservableObject {
    @Published var statistics = ChannelStatistics()
    
    func loadStatistics(for channelId: String) async {
        // TODO: Supabaseからチャンネル統計を取得
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        statistics = ChannelStatistics(
            totalCalls: Int.random(in: 50...200),
            todayCalls: Int.random(in: 0...10),
            averageDuration: TimeInterval.random(in: 120...600),
            lastUsed: Date().addingTimeInterval(-TimeInterval.random(in: 0...86400))
        )
    }
}

struct ChannelStatistics {
    var totalCalls: Int = 0
    var todayCalls: Int = 0
    var averageDuration: TimeInterval = 0
    var lastUsed: Date? = nil
}

#Preview {
    CreateChannelView()
        .environmentObject(AuthenticationManager())
}
