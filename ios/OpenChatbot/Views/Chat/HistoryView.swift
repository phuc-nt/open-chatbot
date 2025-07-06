import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                
                // Conversations list
                List {
                    ForEach(viewModel.filteredConversations(searchText: searchText)) { conversation in
                        ConversationRow(conversation: conversation)
                            .onTapGesture {
                                viewModel.selectConversation(conversation)
                            }
                    }
                    .onDelete(perform: viewModel.deleteConversations)
                }
                .listStyle(PlainListStyle())
                
                if viewModel.conversations.isEmpty {
                    Spacer()
                    Text("No conversations yet")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Spacer()
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Chat") {
                        viewModel.createNewConversation()
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search conversations...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
            
            Text(conversation.lastMessage ?? "No messages")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(conversation.updatedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
} 