import Foundation
import SwiftUI
import Combine
import CoreData

/// Advanced context relevance scoring service using ML-based algorithms
/// Implements sophisticated relevance analysis for better memory management
@MainActor
class SmartContextRelevanceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Float = 0.0
    @Published var lastAnalysisStats: RelevanceAnalysisStats?
    
    // MARK: - Private Properties
    private let memoryService: MemoryService
    private let tokenWindowService: TokenWindowManagementService?
    
    // Relevance scoring cache
    private var relevanceCache: [UUID: ConversationRelevanceMap] = [:]
    private var semanticCache: [String: SemanticVector] = [:]
    
    // Configuration
    private var scoringSettings = RelevanceScoringSettings.default
    
    // MARK: - Initialization
    init(memoryService: MemoryService, tokenWindowService: TokenWindowManagementService? = nil) {
        self.memoryService = memoryService
        self.tokenWindowService = tokenWindowService
    }
    
    // MARK: - Public Methods
    
    /// Calculate relevance scores for all messages in a conversation
    func calculateRelevanceScores(
        for conversationId: UUID,
        query: String? = nil,
        context: RelevanceContext = .general
    ) async throws -> ConversationRelevanceMap {
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        // Get conversation memory
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        guard !memory.messages.isEmpty else {
            return ConversationRelevanceMap(
                conversationId: conversationId,
                messageScores: [:],
                queryRelevance: [:],
                contextualRelevance: [:],
                temporalRelevance: [:],
                semanticRelevance: [:],
                calculatedAt: Date()
            )
        }
        
        analysisProgress = 0.1
        
        // Calculate different types of relevance scores
        let queryRelevance = query != nil ? 
            await calculateQueryRelevance(messages: memory.messages, query: query!) : [:]
        
        analysisProgress = 0.3
        
        let contextualRelevance = await calculateContextualRelevance(
            messages: memory.messages,
            context: context
        )
        
        analysisProgress = 0.5
        
        let temporalRelevance = calculateTemporalRelevance(messages: memory.messages)
        
        analysisProgress = 0.7
        
        let semanticRelevance = await calculateSemanticRelevance(messages: memory.messages)
        
        analysisProgress = 0.9
        
        // Combine all relevance scores
        let combinedScores = combineRelevanceScores(
            queryRelevance: queryRelevance,
            contextualRelevance: contextualRelevance,
            temporalRelevance: temporalRelevance,
            semanticRelevance: semanticRelevance
        )
        
        let relevanceMap = ConversationRelevanceMap(
            conversationId: conversationId,
            messageScores: combinedScores,
            queryRelevance: queryRelevance,
            contextualRelevance: contextualRelevance,
            temporalRelevance: temporalRelevance,
            semanticRelevance: semanticRelevance,
            calculatedAt: Date()
        )
        
        // Cache the results
        relevanceCache[conversationId] = relevanceMap
        
        // Calculate analysis statistics
        let stats = calculateAnalysisStats(relevanceMap: relevanceMap, messages: memory.messages)
        lastAnalysisStats = stats
        
        return relevanceMap
    }
    
    /// Get relevance score for a specific message
    func getMessageRelevanceScore(
        messageId: UUID,
        conversationId: UUID,
        scoreType: RelevanceScoreType = .combined
    ) -> Float {
        
        guard let relevanceMap = relevanceCache[conversationId] else {
            return 0.5 // Default score if no analysis available
        }
        
        switch scoreType {
        case .combined:
            return relevanceMap.messageScores[messageId] ?? 0.5
        case .query:
            return relevanceMap.queryRelevance[messageId] ?? 0.5
        case .contextual:
            return relevanceMap.contextualRelevance[messageId] ?? 0.5
        case .temporal:
            return relevanceMap.temporalRelevance[messageId] ?? 0.5
        case .semantic:
            return relevanceMap.semanticRelevance[messageId] ?? 0.5
        }
    }
    
    /// Filter messages by relevance threshold
    func filterMessagesByRelevance(
        messages: [Message],
        conversationId: UUID,
        threshold: Float = 0.6,
        maxMessages: Int? = nil
    ) -> [Message] {
        
        guard let relevanceMap = relevanceCache[conversationId] else {
            return messages // Return all if no relevance data
        }
        
        // Filter by relevance score
        let relevantMessages = messages.filter { message in
            let score = relevanceMap.messageScores[message.id] ?? 0.5
            return score >= threshold
        }
        
        // Sort by relevance score (descending)
        let sortedMessages = relevantMessages.sorted { msg1, msg2 in
            let score1 = relevanceMap.messageScores[msg1.id] ?? 0.5
            let score2 = relevanceMap.messageScores[msg2.id] ?? 0.5
            return score1 > score2
        }
        
        // Limit number of messages if specified
        if let maxMessages = maxMessages {
            return Array(sortedMessages.prefix(maxMessages))
        }
        
        return sortedMessages
    }
    
    /// Update scoring settings
    func updateScoringSettings(_ settings: RelevanceScoringSettings) {
        scoringSettings = settings
        // Clear cache to force recalculation with new settings
        relevanceCache.removeAll()
        semanticCache.removeAll()
    }
    
    /// Get relevance analysis statistics
    func getAnalysisStatistics(for conversationId: UUID) -> RelevanceAnalysisStats? {
        return lastAnalysisStats
    }
    
    // MARK: - Private Methods
    
    /// Calculate query-based relevance scores
    private func calculateQueryRelevance(
        messages: [Message],
        query: String
    ) async -> [UUID: Float] {
        
        var scores: [UUID: Float] = [:]
        let queryVector = await getSemanticVector(for: query)
        
        for message in messages {
            let messageVector = await getSemanticVector(for: message.content)
            let similarity = calculateCosineSimilarity(queryVector, messageVector)
            
            // Boost score for exact keyword matches
            let keywordBoost = calculateKeywordMatchScore(query: query, content: message.content)
            
            scores[message.id] = min(similarity + keywordBoost, 1.0)
        }
        
        return scores
    }
    
    /// Calculate contextual relevance scores
    private func calculateContextualRelevance(
        messages: [Message],
        context: RelevanceContext
    ) async -> [UUID: Float] {
        
        var scores: [UUID: Float] = [:]
        
        for (index, message) in messages.enumerated() {
            var score: Float = 0.5 // Base score
            
            // Role-based scoring
            score += calculateRoleRelevance(message: message, context: context)
            
            // Position-based scoring
            score += calculatePositionRelevance(index: index, total: messages.count, context: context)
            
            // Content type scoring
            score += calculateContentTypeRelevance(message: message, context: context)
            
            // Conversation flow scoring
            score += calculateFlowRelevance(
                message: message,
                previousMessage: index > 0 ? messages[index - 1] : nil,
                nextMessage: index < messages.count - 1 ? messages[index + 1] : nil,
                context: context
            )
            
            scores[message.id] = min(max(score, 0.0), 1.0)
        }
        
        return scores
    }
    
    /// Calculate temporal relevance scores
    private func calculateTemporalRelevance(messages: [Message]) -> [UUID: Float] {
        var scores: [UUID: Float] = [:]
        
        let now = Date()
        let maxAge = TimeInterval(scoringSettings.maxTemporalAge)
        
        for message in messages {
            let age = now.timeIntervalSince(message.timestamp)
            let normalizedAge = min(age / maxAge, 1.0)
            
            // Exponential decay with configurable factor
            let temporalScore = pow(Float(1.0 - normalizedAge), scoringSettings.temporalDecayFactor)
            
            scores[message.id] = temporalScore
        }
        
        return scores
    }
    
    /// Calculate semantic relevance scores
    private func calculateSemanticRelevance(messages: [Message]) async -> [UUID: Float] {
        var scores: [UUID: Float] = [:]
        
        // Calculate semantic vectors for all messages
        var messageVectors: [UUID: SemanticVector] = [:]
        for message in messages {
            messageVectors[message.id] = await getSemanticVector(for: message.content)
        }
        
        // Calculate semantic clustering and importance
        for message in messages {
            guard let messageVector = messageVectors[message.id] else { continue }
            
            var totalSimilarity: Float = 0.0
            var similarityCount: Int = 0
            
            // Compare with other messages in conversation
            for otherMessage in messages where otherMessage.id != message.id {
                guard let otherVector = messageVectors[otherMessage.id] else { continue }
                
                let similarity = calculateCosineSimilarity(messageVector, otherVector)
                totalSimilarity += similarity
                similarityCount += 1
            }
            
            // Calculate semantic uniqueness (inverse of average similarity)
            let averageSimilarity = similarityCount > 0 ? totalSimilarity / Float(similarityCount) : 0.0
            let uniquenessScore = 1.0 - averageSimilarity
            
            // Boost score for information density
            let densityScore = calculateInformationDensity(content: message.content)
            
            scores[message.id] = min(uniquenessScore + densityScore, 1.0)
        }
        
        return scores
    }
    
    /// Get semantic vector for text (simplified implementation)
    private func getSemanticVector(for text: String) async -> SemanticVector {
        // Check cache first
        if let cached = semanticCache[text] {
            return cached
        }
        
        // Simple semantic vector based on word frequency and importance
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var vector: [Float] = Array(repeating: 0.0, count: scoringSettings.vectorDimensions)
        
        for (index, word) in words.enumerated() {
            let wordHash = abs(word.hashValue)
            let vectorIndex = wordHash % scoringSettings.vectorDimensions
            
            // Weight by word importance and position
            let positionWeight = 1.0 / Float(index + 1)
            let importanceWeight: Float = scoringSettings.importantWords.contains(word) ? 2.0 : 1.0
            
            vector[vectorIndex] += positionWeight * importanceWeight
        }
        
        // Normalize vector
        let magnitude = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            vector = vector.map { $0 / magnitude }
        }
        
        let semanticVector = SemanticVector(dimensions: vector)
        semanticCache[text] = semanticVector
        
        return semanticVector
    }
    
    /// Calculate cosine similarity between two vectors
    private func calculateCosineSimilarity(_ vector1: SemanticVector, _ vector2: SemanticVector) -> Float {
        guard vector1.dimensions.count == vector2.dimensions.count else { return 0.0 }
        
        let dotProduct = zip(vector1.dimensions, vector2.dimensions).reduce(0) { $0 + $1.0 * $1.1 }
        let magnitude1 = sqrt(vector1.dimensions.reduce(0) { $0 + $1 * $1 })
        let magnitude2 = sqrt(vector2.dimensions.reduce(0) { $0 + $1 * $1 })
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    /// Calculate keyword match score
    private func calculateKeywordMatchScore(query: String, content: String) -> Float {
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let contentWords = Set(content.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let matches = queryWords.intersection(contentWords)
        return Float(matches.count) / Float(max(queryWords.count, 1)) * 0.3 // Max 30% boost
    }
    
    /// Calculate role-based relevance
    private func calculateRoleRelevance(message: Message, context: RelevanceContext) -> Float {
        switch context {
        case .general:
            return message.role == .user ? 0.1 : 0.05
        case .userFocused:
            return message.role == .user ? 0.2 : 0.0
        case .assistantFocused:
            return message.role == .assistant ? 0.2 : 0.0
        case .balanced:
            return 0.1
        }
    }
    
    /// Calculate position-based relevance
    private func calculatePositionRelevance(index: Int, total: Int, context: RelevanceContext) -> Float {
        let position = Float(index) / Float(max(total - 1, 1))
        
        switch context {
        case .general, .balanced:
            return position * 0.1 // Recent messages get higher scores
        case .userFocused, .assistantFocused:
            return position * 0.05
        }
    }
    
    /// Calculate content type relevance
    private func calculateContentTypeRelevance(message: Message, context: RelevanceContext) -> Float {
        let content = message.content.lowercased()
        var score: Float = 0.0
        
        // Questions are generally important
        if content.contains("?") {
            score += 0.15
        }
        
        // Commands and requests
        let commandWords = ["please", "can you", "could you", "show me", "tell me", "explain"]
        if commandWords.contains(where: content.contains) {
            score += 0.1
        }
        
        // Important keywords
        if scoringSettings.importantWords.contains(where: content.contains) {
            score += 0.1
        }
        
        // Length-based scoring (longer messages often contain more information)
        if content.count > 100 {
            score += 0.05
        }
        
        return score
    }
    
    /// Calculate conversation flow relevance
    private func calculateFlowRelevance(
        message: Message,
        previousMessage: Message?,
        nextMessage: Message?,
        context: RelevanceContext
    ) -> Float {
        var score: Float = 0.0
        
        // Check for topic transitions
        if let previous = previousMessage {
            let similarity = calculateTextSimilarity(message.content, previous.content)
            if similarity < 0.3 {
                score += 0.1 // Topic change is important
            }
        }
        
        // Check for references in next message
        if let next = nextMessage {
            let nextLower = next.content.lowercased()
            if nextLower.contains("that") || nextLower.contains("it") || nextLower.contains("this") {
                score += 0.1 // Likely referenced
            }
        }
        
        return score
    }
    
    /// Calculate information density
    private func calculateInformationDensity(content: String) -> Float {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let uniqueWords = Set(words)
        
        // Higher density = more unique words relative to total words
        let density = Float(uniqueWords.count) / Float(max(words.count, 1))
        
        // Normalize to 0-0.2 range
        return min(density * 0.2, 0.2)
    }
    
    /// Calculate text similarity (Jaccard similarity)
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Float(intersection.count) / Float(union.count)
    }
    
    /// Combine different relevance scores
    private func combineRelevanceScores(
        queryRelevance: [UUID: Float],
        contextualRelevance: [UUID: Float],
        temporalRelevance: [UUID: Float],
        semanticRelevance: [UUID: Float]
    ) -> [UUID: Float] {
        
        var combinedScores: [UUID: Float] = [:]
        
        // Get all message IDs
        let allMessageIds = Set(queryRelevance.keys)
            .union(Set(contextualRelevance.keys))
            .union(Set(temporalRelevance.keys))
            .union(Set(semanticRelevance.keys))
        
        for messageId in allMessageIds {
            let queryScore = queryRelevance[messageId] ?? 0.5
            let contextualScore = contextualRelevance[messageId] ?? 0.5
            let temporalScore = temporalRelevance[messageId] ?? 0.5
            let semanticScore = semanticRelevance[messageId] ?? 0.5
            
            // Weighted combination
            let combinedScore = (
                queryScore * scoringSettings.queryWeight +
                contextualScore * scoringSettings.contextualWeight +
                temporalScore * scoringSettings.temporalWeight +
                semanticScore * scoringSettings.semanticWeight
            ) / (scoringSettings.queryWeight + scoringSettings.contextualWeight + 
                 scoringSettings.temporalWeight + scoringSettings.semanticWeight)
            
            combinedScores[messageId] = min(max(combinedScore, 0.0), 1.0)
        }
        
        return combinedScores
    }
    
    /// Calculate analysis statistics
    private func calculateAnalysisStats(
        relevanceMap: ConversationRelevanceMap,
        messages: [Message]
    ) -> RelevanceAnalysisStats {
        
        let scores = Array(relevanceMap.messageScores.values)
        let averageScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Float(scores.count)
        let maxScore = scores.max() ?? 0.0
        let minScore = scores.min() ?? 0.0
        
        // Calculate distribution
        let highRelevanceCount = scores.filter { $0 > 0.7 }.count
        let mediumRelevanceCount = scores.filter { $0 > 0.4 && $0 <= 0.7 }.count
        let lowRelevanceCount = scores.filter { $0 <= 0.4 }.count
        
        return RelevanceAnalysisStats(
            totalMessages: messages.count,
            averageRelevanceScore: averageScore,
            maxRelevanceScore: maxScore,
            minRelevanceScore: minScore,
            highRelevanceCount: highRelevanceCount,
            mediumRelevanceCount: mediumRelevanceCount,
            lowRelevanceCount: lowRelevanceCount,
            analysisTimestamp: Date()
        )
    }
}

