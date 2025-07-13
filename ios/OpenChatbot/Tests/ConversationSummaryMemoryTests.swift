import XCTest
@testable import OpenChatbot

@MainActor
class ConversationSummaryMemoryTests: XCTestCase {
    
    var summaryMemoryService: ConversationSummaryMemoryService!
    var mockAPIService: MockLLMAPIService!
    var memoryService: MemoryService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup mock API service
        mockAPIService = MockLLMAPIService()
        
        // Create memory service with data service
        memoryService = MemoryService(dataService: DataService(inMemory: true))
        
        // Create summary memory service
        summaryMemoryService = ConversationSummaryMemoryService(apiService: mockAPIService)
        summaryMemoryService.setMemoryService(memoryService)
    }
    
    override func tearDown() async throws {
        summaryMemoryService = nil
        mockAPIService = nil
        memoryService = nil
        try await super.tearDown()
    }
    
    func testConversationSummaryMemoryInitialization() {
        XCTAssertNotNil(summaryMemoryService)
        XCTAssertFalse(summaryMemoryService.isCompressing)
        XCTAssertEqual(summaryMemoryService.compressionProgress, 0.0)
    }
    
    func testCompressionThresholdSetting() {
        summaryMemoryService.setCompressionThreshold(2000)
        // Threshold is set internally, test would require access to private property
        // This tests that the method doesn't crash
    }
    
    func testNeedsCompressionWithEmptyMemory() async {
        let conversationId = UUID()
        let needsCompression = await summaryMemoryService.needsCompression(for: conversationId)
        XCTAssertFalse(needsCompression, "Empty memory should not need compression")
    }
    
    func testGetMemorySummaryWithNoSummary() async {
        let conversationId = UUID()
        let summary = await summaryMemoryService.getMemorySummary(for: conversationId)
        XCTAssertNil(summary, "Should return nil when no summary exists")
    }
    
    func testCompressionStatsWithNoCompression() async {
        let conversationId = UUID()
        let stats = await summaryMemoryService.getCompressionStats(for: conversationId)
        XCTAssertNil(stats, "Should return nil when no compression has been applied")
    }
    
    func testMemoryServiceIntegration() {
        // Test that MemoryService correctly implements AdvancedLangChainMemoryService
        XCTAssertTrue(memoryService is AdvancedLangChainMemoryService)
    }
    
    func testCompressionConfiguration() {
        let config = CompressionConfiguration.default
        XCTAssertEqual(config.keepRecentMessageCount, 6)
        XCTAssertEqual(config.compressionThreshold, 4000)
        XCTAssertEqual(config.maxSummaryTokens, 500)
        XCTAssertEqual(config.summarizationModel.id, "gpt-3.5-turbo")
    }
    
    func testConversationSummaryCreation() {
        let conversationId = UUID()
        let summary = ConversationSummary(
            conversationId: conversationId,
            summaryText: "Test summary",
            originalMessageCount: 5,
            compressedTokens: 20,
            createdAt: Date(),
            lastMessageTimestamp: Date()
        )
        
        XCTAssertEqual(summary.conversationId, conversationId)
        XCTAssertEqual(summary.summaryText, "Test summary")
        XCTAssertEqual(summary.originalMessageCount, 5)
        XCTAssertEqual(summary.compressedTokens, 20)
    }
    
    func testCompressionStatsCalculation() {
        let stats = CompressionStats(
            originalTokens: 1000,
            compressedTokens: 300,
            compressionRatio: 0.3,
            messageCount: 10,
            lastCompressed: Date()
        )
        
        XCTAssertEqual(stats.originalTokens, 1000)
        XCTAssertEqual(stats.compressedTokens, 300)
        XCTAssertEqual(stats.compressionRatio, 0.3)
        XCTAssertEqual(stats.compressionPercentage, 70.0, accuracy: 0.1)
    }
    
    func testConversationSummaryError() {
        let error = ConversationSummaryError.summarizationFailed("Test error")
        XCTAssertEqual(error.localizedDescription, "Summarization failed: Test error")
        
        let configError = ConversationSummaryError.invalidConfiguration
        XCTAssertEqual(configError.localizedDescription, "Invalid compression configuration")
    }
}

// MockLLMAPIService is now imported from shared file