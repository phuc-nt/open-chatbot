import CoreData
import Foundation

// MARK: - Core Data Entity Extensions

/// Extension for ConversationEntity to provide convenience methods
extension ConversationEntity {
    
    /// Convert ConversationEntity to Conversation model
    func toConversation() -> Conversation {
        var conversation = Conversation(title: self.title ?? "Untitled Conversation")
        // Set the other properties manually
        conversation.messages = self.messagesArray
        return conversation
    }
    
    /// Create ConversationEntity from Conversation model
    static func from(_ conversation: Conversation, context: NSManagedObjectContext) -> ConversationEntity {
        let entity = ConversationEntity(context: context)
        entity.id = conversation.id
        entity.title = conversation.title
        entity.createdAt = conversation.createdAt
        entity.updatedAt = conversation.updatedAt
        return entity
    }
    
    /// Get messages as Swift models
    var messagesArray: [Message] {
        let messageSet = messages as? Set<MessageEntity> ?? []
        return messageSet.compactMap { $0.toMessage() }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Get message count
    var messageCount: Int {
        return messages?.count ?? 0
    }
    
    /// Get last message timestamp
    var lastMessageTimestamp: Date? {
        return messagesArray.last?.timestamp
    }
    
    /// Get preview text (first few words of last message)
    var previewText: String {
        guard let lastMessage = messagesArray.last else { return "No messages" }
        let words = lastMessage.content.components(separatedBy: .whitespaces)
        let preview = words.prefix(5).joined(separator: " ")
        return preview.isEmpty ? "No content" : preview
    }
    
    /// Fetch request for conversations with search term
    static func fetchRequestWithSearch(searchTerm: String) -> NSFetchRequest<ConversationEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchTerm)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return request
    }
    
    /// Fetch request for recent conversations
    static func fetchRequestRecent(limit: Int = 10) -> NSFetchRequest<ConversationEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = limit
        return request
    }
}

/// Extension for MessageEntity to provide convenience methods
extension MessageEntity {
    
    /// Convert MessageEntity to Message model
    func toMessage() -> Message {
        return Message(
            content: self.content ?? "",
            role: MessageRole(rawValue: self.role ?? "user") ?? .user,
            conversationId: self.conversationId ?? UUID()
        )
    }
    
    /// Create MessageEntity from Message model
    static func from(_ message: Message, context: NSManagedObjectContext) -> MessageEntity {
        let entity = MessageEntity(context: context)
        entity.id = message.id
        entity.content = message.content
        entity.role = message.role.rawValue
        entity.timestamp = message.timestamp
        entity.conversationId = message.conversationId
        return entity
    }
    
    /// Check if message is from user
    var isFromUser: Bool {
        return role == MessageRole.user.rawValue
    }
    
    /// Check if message is from assistant
    var isFromAssistant: Bool {
        return role == MessageRole.assistant.rawValue
    }
    
    /// Get formatted timestamp
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }
    
    /// Fetch request for messages in a conversation
    static func fetchRequestForConversation(conversationId: UUID) -> NSFetchRequest<MessageEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
}

/// Extension for APIKeyEntity to provide convenience methods
extension APIKeyEntity {
    
    /// Convert APIKeyEntity to APIKey model (simplified - just name and provider type conversion)
    func toSimpleAPIKey() -> (name: String, provider: String) {
        return (
            name: self.name ?? "",
            provider: self.provider ?? "openrouter"
        )
    }
    
    /// Get provider as LLMProvider enum
    var providerEnum: LLMProvider {
        return LLMProvider(rawValue: provider ?? "openrouter") ?? .openrouter
    }
    
    /// Check if key has data
    var hasKeyData: Bool {
        return keyData != nil && !(keyData?.isEmpty ?? true)
    }
    
    /// Get masked key display
    var maskedKey: String {
        guard let data = keyData,
              let key = String(data: data, encoding: .utf8),
              key.count > 8 else {
            return "••••••••"
        }
        
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
    
    /// Fetch request for API keys by provider
    static func fetchRequestForProvider(provider: String) -> NSFetchRequest<APIKeyEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "provider == %@", provider)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
} 