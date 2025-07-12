import XCTest
@testable import OpenChatbot

class SmartContextRelevanceTests: XCTestCase {
    
    var relevanceService: SmartContextRelevanceService!
    var memoryService: MemoryService!
    var tokenWindowService: TokenWindowManagementService!
    var mockAPIService: MockLLMAPIService!
    var testConversationId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup mock services
        mockAPIService = MockLLMAPIService()
        memoryService = MemoryService(apiService: mockAPIService)
        
        // Create token window service
        let compressionService = ContextCompressionService(
            memoryService: memoryService,
            summaryMemoryService: ConversationSummaryMemoryService(apiService: mockAPIService)
        )
        tokenWindowService = await TokenWindowManagementService(
            memoryService: memoryService,
            compressionService: compressionService
        )
        
        // Create relevance service
        relevanceService = await SmartContextRelevanceService(
            memoryService: memoryService,
            tokenWindowService: tokenWindowService
        )
        
        testConversationId = UUID()
    }
    
    override func tearDown() async throws {
        relevanceService = nil
        memoryService = nil
        tokenWindowService = nil
        mockAPIService = nil
        testConversationId = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSmartContextRelevanceServiceInitialization() {
        XCTAssertNotNil(relevanceService)
        XCTAssertFalse(relevanceService.isAnalyzing)
        XCTAssertEqual(relevanceService.analysisProgress, 0.0)
        XCTAssertNil(relevanceService.lastAnalysisStats)
    }
    
    // MARK: - Relevance Scoring Settings Tests
    
    func testDefaultRelevanceScoringSettings() {
        let settings = RelevanceScoringSettings.default
        XCTAssertEqual(settings.queryWeight, 0.3)
        XCTAssertEqual(settings.contextualWeight, 0.25)
        XCTAssertEqual(settings.temporalWeight, 0.25)
        XCTAssertEqual(settings.semanticWeight, 0.2)
        XCTAssertEqual(settings.maxTemporalAge, 86400) // 24 hours
        XCTAssertEqual(settings.temporalDecayFactor, 2.0)
        XCTAssertEqual(settings.vectorDimensions, 100)
        XCTAssertTrue(settings.importantWords.contains("important"))
        XCTAssertTrue(settings.importantWords.contains("question"))
    }
    
    func testQueryFocusedSettings() {
        let settings = RelevanceScoringSettings.queryFocused
        XCTAssertEqual(settings.queryWeight, 0.5)
        XCTAssertEqual(settings.contextualWeight, 0.2)
        XCTAssertEqual(settings.temporalWeight, 0.15)
        XCTAssertEqual(settings.semanticWeight, 0.15)
    }
    
    func testTemporalFocusedSettings() {
        let settings = RelevanceScoringSettings.temporalFocused
        XCTAssertEqual(settings.queryWeight, 0.2)
        XCTAssertEqual(settings.contextualWeight, 0.2)
        XCTAssertEqual(settings.temporalWeight, 0.4)
        XCTAssertEqual(settings.semanticWeight, 0.2)
    }
    
    func testSemanticFocusedSettings() {
        let settings = RelevanceScoringSettings.semanticFocused
        XCTAssertEqual(settings.queryWeight, 0.2)
        XCTAssertEqual(settings.contextualWeight, 0.2)
        XCTAssertEqual(settings.temporalWeight, 0.2)
        XCTAssertEqual(settings.semanticWeight, 0.4)
    }
    
    // MARK: - Relevance Context Tests
    
    func testRelevanceContextEnum() {
        let contexts: [RelevanceContext] = [.general, .userFocused, .assistantFocused, .balanced]
        XCTAssertEqual(contexts.count, 4)
    }
    
    func testRelevanceScoreTypeEnum() {
        let scoreTypes: [RelevanceScoreType] = [.combined, .query, .contextual, .temporal, .semantic]
        XCTAssertEqual(scoreTypes.count, 5)
    }
    
    // MARK: - Relevance Analysis Tests
    
    func testCalculateRelevanceScoresWithEmptyConversation() async throws {
        // Test with empty conversation
        let relevanceMap = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "test query",
            context: .general
        )
        
        XCTAssertEqual(relevanceMap.conversationId, testConversationId)
        XCTAssertTrue(relevanceMap.messageScores.isEmpty)
        XCTAssertTrue(relevanceMap.queryRelevance.isEmpty)
        XCTAssertTrue(relevanceMap.contextualRelevance.isEmpty)
        XCTAssertTrue(relevanceMap.temporalRelevance.isEmpty)
        XCTAssertTrue(relevanceMap.semanticRelevance.isEmpty)
    }
    
    func testCalculateRelevanceScoresWithSingleMessage() async throws {
        // Add a test message
        let testMessage = Message(
            content: "This is an important question about the system?",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(testMessage, conversationId: testConversationId)
        
        // Calculate relevance scores
        let relevanceMap = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important question",
            context: .general
        )
        
        XCTAssertEqual(relevanceMap.conversationId, testConversationId)
        XCTAssertEqual(relevanceMap.messageScores.count, 1)
        XCTAssertEqual(relevanceMap.queryRelevance.count, 1)
        XCTAssertEqual(relevanceMap.contextualRelevance.count, 1)
        XCTAssertEqual(relevanceMap.temporalRelevance.count, 1)
        XCTAssertEqual(relevanceMap.semanticRelevance.count, 1)
        
        // Check that scores are within valid range
        let messageScore = relevanceMap.messageScores[testMessage.id]
        XCTAssertNotNil(messageScore)
        XCTAssertGreaterThanOrEqual(messageScore!, 0.0)
        XCTAssertLessThanOrEqual(messageScore!, 1.0)
    }
    
    func testCalculateRelevanceScoresWithMultipleMessages() async throws {
        // Add multiple test messages
        let messages = [
            Message(content: "Hello, how are you?", role: .user, conversationId: testConversationId),
            Message(content: "I'm doing well, thank you!", role: .assistant, conversationId: testConversationId),
            Message(content: "Can you help me with an important task?", role: .user, conversationId: testConversationId),
            Message(content: "Of course! What do you need help with?", role: .assistant, conversationId: testConversationId),
            Message(content: "I need to understand how the system works.", role: .user, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Calculate relevance scores
        let relevanceMap = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "system help",
            context: .general
        )
        
        XCTAssertEqual(relevanceMap.messageScores.count, messages.count)
        XCTAssertEqual(relevanceMap.queryRelevance.count, messages.count)
        XCTAssertEqual(relevanceMap.contextualRelevance.count, messages.count)
        XCTAssertEqual(relevanceMap.temporalRelevance.count, messages.count)
        XCTAssertEqual(relevanceMap.semanticRelevance.count, messages.count)
        
        // Verify all scores are valid
        for message in messages {
            let score = relevanceMap.messageScores[message.id]
            XCTAssertNotNil(score)
            XCTAssertGreaterThanOrEqual(score!, 0.0)
            XCTAssertLessThanOrEqual(score!, 1.0)
        }
    }
    
    // MARK: - Message Relevance Score Tests
    
    func testGetMessageRelevanceScoreWithNoAnalysis() {
        let messageId = UUID()
        let score = relevanceService.getMessageRelevanceScore(
            messageId: messageId,
            conversationId: testConversationId,
            scoreType: .combined
        )
        
        // Should return default score when no analysis available
        XCTAssertEqual(score, 0.5)
    }
    
    func testGetMessageRelevanceScoreWithDifferentTypes() async throws {
        // Add test message
        let testMessage = Message(
            content: "This is a test message with important information.",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(testMessage, conversationId: testConversationId)
        
        // Calculate relevance scores
        _ = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important",
            context: .general
        )
        
        // Test different score types
        let combinedScore = relevanceService.getMessageRelevanceScore(
            messageId: testMessage.id,
            conversationId: testConversationId,
            scoreType: .combined
        )
        
        let queryScore = relevanceService.getMessageRelevanceScore(
            messageId: testMessage.id,
            conversationId: testConversationId,
            scoreType: .query
        )
        
        let contextualScore = relevanceService.getMessageRelevanceScore(
            messageId: testMessage.id,
            conversationId: testConversationId,
            scoreType: .contextual
        )
        
        let temporalScore = relevanceService.getMessageRelevanceScore(
            messageId: testMessage.id,
            conversationId: testConversationId,
            scoreType: .temporal
        )
        
        let semanticScore = relevanceService.getMessageRelevanceScore(
            messageId: testMessage.id,
            conversationId: testConversationId,
            scoreType: .semantic
        )
        
        // All scores should be valid
        XCTAssertGreaterThanOrEqual(combinedScore, 0.0)
        XCTAssertLessThanOrEqual(combinedScore, 1.0)
        XCTAssertGreaterThanOrEqual(queryScore, 0.0)
        XCTAssertLessThanOrEqual(queryScore, 1.0)
        XCTAssertGreaterThanOrEqual(contextualScore, 0.0)
        XCTAssertLessThanOrEqual(contextualScore, 1.0)
        XCTAssertGreaterThanOrEqual(temporalScore, 0.0)
        XCTAssertLessThanOrEqual(temporalScore, 1.0)
        XCTAssertGreaterThanOrEqual(semanticScore, 0.0)
        XCTAssertLessThanOrEqual(semanticScore, 1.0)
    }
    
    // MARK: - Message Filtering Tests
    
    func testFilterMessagesByRelevanceWithNoAnalysis() {
        let messages = [
            Message(content: "Test message 1", role: .user, conversationId: testConversationId),
            Message(content: "Test message 2", role: .assistant, conversationId: testConversationId)
        ]
        
        let filteredMessages = relevanceService.filterMessagesByRelevance(
            messages: messages,
            conversationId: testConversationId,
            threshold: 0.6
        )
        
        // Should return all messages when no relevance data available
        XCTAssertEqual(filteredMessages.count, messages.count)
    }
    
    func testFilterMessagesByRelevanceWithThreshold() async throws {
        // Add test messages with varying relevance
        let messages = [
            Message(content: "Very important critical information", role: .user, conversationId: testConversationId),
            Message(content: "Just a simple hello", role: .user, conversationId: testConversationId),
            Message(content: "Another important question about the system?", role: .user, conversationId: testConversationId),
            Message(content: "Random comment", role: .assistant, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Calculate relevance scores
        _ = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important system",
            context: .general
        )
        
        // Filter with high threshold
        let filteredMessages = relevanceService.filterMessagesByRelevance(
            messages: messages,
            conversationId: testConversationId,
            threshold: 0.7
        )
        
        // Should filter out less relevant messages
        XCTAssertLessThanOrEqual(filteredMessages.count, messages.count)
        
        // Filter with low threshold
        let filteredMessagesLow = relevanceService.filterMessagesByRelevance(
            messages: messages,
            conversationId: testConversationId,
            threshold: 0.3
        )
        
        // Should include more messages
        XCTAssertGreaterThanOrEqual(filteredMessagesLow.count, filteredMessages.count)
    }
    
    func testFilterMessagesByRelevanceWithMaxMessages() async throws {
        // Add many test messages
        let messages = (1...10).map { i in
            Message(
                content: "Test message \(i) with important information",
                role: .user,
                conversationId: testConversationId
            )
        }
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Calculate relevance scores
        _ = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important",
            context: .general
        )
        
        // Filter with max messages limit
        let filteredMessages = relevanceService.filterMessagesByRelevance(
            messages: messages,
            conversationId: testConversationId,
            threshold: 0.0, // Low threshold to include all
            maxMessages: 5
        )
        
        // Should respect max messages limit
        XCTAssertEqual(filteredMessages.count, 5)
    }
    
    // MARK: - Settings Update Tests
    
    func testUpdateScoringSettings() async throws {
        // Add test message
        let testMessage = Message(
            content: "Test message",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(testMessage, conversationId: testConversationId)
        
        // Calculate with default settings
        let relevanceMap1 = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "test",
            context: .general
        )
        
        // Update settings
        let newSettings = RelevanceScoringSettings.queryFocused
        await relevanceService.updateScoringSettings(newSettings)
        
        // Calculate again with new settings
        let relevanceMap2 = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "test",
            context: .general
        )
        
        // Scores might be different due to different weights
        XCTAssertNotNil(relevanceMap1.messageScores[testMessage.id])
        XCTAssertNotNil(relevanceMap2.messageScores[testMessage.id])
    }
    
    // MARK: - Analysis Statistics Tests
    
    func testGetAnalysisStatistics() async throws {
        // Initially no statistics
        let initialStats = relevanceService.getAnalysisStatistics(for: testConversationId)
        XCTAssertNil(initialStats)
        
        // Add test messages
        let messages = [
            Message(content: "High relevance important message", role: .user, conversationId: testConversationId),
            Message(content: "Medium relevance message", role: .user, conversationId: testConversationId),
            Message(content: "Low relevance", role: .user, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Calculate relevance scores
        _ = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important",
            context: .general
        )
        
        // Get statistics
        let stats = relevanceService.getAnalysisStatistics(for: testConversationId)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.totalMessages, messages.count)
        XCTAssertGreaterThanOrEqual(stats?.averageRelevanceScore ?? 0.0, 0.0)
        XCTAssertLessThanOrEqual(stats?.averageRelevanceScore ?? 1.0, 1.0)
        XCTAssertGreaterThanOrEqual(stats?.maxRelevanceScore ?? 0.0, 0.0)
        XCTAssertLessThanOrEqual(stats?.maxRelevanceScore ?? 1.0, 1.0)
        XCTAssertGreaterThanOrEqual(stats?.minRelevanceScore ?? 0.0, 0.0)
        XCTAssertLessThanOrEqual(stats?.minRelevanceScore ?? 1.0, 1.0)
    }
    
    // MARK: - Semantic Vector Tests
    
    func testSemanticVectorCreation() {
        let dimensions: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let vector = SemanticVector(dimensions: dimensions)
        
        XCTAssertEqual(vector.dimensions.count, 5)
        XCTAssertEqual(vector.dimensions[0], 0.1)
        XCTAssertEqual(vector.dimensions[4], 0.5)
    }
    
    // MARK: - Relevance Analysis Stats Tests
    
    func testRelevanceAnalysisStatsPercentages() {
        let stats = RelevanceAnalysisStats(
            totalMessages: 10,
            averageRelevanceScore: 0.6,
            maxRelevanceScore: 0.9,
            minRelevanceScore: 0.2,
            highRelevanceCount: 3,
            mediumRelevanceCount: 4,
            lowRelevanceCount: 3,
            analysisTimestamp: Date()
        )
        
        XCTAssertEqual(stats.highRelevancePercentage, 30.0)
        XCTAssertEqual(stats.mediumRelevancePercentage, 40.0)
        XCTAssertEqual(stats.lowRelevancePercentage, 30.0)
    }
    
    func testRelevanceAnalysisStatsWithZeroMessages() {
        let stats = RelevanceAnalysisStats(
            totalMessages: 0,
            averageRelevanceScore: 0.0,
            maxRelevanceScore: 0.0,
            minRelevanceScore: 0.0,
            highRelevanceCount: 0,
            mediumRelevanceCount: 0,
            lowRelevanceCount: 0,
            analysisTimestamp: Date()
        )
        
        XCTAssertEqual(stats.highRelevancePercentage, 0.0)
        XCTAssertEqual(stats.mediumRelevancePercentage, 0.0)
        XCTAssertEqual(stats.lowRelevancePercentage, 0.0)
    }
    
    // MARK: - Performance Tests
    
    func testRelevanceAnalysisPerformance() async throws {
        // Add many messages for performance testing
        let messages = (1...100).map { i in
            Message(
                content: "Performance test message \(i) with various content lengths and important keywords",
                role: i % 2 == 0 ? .user : .assistant,
                conversationId: testConversationId
            )
        }
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Measure performance
        let startTime = Date()
        
        _ = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "important performance",
            context: .general
        )
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(executionTime, 5.0, "Relevance analysis should complete within 5 seconds")
    }
} 