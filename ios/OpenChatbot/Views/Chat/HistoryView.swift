import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @EnvironmentObject var appState: AppState
    
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
                
                // Conversations Section
                if !viewModel.conversations.isEmpty {
                    Section("Recent Conversations") {
                        ForEach(viewModel.filteredConversations(searchText: searchText), id: \.id) { conversation in
                            ConversationRow(conversation: conversation, viewModel: viewModel, appState: appState)
                        }
                        .onDelete(perform: viewModel.deleteConversations)
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
            .onAppear {
                viewModel.loadConversations()
            }
            .refreshable {
                viewModel.refreshConversations()
            }
        }
    }
}



struct ConversationRow: View {
    let conversation: ConversationEntity
    let viewModel: HistoryViewModel
    let appState: AppState
    
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
                
                Text("\(viewModel.getMessageCount(conversation)) messages")
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