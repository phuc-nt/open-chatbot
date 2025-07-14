import Foundation
import CoreData

// MARK: - ConversationEntity Memory Extensions

extension ConversationEntity {
    
    // MARK: - Memory Persistence Properties
    
    // Note: These properties are now defined in Core Data model
    // memoryData: Data? - Memory data stored as serialized JSON
    // memoryLastUpdated: Date? - Last time memory was updated  
    // memoryMessageCount: Int32 - Number of messages in memory
    // memoryTokenCount: Int32 - Estimated token count in memory
    
    // MARK: - Memory Helper Methods
    
    /// Check if conversation has memory data
    var hasMemoryData: Bool {
        return memoryData != nil && memoryMessageCount > 0
    }
    
    /// Get memory age in hours
    var memoryAgeInHours: Double {
        guard let lastUpdated = memoryLastUpdated else { return 0 }
        return Date().timeIntervalSince(lastUpdated) / 3600.0
    }
    
    /// Clear all memory data
    func clearMemoryData() {
        memoryData = nil
        memoryLastUpdated = nil
        memoryMessageCount = 0
        memoryTokenCount = 0
    }
    
    /// Update memory statistics
    func updateMemoryStats(messageCount: Int, tokenCount: Int) {
        memoryMessageCount = Int32(messageCount)
        memoryTokenCount = Int32(tokenCount)
        memoryLastUpdated = Date()
    }
    
    /// Initialize memory fields if needed (for migration)
    func initializeMemoryFieldsIfNeeded() {
        // This method ensures memory fields are properly initialized
        // Useful for existing conversations that don't have memory data
        if memoryData == nil {
            memoryData = nil
        }
        if memoryLastUpdated == nil {
            memoryLastUpdated = nil
        }
        // memoryMessageCount and memoryTokenCount have default values in Core Data model
    }
}

// MARK: - Core Data Migration Helper

extension ConversationEntity {
    
    /// Add memory fields to existing Core Data model via setValue
    /// This is a temporary solution until Core Data model is updated
    static func addMemoryFields(to conversation: ConversationEntity) {
        // Initialize memory fields if they don't exist
        if conversation.value(forKey: "memoryData") == nil {
            conversation.setValue(nil, forKey: "memoryData")
        }
        
        if conversation.value(forKey: "memoryLastUpdated") == nil {
            conversation.setValue(nil, forKey: "memoryLastUpdated")
        }
        
        if conversation.value(forKey: "memoryMessageCount") == nil {
            conversation.setValue(0, forKey: "memoryMessageCount")
        }
        
        if conversation.value(forKey: "memoryTokenCount") == nil {
            conversation.setValue(0, forKey: "memoryTokenCount")
        }
    }
    
    /// Migrate existing conversations to include memory support
    static func migrateToMemorySupport(context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        let conversations = try context.fetch(request)
        
        for conversation in conversations {
            addMemoryFields(to: conversation)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
}

// MARK: - Memory Statistics

struct ConversationMemoryStats {
    let conversationId: UUID
    let hasMemory: Bool
    let messageCount: Int
    let tokenCount: Int
    let lastUpdated: Date?
    let memoryAge: TimeInterval
    let isMemoryFresh: Bool
    let efficiency: Double
    let summary: String
    
    init(from conversation: ConversationEntity) {
        self.conversationId = conversation.id ?? UUID()
        self.hasMemory = conversation.hasMemoryData
        self.messageCount = Int(conversation.memoryMessageCount)
        self.tokenCount = Int(conversation.memoryTokenCount)
        self.lastUpdated = conversation.memoryLastUpdated
        self.memoryAge = conversation.memoryAgeInHours * 3600 // Convert hours to seconds
        self.isMemoryFresh = conversation.memoryAgeInHours < 1 // Less than 1 hour old
        self.efficiency = tokenCount > 0 ? Double(messageCount) / Double(tokenCount) : 0
        
        // Generate summary
        if hasMemory {
            let ageString = memoryAge < 60 ? "\(Int(memoryAge))s" : 
                           memoryAge < 3600 ? "\(Int(memoryAge/60))m" : 
                           "\(Int(memoryAge/3600))h"
            self.summary = "\(messageCount) messages, \(tokenCount) tokens, \(ageString) old"
        } else {
            self.summary = "No memory data"
        }
    }
}

// MARK: - Memory Query Extensions

extension ConversationEntity {
    
    /// Fetch conversations with active memory
    static func fetchConversationsWithMemory(context: NSManagedObjectContext) throws -> [ConversationEntity] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoryMessageCount > 0")
        request.sortDescriptors = [NSSortDescriptor(key: "memoryLastUpdated", ascending: false)]
        return try context.fetch(request)
    }
    
    /// Fetch conversations with stale memory (older than 1 hour)
    static func fetchConversationsWithStaleMemory(context: NSManagedObjectContext) throws -> [ConversationEntity] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        let oneHourAgo = Date().addingTimeInterval(-3600)
        request.predicate = NSPredicate(format: "memoryLastUpdated < %@ AND memoryMessageCount > 0", oneHourAgo as NSDate)
        return try context.fetch(request)
    }
    
    /// Get total memory statistics across all conversations
    static func getTotalMemoryStats(context: NSManagedObjectContext) throws -> (conversations: Int, totalMessages: Int, totalTokens: Int) {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoryMessageCount > 0")
        
        let conversations = try context.fetch(request)
        let totalMessages = conversations.reduce(0) { $0 + Int($1.memoryMessageCount) }
        let totalTokens = conversations.reduce(0) { $0 + Int($1.memoryTokenCount) }
        
        return (conversations.count, totalMessages, totalTokens)
    }
} 