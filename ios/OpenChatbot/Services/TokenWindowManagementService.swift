import Foundation
import SwiftUI

/// Service for managing token windows across different LLM models
@MainActor
class TokenWindowManagementService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTokenUsage: TokenUsage = TokenUsage()
    @Published var isOptimizing: Bool = false
    @Published var optimizationProgress: Float = 0.0
    @Published var tokenWarningLevel: TokenWarningLevel = .normal
    
    // MARK: - Private Properties
    private let memoryService: MemoryService
    private let compressionService: ContextCompressionService
    private var tokenCountCache: [UUID: Int] = [:]
    private var modelTokenizers: [String: TokenCounter] = [:]
    
    // MARK: - Initialization
    init(memoryService: MemoryService, compressionService: ContextCompressionService) {
        self.memoryService = memoryService
        self.compressionService = compressionService
        setupTokenCounters()
    }
    
    // MARK: - Public Methods
    
    /// Manage token window for a conversation with specific model
    func manageTokenWindow(
        for conversationId: UUID,
        model: LLMModel,
        reserveTokens: Int = 1000 // Reserve for response
    ) async throws -> TokenWindowResult {
        
        isOptimizing = true
        optimizationProgress = 0.0
        
        defer {
            isOptimizing = false
            optimizationProgress = 1.0
        }
        
        // Get current memory
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        // Count tokens for current conversation
        let currentTokens = await countTokens(for: memory.messages, model: model)
        tokenCountCache[conversationId] = currentTokens
        
        optimizationProgress = 0.3
        
        // Calculate available token budget
        let maxTokens = model.contextLength - reserveTokens
        let tokenBudget = maxTokens - currentTokens
        
        // Update token usage
        currentTokenUsage = TokenUsage(
            current: currentTokens,
            maximum: model.contextLength,
            reserved: reserveTokens,
            available: tokenBudget
        )
        
        // Determine warning level
        updateWarningLevel(currentTokens: currentTokens, maxTokens: model.contextLength)
        
        optimizationProgress = 0.5
        
        // If within budget, no optimization needed
        if currentTokens <= maxTokens {
            print("🪟 Token window OK: \(currentTokens)/\(maxTokens) tokens")
            return TokenWindowResult(
                optimized: false,
                originalTokens: currentTokens,
                finalTokens: currentTokens,
                messagesRemoved: 0,
                compressionApplied: false
            )
        }
        
        // Need optimization
        print("🪟 Token overflow detected: \(currentTokens)/\(maxTokens) tokens")
        
        // Try compression first
        let targetTokens = Int(Float(maxTokens) * 0.8) // Target 80% of max
        let compressedContext = try await compressionService.compressContext(
            for: conversationId,
            targetTokens: targetTokens,
            preserveRecentCount: calculatePreserveCount(model: model)
        )
        
        optimizationProgress = 0.8
        
        // Count tokens after compression
        let compressedTokens = await countTokens(for: compressedContext.messages, model: model)
        
        // Update memory with compressed context if successful
        if compressedTokens <= maxTokens {
            memory.messages = compressedContext.messages
            memory.lastUpdated = Date()
            
            return TokenWindowResult(
                optimized: true,
                originalTokens: currentTokens,
                finalTokens: compressedTokens,
                messagesRemoved: memory.messages.count - compressedContext.messages.count,
                compressionApplied: true
            )
        }
        
        // If compression wasn't enough, apply more aggressive truncation
        let truncatedMessages = try await applyAggressiveTruncation(
            messages: compressedContext.messages,
            targetTokens: maxTokens,
            model: model
        )
        
        memory.messages = truncatedMessages
        memory.lastUpdated = Date()
        
        let finalTokens = await countTokens(for: truncatedMessages, model: model)
        
        return TokenWindowResult(
            optimized: true,
            originalTokens: currentTokens,
            finalTokens: finalTokens,
            messagesRemoved: memory.messages.count - truncatedMessages.count,
            compressionApplied: true
        )
    }
    
    /// Count tokens for messages using model-specific tokenizer
    func countTokens(for messages: [Message], model: LLMModel) async -> Int {
        let tokenCounter = getTokenCounter(for: model)
        
        var totalTokens = 0
        for message in messages {
            totalTokens += tokenCounter.count(message.content, role: message.role)
        }
        
        // Add overhead for message formatting
        totalTokens += messages.count * tokenCounter.messageOverhead
        
        return totalTokens
    }
    
    /// Get token usage statistics for a conversation
    func getTokenStats(for conversationId: UUID, model: LLMModel) async -> TokenStatistics {
        let memory = await memoryService.getMemoryForConversation(conversationId)
        let currentTokens = await countTokens(for: memory.messages, model: model)
        
        let stats = TokenStatistics(
            conversationId: conversationId,
            modelId: model.id,
            currentTokens: currentTokens,
            maxTokens: model.contextLength,
            messageCount: memory.messages.count,
            averageTokensPerMessage: memory.messages.isEmpty ? 0 : currentTokens / memory.messages.count,
            compressionPotential: calculateCompressionPotential(messages: memory.messages)
        )
        
        return stats
    }
    
    /// Monitor token usage across all conversations
    func monitorTokenUsage(for model: LLMModel) async -> TokenMonitoringReport {
        var conversationStats: [TokenStatistics] = []
        var totalTokens = 0
        var totalMessages = 0
        
        // Get all cached conversations
        for (conversationId, _) in tokenCountCache {
            let stats = await getTokenStats(for: conversationId, model: model)
            conversationStats.append(stats)
            totalTokens += stats.currentTokens
            totalMessages += stats.messageCount
        }
        
        return TokenMonitoringReport(
            timestamp: Date(),
            modelId: model.id,
            conversationStats: conversationStats,
            totalTokens: totalTokens,
            totalMessages: totalMessages,
            averageTokensPerConversation: conversationStats.isEmpty ? 0 : totalTokens / conversationStats.count
        )
    }
    
    // MARK: - Private Methods
    
    private func setupTokenCounters() {
        // Initialize token counters for different model families
        modelTokenizers["gpt"] = GPTTokenCounter()
        modelTokenizers["claude"] = ClaudeTokenCounter()
        modelTokenizers["llama"] = LlamaTokenCounter()
        modelTokenizers["default"] = DefaultTokenCounter()
    }
    
    private func getTokenCounter(for model: LLMModel) -> TokenCounter {
        // Determine which tokenizer to use based on model ID
        if model.id.contains("gpt") || model.id.contains("openai") {
            return modelTokenizers["gpt"]!
        } else if model.id.contains("claude") || model.id.contains("anthropic") {
            return modelTokenizers["claude"]!
        } else if model.id.contains("llama") || model.id.contains("meta") {
            return modelTokenizers["llama"]!
        } else {
            return modelTokenizers["default"]!
        }
    }
    
    private func updateWarningLevel(currentTokens: Int, maxTokens: Int) {
        let usage = Float(currentTokens) / Float(maxTokens)
        
        if usage > 0.95 {
            tokenWarningLevel = .critical
        } else if usage > 0.8 {
            tokenWarningLevel = .high
        } else if usage > 0.6 {
            tokenWarningLevel = .medium
        } else {
            tokenWarningLevel = .normal
        }
    }
    
    private func calculatePreserveCount(model: LLMModel) -> Int {
        // Preserve more recent messages for models with larger context
        switch model.contextLength {
        case 0..<8000:
            return 4
        case 8000..<32000:
            return 8
        case 32000..<128000:
            return 12
        default:
            return 16
        }
    }
    
    private func applyAggressiveTruncation(
        messages: [Message],
        targetTokens: Int,
        model: LLMModel
    ) async throws -> [Message] {
        
        let tokenCounter = getTokenCounter(for: model)
        var truncatedMessages: [Message] = []
        var currentTokens = 0
        
        // Keep messages from the end (most recent) until we hit token limit
        for message in messages.reversed() {
            let messageTokens = tokenCounter.count(message.content, role: message.role) + tokenCounter.messageOverhead
            
            if currentTokens + messageTokens <= targetTokens {
                truncatedMessages.insert(message, at: 0)
                currentTokens += messageTokens
            } else {
                // Try to include a truncated version of this message
                if let truncated = truncateMessage(message, availableTokens: targetTokens - currentTokens, tokenCounter: tokenCounter) {
                    truncatedMessages.insert(truncated, at: 0)
                }
                break
            }
        }
        
        return truncatedMessages
    }
    
    private func truncateMessage(_ message: Message, availableTokens: Int, tokenCounter: TokenCounter) -> Message? {
        guard availableTokens > tokenCounter.messageOverhead + 10 else { return nil }
        
        // Binary search for the right truncation point
        var low = 0
        var high = message.content.count
        var bestFit = ""
        
        while low <= high {
            let mid = (low + high) / 2
            let truncated = String(message.content.prefix(mid)) + "..."
            let tokens = tokenCounter.count(truncated, role: message.role) + tokenCounter.messageOverhead
            
            if tokens <= availableTokens {
                bestFit = truncated
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        guard !bestFit.isEmpty else { return nil }
        
        var truncatedMessage = Message(
            content: bestFit,
            role: message.role,
            conversationId: message.conversationId
        )
        truncatedMessage.id = message.id
        truncatedMessage.timestamp = message.timestamp
        return truncatedMessage
    }
    
    private func calculateCompressionPotential(messages: [Message]) -> Float {
        guard !messages.isEmpty else { return 0.0 }
        
        // Estimate based on message age and redundancy
        let oldMessageRatio = Float(messages.count > 10 ? messages.count - 10 : 0) / Float(messages.count)
        let averageLength = messages.reduce(0) { $0 + $1.content.count } / messages.count
        let lengthFactor = min(Float(averageLength) / 1000.0, 1.0)
        
        return (oldMessageRatio * 0.6 + lengthFactor * 0.4)
    }
}

// MARK: - Token Counter Protocols and Implementations

protocol TokenCounter {
    var messageOverhead: Int { get }
    func count(_ text: String, role: MessageRole) -> Int
}

/// GPT family token counter (cl100k_base encoding)
class GPTTokenCounter: TokenCounter {
    var messageOverhead: Int { 4 } // Typical GPT message overhead
    
    func count(_ text: String, role: MessageRole) -> Int {
        // Approximation: ~1 token per 4 characters for English
        // More accurate would use tiktoken library
        let baseCount = text.count / 4
        
        // Role-specific adjustments
        let roleTokens = switch role {
        case .system: 3
        case .user: 2
        case .assistant: 2
        }
        
        return baseCount + roleTokens
    }
}

/// Claude family token counter
class ClaudeTokenCounter: TokenCounter {
    var messageOverhead: Int { 3 }
    
    func count(_ text: String, role: MessageRole) -> Int {
        // Claude uses similar tokenization to GPT but slightly different
        let baseCount = Int(Float(text.count) / 3.8)
        
        let roleTokens = switch role {
        case .system: 2
        case .user: 2
        case .assistant: 2
        }
        
        return baseCount + roleTokens
    }
}

/// Llama family token counter
class LlamaTokenCounter: TokenCounter {
    var messageOverhead: Int { 5 }
    
    func count(_ text: String, role: MessageRole) -> Int {
        // Llama models typically use more tokens
        let baseCount = Int(Float(text.count) / 3.5)
        
        let roleTokens = switch role {
        case .system: 4
        case .user: 3
        case .assistant: 3
        }
        
        return baseCount + roleTokens
    }
}

/// Default token counter for unknown models
class DefaultTokenCounter: TokenCounter {
    var messageOverhead: Int { 4 }
    
    func count(_ text: String, role: MessageRole) -> Int {
        // Conservative estimate
        return text.count / 3 + 3
    }
}

// MARK: - Supporting Types

struct TokenUsage {
    let current: Int
    let maximum: Int
    let reserved: Int
    let available: Int
    
    var usagePercentage: Float {
        return Float(current) / Float(maximum) * 100
    }
    
    var isOverLimit: Bool {
        return current > (maximum - reserved)
    }
    
    init(current: Int = 0, maximum: Int = 4096, reserved: Int = 1000, available: Int = 3096) {
        self.current = current
        self.maximum = maximum
        self.reserved = reserved
        self.available = available
    }
}

enum TokenWarningLevel {
    case normal     // < 60% usage
    case medium     // 60-80% usage
    case high       // 80-95% usage
    case critical   // > 95% usage
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "Token usage is normal"
        case .medium: return "Token usage is moderate"
        case .high: return "Token usage is high"
        case .critical: return "Token limit nearly reached"
        }
    }
}

