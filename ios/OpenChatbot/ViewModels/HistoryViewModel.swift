import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var conversations: [ConversationEntity] = []
    @Published var selectedConversation: ConversationEntity?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let dataService: DataService  // Make it public for HistoryView access
    
    init(dataService: DataService = DataService()) {
        self.dataService = dataService
        loadConversations()
        
        // Listen for Core Data context changes
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: dataService.viewContext,
            queue: .main
        ) { [weak self] notification in
            self?.handleCoreDataChanges(notification)
        }
    }
    
    // MARK: - Core Data Change Handling
    
    private func handleCoreDataChanges(_ notification: Notification) {
        // Check if any ConversationEntity or MessageEntity was changed
        guard let userInfo = notification.userInfo else { return }
        
        let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        let allChangedObjects = insertedObjects.union(updatedObjects).union(deletedObjects)
        
        // Check if any of the changed objects affect conversations or messages
        let hasRelevantChanges = allChangedObjects.contains { object in
            return String(describing: type(of: object)).contains("Conversation") || 
                   String(describing: type(of: object)).contains("Message")
        }
        
        if hasRelevantChanges {
            Task { @MainActor in
                refreshConversations()
            }
        }
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
    
    /// Clear all conversations
    func clearAllConversations() {
        isLoading = true
        errorMessage = nil
        
        // Delete all conversations from Core Data
        for conversation in conversations {
            dataService.deleteConversation(conversation)
        }
        
        // Clear local array
        conversations.removeAll()
        selectedConversation = nil
        
        // Notify ChatViewModel to reset its state
        NotificationCenter.default.post(name: Notification.Name("AllConversationsCleared"), object: nil)
        
        isLoading = false
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