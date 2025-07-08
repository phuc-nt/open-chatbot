import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HistorySearchBar(text: $searchText)
                
                // Conversations list
                List {
                    ForEach(viewModel.filteredConversations(searchText: searchText), id: \.id) { conversation in
                        ConversationRow(conversation: conversation, viewModel: viewModel)
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
            .onAppear {
                viewModel.loadConversations()
            }
            .refreshable {
                viewModel.refreshConversations()
            }
        }
    }
}

struct HistorySearchBar: View {
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
    let conversation: ConversationEntity
    let viewModel: HistoryViewModel
    
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
    }
}

#Preview {
    HistoryView()
} 