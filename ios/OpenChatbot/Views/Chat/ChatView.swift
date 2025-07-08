import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showModelPicker = false
    @EnvironmentObject var appState: AppState
    
    // Default initializer for when no viewModel is provided (like in previews)
    init(viewModel: ChatViewModel? = nil) {
        if let viewModel = viewModel {
            self.viewModel = viewModel
        } else {
            self.viewModel = ChatViewModel()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with model selection
                headerView
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                            
                            // Streaming indicator
                            if viewModel.isStreaming {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("streaming")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            if let lastMessage = viewModel.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isStreaming) { isStreaming in
                        if isStreaming {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }
                
                // Input area
                inputArea
            }
            .navigationTitle("🤖 OpenChatbot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Chat") {
                        viewModel.createNewConversation()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Chọn Model") {
                            showModelPicker = true
                        }
                        Button("Xóa Cuộc Trò Chuyện") {
                            viewModel.clearMessages()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerView(viewModel: viewModel)
            }
            .onChange(of: appState.selectedConversationID) { conversationID in
                if let id = conversationID, let uuid = UUID(uuidString: id) {
                    // Load conversation by ID when coming from History tab
                    viewModel.loadConversationByID(conversationID: uuid)
                    // Clear the selected conversation ID to avoid reloading
                    appState.selectedConversationID = nil
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            let selectedModel = viewModel.selectedModel
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                    Text(selectedModel.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text(selectedModel.provider.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Nhập tin nhắn...", text: $messageText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...5)
                .disabled(viewModel.isStreaming)
            
            if viewModel.isStreaming {
                Button(action: {
                    viewModel.cancelCurrentRequest()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !viewModel.isLoading && 
        !viewModel.isStreaming
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Set the input in viewModel and call sendMessage
        viewModel.currentInput = trimmedMessage
        Task {
            await viewModel.sendMessage()
        }
        messageText = ""
        
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Message Row Component
struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 50)
                Text(message.content)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.top, 2)
                    
                    Text(message.content)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            animationOffset = 2
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Button("Đóng", action: onDismiss)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Model Picker
struct ModelPickerView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    // Computed property for filtered models
    private var filteredModels: [LLMModel] {
        if searchText.isEmpty {
            return viewModel.availableModels
        } else {
            return viewModel.availableModels.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.provider.displayName.localizedCaseInsensitiveContains(searchText) ||
                (model.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Models list
                List {
                    if !filteredModels.isEmpty {
                        Section {
                            ForEach(filteredModels, id: \.id) { model in
                                ModelRow(
                                    model: model,
                                    isSelected: viewModel.selectedModel.id == model.id
                                ) {
                                    viewModel.updateSelectedModel(model)
                                    dismiss()
                                }
                            }
                        } header: {
                            Text("Available Models (\(filteredModels.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if viewModel.availableModels.isEmpty {
                        Section {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading models...")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    } else {
                        Section {
                            Text("No models found matching '\(searchText)'")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select AI Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search models...", text: $text)
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    isEditing = false
                    text = ""
                    hideKeyboard()
                }
                .padding(.leading, 8)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ModelRow: View {
    let model: LLMModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(model.provider.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let description = model.description {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ChatView(viewModel: nil)
        .environmentObject(AppState())
} 