// MARK: - Supporting Types

/// Relevance context for scoring
enum RelevanceContext {
    case general
    case userFocused
    case assistantFocused
    case balanced
}

/// Relevance score type
enum RelevanceScoreType {
    case combined
    case query
    case contextual
    case temporal
    case semantic
}

/// Relevance scoring settings
struct RelevanceScoringSettings {
    var queryWeight: Float = 0.3
    var contextualWeight: Float = 0.25
    var temporalWeight: Float = 0.25
    var semanticWeight: Float = 0.2
    var maxTemporalAge: TimeInterval = 86400 // 24 hours
    var temporalDecayFactor: Float = 2.0
    var vectorDimensions: Int = 100
    var importantWords: [String] = [
        "important", "remember", "key", "critical", "main", "summary",
        "question", "answer", "problem", "solution", "help", "please",
        "error", "issue", "bug", "fix", "work", "working", "broken"
    ]
    
    static let `default` = RelevanceScoringSettings()
    
    static let queryFocused = RelevanceScoringSettings(
        queryWeight: 0.5,
        contextualWeight: 0.2,
        temporalWeight: 0.15,
        semanticWeight: 0.15
    )
    
    static let temporalFocused = RelevanceScoringSettings(
        queryWeight: 0.2,
        contextualWeight: 0.2,
        temporalWeight: 0.4,
        semanticWeight: 0.2
    )
    
