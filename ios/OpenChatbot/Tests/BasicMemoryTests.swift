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

// MARK: - Shared Mock API Service for All Tests
class MockLLMAPIService: LLMAPIService {
    
    // MARK: - Mock Data
    private var mockModels: [LLMModel] = []
    private var mockResponses: [String] = []
    private var shouldThrowError: Bool = false
    private var mockError: Error?
    
    init() {
        setupDefaultMockModels()
    }
    
    // MARK: - Configuration Methods
    func setMockModels(_ models: [LLMModel]) {
        mockModels = models
    }
    
    func setMockResponses(_ responses: [String]) {
        mockResponses = responses
    }
    
    func setShouldThrowError(_ shouldThrow: Bool, error: Error? = nil) {
        shouldThrowError = shouldThrow
        mockError = error
    }
    
    // MARK: - LLMAPIService Implementation
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncStream<String> {
        if shouldThrowError {
            throw mockError ?? MockError.testError
        }
        
        return AsyncStream { continuation in
            Task {
                let response = getNextMockResponse()
                
                // Simulate streaming response
                for chunk in response.components(separatedBy: " ") {
                    continuation.yield(chunk + " ")
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
                }
                
                continuation.finish()
            }
        }
    }
    
    func sendMessageSync(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> String {
        if shouldThrowError {
            throw mockError ?? MockError.testError
        }
        
        return getNextMockResponse()
    }
    
    func getAvailableModels() async throws -> [LLMModel] {
        if shouldThrowError {
            throw mockError ?? MockError.testError
        }
        
        return mockModels
    }
    
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        if shouldThrowError {
            throw mockError ?? MockError.testError
        }
        
        return !apiKey.isEmpty
    }
    
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        if shouldThrowError {
            throw mockError ?? MockError.testError
        }
        
        return APIKeyStatus(
            isValid: true,
            remainingCredits: 100.0,
            usageToday: 5.0,
            rateLimitRemaining: 1000,
            rateLimitReset: Date().addingTimeInterval(3600)
        )
    }
    
    func cancelCurrentRequest() {
        // Mock implementation - no actual cancellation needed
    }
    
    // MARK: - Helper Methods
    private func setupDefaultMockModels() {
        mockModels = [
            LLMModel(
                id: "gpt-3.5-turbo",
                name: "GPT-3.5 Turbo",
                provider: .openai,
                contextLength: 4096,
                pricing: ModelPricing(inputTokens: 1.5, outputTokens: 2.0, imageInputs: nil),
                description: "Mock GPT-3.5 for testing",
                capabilities: ModelCapabilities(supportsImages: false, supportsStreaming: true, maxTokens: 4096)
            ),
            LLMModel(
                id: "gpt-4",
                name: "GPT-4",
                provider: .openai,
                contextLength: 8192,
                pricing: ModelPricing(inputTokens: 30, outputTokens: 60, imageInputs: nil),
                description: "Mock GPT-4 for testing",
                capabilities: ModelCapabilities(supportsImages: true, supportsStreaming: true, maxTokens: 8192)
            ),
            LLMModel(
                id: "claude-3-sonnet",
                name: "Claude 3 Sonnet",
                provider: .anthropic,
                contextLength: 200000,
                pricing: ModelPricing(inputTokens: 3, outputTokens: 15, imageInputs: nil),
                description: "Mock Claude 3 for testing",
                capabilities: ModelCapabilities(supportsImages: true, supportsStreaming: true, maxTokens: 200000)
            )
        ]
        
        mockResponses = [
            "This is a mock response for testing purposes.",
            "Another mock response with different content.",
            "Mock response for comprehensive testing scenarios.",
            "Advanced mock response for integration testing."
        ]
    }
    
    private func getNextMockResponse() -> String {
        if mockResponses.isEmpty {
            return "Default mock response"
        }
        
        // Cycle through responses
        let response = mockResponses.removeFirst()
        mockResponses.append(response)
        return response
    }
}

// MARK: - Mock Error
enum MockError: Error {
    case testError
    case networkError
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .testError:
            return "Test error for mock service"
        case .networkError:
            return "Mock network error"
        case .invalidResponse:
            return "Mock invalid response error"
        }
    }
} 