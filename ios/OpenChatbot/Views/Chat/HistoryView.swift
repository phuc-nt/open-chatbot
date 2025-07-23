import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @State private var showClearAllConfirmation = false
    @EnvironmentObject var appState: AppState
    
    // Direct Core Data fetch request for automatic refresh
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConversationEntity.updatedAt, ascending: false)],
        animation: .default
    ) private var fetchedConversations: FetchedResults<ConversationEntity>
    
    // Computed property for filtered conversations - USE ONLY @FetchRequest data
    private var filteredConversations: [ConversationEntity] {
        if searchText.isEmpty {
            return Array(fetchedConversations)
        } else {
            return fetchedConversations.filter { conversation in
                let title = conversation.title ?? ""
                let titleMatches = title.localizedCaseInsensitiveContains(searchText)
                
                // Check if any message content matches - use Core Data directly
                let messages = viewModel.dataService.getMessagesForConversation(conversation)
                let messageMatches = messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
                
                return titleMatches || messageMatches
            }
        }
    }
    
    // Delete conversations function - work directly with Core Data
    private func deleteConversations(offsets: IndexSet) {
        let conversationsToDelete = offsets.map { filteredConversations[$0] }
        for conversation in conversationsToDelete {
            // Store conversation ID before deletion for notification
            let deletedConversationId = conversation.id
            let conversationTitle = conversation.title ?? "Untitled"
            
            print("🗑️ Deleting conversation: '\(conversationTitle)' with ID: \(deletedConversationId?.uuidString ?? "nil")")
            
            // Use DataService directly instead of ViewModel array manipulation
            viewModel.dataService.deleteConversation(conversation)
            
            // Only notify if conversation has valid ID
            if let deletedId = deletedConversationId {
                NotificationCenter.default.post(
                    name: Notification.Name("ConversationDeleted"), 
                    object: deletedId
                )
                print("📢 Posted ConversationDeleted notification for ID: \(deletedId.uuidString)")
            } else {
                print("⚠️ Cannot post deletion notification - conversation has no ID")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Search Section
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search conversations...", text: $searchText)
                    }
                }
                
                // Conversations Section - USE ONLY @FetchRequest data
                if !fetchedConversations.isEmpty {
                    Section("Recent Conversations") {
                        ForEach(filteredConversations, id: \.id) { conversation in
                            ConversationRow(conversation: conversation, viewModel: viewModel, appState: appState)
                        }
                        .onDelete(perform: deleteConversations)
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "message.badge")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.6))
                            
                            Text("No conversations yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Start a new conversation in the Chat tab")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !fetchedConversations.isEmpty {
                        Button("Clear All") {
                            showClearAllConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog(
                "Clear All Conversations",
                isPresented: $showClearAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    // Clear all using DataService directly
                    for conversation in fetchedConversations {
                        viewModel.dataService.deleteConversation(conversation)
                    }
                    // Send notification to ChatViewModel
                    NotificationCenter.default.post(name: Notification.Name("AllConversationsCleared"), object: nil)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all conversation history. This action cannot be undone.")
            }
            // Remove unnecessary refresh calls - @FetchRequest handles this automatically
        }
    }
}

struct ConversationRow: View {
    let conversation: ConversationEntity
    let viewModel: HistoryViewModel
    let appState: AppState
    
    // 🔥 ADD: Real-time message count using @FetchRequest
    @FetchRequest private var messages: FetchedResults<MessageEntity>
    
    // Initialize @FetchRequest with conversation-specific predicate
    init(conversation: ConversationEntity, viewModel: HistoryViewModel, appState: AppState) {
        self.conversation = conversation
        self.viewModel = viewModel
        self.appState = appState
        
        // Create predicate for this specific conversation
        let predicate = NSPredicate(format: "conversationId == %@", conversation.id! as CVarArg)
        
        // Initialize @FetchRequest with conversation-specific filter
        self._messages = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \MessageEntity.timestamp, ascending: true)],
            predicate: predicate,
            animation: .default
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.getConversationTitle(conversation))
                .font(.headline)
            
            Text(viewModel.getConversationPreview(conversation))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(viewModel.getFormattedDate(conversation))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 🔥 FIXED: Use real-time @FetchRequest count instead of method call
                Text("\(messages.count) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            // Switch to Chat tab and load this conversation
            if let conversationID = conversation.id?.uuidString {
                appState.switchToChatTab(withConversation: conversationID)
            }
        }
    }
}

#Preview {
    HistoryView()
}