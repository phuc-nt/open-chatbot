import XCTest
@testable import OpenChatbot

@MainActor
class ContextCompressionTests: XCTestCase {
    
    var contextCompressionService: ContextCompressionService!
    var memoryService: MemoryService!
    var summaryMemoryService: ConversationSummaryMemoryService!
    var mockAPIService: MockLLMAPIService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup mock services
        mockAPIService = MockLLMAPIService()
        memoryService = MemoryService(dataService: DataService(inMemory: true))
        summaryMemoryService = ConversationSummaryMemoryService(apiService: mockAPIService)
        summaryMemoryService.setMemoryService(memoryService)
        
        // Create context compression service
        contextCompressionService = ContextCompressionService(
            memoryService: memoryService,
            summaryMemoryService: summaryMemoryService
        )
    }
    
    override func tearDown() async throws {
        contextCompressionService = nil
        memoryService = nil
        summaryMemoryService = nil
        mockAPIService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testContextCompressionServiceInitialization() {
        XCTAssertNotNil(contextCompressionService)
        XCTAssertFalse(contextCompressionService.isCompressing)
        XCTAssertEqual(contextCompressionService.compressionProgress, 0.0)
    }
    
    // MARK: - Compression Settings Tests
    
    func testDefaultCompressionSettings() {
        let settings = CompressionSettings.default
        XCTAssertEqual(settings.importanceThreshold, 0.4)
        XCTAssertEqual(settings.recencyWeight, 0.3)
        XCTAssertEqual(settings.relevanceWeight, 0.25)
        XCTAssertEqual(settings.flowWeight, 0.2)
        XCTAssertEqual(settings.interactionWeight, 0.15)
        XCTAssertEqual(settings.densityWeight, 0.1)
        XCTAssertEqual(settings.recencyDecayFactor, 2.0)
    }
    
    func testAggressiveCompressionSettings() {
        let settings = CompressionSettings.aggressive
        XCTAssertEqual(settings.importanceThreshold, 0.6)
        XCTAssertEqual(settings.recencyWeight, 0.4)
        XCTAssertEqual(settings.relevanceWeight, 0.3)
    }
    
    func testConservativeCompressionSettings() {
        let settings = CompressionSettings.conservative
        XCTAssertEqual(settings.importanceThreshold, 0.3)
        XCTAssertEqual(settings.recencyWeight, 0.25)
    }
    
    func testUpdateCompressionSettings() {
        let customSettings = CompressionSettings(
            importanceThreshold: 0.5,
            recencyWeight: 0.35,
            relevanceWeight: 0.25,
            flowWeight: 0.2,
            interactionWeight: 0.1,
            densityWeight: 0.1
        )
        contextCompressionService.updateCompressionSettings(customSettings)
        // Settings are updated internally
    }
    
    // MARK: - Compression Algorithm Tests
    
    func testCompressContextWithEmptyMemory() async throws {
        let conversationId = UUID()
        
        // Compress with empty memory
        let result = try await contextCompressionService.compressContextWithImportanceScoring(
            for: conversationId,
            targetTokens: 1000
        )
        
        XCTAssertEqual(result.messages.count, 0)
        XCTAssertEqual(result.compressionRatio, 0.0)
        XCTAssertEqual(result.preservedImportance, 1.0)
    }
    
    func testCompressContextBelowTargetTokens() async throws {
        let conversationId = UUID()
        
        // Add a few messages that are below target tokens
        let messages = [
            Message(content: "Hello", role: .user, conversationId: conversationId),
            Message(content: "Hi there!", role: .assistant, conversationId: conversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Compress with high target tokens
        let result = try await contextCompressionService.compressContextWithImportanceScoring(
            for: conversationId,
            targetTokens: 10000
        )
        
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.compressionRatio, 0.0)
        XCTAssertEqual(result.preservedImportance, 1.0)
    }
    
    func testMessageImportanceScoring() async {
        let conversationId = UUID()
        let messageId = UUID()
        
        // Initially should return default score
        let score = contextCompressionService.getMessageImportance(
            messageId: messageId,
            conversationId: conversationId
        )
        XCTAssertEqual(score, 0.5)
    }
    
    // MARK: - Compression Statistics Tests
    
    func testCompressionAlgorithmStats() {
        let stats = CompressionAlgorithmStats(
            originalMessages: 20,
            compressedMessages: 8,
            originalTokens: 2000,
            compressedTokens: 600,
            compressionRatio: 0.3,
            importanceRetention: 0.85,
            timestamp: Date()
        )
        
        XCTAssertEqual(stats.compressionPercentage, 70.0)
        XCTAssertEqual(stats.messageRetentionRate, 0.4)
    }
    
    // MARK: - Supporting Types Tests
    
    func testMessageImportanceMap() {
        let conversationId = UUID()
        let scores: [UUID: Float] = [
            UUID(): 0.8,
            UUID(): 0.6,
            UUID(): 0.4
        ]
        
        let importanceMap = MessageImportanceMap(
            conversationId: conversationId,
            scores: scores,
            calculatedAt: Date()
        )
        
        XCTAssertEqual(importanceMap.conversationId, conversationId)
        XCTAssertEqual(importanceMap.scores.count, 3)
    }
    
    func testCompressedContext() {
        let messages = [
            Message(content: "Test", role: .user, conversationId: UUID())
        ]
        
        let compressedContext = CompressedContext(
            messages: messages,
            compressionRatio: 0.5,
            preservedImportance: 0.9
        )
        
        XCTAssertEqual(compressedContext.messages.count, 1)
        XCTAssertEqual(compressedContext.compressionRatio, 0.5)
        XCTAssertEqual(compressedContext.preservedImportance, 0.9)
    }
    
    func testCompressionAlgorithmEnum() {
        XCTAssertEqual(CompressionAlgorithm.importanceBased.displayName, "Importance-Based")
        XCTAssertEqual(CompressionAlgorithm.summarization.displayName, "AI Summarization")
        XCTAssertEqual(CompressionAlgorithm.hybrid.displayName, "Hybrid (Importance + Summary)")
        XCTAssertEqual(CompressionAlgorithm.sliding.displayName, "Sliding Window")
    }
    
    // MARK: - Integration Tests
    
    func testCompressionWithRealMessages() async throws {
        let conversationId = UUID()
        
        // Create a conversation with various message types
        let messages = [
            Message(content: "What is the capital of France?", role: .user, conversationId: conversationId),
            Message(content: "The capital of France is Paris.", role: .assistant, conversationId: conversationId),
            Message(content: "Tell me more about Paris", role: .user, conversationId: conversationId),
            Message(content: "Paris is known as the City of Light...", role: .assistant, conversationId: conversationId),
            Message(content: "How many people live there?", role: .user, conversationId: conversationId),
            Message(content: "The population of Paris is approximately 2.2 million...", role: .assistant, conversationId: conversationId),
            Message(content: "That's interesting", role: .user, conversationId: conversationId),
            Message(content: "Yes, Paris is a fascinating city with rich history...", role: .assistant, conversationId: conversationId),
            Message(content: "What about the weather?", role: .user, conversationId: conversationId),
            Message(content: "Paris has a temperate climate...", role: .assistant, conversationId: conversationId)
        ]
        
        // Add messages to memory
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Compress to a small target
        let result = try await contextCompressionService.compressContextWithImportanceScoring(
            for: conversationId,
            targetTokens: 200,
            preserveRecentCount: 4
        )
        
        // Should have compressed messages
        XCTAssertLessThan(result.messages.count, messages.count)
        XCTAssertGreaterThan(result.compressionRatio, 0.0)
        XCTAssertLessThan(result.compressionRatio, 1.0)
        
        // Should preserve recent messages
        let recentMessages = messages.suffix(4)
        let resultLastFour = result.messages.suffix(4)
        XCTAssertEqual(resultLastFour.count, 4)
    }
    
    func testCompressionProgressTracking() async throws {
        let conversationId = UUID()
        
        // Add some messages
        for i in 1...10 {
            let message = Message(
                content: "Message \(i)",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Track progress during compression
        var progressValues: [Float] = []
        
        let expectation = XCTestExpectation(description: "Compression completes")
        
        Task {
            // Observe progress
            for await progress in contextCompressionService.$compressionProgress.values {
                progressValues.append(progress)
                if progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Start compression
        _ = try await contextCompressionService.compressContextWithImportanceScoring(
            for: conversationId,
            targetTokens: 100
        )
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Should have tracked progress
        XCTAssertGreaterThan(progressValues.count, 1)
        XCTAssertEqual(progressValues.last, 1.0)
    }
}

// MARK: - Mock API Service Extension

extension MockLLMAPIService {
    // Already defined in ConversationSummaryMemoryTests.swift
} 