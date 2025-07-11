import Foundation
import Combine
import SwiftUI

// MARK: - Supporting Types
struct MemoryStatistics {
    let messageCount: Int
    let estimatedTokens: Int
    let lastUpdated: Date
    let cacheStatus: String
    let memorySize: Int
}

/// Memory service implementing ConversationBufferMemory pattern similar to LangChain
@MainActor
class MemoryService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isMemoryEnabled: Bool = true
    @Published var memoryStatus: MemoryStatus = .idle
    
    // MARK: - Private Properties
    private let dataService: DataService
    private let memoryCoreDataBridge: MemoryCoreDataBridge
    private var memoryCache: [UUID: ConversationMemory] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataService = DataService(), 
         memoryCoreDataBridge: MemoryCoreDataBridge? = nil) {
        self.dataService = dataService
        self.memoryCoreDataBridge = memoryCoreDataBridge ?? MemoryCoreDataBridge()
        setupMemorySystem()
    }
    
    // MARK: - Public Methods
    
    /// Get memory for a conversation - equivalent to LangChain ConversationBufferMemory
    func getMemoryForConversation(_ conversationId: UUID) async -> ConversationMemory {
        if let cached = memoryCache[conversationId] {
            return cached
        }
        
        memoryStatus = .loading
        
        // Load messages from Core Data and convert to memory
        let messages = await loadMessagesFromStorage(conversationId)
        let memory = ConversationMemory(
            conversationId: conversationId,
            messages: messages
        )
        
        memoryCache[conversationId] = memory
        memoryStatus = .ready
        
        print("🧠 Loaded memory for conversation \(conversationId): \(messages.count) messages")
        return memory
    }
    
    /// Add new message to memory - similar to LangChain memory.addMessage()
    func addMessageToMemory(_ message: Message, conversationId: UUID) async {
        guard let memory = memoryCache[conversationId] else {
            // If no memory exists, create new one
            let newMemory = ConversationMemory(conversationId: conversationId, messages: [message])
            memoryCache[conversationId] = newMemory
            return
        }
        
        memory.addMessage(message)
        
        // Save to persistent storage
        await saveMemoryToStorage(memory)
        
        print("🧠 Added message to memory: \(message.role.rawValue)")
    }
    
    /// Get context for API call - equivalent to memory.chatMemory.messages
    func getContextForAPICall(conversationId: UUID, maxTokens: Int = 4000) async -> [Message] {
        let memory = await getMemoryForConversation(conversationId)
        return memory.getContextWithTokenLimit(maxTokens: maxTokens)
    }
    
    /// Clear memory for conversation
    func clearMemory(for conversationId: UUID) {
        memoryCache.removeValue(forKey: conversationId)
        print("🧠 Cleared memory for conversation \(conversationId)")
    }
    
    /// Get memory statistics
    func getMemoryStats(for conversationId: UUID) async -> MemoryStats {
        let memory = await getMemoryForConversation(conversationId)
        return MemoryStats(
            messageCount: memory.messageCount,
            estimatedTokens: memory.estimatedTokenCount,
            lastUpdated: memory.lastUpdated,
            cacheStatus: memoryCache[conversationId] != nil ? .cached : .loaded
        )
    }
    
    // MARK: - Private Methods
    
    private func setupMemorySystem() {
        print("🧠 Memory Service initialized")
    }
    
    private func loadMessagesFromStorage(_ conversationId: UUID) async -> [Message] {
        // Find conversation in Core Data
        let conversations = dataService.getAllConversations()
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else {
            return []
        }
        
        return dataService.getMessagesForConversation(conversation)
    }
    
    private func saveMemoryToStorage(_ memory: ConversationMemory) async {
        // Memory is automatically saved through DataService when messages are added
        // This method can be extended for additional memory-specific storage
        print("🧠 Memory saved to storage for conversation \(memory.conversationId)")
    }
}

// MARK: - Supporting Types

enum MemoryStatus {
    case idle
    case loading
    case ready
    case error(String)
}

enum CacheStatus {
    case cached
    case loaded
}

struct MemoryStats {
    let messageCount: Int
    let estimatedTokens: Int
    let lastUpdated: Date
    let cacheStatus: CacheStatus
}

/// Conversation memory similar to LangChain ConversationBufferMemory
class ConversationMemory: ObservableObject {
    let conversationId: UUID
    var messages: [Message]
    private(set) var createdAt: Date
    var lastUpdated: Date
    var maxTokens: Int
    var cacheStatus: String
    
    init(conversationId: UUID, messages: [Message] = [], maxTokens: Int = 4000) {
        self.conversationId = conversationId
        self.messages = messages
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.maxTokens = maxTokens
        self.cacheStatus = "new"
    }
    
    var estimatedTokens: Int {
        return estimatedTokenCount
    }
    
    func addMessage(_ message: Message) {
        messages.append(message)
        lastUpdated = Date()
    }
    
    func getContextWithTokenLimit(maxTokens: Int) -> [Message] {
        // Simple token estimation: ~4 characters per token
        let estimatedCharsPerToken = 4
        let maxChars = maxTokens * estimatedCharsPerToken
        
        var totalChars = 0
        var contextMessages: [Message] = []
        
        // Start from the most recent messages and work backwards
        for message in messages.reversed() {
            let messageChars = message.content.count
            
            if totalChars + messageChars <= maxChars {
                contextMessages.insert(message, at: 0)
                totalChars += messageChars
            } else {
                break
            }
        }
        
        print("🧠 Context with token limit: \(contextMessages.count)/\(messages.count) messages, ~\(totalChars/estimatedCharsPerToken) tokens")
        return contextMessages
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var estimatedTokenCount: Int {
        let totalChars = messages.reduce(0) { $0 + $1.content.count }
        return totalChars / 4 // Rough estimation
    }
} 