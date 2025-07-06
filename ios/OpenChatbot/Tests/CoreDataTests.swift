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
    
    // MARK: - Relationship Tests
    
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
} 