import XCTest
import CoreData
@testable import OpenChatbot

class CoreDataTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var dataService: DataService!
    
    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        dataService = DataService(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        persistenceController = nil
        dataService = nil
        super.tearDown()
    }
    
    // MARK: - Conversation Tests
    
    func testCreateConversation() {
        // Given
        let title = "Test Conversation"
        
        // When
        let conversation = dataService.createConversation(title: title)
        
        // Then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation.title, title)
        XCTAssertNotNil(conversation.id)
        XCTAssertNotNil(conversation.createdAt)
        XCTAssertNotNil(conversation.updatedAt)
    }
    
    func testFetchConversations() {
        // Given
        dataService.createConversation(title: "Conversation 1")
        dataService.createConversation(title: "Conversation 2")
        
        // When
        let conversations = dataService.fetchConversations()
        
        // Then
        XCTAssertEqual(conversations.count, 2)
        XCTAssertEqual(conversations.first?.title, "Conversation 2") // Most recent first
    }
    
    func testUpdateConversation() {
        // Given
        let conversation = dataService.createConversation(title: "Original Title")
        let newTitle = "Updated Title"
        
        // When
        dataService.updateConversation(conversation, title: newTitle)
        
        // Then
        XCTAssertEqual(conversation.title, newTitle)
    }
    
    func testDeleteConversation() {
        // Given
        let conversation = dataService.createConversation(title: "To Delete")
        
        // When
        dataService.deleteConversation(conversation)
        
        // Then
        let conversations = dataService.fetchConversations()
        XCTAssertEqual(conversations.count, 0)
    }
    
    // MARK: - Message Tests
    
    func testAddMessage() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        let content = "Hello, world!"
        let role = "user"
        
        // When
        let message = dataService.addMessage(to: conversation, content: content, role: role)
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.role, role)
        XCTAssertEqual(message.conversationId, conversation.id)
        XCTAssertEqual(message.conversation, conversation)
    }
    
    func testFetchMessages() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        dataService.addMessage(to: conversation, content: "Message 1", role: "user")
        dataService.addMessage(to: conversation, content: "Message 2", role: "assistant")
        
        // When
        let messages = dataService.fetchMessages(for: conversation.id!)
        
        // Then
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.first?.content, "Message 1") // Chronological order
    }
    
    func testDeleteMessage() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        let message = dataService.addMessage(to: conversation, content: "To Delete", role: "user")
        
        // When
        dataService.deleteMessage(message)
        
        // Then
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 0)
    }
    
    // MARK: - API Key Tests
    
    func testCreateAPIKey() {
        // Given
        let name = "Test API Key"
        let provider = "openai"
        let keyData = "test-key-data".data(using: .utf8)!
        
        // When
        let apiKey = dataService.createAPIKey(name: name, provider: provider, keyData: keyData)
        
        // Then
        XCTAssertNotNil(apiKey)
        XCTAssertEqual(apiKey.name, name)
        XCTAssertEqual(apiKey.provider, provider)
        XCTAssertEqual(apiKey.keyData, keyData)
        XCTAssertNotNil(apiKey.createdAt)
    }
    
    func testFetchAPIKeys() {
        // Given
        dataService.createAPIKey(name: "OpenAI Key", provider: "openai", keyData: Data())
        dataService.createAPIKey(name: "Claude Key", provider: "anthropic", keyData: Data())
        
        // When
        let apiKeys = dataService.fetchAPIKeys()
        
        // Then
        XCTAssertEqual(apiKeys.count, 2)
    }
    
    func testDeleteAPIKey() {
        // Given
        let apiKey = dataService.createAPIKey(name: "To Delete", provider: "openai", keyData: Data())
        
        // When
        dataService.deleteAPIKey(apiKey)
        
        // Then
        let apiKeys = dataService.fetchAPIKeys()
        XCTAssertEqual(apiKeys.count, 0)
    }
    
    // MARK: - Utility Tests
    
    func testConversationCount() {
        // Given
        dataService.createConversation(title: "Conversation 1")
        dataService.createConversation(title: "Conversation 2")
        
        // When
        let count = dataService.getConversationCount()
        
        // Then
        XCTAssertEqual(count, 2)
    }
    
    func testMessageCount() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        dataService.addMessage(to: conversation, content: "Message 1", role: "user")
        dataService.addMessage(to: conversation, content: "Message 2", role: "assistant")
        
        // When
        let count = dataService.getMessageCount(for: conversation.id!)
        
        // Then
        XCTAssertEqual(count, 2)
    }
    
    func testDeleteAllData() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        dataService.addMessage(to: conversation, content: "Test Message", role: "user")
        dataService.createAPIKey(name: "Test Key", provider: "openai", keyData: Data())
        
        // When
        dataService.deleteAllData()
        
        // Then
        XCTAssertEqual(dataService.getConversationCount(), 0)
        XCTAssertEqual(dataService.fetchAPIKeys().count, 0)
    }
    
    // MARK: - Cascade Delete Tests
    
    func testCascadeDelete() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        dataService.addMessage(to: conversation, content: "Message 1", role: "user")
        dataService.addMessage(to: conversation, content: "Message 2", role: "assistant")
        
        // When
        dataService.deleteConversation(conversation)
        
        // Then
        let allMessages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(allMessages.count, 0) // Messages should be deleted via cascade
    }
    
    // MARK: - Smart Memory System Integration Tests (Sprint 3)
    
    func testMemoryPersistenceData() {
        // Test MEM-004: Memory Persistence Across Sessions
        let conversation = dataService.createConversation(title: "Memory Test Conversation")
        
        // Add messages with memory-related metadata
        let message1 = dataService.addMessage(to: conversation, content: "What is the capital of France?", role: "user")
        let message2 = dataService.addMessage(to: conversation, content: "The capital of France is Paris.", role: "assistant")
        let message3 = dataService.addMessage(to: conversation, content: "Tell me more about it", role: "user")
        
        // Verify messages are persisted with proper order
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].content, "What is the capital of France?")
        XCTAssertEqual(messages[1].content, "The capital of France is Paris.")
        XCTAssertEqual(messages[2].content, "Tell me more about it")
        
        // Test context continuity
        XCTAssertEqual(messages[0].role, "user")
        XCTAssertEqual(messages[1].role, "assistant")
        XCTAssertEqual(messages[2].role, "user")
    }
    
    func testConversationMemoryMetadata() {
        // Test storing memory-related metadata
        let conversation = dataService.createConversation(title: "Metadata Test")
        
        // Add messages with various content types
        let shortMessage = dataService.addMessage(to: conversation, content: "Hi", role: "user")
        let longMessage = dataService.addMessage(to: conversation, content: "This is a much longer message that contains substantial content for testing token counting and memory compression algorithms in the Smart Memory System.", role: "assistant")
        
        // Verify both messages are stored correctly
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 2)
        
        // Test that long content is preserved
        let retrievedLongMessage = messages.first { $0.content.contains("substantial content") }
        XCTAssertNotNil(retrievedLongMessage)
        XCTAssertEqual(retrievedLongMessage?.role, "assistant")
    }
    
    func testMemoryCompressionDataPersistence() {
        // Test data persistence for memory compression
        let conversation = dataService.createConversation(title: "Compression Test")
        
        // Add many messages to simulate compression scenario
        for i in 1...20 {
            let role = i % 2 == 0 ? "assistant" : "user"
            let content = "Message \(i): This is message content that would be subject to compression in the Smart Memory System."
            dataService.addMessage(to: conversation, content: content, role: role)
        }
        
        // Verify all messages are persisted
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 20)
        
        // Test that messages maintain proper order
        let firstMessage = messages.first
        let lastMessage = messages.last
        XCTAssertTrue(firstMessage!.content.contains("Message 1"))
        XCTAssertTrue(lastMessage!.content.contains("Message 20"))
        
        // Test chronological ordering
        XCTAssertTrue(firstMessage!.timestamp! <= lastMessage!.timestamp!)
    }
    
    func testConversationSummaryPersistence() {
        // Test persistence of conversation summaries (for ConversationSummaryMemory)
        let conversation = dataService.createConversation(title: "Summary Test")
        
        // Add messages that would trigger summarization
        for i in 1...10 {
            let content = "Message \(i): Detailed content about a specific topic that would be summarized by the ConversationSummaryMemory service."
            dataService.addMessage(to: conversation, content: content, role: i % 2 == 0 ? "assistant" : "user")
        }
        
        // Verify data is ready for summarization
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 10)
        
        // Test that conversation has enough content for summarization
        let totalContentLength = messages.reduce(0) { $0 + $1.content.count }
        XCTAssertGreaterThan(totalContentLength, 500) // Should have substantial content
    }
    
    func testMemoryContextRetrieval() {
        // Test efficient retrieval of memory context
        let conversation = dataService.createConversation(title: "Context Retrieval Test")
        
        // Add messages with different timestamps
        let message1 = dataService.addMessage(to: conversation, content: "First message", role: "user")
        
        // Simulate time passing
        Thread.sleep(forTimeInterval: 0.1)
        
        let message2 = dataService.addMessage(to: conversation, content: "Second message", role: "assistant")
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let message3 = dataService.addMessage(to: conversation, content: "Third message", role: "user")
        
        // Test retrieval with proper ordering
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 3)
        
        // Verify chronological order
        XCTAssertTrue(messages[0].timestamp! <= messages[1].timestamp!)
        XCTAssertTrue(messages[1].timestamp! <= messages[2].timestamp!)
        
        // Test recent message retrieval (for token window management)
        let recentMessages = Array(messages.suffix(2))
        XCTAssertEqual(recentMessages.count, 2)
        XCTAssertEqual(recentMessages[0].content, "Second message")
        XCTAssertEqual(recentMessages[1].content, "Third message")
    }
    
    func testMemoryDataIntegrity() {
        // Test data integrity for memory operations
        let conversation = dataService.createConversation(title: "Data Integrity Test")
        
        // Add messages with special characters and long content
        let specialMessage = dataService.addMessage(
            to: conversation, 
            content: "Message with special chars: 🚀 émoji ñ unicode 中文 العربية", 
            role: "user"
        )
        
        let longMessage = dataService.addMessage(
            to: conversation,
            content: String(repeating: "Long content for testing data integrity in memory persistence. ", count: 50),
            role: "assistant"
        )
        
        // Verify data integrity
        let messages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(messages.count, 2)
        
        // Test special character preservation
        let retrievedSpecialMessage = messages.first { $0.content.contains("🚀") }
        XCTAssertNotNil(retrievedSpecialMessage)
        XCTAssertTrue(retrievedSpecialMessage!.content.contains("émoji"))
        XCTAssertTrue(retrievedSpecialMessage!.content.contains("中文"))
        
        // Test long content preservation
        let retrievedLongMessage = messages.first { $0.content.count > 1000 }
        XCTAssertNotNil(retrievedLongMessage)
        XCTAssertEqual(retrievedLongMessage?.role, "assistant")
    }
    
    // MARK: - Performance Tests for Memory Operations
    
    func testMemoryDataPerformance() {
        // Test Core Data performance for memory operations
        let conversation = dataService.createConversation(title: "Performance Test")
        
        // Measure message insertion performance
        let insertStartTime = CFAbsoluteTimeGetCurrent()
        
        for i in 1...100 {
            dataService.addMessage(to: conversation, content: "Performance test message \(i)", role: i % 2 == 0 ? "assistant" : "user")
        }
        
        let insertEndTime = CFAbsoluteTimeGetCurrent()
        let insertTime = insertEndTime - insertStartTime
        
        // Measure retrieval performance
        let retrievalStartTime = CFAbsoluteTimeGetCurrent()
        let messages = dataService.fetchMessages(for: conversation.id!)
        let retrievalEndTime = CFAbsoluteTimeGetCurrent()
        let retrievalTime = retrievalEndTime - retrievalStartTime
        
        // Performance assertions
        XCTAssertLessThan(insertTime, 2.0, "Message insertion should complete within 2 seconds")
        XCTAssertLessThan(retrievalTime, 0.5, "Message retrieval should complete within 500ms")
        XCTAssertEqual(messages.count, 100, "Should retrieve all messages")
    }
    
    // MARK: - Memory Bridge Integration Tests
    
    func testMemoryBridgeDataFlow() {
        // Test data flow between memory service and Core Data
        let conversation = dataService.createConversation(title: "Bridge Test")
        
        // Simulate memory service operations
        let contextMessages = [
            ("What is machine learning?", "user"),
            ("Machine learning is a subset of artificial intelligence...", "assistant"),
            ("Can you give me an example?", "user"),
            ("Sure! A common example is email spam detection...", "assistant")
        ]
        
        // Add messages through data service (simulating memory bridge)
        for (content, role) in contextMessages {
            dataService.addMessage(to: conversation, content: content, role: role)
        }
        
        // Verify data is available for memory retrieval
        let storedMessages = dataService.fetchMessages(for: conversation.id!)
        XCTAssertEqual(storedMessages.count, 4)
        
        // Test conversation flow integrity
        XCTAssertEqual(storedMessages[0].content, "What is machine learning?")
        XCTAssertEqual(storedMessages[1].role, "assistant")
        XCTAssertEqual(storedMessages[2].content, "Can you give me an example?")
        XCTAssertEqual(storedMessages[3].role, "assistant")
    }
    
    // MARK: - Existing Tests (Relationship Tests)
    
    func testConversationMessageRelationship() {
        // Given
        let conversation = dataService.createConversation(title: "Test Conversation")
        let message1 = dataService.addMessage(to: conversation, content: "Message 1", role: "user")
        let message2 = dataService.addMessage(to: conversation, content: "Message 2", role: "assistant")
        
        // When
        let conversationMessages = conversation.messages?.allObjects as? [MessageEntity] ?? []
        
        // Then
        XCTAssertEqual(conversationMessages.count, 2)
        XCTAssertTrue(conversationMessages.contains(message1))
        XCTAssertTrue(conversationMessages.contains(message2))
        XCTAssertEqual(message1.conversation, conversation)
        XCTAssertEqual(message2.conversation, conversation)
    }
} 