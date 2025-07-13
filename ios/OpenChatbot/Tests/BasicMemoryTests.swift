import XCTest
@testable import OpenChatbot

@MainActor
class BasicMemoryTests: XCTestCase {
    
    var dataService: DataService!
    var memoryService: MemoryService!
    var testConversationId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup test data
        testConversationId = UUID()
        dataService = DataService(inMemory: true)
        memoryService = MemoryService(dataService: dataService)
    }
    
    override func tearDown() async throws {
        memoryService = nil
        dataService = nil
        testConversationId = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Basic Memory Service Tests
    
    func testMemoryServiceInitialization() async throws {
        XCTAssertNotNil(memoryService)
        XCTAssertTrue(memoryService.isMemoryEnabled)
        XCTAssertEqual(memoryService.memoryStatus, .idle)
    }
    
    func testConversationMemoryCreation() async throws {
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        
        XCTAssertEqual(memory.conversationId, testConversationId)
        XCTAssertEqual(memory.messageCount, 0)
        XCTAssertEqual(memoryService.memoryStatus, .ready)
    }
    
    func testAddMessageToMemory() async throws {
        let message = Message(
            content: "Hello, this is a test message for Smart Memory System",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 1)
        XCTAssertEqual(memory.messages.first?.content, message.content)
        XCTAssertEqual(memory.messages.first?.role, .user)
    }
    
    func testMultipleMessagesInMemory() async throws {
        let messages = [
            Message(content: "First message", role: .user, conversationId: testConversationId),
            Message(content: "AI response", role: .assistant, conversationId: testConversationId),
            Message(content: "Second user message", role: .user, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 3)
        XCTAssertEqual(memory.messages.count, 3)
        XCTAssertEqual(memory.messages[0].content, "First message")
        XCTAssertEqual(memory.messages[1].content, "AI response")
        XCTAssertEqual(memory.messages[2].content, "Second user message")
    }
    
    func testMemoryContextForAPICall() async throws {
        let messages = [
            Message(content: "What is AI?", role: .user, conversationId: testConversationId),
            Message(content: "AI is artificial intelligence", role: .assistant, conversationId: testConversationId),
            Message(content: "Tell me more", role: .user, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        let context = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 1000
        )
        
        XCTAssertEqual(context.count, 3)
        XCTAssertEqual(context[0].content, "What is AI?")
        XCTAssertEqual(context[1].content, "AI is artificial intelligence")
        XCTAssertEqual(context[2].content, "Tell me more")
    }
    
    func testMemoryStatistics() async throws {
        let messages = [
            Message(content: "Test message 1", role: .user, conversationId: testConversationId),
            Message(content: "Test response 1", role: .assistant, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        let stats = await memoryService.getMemoryStatistics(for: testConversationId)
        XCTAssertEqual(stats.messageCount, 2)
        XCTAssertGreaterThan(stats.estimatedTokens, 0)
        XCTAssertNotNil(stats.lastUpdated)
    }
    
    func testClearMemoryCache() async throws {
        let message = Message(
            content: "Test message",
            role: .user,
            conversationId: testConversationId
        )
        
        await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        
        // Verify message is in memory
        let memoryBefore = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memoryBefore.messageCount, 1)
        
        // Clear memory cache
        memoryService.clearMemory(for: testConversationId)
        
        // Verify memory is cleared from cache but can be reloaded from persistence
        let memoryAfter = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memoryAfter.messageCount, 1) // Should reload from persistence
    }
    
    func testMemoryWithDifferentConversations() async throws {
        let conversation1 = UUID()
        let conversation2 = UUID()
        
        let message1 = Message(content: "Message for conversation 1", role: .user, conversationId: conversation1)
        let message2 = Message(content: "Message for conversation 2", role: .user, conversationId: conversation2)
        
        await memoryService.addMessageToMemory(message1, conversationId: conversation1)
        await memoryService.addMessageToMemory(message2, conversationId: conversation2)
        
        let memory1 = await memoryService.getMemoryForConversation(conversation1)
        let memory2 = await memoryService.getMemoryForConversation(conversation2)
        
        XCTAssertEqual(memory1.messageCount, 1)
        XCTAssertEqual(memory2.messageCount, 1)
        XCTAssertEqual(memory1.messages.first?.content, "Message for conversation 1")
        XCTAssertEqual(memory2.messages.first?.content, "Message for conversation 2")
    }
} 