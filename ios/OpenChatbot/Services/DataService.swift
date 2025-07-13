import CoreData
import Foundation

/// Service class để handle tất cả Core Data operations
class DataService: ObservableObject {
    
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    /// Convenience initializer for testing with in-memory store
    convenience init(inMemory: Bool) {
        if inMemory {
            self.init(persistenceController: PersistenceController(inMemory: true))
        } else {
            self.init(persistenceController: .shared)
        }
    }
    
    // MARK: - Conversation Operations
    
    /// Create a new conversation
    @discardableResult
    func createConversation(title: String = "New Conversation") -> ConversationEntity {
        let context = persistenceController.viewContext
        let conversation = ConversationEntity(context: context)
        
        conversation.id = UUID()
        conversation.title = title
        conversation.createdAt = Date()
        conversation.updatedAt = Date()
        
        saveContext()
        return conversation
    }
    
    /// Get all conversations
    func getAllConversations() -> [ConversationEntity] {
        let request = ConversationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            return try persistenceController.viewContext.fetch(request)
        } catch {
            print("Error fetching conversations: \(error)")
            return []
        }
    }
    
    /// Fetch conversations - alias for getAllConversations for test compatibility
    func fetchConversations() -> [ConversationEntity] {
        return getAllConversations()
    }
    
    /// Get most recent conversation
    func getMostRecentConversation() -> ConversationEntity? {
        let request = ConversationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let conversations = try persistenceController.viewContext.fetch(request)
            return conversations.first
        } catch {
            print("Error fetching most recent conversation: \(error)")
            return nil
        }
    }
    
    /// Update conversation
    func updateConversation(_ conversation: ConversationEntity, title: String) {
        conversation.title = title
        conversation.updatedAt = Date()
        saveContext()
    }
    
    /// Delete conversation
    func deleteConversation(_ conversation: ConversationEntity) {
        let context = persistenceController.viewContext
        context.delete(conversation)
        saveContext()
    }
    
    // MARK: - Message Operations
    
    /// Get messages for conversation
    func getMessagesForConversation(_ conversation: ConversationEntity) -> [Message] {
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversation.id! as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            let messageEntities = try persistenceController.viewContext.fetch(request)
            return messageEntities.map { $0.toMessage() }
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    /// Fetch messages by conversation ID - for test compatibility
    func fetchMessages(for conversationId: UUID) -> [Message] {
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            let messageEntities = try persistenceController.viewContext.fetch(request)
            return messageEntities.map { $0.toMessage() }
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    /// Add message to conversation
    @discardableResult
    func addMessage(_ message: Message, to conversation: ConversationEntity) -> MessageEntity {
        let context = persistenceController.viewContext
        let messageEntity = MessageEntity(context: context)
        
        messageEntity.id = message.id
        messageEntity.content = message.content
        messageEntity.role = message.role.rawValue
        messageEntity.timestamp = message.timestamp
        messageEntity.conversationId = message.conversationId
        messageEntity.conversation = conversation
        
        // Update conversation timestamp
        conversation.updatedAt = Date()
        
        saveContext()
        return messageEntity
    }
    
    /// Delete message
    func deleteMessage(_ message: Message, from conversation: ConversationEntity) {
        let context = persistenceController.viewContext
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", message.id as CVarArg)
        
        do {
            let messageEntities = try context.fetch(request)
            for entity in messageEntities {
                context.delete(entity)
            }
            
            // Update conversation timestamp
            conversation.updatedAt = Date()
            saveContext()
        } catch {
            print("Error deleting message: \(error)")
        }
    }
    
    /// Clear all messages in conversation
    func clearMessagesInConversation(_ conversation: ConversationEntity) {
        let context = persistenceController.viewContext
        let request = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversation.id! as CVarArg)
        
        do {
            let messageEntities = try context.fetch(request)
            for entity in messageEntities {
                context.delete(entity)
            }
            
            // Update conversation timestamp
            conversation.updatedAt = Date()
            saveContext()
        } catch {
            print("Error clearing messages: \(error)")
        }
    }
    
    // MARK: - Context Management
    
    /// Save Core Data context
    func saveContext() {
        persistenceController.save()
    }
    
    /// Get view context
    var viewContext: NSManagedObjectContext {
        return persistenceController.viewContext
    }
    
    // MARK: - API Key Operations (existing from previous tasks)
    
    /// Create a new API key
    @discardableResult
    func createAPIKey(name: String, provider: String, keyData: Data) -> APIKeyEntity {
        let context = persistenceController.viewContext
        let apiKey = APIKeyEntity(context: context)
        
        apiKey.id = UUID()
        apiKey.name = name
        apiKey.provider = provider
        apiKey.keyData = keyData
        apiKey.createdAt = Date()
        
        persistenceController.save()
        return apiKey
    }
    
    /// Fetch all API keys
    func fetchAPIKeys() -> [APIKeyEntity] {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<APIKeyEntity> = APIKeyEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching API keys: \(error)")
            return []
        }
    }
    
    /// Fetch API keys for a specific provider
    func fetchAPIKeys(for provider: String) -> [APIKeyEntity] {
        let context = persistenceController.viewContext
        let request = APIKeyEntity.fetchRequestForProvider(provider: provider)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching API keys for provider: \(error)")
            return []
        }
    }
    
    /// Delete an API key
    func deleteAPIKey(_ apiKey: APIKeyEntity) {
        let context = persistenceController.viewContext
        context.delete(apiKey)
        persistenceController.save()
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch operation in background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = persistenceController.newBackgroundContext()
        backgroundContext.perform {
            block(backgroundContext)
            self.persistenceController.save(context: backgroundContext)
        }
    }
    
    /// Delete all data (for testing/reset purposes)
    func deleteAllData() {
        let context = persistenceController.viewContext
        
        // Delete all conversations (messages will be cascade deleted)
        let conversationRequest: NSFetchRequest<NSFetchRequestResult> = ConversationEntity.fetchRequest()
        let conversationDeleteRequest = NSBatchDeleteRequest(fetchRequest: conversationRequest)
        
        // Delete all API keys
        let apiKeyRequest: NSFetchRequest<NSFetchRequestResult> = APIKeyEntity.fetchRequest()
        let apiKeyDeleteRequest = NSBatchDeleteRequest(fetchRequest: apiKeyRequest)
        
        do {
            try context.execute(conversationDeleteRequest)
            try context.execute(apiKeyDeleteRequest)
            persistenceController.save()
        } catch {
            print("❌ Error deleting all data: \(error)")
        }
    }
}

// MARK: - Convenience Extensions

extension DataService {
    
    /// Create a conversation from Conversation model
    @discardableResult
    func createConversation(from conversation: Conversation) -> ConversationEntity {
        let entity = createConversation(title: conversation.title)
        
        // Add messages
        for message in conversation.messages {
            addMessage(message, to: entity)
        }
        
        return entity
    }
    
    /// Convert ConversationEntity to Conversation model
    func toConversation(_ entity: ConversationEntity) -> Conversation {
        var conversation = Conversation(title: entity.title ?? "Untitled")
        conversation.messages = entity.messagesArray
        return conversation
    }
} 