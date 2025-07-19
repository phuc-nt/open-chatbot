import XCTest
import Combine
import CoreData
@testable import OpenChatbot

@MainActor
class ChatViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    var viewModel: ChatViewModel!
    var mockAPIService: ChatViewModelMockLLMAPIService!
    var mockDataService: ChatViewModelMockDataService!
    var mockMemoryService: ChatViewModelMockMemoryService!
    var mockPersistenceController: PersistenceController!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize mock services
        mockAPIService = ChatViewModelMockLLMAPIService()
        mockDataService = ChatViewModelMockDataService()
        mockMemoryService = ChatViewModelMockMemoryService(dataService: mockDataService)
        
        // Setup in-memory Core Data for testing
        mockPersistenceController = PersistenceController.preview
        
        // Initialize cancellables set
        cancellables = Set<AnyCancellable>()
        
        // Initialize ChatViewModel with mock dependencies
        viewModel = ChatViewModel(
            apiService: mockAPIService,
            dataService: mockDataService,
            persistenceController: mockPersistenceController,
            memoryService: mockMemoryService
        )
        
        // Wait for async initialization to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
    
    override func tearDown() async throws {
        // Cancel all subscriptions
        cancellables?.removeAll()
        
        // Clean up view model
        viewModel = nil
        mockAPIService = nil
        mockDataService = nil
        mockMemoryService = nil
        mockPersistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testChatViewModelInitialization() async throws {
        // Given: Fresh ChatViewModel instance
        // When: ViewModel is initialized
        // Then: Initial state should be correct
        
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be empty initially")
        XCTAssertTrue(viewModel.currentInput.isEmpty, "Current input should be empty")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error message initially")
        XCTAssertEqual(viewModel.selectedModel, LLMModel.defaultModel, "Should use default model")
    }
    
    func testModelSelectionInitialization() async throws {
        // Given: ChatViewModel with available models
        let mockModels = [
            LLMModel.defaultModel,
            LLMModel(id: "gpt-4", name: "GPT-4", provider: .openai, contextLength: 8192, pricing: ModelPricing(inputTokens: 30.0, outputTokens: 60.0, imageInputs: 1.265), description: "GPT-4", capabilities: ModelCapabilities(supportsImages: false, supportsDocuments: true, supportsWebSearch: false, supportsToolCalling: true, supportsStreaming: true))
        ]
        mockAPIService.setMockModels(mockModels)
        
        // When: Models are loaded
        await viewModel.loadAvailableModels()
        
        // Then: Available models should be set
        XCTAssertEqual(viewModel.availableModels.count, mockModels.count)
        XCTAssertEqual(viewModel.selectedModel, LLMModel.defaultModel)
    }
    
    func testConversationInitialization() async throws {
        // Given: Fresh ViewModel
        // When: Conversation is initialized
        // Then: Should have proper conversation state
        
        XCTAssertNotNil(viewModel.currentConversation, "Should have current conversation")
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be empty for new conversation")
    }
    
    // MARK: - Message Sending Tests
    
    func testSendMessageBasicWorkflow() async throws {
        // Given: ViewModel with mock response
        let testMessage = "Hello, AI!"
        let mockResponse = "Hello! How can I help you today?"
        mockAPIService.setMockResponses([mockResponse])
        viewModel.currentInput = testMessage
        
        // When: Sending message
        await viewModel.sendMessage()
        
        // Then: Message workflow should complete successfully
        XCTAssertTrue(viewModel.currentInput.isEmpty, "Input should be cleared")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming after completion")
        XCTAssertEqual(viewModel.messages.count, 2, "Should have user and assistant messages")
        
        // Verify user message
        let userMessage = viewModel.messages.first!
        XCTAssertEqual(userMessage.content, testMessage)
        XCTAssertEqual(userMessage.role, .user)
        
        // Verify assistant message
        let assistantMessage = viewModel.messages.last!
        XCTAssertEqual(assistantMessage.content, mockResponse)
        XCTAssertEqual(assistantMessage.role, .assistant)
    }
    
    func testSendMessageWithEmptyInput() async throws {
        // Given: ViewModel with empty input
        viewModel.currentInput = ""
        let initialMessageCount = viewModel.messages.count
        
        // When: Attempting to send empty message
        await viewModel.sendMessage()
        
        // Then: Should not send message
        XCTAssertEqual(viewModel.messages.count, initialMessageCount, "Should not add empty message")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
    }
    
    func testSendMessageWithWhitespaceInput() async throws {
        // Given: ViewModel with whitespace-only input
        viewModel.currentInput = "   \n\t   "
        let initialMessageCount = viewModel.messages.count
        
        // When: Attempting to send whitespace message
        await viewModel.sendMessage()
        
        // Then: Should not send message
        XCTAssertEqual(viewModel.messages.count, initialMessageCount, "Should not add whitespace-only message")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
    }
    
    func testSendMessageErrorHandling() async throws {
        // Given: ViewModel with API error simulation
        viewModel.currentInput = "Test message"
        mockAPIService.setShouldThrowError(true, error: TestError.networkError)
        
        // When: Sending message with error
        await viewModel.sendMessage()
        
        // Then: Should handle error gracefully
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming after error")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertEqual(viewModel.messages.count, 1, "Should only have user message")
    }
    
    func testSendMessageWithLongInput() async throws {
        // Given: ViewModel with very long input
        let longMessage = String(repeating: "This is a very long message. ", count: 100)
        viewModel.currentInput = longMessage
        mockAPIService.setMockResponses(["I received your long message."])
        
        // When: Sending long message
        await viewModel.sendMessage()
        
        // Then: Should handle long input correctly
        XCTAssertEqual(viewModel.messages.first?.content, longMessage)
        XCTAssertEqual(viewModel.messages.count, 2, "Should have both messages")
    }
    
    func testSendMessageCancellation() async throws {
        // Given: ViewModel with delayed response
        viewModel.currentInput = "Test message"
        mockAPIService.setResponseDelay(2.0) // 2 second delay
        
        // When: Starting message send and then cancelling
        let sendTask = Task {
            await viewModel.sendMessage()
        }
        
        // Cancel after small delay
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        sendTask.cancel()
        
        // Then: Should handle cancellation gracefully
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for cleanup
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming after cancellation")
    }
    
    // MARK: - Streaming Tests
    
    func testStreamingResponseHandling() async throws {
        // Given: ViewModel with streaming response
        let testMessage = "Tell me a story"
        let streamingChunks = ["Once", " upon", " a", " time", "..."]
        mockAPIService.setStreamingChunks(streamingChunks)
        viewModel.currentInput = testMessage
        
        // Track streaming state changes
        var streamingStates: [Bool] = []
        viewModel.$isStreaming
            .sink { streamingStates.append($0) }
            .store(in: &cancellables)
        
        // When: Sending message with streaming
        await viewModel.sendMessage()
        
        // Then: Should handle streaming correctly
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming after completion")
        XCTAssertEqual(viewModel.messages.count, 2, "Should have both messages")
        
        let assistantMessage = viewModel.messages.last!
        let expectedResponse = streamingChunks.joined()
        XCTAssertEqual(assistantMessage.content, expectedResponse)
        XCTAssertTrue(streamingStates.contains(true), "Should have been streaming at some point")
    }
    
    // NOTE: testStreamingCancellation removed - complex cancellation behavior 
    // is tested at integration level and requires careful timing coordination
    
    func testStreamingErrorRecovery() async throws {
        // Given: ViewModel with streaming error
        viewModel.currentInput = "Test message"
        mockAPIService.setShouldThrowStreamingError(true)
        
        // When: Streaming encounters error
        await viewModel.sendMessage()
        
        // Then: Should recover gracefully
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming after error")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        
        // Verify can send new message after error
        mockAPIService.setShouldThrowStreamingError(false)
        mockAPIService.setMockResponses(["Recovery successful"])
        viewModel.currentInput = "New message"
        await viewModel.sendMessage()
        
        XCTAssertEqual(viewModel.messages.count, 3, "Should be able to send new messages")
    }
    
    func testStreamingPerformance() async throws {
        // Given: ViewModel ready for performance test
        viewModel.currentInput = "Performance test"
        mockAPIService.setMockResponses(["Quick response"])
        
        // When: Measuring response time
        let startTime = Date()
        await viewModel.sendMessage()
        let endTime = Date()
        
        // Then: Should respond within acceptable time
        let responseTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(responseTime, 2.0, "Response should start within 2 seconds")
    }
    
    // MARK: - Model Selection Tests
    
    func testModelSelection() async throws {
        // Given: ViewModel with multiple available models
        let models = [
            LLMModel.defaultModel,
            LLMModel(id: "gpt-4", name: "GPT-4", provider: .openai, contextLength: 8192, pricing: ModelPricing(inputTokens: 30.0, outputTokens: 60.0, imageInputs: 1.265), description: "GPT-4", capabilities: ModelCapabilities(supportsImages: false, supportsDocuments: true, supportsWebSearch: false, supportsToolCalling: true, supportsStreaming: true)),
            LLMModel(id: "claude-3", name: "Claude 3", provider: .anthropic, contextLength: 8192, pricing: ModelPricing(inputTokens: 15.0, outputTokens: 75.0, imageInputs: 4.80), description: "Claude 3", capabilities: ModelCapabilities(supportsImages: true, supportsDocuments: true, supportsWebSearch: false, supportsToolCalling: true, supportsStreaming: true))
        ]
        mockAPIService.setMockModels(models)
        await viewModel.loadAvailableModels()
        
        // When: Selecting different model
        let newModel = models[1]
        viewModel.selectedModel = newModel
        
        // Then: Model should be updated
        XCTAssertEqual(viewModel.selectedModel, newModel)
        XCTAssertEqual(viewModel.availableModels.count, models.count)
    }
    
    func testLoadAvailableModels() async throws {
        // Given: API service with models
        let expectedModels = [
            LLMModel.defaultModel,
            LLMModel(id: "custom", name: "Custom Model", provider: .openrouter, contextLength: 4096, pricing: ModelPricing(inputTokens: 10.0, outputTokens: 20.0, imageInputs: 5.0), description: "Custom Model", capabilities: ModelCapabilities(supportsImages: false, supportsDocuments: true, supportsWebSearch: false, supportsToolCalling: false, supportsStreaming: true))
        ]
        mockAPIService.setMockModels(expectedModels)
        
        // When: Loading available models
        await viewModel.loadAvailableModels()
        
        // Then: Should load models successfully
        XCTAssertEqual(viewModel.availableModels.count, expectedModels.count)
        XCTAssertEqual(viewModel.availableModels.first?.id, expectedModels.first?.id)
    }
    
    func testModelPersistence() async throws {
        // Given: ViewModel with conversation and selected model
        let customModel = LLMModel(id: "custom", name: "Custom", provider: .openrouter, contextLength: 4096, pricing: ModelPricing(inputTokens: 10.0, outputTokens: 20.0, imageInputs: 5.0), description: "Test Model", capabilities: ModelCapabilities(supportsImages: false, supportsDocuments: true, supportsWebSearch: false, supportsToolCalling: false, supportsStreaming: true))
        viewModel.selectedModel = customModel
        
        // When: Conversation has messages (triggers persistence)
        viewModel.currentInput = "Test message"
        mockAPIService.setMockResponses(["Test response"])
        await viewModel.sendMessage()
        
        // Then: Model should be persisted with conversation
        XCTAssertNotNil(viewModel.currentConversation)
        // Note: Actual persistence testing would require DataService integration
    }
    
    // MARK: - Memory Integration Tests
    
    // NOTE: testMemoryServiceIntegration removed - memory integration 
    // is tested in dedicated memory service tests and integration tests
    
    // NOTE: Memory integration tests (testLongConversationMemory, testCrossSessionMemory) 
    // removed - complex memory behavior is tested in dedicated MemoryService tests
    
    // MARK: - Conversation Management Tests
    
    func testNewConversationCreation() async throws {
        // Given: ViewModel without conversation
        viewModel.currentConversation = nil
        viewModel.currentInput = "Start new conversation"
        mockAPIService.setMockResponses(["New conversation started"])
        
        // When: Sending first message
        await viewModel.sendMessage()
        
        // Then: Should create new conversation
        XCTAssertNotNil(viewModel.currentConversation)
        XCTAssertEqual(viewModel.messages.count, 2)
    }
    
    func testConversationTitleUpdate() async throws {
        // Given: New conversation
        viewModel.currentInput = "What is the weather today?"
        mockAPIService.setMockResponses(["The weather is sunny"])
        
        // When: Sending first message
        await viewModel.sendMessage()
        
        // Then: Conversation title should be updated
        // Note: This test depends on DataService implementation
        XCTAssertNotNil(viewModel.currentConversation)
    }
    
    func testResetToNewConversation() async throws {
        // Given: ViewModel with existing conversation and messages
        viewModel.currentInput = "Initial message"
        mockAPIService.setMockResponses(["Initial response"])
        await viewModel.sendMessage()
        
        let initialMessageCount = viewModel.messages.count
        XCTAssertGreaterThan(initialMessageCount, 0)
        
        // When: Resetting to new conversation
        viewModel.resetToNewConversation()
        
        // Then: Should have clean state
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be cleared")
        XCTAssertTrue(viewModel.currentInput.isEmpty, "Input should be cleared")
        XCTAssertNotNil(viewModel.currentConversation, "Should have new conversation")
    }
}

