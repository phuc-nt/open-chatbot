import CoreData
import Foundation

// MARK: - Core Data Entity Extensions
// NOTE: These extensions will be uncommented after Core Data entities are generated

/*
/// Extension for ConversationEntity to provide convenience methods
extension ConversationEntity {
    
    /// Convert ConversationEntity to Conversation model
    func toConversation() -> Conversation {
        return Conversation(
            id: self.id ?? UUID(),
            title: self.title ?? "Untitled Conversation",
            createdAt: self.createdAt ?? Date(),
            updatedAt: self.updatedAt ?? Date()
        )
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
}

/// Extension for MessageEntity to provide convenience methods
extension MessageEntity {
    
    /// Convert MessageEntity to Message model
    func toMessage() -> Message {
        return Message(
            id: self.id ?? UUID(),
            content: self.content ?? "",
            role: MessageRole(rawValue: self.role ?? "user") ?? .user,
            timestamp: self.timestamp ?? Date(),
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
}

/// Extension for APIKeyEntity to provide convenience methods
extension APIKeyEntity {
    
    /// Convert APIKeyEntity to APIKey model
    func toAPIKey() -> APIKey {
        return APIKey(
            id: self.id ?? UUID(),
            name: self.name ?? "Unknown",
            provider: APIProvider(rawValue: self.provider ?? "openai") ?? .openai,
            createdAt: self.createdAt ?? Date()
        )
    }
    
    /// Create APIKeyEntity from APIKey model
    static func from(_ apiKey: APIKey, keyData: Data, context: NSManagedObjectContext) -> APIKeyEntity {
        let entity = APIKeyEntity(context: context)
        entity.id = apiKey.id
        entity.name = apiKey.name
        entity.provider = apiKey.provider.rawValue
        entity.keyData = keyData
        entity.createdAt = apiKey.createdAt
        return entity
    }
    
    /// Get provider as enum
    var providerEnum: APIProvider {
        return APIProvider(rawValue: provider ?? "openai") ?? .openai
    }
    
    /// Check if API key has data
    var hasKeyData: Bool {
        return keyData != nil && !keyData!.isEmpty
    }
    
    /// Get formatted creation date
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt ?? Date())
    }
}

// MARK: - Fetch Request Extensions

extension ConversationEntity {
    
    /// Fetch request for all conversations
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationEntity> {
        return NSFetchRequest<ConversationEntity>(entityName: "Conversation")
    }
    
    /// Fetch request for conversations with search term
    static func fetchRequest(searchTerm: String) -> NSFetchRequest<ConversationEntity> {
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

extension MessageEntity {
    
    /// Fetch request for all messages
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        return NSFetchRequest<MessageEntity>(entityName: "Message")
    }
    
    /// Fetch request for messages in a conversation
    static func fetchRequest(conversationId: UUID) -> NSFetchRequest<MessageEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return request
    }
}

extension APIKeyEntity {
    
    /// Fetch request for all API keys
    @nonobjc public class func fetchRequest() -> NSFetchRequest<APIKeyEntity> {
        return NSFetchRequest<APIKeyEntity>(entityName: "APIKey")
    }
    
    /// Fetch request for API keys by provider
    static func fetchRequest(provider: APIProvider) -> NSFetchRequest<APIKeyEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "provider == %@", provider.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
}
*/ 