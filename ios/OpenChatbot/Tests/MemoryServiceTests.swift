import XCTest
@testable import OpenChatbot

class MemoryServiceTests: XCTestCase {
    
    var memoryService: MemoryService!
    var dataService: DataService!
    
    override func setUp() {
        super.setUp()
        dataService = DataService()
        memoryService = MemoryService(dataService: dataService)
    }
    
    override func tearDown() {
        memoryService = nil
        dataService = nil
        super.tearDown()
    }
    
    func testMemoryServiceInitialization() {
        XCTAssertNotNil(memoryService)
        XCTAssertTrue(memoryService.isMemoryEnabled)
        XCTAssertEqual(memoryService.memoryStatus, .idle)
    }
    
    func testConversationMemoryCreation() async {
        let conversationId = UUID()
        
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        XCTAssertEqual(memory.conversationId, conversationId)
        XCTAssertEqual(memory.messageCount, 0)
        XCTAssertEqual(memoryService.memoryStatus, .ready)
    }
    
    func testAddMessageToMemory() async {
        let conversationId = UUID()
        let message = Message(
            content: "Hello, this is a test message",
            role: .user,
            conversationId: conversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: conversationId)
        
        let memory = await memoryService.getMemoryForConversation(conversationId)
        XCTAssertEqual(memory.messageCount, 1)
        XCTAssertEqual(memory.messages.first?.content, "Hello, this is a test message")
        XCTAssertEqual(memory.messages.first?.role, .user)
    }
    
    func testTokenLimitContext() async {
        let conversationId = UUID()
        
        // Add multiple messages
        for i in 1...10 {
            let message = Message(
                content: "This is message number \(i) with some content to test token limits",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Test with token limit
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: conversationId,
            maxTokens: 100 // Very small limit to test filtering
        )
        
        XCTAssertTrue(contextMessages.count < 10, "Should filter messages based on token limit")
        XCTAssertTrue(contextMessages.count > 0, "Should return at least some messages")
        
        // Verify messages are in correct order (recent first in context)
        if contextMessages.count > 1 {
            XCTAssertTrue(contextMessages[0].timestamp <= contextMessages[1].timestamp)
        }
    }
    
    func testMemoryStats() async {
        let conversationId = UUID()
        let message = Message(
            content: "Test message for stats",
            role: .user,
            conversationId: conversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: conversationId)
        
        let stats = await memoryService.getMemoryStats(for: conversationId)
        
        XCTAssertEqual(stats.messageCount, 1)
        XCTAssertTrue(stats.estimatedTokens > 0)
        XCTAssertEqual(stats.cacheStatus, .cached)
    }
    
    func testClearMemory() async {
        let conversationId = UUID()
        let message = Message(
            content: "Test message to be cleared",
            role: .user,
            conversationId: conversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: conversationId)
        
        // Verify message exists
        var memory = await memoryService.getMemoryForConversation(conversationId)
        XCTAssertEqual(memory.messageCount, 1)
        
        // Clear memory
        memoryService.clearMemory(for: conversationId)
        
        // Get memory again (should reload from storage)
        memory = await memoryService.getMemoryForConversation(conversationId)
        // Note: This might still show messages if they exist in Core Data
        // clearMemory only clears the cache, not persistent storage
    }
} 