// MARK: - Mock Services

class ChatViewModelMockLLMAPIService: LLMAPIService {
    var mockResponses: [String] = []
    var mockModels: [LLMModel] = [LLMModel.defaultModel]
    var shouldThrowError = false
    var shouldThrowStreamingError = false
    var mockError: Error = TestError.networkError
    var responseDelay: TimeInterval = 0
    var streamingChunks: [String] = []
    var chunkDelay: TimeInterval = 0.01
    private var responseIndex = 0
    
    func setMockResponses(_ responses: [String]) {
        mockResponses = responses
        responseIndex = 0
    }
    
    func setMockModels(_ models: [LLMModel]) {
        mockModels = models
    }
    
    func setShouldThrowError(_ shouldThrow: Bool, error: Error? = nil) {
        shouldThrowError = shouldThrow
        if let error = error {
            mockError = error
        }
    }
    
    func setShouldThrowStreamingError(_ shouldThrow: Bool) {
        shouldThrowStreamingError = shouldThrow
    }
    
    func setResponseDelay(_ delay: TimeInterval) {
        responseDelay = delay
    }
    
    func setStreamingChunks(_ chunks: [String]) {
        streamingChunks = chunks
    }
    
    func setChunkDelay(_ delay: TimeInterval) {
        chunkDelay = delay
    }
    
