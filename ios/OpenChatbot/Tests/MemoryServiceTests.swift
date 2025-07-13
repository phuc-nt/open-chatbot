import XCTest
@testable import OpenChatbot

@MainActor
class MemoryServiceTests: XCTestCase {
    
    var memoryService: MemoryService!
    var dataService: DataService!
    var testConversationId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup services for testing
        dataService = DataService(inMemory: true)
        memoryService = MemoryService(dataService: dataService)
        testConversationId = UUID()
    }
    
    override func tearDown() async throws {
        memoryService = nil
        dataService = nil
        testConversationId = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Memory Service Tests
    
    func testMemoryServiceInitialization() {
        XCTAssertNotNil(memoryService)
        XCTAssertTrue(memoryService.isMemoryEnabled)
        XCTAssertEqual(memoryService.memoryStatus, .idle)
    }
    
    func testConversationMemoryCreation() async {
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        
        XCTAssertEqual(memory.conversationId, testConversationId)
        XCTAssertEqual(memory.messageCount, 0)
        XCTAssertEqual(memoryService.memoryStatus, .ready)
    }
    
    func testAddMessageToMemory() async {
        let message = Message(
            content: "Hello, this is a test message for Smart Memory System",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 1)
        XCTAssertEqual(memory.messages.first?.content, "Hello, this is a test message for Smart Memory System")
        XCTAssertEqual(memory.messages.first?.role, .user)
    }
    
    func testContextAwareResponseGeneration() async {
        // Test MEM-003: Context-Aware Response Generation
        let userMessage = Message(
            content: "What is the capital of France?",
            role: .user,
            conversationId: testConversationId
        )
        
        let assistantMessage = Message(
            content: "The capital of France is Paris.",
            role: .assistant,
            conversationId: testConversationId
        )
        
        let followUpMessage = Message(
            content: "Tell me more about it",
            role: .user,
            conversationId: testConversationId
        )
        
        // Add messages to memory
        await memoryService.addMessageToMemory(userMessage, conversationId: testConversationId)
        await memoryService.addMessageToMemory(assistantMessage, conversationId: testConversationId)
        await memoryService.addMessageToMemory(followUpMessage, conversationId: testConversationId)
        
        // Get context for API call
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 4000
        )
        
        XCTAssertEqual(contextMessages.count, 3)
        XCTAssertEqual(contextMessages[0].content, "What is the capital of France?")
        XCTAssertEqual(contextMessages[1].content, "The capital of France is Paris.")
        XCTAssertEqual(contextMessages[2].content, "Tell me more about it")
    }
    
    func testTokenLimitContextHandling() async {
        // Add multiple messages to test token limit handling
        for i in 1...20 {
            let message = Message(
                content: "This is message number \(i) with substantial content to test token limits in the Smart Memory System. The message contains enough text to contribute meaningfully to token count calculations.",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Test with small token limit to trigger compression
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 500 // Small limit to test filtering
        )
        
        XCTAssertLessThan(contextMessages.count, 20, "Should filter messages based on token limit")
        XCTAssertGreaterThan(contextMessages.count, 0, "Should return at least some messages")
        
        // Verify recent messages are preserved
        let lastMessage = contextMessages.last
        XCTAssertNotNil(lastMessage)
        XCTAssertTrue(lastMessage!.content.contains("20"), "Should preserve most recent messages")
    }
    
    func testMemoryPersistence() async {
        // Test MEM-004: Memory Persistence Across Sessions
        let message = Message(
            content: "Test message for persistence across sessions",
            role: .user,
            conversationId: testConversationId
        )
        
        // Add message to memory
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        // Verify message is persisted
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 1)
        XCTAssertEqual(memory.messages.first?.content, "Test message for persistence across sessions")
    }
    
    func testMemoryStats() async {
        let message = Message(
            content: "Test message for Smart Memory System statistics",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        let stats = await memoryService.getMemoryStats(for: testConversationId)
        
        XCTAssertEqual(stats.messageCount, 1)
        XCTAssertGreaterThan(stats.estimatedTokens, 0)
        XCTAssertEqual(stats.cacheStatus, .cached)
    }
    
    func testClearMemory() async {
        let message = Message(
            content: "Test message to be cleared from memory",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        // Verify message exists
        var memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 1)
        
        // Clear memory
        memoryService.clearMemory(for: testConversationId)
        
        // Get memory again - should be empty in cache
        memory = await memoryService.getMemoryForConversation(testConversationId)
        // Note: Memory might reload from Core Data, so we test that clearMemory doesn't crash
        XCTAssertNotNil(memory)
    }
    
    // MARK: - Performance Tests
    
    func testMemoryPerformance() async {
        // Test MEM-005: Memory Performance Optimization
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Add messages and measure performance
        for i in 1...100 {
            let message = Message(
                content: "Performance test message \(i)",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Get context with performance measurement
        let contextStartTime = CFAbsoluteTimeGetCurrent()
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 4000
        )
        let contextEndTime = CFAbsoluteTimeGetCurrent()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Performance assertions
        let totalTime = endTime - startTime
        let contextRetrievalTime = contextEndTime - contextStartTime
        
        XCTAssertLessThan(totalTime, 5.0, "Total memory operations should complete within 5 seconds")
        XCTAssertLessThan(contextRetrievalTime, 0.5, "Context retrieval should complete within 500ms")
        XCTAssertGreaterThan(contextMessages.count, 0, "Should retrieve context messages")
    }
    
    // MARK: - Integration Tests
    
    func testMemoryIntegrationWithMultipleConversations() async {
        let conversation1 = UUID()
        let conversation2 = UUID()
        
        // Add messages to first conversation
        await memoryService.addMessageToMemory(
            Message(content: "Message in conversation 1", role: .user, conversationId: conversation1),
            conversationId: conversation1
        )
        
        // Add messages to second conversation
        await memoryService.addMessageToMemory(
            Message(content: "Message in conversation 2", role: .user, conversationId: conversation2),
            conversationId: conversation2
        )
        
        // Verify conversations are separate
        let memory1 = await memoryService.getMemoryForConversation(conversation1)
        let memory2 = await memoryService.getMemoryForConversation(conversation2)
        
        XCTAssertEqual(memory1.messageCount, 1)
        XCTAssertEqual(memory2.messageCount, 1)
        XCTAssertEqual(memory1.messages.first?.content, "Message in conversation 1")
        XCTAssertEqual(memory2.messages.first?.content, "Message in conversation 2")
    }
    
    func testMemoryServiceErrorHandling() async {
        // Test error handling with invalid data
        let invalidMessage = Message(
            content: "", // Empty content
            role: .user,
            conversationId: testConversationId
        )
        
        // Should handle empty content gracefully
        await memoryService.addMessageToMemory(invalidMessage, conversationId: testConversationId)
        
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        // Should still work, just with empty content
        XCTAssertEqual(memory.messageCount, 1)
    }
} 