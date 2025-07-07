import Foundation
import SwiftUI
import CoreData

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var conversations: [ConversationEntity] = []
    @Published var selectedConversation: ConversationEntity?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataService: DataService
    
    init(dataService: DataService = DataService()) {
        self.dataService = dataService
        loadConversations()
    }
    
    // MARK: - Public Methods
    
    /// Load conversations from Core Data
    func loadConversations() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedConversations = dataService.getAllConversations()
                await MainActor.run {
                    self.conversations = fetchedConversations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load conversations: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Filter conversations based on search text
    func filteredConversations(searchText: String) -> [ConversationEntity] {
        let sortedConversations = conversations.sorted { 
            ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast) 
        }
        
        if searchText.isEmpty {
            return sortedConversations
        } else {
            return sortedConversations.filter { conversation in
                let title = conversation.title ?? ""
                let titleMatches = title.localizedCaseInsensitiveContains(searchText)
                
                // Check if any message content matches
                let messages = dataService.getMessagesForConversation(conversation)
                let messageMatches = messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
                
                return titleMatches || messageMatches
            }
        }
    }
    
    /// Select a conversation
    func selectConversation(_ conversation: ConversationEntity) {
        selectedConversation = conversation
    }
    
    /// Create a new conversation
    @discardableResult
    func createNewConversation(title: String = "New Conversation") -> ConversationEntity {
        let newConversation = dataService.createConversation(title: title)
        conversations.insert(newConversation, at: 0)
        selectedConversation = newConversation
        return newConversation
    }
    
    /// Delete conversations at specified offsets
    func deleteConversations(at offsets: IndexSet) {
        let conversationsToDelete = offsets.map { conversations[$0] }
        
        for conversation in conversationsToDelete {
            dataService.deleteConversation(conversation)
        }
        
        conversations.remove(atOffsets: offsets)
        
        // Clear selection if selected conversation was deleted
        if let selected = selectedConversation,
           conversationsToDelete.contains(where: { $0.id == selected.id }) {
            selectedConversation = nil
        }
    }
    
    /// Delete a specific conversation
    func deleteConversation(_ conversation: ConversationEntity) {
        dataService.deleteConversation(conversation)
        conversations.removeAll { $0.id == conversation.id }
        
        // Clear selection if selected conversation was deleted
        if selectedConversation?.id == conversation.id {
            selectedConversation = nil
        }
    }
    
    /// Get conversation title with fallback
    func getConversationTitle(_ conversation: ConversationEntity) -> String {
        return conversation.title ?? "Untitled Conversation"
    }
    
    /// Get conversation preview (last message content)
    func getConversationPreview(_ conversation: ConversationEntity) -> String {
        let messages = dataService.getMessagesForConversation(conversation)
        guard let lastMessage = messages.last else {
            return "No messages"
        }
        
        let words = lastMessage.content.components(separatedBy: .whitespaces)
        return words.prefix(10).joined(separator: " ")
    }
    
    /// Get conversation message count
    func getMessageCount(_ conversation: ConversationEntity) -> Int {
        return dataService.getMessagesForConversation(conversation).count
    }
    
    /// Refresh conversations (pull to refresh)
    func refreshConversations() {
        loadConversations()
    }
    
    /// Search conversations
    func searchConversations(query: String) -> [ConversationEntity] {
        return filteredConversations(searchText: query)
    }
    
    // MARK: - Helper Methods
    
    /// Check if there are any conversations
    var hasConversations: Bool {
        return !conversations.isEmpty
    }
    
    /// Get formatted date for conversation
    func getFormattedDate(_ conversation: ConversationEntity) -> String {
        guard let date = conversation.updatedAt else { return "" }
        
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
} 