    static let semanticFocused = RelevanceScoringSettings(
        queryWeight: 0.2,
        contextualWeight: 0.2,
        temporalWeight: 0.2,
        semanticWeight: 0.4
    )
}

/// Semantic vector representation
struct SemanticVector {
    let dimensions: [Float]
}

/// Conversation relevance map
struct ConversationRelevanceMap {
    let conversationId: UUID
    let messageScores: [UUID: Float]
    let queryRelevance: [UUID: Float]
    let contextualRelevance: [UUID: Float]
    let temporalRelevance: [UUID: Float]
    let semanticRelevance: [UUID: Float]
    let calculatedAt: Date
}

/// Relevance analysis statistics
struct RelevanceAnalysisStats {
    let totalMessages: Int
    let averageRelevanceScore: Float
    let maxRelevanceScore: Float
    let minRelevanceScore: Float
    let highRelevanceCount: Int
    let mediumRelevanceCount: Int
    let lowRelevanceCount: Int
    let analysisTimestamp: Date
    
    var highRelevancePercentage: Float {
        return totalMessages > 0 ? Float(highRelevanceCount) / Float(totalMessages) * 100 : 0.0
    }
    
    var mediumRelevancePercentage: Float {
        return totalMessages > 0 ? Float(mediumRelevanceCount) / Float(totalMessages) * 100 : 0.0
    }
    
    var lowRelevancePercentage: Float {
        return totalMessages > 0 ? Float(lowRelevanceCount) / Float(totalMessages) * 100 : 0.0
    }
} 