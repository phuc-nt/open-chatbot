import Foundation
import Combine
import SwiftUI

/// Context compression algorithms for intelligent memory management
/// Implements smart context compression with importance scoring
@MainActor
class ContextCompressionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCompressing: Bool = false
    @Published var compressionProgress: Float = 0.0
    @Published var lastCompressionStats: CompressionAlgorithmStats?
    
    // MARK: - Private Properties
    private let memoryService: MemoryService
    private let summaryMemoryService: ConversationSummaryMemoryService
    private var compressionSettings = CompressionSettings.default
    
    // Importance scoring cache
    private var importanceCache: [UUID: MessageImportanceMap] = [:]
    
    // MARK: - Initialization
    init(memoryService: MemoryService, summaryMemoryService: ConversationSummaryMemoryService) {
        self.memoryService = memoryService
        self.summaryMemoryService = summaryMemoryService
    }
    
    // MARK: - Public Methods
    
    /// Compress context using importance-based algorithm
    func compressContextWithImportanceScoring(
        for conversationId: UUID,
        targetTokens: Int,
        preserveRecentCount: Int = 6
    ) async throws -> CompressedContext {
        
        isCompressing = true
        compressionProgress = 0.0
        
        defer {
            isCompressing = false
            compressionProgress = 1.0
        }
        
        // Get current memory
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        guard memory.estimatedTokens > targetTokens else {
            print("🗜️ Memory already within target token limit")
            return CompressedContext(
                messages: memory.messages,
                compressionRatio: 0.0,
                preservedImportance: 1.0
            )
        }
        
        compressionProgress = 0.2
        
        // Calculate importance scores for all messages
        let importanceMap = await calculateImportanceScores(for: memory.messages, conversationId: conversationId)
        importanceCache[conversationId] = importanceMap
        
        compressionProgress = 0.4
        
        // Apply compression algorithm
        let compressedMessages = try await applyCompressionAlgorithm(
            messages: memory.messages,
            importanceMap: importanceMap,
            targetTokens: targetTokens,
            preserveRecentCount: preserveRecentCount
        )
        
        compressionProgress = 0.8
        
        // Calculate compression statistics
        let stats = calculateCompressionStats(
            original: memory.messages,
            compressed: compressedMessages,
            importanceMap: importanceMap
        )
        
        lastCompressionStats = stats
        
        return CompressedContext(
            messages: compressedMessages,
            compressionRatio: stats.compressionRatio,
            preservedImportance: stats.importanceRetention
        )
    }
    
    /// Get importance score for a specific message
    func getMessageImportance(messageId: UUID, conversationId: UUID) -> Float {
        return importanceCache[conversationId]?.scores[messageId] ?? 0.5
    }
    
    /// Update compression settings
    func updateCompressionSettings(_ settings: CompressionSettings) {
        compressionSettings = settings
    }
    
    // MARK: - Private Methods
    
    /// Calculate importance scores for messages
    private func calculateImportanceScores(
        for messages: [Message],
        conversationId: UUID
    ) async -> MessageImportanceMap {
        
        var scores: [UUID: Float] = [:]
        
        for (index, message) in messages.enumerated() {
            var score: Float = 0.0
            
            // 1. Recency factor (more recent = higher score)
            let recencyScore = calculateRecencyScore(index: index, total: messages.count)
            score += recencyScore * compressionSettings.recencyWeight
            
            // 2. Content relevance (keywords, entities, questions)
            let relevanceScore = calculateContentRelevance(message: message)
            score += relevanceScore * compressionSettings.relevanceWeight
            
            // 3. Conversation flow (topic changes, important decisions)
            let flowScore = calculateConversationFlowScore(
                message: message,
                previousMessage: index > 0 ? messages[index - 1] : nil,
                nextMessage: index < messages.count - 1 ? messages[index + 1] : nil
            )
            score += flowScore * compressionSettings.flowWeight
            
            // 4. User interaction patterns (questions, commands)
            let interactionScore = calculateInteractionScore(message: message)
            score += interactionScore * compressionSettings.interactionWeight
            
            // 5. Information density (unique information)
            let densityScore = calculateInformationDensity(
                message: message,
                allMessages: messages
            )
            score += densityScore * compressionSettings.densityWeight
            
            // Normalize score to 0-1 range
            scores[message.id] = min(max(score, 0.0), 1.0)
        }
        
        return MessageImportanceMap(
            conversationId: conversationId,
            scores: scores,
            calculatedAt: Date()
        )
    }
    
    /// Calculate recency score
    private func calculateRecencyScore(index: Int, total: Int) -> Float {
        // Exponential decay: newer messages get higher scores
        let position = Float(index) / Float(max(total - 1, 1))
        return pow(position, compressionSettings.recencyDecayFactor)
    }
    
    /// Calculate content relevance score
    private func calculateContentRelevance(message: Message) -> Float {
        var score: Float = 0.0
        let content = message.content.lowercased()
        
        // Check for important keywords
        let importantKeywords = compressionSettings.importantKeywords
        for keyword in importantKeywords {
            if content.contains(keyword.lowercased()) {
                score += 0.2
            }
        }
        
        // Check for questions
        if content.contains("?") || content.contains("how") || content.contains("what") || content.contains("why") {
            score += 0.3
        }
        
        // Check for named entities (simple heuristic)
        let words = content.components(separatedBy: .whitespaces)
        let capitalizedWords = words.filter { $0.first?.isUppercase ?? false }
        score += Float(capitalizedWords.count) * 0.05
        
        // Check for numbers/dates (important information)
        let hasNumbers = content.rangeOfCharacter(from: .decimalDigits) != nil
        if hasNumbers {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    /// Calculate conversation flow score
    private func calculateConversationFlowScore(
        message: Message,
        previousMessage: Message?,
        nextMessage: Message?
    ) -> Float {
        var score: Float = 0.0
        
        // Topic change detection (simple heuristic)
        if let previous = previousMessage {
            let similarity = calculateTextSimilarity(message.content, previous.content)
            if similarity < 0.3 {
                // Significant topic change
                score += 0.4
            }
        }
        
        // Check if this message is referenced by next message
        if let next = nextMessage {
            let nextLower = next.content.lowercased()
            if nextLower.contains("that") || nextLower.contains("it") || nextLower.contains("this") {
                // Likely referenced, important for context
                score += 0.3
            }
        }
        
        // Role transitions (user -> assistant usually important)
        if message.role == .user {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    /// Calculate interaction score
    private func calculateInteractionScore(message: Message) -> Float {
        var score: Float = 0.0
        let content = message.content.lowercased()
        
        // Commands and instructions
        let commandWords = ["please", "can you", "could you", "show me", "tell me", "explain", "create", "make"]
        for command in commandWords {
            if content.contains(command) {
                score += 0.15
                break
            }
        }
        
        // Feedback and corrections
        let feedbackWords = ["no", "yes", "correct", "wrong", "actually", "instead"]
        for feedback in feedbackWords {
            if content.contains(feedback) && message.role == .user {
                score += 0.25
                break
            }
        }
        
        return min(score, 1.0)
    }
    
    /// Calculate information density
    private func calculateInformationDensity(message: Message, allMessages: [Message]) -> Float {
        // Simple uniqueness score based on vocabulary
        let messageWords = Set(message.content.lowercased().components(separatedBy: .whitespaces))
        
        var totalOverlap: Float = 0.0
        var comparisonCount: Float = 0.0
        
        for otherMessage in allMessages where otherMessage.id != message.id {
            let otherWords = Set(otherMessage.content.lowercased().components(separatedBy: .whitespaces))
            let intersection = messageWords.intersection(otherWords)
            let overlap = Float(intersection.count) / Float(max(messageWords.count, 1))
            totalOverlap += overlap
            comparisonCount += 1.0
        }
        
        let averageOverlap = comparisonCount > 0 ? totalOverlap / comparisonCount : 0.0
        return 1.0 - averageOverlap // Higher score for more unique content
    }
    
    /// Calculate text similarity (simple Jaccard similarity)
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespaces))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespaces))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Float(intersection.count) / Float(union.count)
    }
    
    /// Apply compression algorithm based on importance scores
    private func applyCompressionAlgorithm(
        messages: [Message],
        importanceMap: MessageImportanceMap,
        targetTokens: Int,
        preserveRecentCount: Int
    ) async throws -> [Message] {
        
        // Always preserve most recent messages
        let recentMessages = Array(messages.suffix(preserveRecentCount))
        let olderMessages = Array(messages.dropLast(preserveRecentCount))
        
        guard !olderMessages.isEmpty else {
            return messages // Nothing to compress
        }
        
        // Sort older messages by importance score
        let sortedByImportance = olderMessages.sorted { msg1, msg2 in
            let score1 = importanceMap.scores[msg1.id] ?? 0.0
            let score2 = importanceMap.scores[msg2.id] ?? 0.0
            return score1 > score2
        }
        
        // Progressive compression based on importance threshold
        var compressedMessages: [Message] = []
        var currentTokens = recentMessages.reduce(0) { $0 + estimateTokens(text: $1.content) }
        
        for message in sortedByImportance {
            let messageTokens = estimateTokens(text: message.content)
            let importanceScore = importanceMap.scores[message.id] ?? 0.0
            
            // Dynamic threshold based on remaining token budget
            let remainingBudget = targetTokens - currentTokens
            let threshold = calculateDynamicThreshold(
                remainingBudget: remainingBudget,
                targetTokens: targetTokens,
                baseThreshold: compressionSettings.importanceThreshold
            )
            
            if importanceScore >= threshold && currentTokens + messageTokens <= targetTokens {
                compressedMessages.append(message)
                currentTokens += messageTokens
            }
        }
        
        // Combine compressed older messages with recent messages
        // Sort by timestamp to maintain chronological order
        let allMessages = (compressedMessages + recentMessages).sorted { $0.timestamp < $1.timestamp }
        
        return allMessages
    }
    
    /// Calculate dynamic importance threshold
    private func calculateDynamicThreshold(
        remainingBudget: Int,
        targetTokens: Int,
        baseThreshold: Float
    ) -> Float {
        // As budget decreases, threshold increases (be more selective)
        let budgetRatio = Float(remainingBudget) / Float(targetTokens)
        let adjustment = (1.0 - budgetRatio) * 0.3 // Max 30% increase
        return min(baseThreshold + adjustment, 0.95)
    }
    
    /// Estimate tokens for text
    private func estimateTokens(text: String) -> Int {
        // Simple estimation: ~4 characters per token
        return text.count / 4
    }
    
    /// Calculate compression statistics
    private func calculateCompressionStats(
        original: [Message],
        compressed: [Message],
        importanceMap: MessageImportanceMap
    ) -> CompressionAlgorithmStats {
        
        let originalTokens = original.reduce(0) { $0 + estimateTokens(text: $1.content) }
        let compressedTokens = compressed.reduce(0) { $0 + estimateTokens(text: $1.content) }
        
        // Calculate importance retention
        let originalImportance = original.reduce(0.0) { total, msg in
            total + (importanceMap.scores[msg.id] ?? 0.0)
        }
        
        let retainedImportance = compressed.reduce(0.0) { total, msg in
            total + (importanceMap.scores[msg.id] ?? 0.0)
        }
        
        let importanceRetention = originalImportance > 0 ? retainedImportance / originalImportance : 0.0
        
        return CompressionAlgorithmStats(
            originalMessages: original.count,
            compressedMessages: compressed.count,
            originalTokens: originalTokens,
            compressedTokens: compressedTokens,
            compressionRatio: Float(compressedTokens) / Float(max(originalTokens, 1)),
            importanceRetention: importanceRetention,
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

/// Compression settings configuration
struct CompressionSettings {
    var importanceThreshold: Float = 0.4
    var recencyWeight: Float = 0.3
    var relevanceWeight: Float = 0.25
    var flowWeight: Float = 0.2
    var interactionWeight: Float = 0.15
    var densityWeight: Float = 0.1
    var recencyDecayFactor: Float = 2.0
    var importantKeywords: [String] = ["important", "remember", "key", "critical", "main", "summary"]
    
    static let `default` = CompressionSettings()
    
    static let aggressive = CompressionSettings(
        importanceThreshold: 0.6,
        recencyWeight: 0.4,
        relevanceWeight: 0.3,
        flowWeight: 0.15,
        interactionWeight: 0.1,
        densityWeight: 0.05
    )
    
    static let balanced = CompressionSettings.default
    
    static let conservative = CompressionSettings(
        importanceThreshold: 0.3,
        recencyWeight: 0.25,
        relevanceWeight: 0.25,
        flowWeight: 0.2,
        interactionWeight: 0.2,
        densityWeight: 0.1
    )
}

/// Message importance map
struct MessageImportanceMap {
    let conversationId: UUID
    let scores: [UUID: Float]
    let calculatedAt: Date
}

/// Compressed context result
struct CompressedContext {
    let messages: [Message]
    let compressionRatio: Float
    let preservedImportance: Float
}

/// Compression algorithm statistics
struct CompressionAlgorithmStats {
    let originalMessages: Int
    let compressedMessages: Int
    let originalTokens: Int
    let compressedTokens: Int
    let compressionRatio: Float
    let importanceRetention: Float
    let timestamp: Date
    
    var compressionPercentage: Float {
        return (1.0 - compressionRatio) * 100
    }
    
    var messageRetentionRate: Float {
        return Float(compressedMessages) / Float(max(originalMessages, 1))
    }
}

/// Compression algorithm type
enum CompressionAlgorithm: String, CaseIterable {
    case importanceBased = "importance_based"
    case summarization = "summarization"
    case hybrid = "hybrid"
    case sliding = "sliding_window"
    
    var displayName: String {
        switch self {
        case .importanceBased:
            return "Importance-Based"
        case .summarization:
            return "AI Summarization"
        case .hybrid:
            return "Hybrid (Importance + Summary)"
        case .sliding:
            return "Sliding Window"
        }
    }
} 