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
    private let summaryMemoryService: ConversationSummaryMemoryService
    private let contextCompressionService: ContextCompressionService?
    private var relevanceService: SmartContextRelevanceService?
    private var memoryCache: [UUID: ConversationMemory] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataService = DataService(),
         memoryCoreDataBridge: MemoryCoreDataBridge? = nil,
         apiService: LLMAPIService? = nil) {
        self.dataService = dataService
        self.memoryCoreDataBridge = memoryCoreDataBridge ?? MemoryCoreDataBridge()
        
        // Initialize ConversationSummaryMemoryService with lazy initialization
        let defaultAPIService = apiService ?? OpenRouterAPIService(keychain: KeychainService())
        self.summaryMemoryService = ConversationSummaryMemoryService(apiService: defaultAPIService)
        
        // Initialize ContextCompressionService - will be set after full initialization
        self.contextCompressionService = nil
        
        setupMemorySystem()
        
        // Set the memory service reference after initialization
        summaryMemoryService.setMemoryService(self)
    }
    
    // MARK: - Public Methods
    
    /// Set relevance service for smart context analysis
    func setRelevanceService(_ service: SmartContextRelevanceService) {
        relevanceService = service
    }
    
    /// Get context with relevance filtering
    func getContextWithRelevanceFiltering(
        conversationId: UUID,
        query: String? = nil,
        maxTokens: Int = 4000,
        relevanceThreshold: Float = 0.6
    ) async -> [Message] {
        
        guard let relevanceService = relevanceService else {
            // Fall back to regular context if no relevance service
            return await getContextForAPICall(conversationId: conversationId, maxTokens: maxTokens)
        }
        
        let memory = await getMemoryForConversation(conversationId)
        
        // Calculate relevance scores if not already cached
        do {
            _ = try await relevanceService.calculateRelevanceScores(
                for: conversationId,
                query: query,
                context: .general
            )
        } catch {
            print("🧠 Relevance calculation failed: \(error)")
            // Fall back to regular context
            return memory.getContextWithTokenLimit(maxTokens: maxTokens)
        }
        
        // Filter messages by relevance
        let relevantMessages = relevanceService.filterMessagesByRelevance(
            messages: memory.messages,
            conversationId: conversationId,
            threshold: relevanceThreshold
        )
        
        // Apply token limit to relevant messages
        let contextMessages = applyTokenLimitToMessages(relevantMessages, maxTokens: maxTokens)
        
        print("🧠 Context with relevance filtering: \(contextMessages.count)/\(memory.messages.count) messages")
        return contextMessages
    }
    
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
        // First, ensure the conversation exists in persistence
        let conversations = dataService.getAllConversations()
        let conversation = conversations.first(where: { $0.id == conversationId }) ?? {
            // Create new conversation if it doesn't exist
            let newConversation = dataService.createConversation(title: "New Conversation")
            return newConversation
        }()
        
        // Save the message to persistence first
        dataService.addMessage(message, to: conversation)
        
        // Then add to memory cache
        guard let memory = memoryCache[conversationId] else {
            // If no memory exists, create new one
            let newMemory = ConversationMemory(conversationId: conversationId, messages: [message])
            memoryCache[conversationId] = newMemory
            return
        }
        
        memory.addMessage(message)
        
        print("🧠 Added message to memory and persistence: \(message.role.rawValue)")
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
    
    /// Cache loaded memory for conversation (used by persistence service)
    func cacheLoadedMemory(_ memory: ConversationMemory, for conversationId: UUID) async {
        memoryCache[conversationId] = memory
        print("💾 Cached loaded memory for conversation \(conversationId)")
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
    
    /// Get memory statistics - alias for test compatibility
    func getMemoryStatistics(for conversationId: UUID) async -> MemoryStatistics {
        let memory = await getMemoryForConversation(conversationId)
        return MemoryStatistics(
            messageCount: memory.messageCount,
            estimatedTokens: memory.estimatedTokenCount,
            lastUpdated: memory.lastUpdated,
            cacheStatus: memoryCache[conversationId] != nil ? "cached" : "loaded",
            memorySize: memory.estimatedTokens * 4 // Rough estimation
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
    
    private func applyTokenLimitToMessages(_ messages: [Message], maxTokens: Int) -> [Message] {
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
        
        return contextMessages
    }
}

// MARK: - Supporting Types

enum MemoryStatus: Equatable {
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

// MARK: - AdvancedLangChainMemoryService Implementation

extension MemoryService: AdvancedLangChainMemoryService {
    
    /// Compress memory using summarization - similar to ConversationSummaryMemory
    func compressMemory(for conversationId: UUID, targetTokens: Int) async -> Bool {
        do {
            return try await summaryMemoryService.compressMemory(for: conversationId, targetTokens: targetTokens)
        } catch {
            print("🧠 Memory compression failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Compress memory using importance-based algorithm
    func compressMemoryWithImportanceScoring(for conversationId: UUID, targetTokens: Int) async -> Bool {
        // For now, delegate to summarization until ContextCompressionService is fully integrated
        return await compressMemory(for: conversationId, targetTokens: targetTokens)
    }
    
    /// Get memory summary for conversation
    func getMemorySummary(for conversationId: UUID) async -> String? {
        return await summaryMemoryService.getMemorySummary(for: conversationId)
    }
    
    /// Set memory compression threshold
    func setCompressionThreshold(_ threshold: Int) {
        summaryMemoryService.setCompressionThreshold(threshold)
    }
    
    /// Get relevance score for context
    func getContextRelevanceScore(for conversationId: UUID, query: String) async -> Float {
        let memory = await getMemoryForConversation(conversationId)
        
        // Simple relevance scoring based on keyword matching
        let queryWords = query.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines)
        var totalScore: Float = 0.0
        var messageCount = 0
        
        for message in memory.messages {
            let messageWords = message.content.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines)
            let matchingWords = queryWords.filter { queryWord in
                messageWords.contains { messageWord in
                    messageWord.contains(queryWord) || queryWord.contains(messageWord)
                }
            }
            
            let relevanceScore = Float(matchingWords.count) / Float(queryWords.count)
            totalScore += relevanceScore
            messageCount += 1
        }
        
        return messageCount > 0 ? totalScore / Float(messageCount) : 0.0
    }
    
    /// Check if conversation needs compression
    func shouldCompressMemory(for conversationId: UUID) async -> Bool {
        return await summaryMemoryService.needsCompression(for: conversationId)
    }
    
    /// Get compression statistics
    func getCompressionStatistics(for conversationId: UUID) async -> String {
        if let stats = await summaryMemoryService.getCompressionStats(for: conversationId) {
            return """
            Compression Stats:
            - Original: \(stats.originalTokens) tokens
            - Compressed: \(stats.compressedTokens) tokens
            - Ratio: \(String(format: "%.1f", stats.compressionPercentage))% reduction
            - Messages: \(stats.messageCount) summarized
            - Last compressed: \(stats.lastCompressed.formatted())
            """
        } else {
            return "No compression applied yet"
        }
    }
}