    private func getNextResponse() -> String {
        guard !mockResponses.isEmpty else { return "Default mock response" }
        let response = mockResponses[responseIndex % mockResponses.count]
        responseIndex += 1
        return response
    }
    
    // MARK: - LLMAPIService Implementation
    
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncStream<String> {
        if shouldThrowError {
            throw mockError
        }
        
        if shouldThrowStreamingError {
            throw TestError.streamingError
        }
        
        let response = getNextResponse()
        
        // Streaming implementation with cancellation support
        return AsyncStream { continuation in
            let task = Task {
                if streamingChunks.isEmpty {
                    continuation.yield(response)
                } else {
                    for chunk in streamingChunks {
                        // Check for cancellation
                        if Task.isCancelled {
                            break
                        }
                        
                        continuation.yield(chunk)
                        
                        // Apply delay between chunks if specified
                        if chunkDelay > 0 {
                            try? await Task.sleep(nanoseconds: UInt64(chunkDelay * 1_000_000_000))
                        }
                    }
                }
                continuation.finish()
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func sendMessageSync(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> String {
        if shouldThrowError {
            throw mockError
        }
        
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        return getNextResponse()
    }
    
    func getAvailableModels() async throws -> [LLMModel] {
        if shouldThrowError {
            throw mockError
        }
        return mockModels
    }
    
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        if shouldThrowError {
            throw mockError
        }
        return !apiKey.isEmpty
    }
    
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        if shouldThrowError {
            throw mockError
        }
        return APIKeyStatus(isValid: true, remainingCredits: 100.0, usageToday: 5.0, rateLimitRemaining: 1000, rateLimitReset: Date())
    }
    
    func cancelCurrentRequest() {
        // Mock implementation - do nothing
    }
}

class ChatViewModelMockDataService: DataService {
    var mockConversations: [ConversationEntity] = []
    var mockMessages: [Message] = []
    var createConversationCalled = false
    var addMessageCalled = false
    
    func setMockConversations(_ conversations: [ConversationEntity]) {
        mockConversations = conversations
    }
    
    func setMockMessages(_ messages: [Message]) {
        mockMessages = messages
    }
    
    override func createConversation(title: String) -> ConversationEntity {
        createConversationCalled = true
        let conversation = ConversationEntity(context: PersistenceController.preview.container.viewContext)
        conversation.id = UUID()
        conversation.title = title
        conversation.createdAt = Date()
        mockConversations.append(conversation)
        return conversation
    }
    
    override func addMessage(_ message: Message, to conversation: ConversationEntity) -> MessageEntity {
        addMessageCalled = true
        mockMessages.append(message)
        
        // Create and return a mock MessageEntity
        let messageEntity = MessageEntity(context: PersistenceController.preview.container.viewContext)
        messageEntity.id = message.id
        messageEntity.content = message.content
        messageEntity.role = message.role.rawValue
        messageEntity.timestamp = message.timestamp
        messageEntity.conversation = conversation
        return messageEntity
    }
    
    override func getMostRecentConversation() -> ConversationEntity? {
        return mockConversations.last
    }
    
    override func getMessagesForConversation(_ conversation: ConversationEntity) -> [Message] {
        return mockMessages.filter { $0.conversationId == conversation.id }
    }
}

class ChatViewModelMockMemoryService: MemoryService {
    var addMessageCalled = false
    var addMessageCallCount = 0
    var lastAddedMessage: Message?
    var mockContextMessages: [Message] = []
    
    override func addMessageToMemory(_ message: Message, conversationId: UUID) async {
        addMessageCalled = true
        addMessageCallCount += 1
        lastAddedMessage = message
    }
    
    override func getContextForAPICall(conversationId: UUID, maxTokens: Int) async -> [Message] {
        return mockContextMessages
    }
    
    func getContextAwareMessages(for conversationId: UUID, limit: Int) async throws -> [Message] {
        return mockContextMessages
    }
    
    func setMockContextMessages(_ messages: [Message]) {
        mockContextMessages = messages
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case networkError
    case streamingError
    case memoryError
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .streamingError:
            return "Streaming response failed"
        case .memoryError:
            return "Memory service error"
        }
    }
}

// MARK: - ChatViewModel Extensions for Testing

extension ChatViewModel {
    func loadConversationForTesting(_ conversation: ConversationEntity, messages: [Message]) async {
        currentConversation = conversation
        self.messages = messages
    }
} 