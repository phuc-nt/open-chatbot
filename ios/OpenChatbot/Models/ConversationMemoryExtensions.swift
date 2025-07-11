import Foundation
import CoreData

// MARK: - ConversationEntity Memory Extensions

extension ConversationEntity {
    
    // MARK: - Memory Persistence Properties
    
    /// Memory data stored as serialized JSON
    var memoryData: Data? {
        get {
            return value(forKey: "memoryData") as? Data
        }
        set {
            setValue(newValue, forKey: "memoryData")
        }
    }
    
    /// Last time memory was updated
    var memoryLastUpdated: Date? {
        get {
            return value(forKey: "memoryLastUpdated") as? Date
        }
        set {
            setValue(newValue, forKey: "memoryLastUpdated")
        }
    }
    
    /// Number of messages in memory
    var memoryMessageCount: Int {
        get {
            return value(forKey: "memoryMessageCount") as? Int ?? 0
        }
        set {
            setValue(newValue, forKey: "memoryMessageCount")
        }
    }
    
    /// Estimated token count in memory
    var memoryTokenCount: Int {
        get {
            return value(forKey: "memoryTokenCount") as? Int ?? 0
        }
        set {
            setValue(newValue, forKey: "memoryTokenCount")
        }
    }
    
    // MARK: - Memory Helper Methods
    
    /// Check if conversation has memory data
    var hasMemoryData: Bool {
        return memoryData != nil && memoryMessageCount > 0
    }
    
    /// Get memory age in seconds
    var memoryAge: TimeInterval {
        guard let lastUpdated = memoryLastUpdated else { return 0 }
        return Date().timeIntervalSince(lastUpdated)
    }
    
    /// Check if memory is fresh (less than 1 hour old)
    var isMemoryFresh: Bool {
        return memoryAge < 3600 // 1 hour
    }
    
    /// Get memory efficiency score (messages per token)
    var memoryEfficiency: Double {
        guard memoryTokenCount > 0 else { return 0 }
        return Double(memoryMessageCount) / Double(memoryTokenCount)
    }
    
    /// Clear all memory data
    func clearMemoryData() {
        memoryData = nil
        memoryLastUpdated = nil
        memoryMessageCount = 0
        memoryTokenCount = 0
    }
    
    /// Update memory metadata
    func updateMemoryMetadata(messageCount: Int, tokenCount: Int) {
        memoryMessageCount = messageCount
        memoryTokenCount = tokenCount
        memoryLastUpdated = Date()
    }
    
    /// Get memory summary for debugging
    var memorySummary: String {
        guard hasMemoryData else { return "No memory data" }
        
        let ageString = memoryAge < 60 ? "\(Int(memoryAge))s" : 
                       memoryAge < 3600 ? "\(Int(memoryAge/60))m" : 
                       "\(Int(memoryAge/3600))h"
        
        return "\(memoryMessageCount) messages, \(memoryTokenCount) tokens, \(ageString) old"
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
        self.messageCount = conversation.memoryMessageCount
        self.tokenCount = conversation.memoryTokenCount
        self.lastUpdated = conversation.memoryLastUpdated
        self.memoryAge = conversation.memoryAge
        self.isMemoryFresh = conversation.isMemoryFresh
        self.efficiency = conversation.memoryEfficiency
        self.summary = conversation.memorySummary
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
        let totalMessages = conversations.reduce(0) { $0 + $1.memoryMessageCount }
        let totalTokens = conversations.reduce(0) { $0 + $1.memoryTokenCount }
        
        return (conversations.count, totalMessages, totalTokens)
    }
} 