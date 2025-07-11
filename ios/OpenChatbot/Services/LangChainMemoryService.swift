import Foundation

/// Protocol defining LangChain-inspired memory service interface
/// Similar to LangChain's BaseMemory and ConversationBufferMemory
protocol LangChainMemoryService {
    
    // MARK: - Core Memory Operations
    
    /// Get memory for a conversation - equivalent to LangChain ConversationBufferMemory
    func getMemoryForConversation(_ conversationId: UUID) async -> ConversationMemory
    
    /// Add message to memory - similar to memory.add_message()
    func addMessageToMemory(_ message: Message, conversationId: UUID) async
    
    /// Get context for API call - equivalent to memory.chat_memory.messages
    func getContextForAPICall(conversationId: UUID, maxTokens: Int) async -> [Message]
    
    /// Clear memory for conversation
    func clearMemory(for conversationId: UUID)
    
    // MARK: - Memory Management
    
    /// Get memory statistics
    func getMemoryStats(for conversationId: UUID) async -> MemoryStats
    
    /// Check if memory is enabled
    var isMemoryEnabled: Bool { get set }
    
    /// Current memory status
    var memoryStatus: MemoryStatus { get }
}

/// Extended protocol for advanced memory features (ConversationSummaryMemory, etc.)
protocol AdvancedLangChainMemoryService: LangChainMemoryService {
    
    // MARK: - Advanced Memory Features
    
    /// Compress memory using summarization - similar to ConversationSummaryMemory
    func compressMemory(for conversationId: UUID, targetTokens: Int) async -> Bool
    
    /// Get memory summary for conversation
    func getMemorySummary(for conversationId: UUID) async -> String?
    
    /// Set memory compression threshold
    func setCompressionThreshold(_ threshold: Int)
    
    /// Get relevance score for context
    func getContextRelevanceScore(for conversationId: UUID, query: String) async -> Float
}

// MARK: - MemoryService Extension

extension MemoryService: LangChainMemoryService {
    // MemoryService already implements the basic protocol
    // No additional implementation needed as methods already exist
}

// MARK: - Memory Configuration

struct MemoryConfiguration {
    /// Maximum tokens before compression
    var maxTokensBeforeCompression: Int = 4000
    
    /// Target tokens after compression
    var targetTokensAfterCompression: Int = 2000
    
    /// Enable automatic compression
    var autoCompressionEnabled: Bool = true
    
    /// Memory cache size (number of conversations to keep in memory)
    var memoryCacheSize: Int = 10
    
    /// Memory retention period in hours
    var memoryRetentionHours: Int = 24
    
    static let `default` = MemoryConfiguration()
}

// MARK: - Memory Context Builder

class MemoryContextBuilder {
    
    /// Build context string for API call from messages
    static func buildContextString(from messages: [Message]) -> String {
        return messages.map { message in
            let rolePrefix = switch message.role {
            case .user: "Human"
            case .assistant: "Assistant" 
            case .system: "System"
            }
            return "\(rolePrefix): \(message.content)"
        }.joined(separator: "\n\n")
    }
    
    /// Extract key information from conversation for summarization
    static func extractKeyInformation(from messages: [Message]) -> [String] {
        var keyInfo: [String] = []
        
        // Extract questions
        let questions = messages.filter { $0.role == .user && $0.content.contains("?") }
        keyInfo.append(contentsOf: questions.map { "Q: \($0.content)" })
        
        // Extract important statements (simple heuristic)
        let importantStatements = messages.filter { message in
            let content = message.content.lowercased()
            return content.contains("important") || 
                   content.contains("remember") || 
                   content.contains("note that") ||
                   content.count > 100 // Longer messages might be more important
        }
        keyInfo.append(contentsOf: importantStatements.map { "Info: \($0.content)" })
        
        return keyInfo
    }
    
    /// Calculate message importance score (0.0 - 1.0)
    static func calculateImportanceScore(for message: Message) -> Float {
        var score: Float = 0.5 // Base score
        
        let content = message.content.lowercased()
        
        // Boost score for questions
        if content.contains("?") {
            score += 0.2
        }
        
        // Boost score for important keywords
        let importantKeywords = ["important", "remember", "note", "key", "crucial", "significant"]
        for keyword in importantKeywords {
            if content.contains(keyword) {
                score += 0.1
                break
            }
        }
        
        // Boost score for longer messages (more information)
        if message.content.count > 200 {
            score += 0.1
        }
        
        // Reduce score for very short messages
        if message.content.count < 20 {
            score -= 0.2
        }
        
        return min(1.0, max(0.0, score))
    }
} 