struct TokenWindowResult {
    let optimized: Bool
    let originalTokens: Int
    let finalTokens: Int
    let messagesRemoved: Int
    let compressionApplied: Bool
    
    var tokensSaved: Int {
        return originalTokens - finalTokens
    }
    
    var compressionRatio: Float {
        guard originalTokens > 0 else { return 0 }
        return Float(finalTokens) / Float(originalTokens)
    }
}

struct TokenStatistics {
    let conversationId: UUID
    let modelId: String
    let currentTokens: Int
    let maxTokens: Int
    let messageCount: Int
    let averageTokensPerMessage: Int
    let compressionPotential: Float
    
    var usagePercentage: Float {
        return Float(currentTokens) / Float(maxTokens) * 100
    }
}

struct TokenMonitoringReport {
    let timestamp: Date
    let modelId: String
    let conversationStats: [TokenStatistics]
    let totalTokens: Int
    let totalMessages: Int
    let averageTokensPerConversation: Int
    
    var summary: String {
        return """
        Token Monitoring Report - \(modelId)
        Time: \(timestamp)
        Conversations: \(conversationStats.count)
        Total Tokens: \(totalTokens)
        Total Messages: \(totalMessages)
        Avg Tokens/Conversation: \(averageTokensPerConversation)
        """
    }
}

// MARK: - Token Window Configuration

struct TokenWindowConfiguration {
    let defaultReserveTokens: Int
    let compressionThreshold: Float
    let aggressiveTruncationEnabled: Bool
    let monitoringInterval: TimeInterval
    
    static let `default` = TokenWindowConfiguration(
        defaultReserveTokens: 1000,      // Reserve for AI response
        compressionThreshold: 0.8,       // Start compression at 80% usage
        aggressiveTruncationEnabled: true,
        monitoringInterval: 300          // Monitor every 5 minutes
    )
}

enum TokenWindowError: Error, LocalizedError {
    case tokenCountingFailed(String)
    case compressionFailed(String)
    case truncationFailed(String)
    case modelNotSupported(String)
    
    var errorDescription: String? {
        switch self {
        case .tokenCountingFailed(let message):
            return "Token counting failed: \(message)"
        case .compressionFailed(let message):
            return "Token compression failed: \(message)"
        case .truncationFailed(let message):
            return "Message truncation failed: \(message)"
        case .modelNotSupported(let model):
            return "Model not supported: \(model)"
        }
    }
} 