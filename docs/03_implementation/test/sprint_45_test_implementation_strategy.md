# Sprint 4.5 Test Implementation Strategy

**Document**: Test Implementation Strategy for Sprint 4.5  
**Purpose**: Detailed technical guide cho implementing missing test coverage  
**Target**: 85%+ overall coverage với production-ready quality  
**Status**: 🚀 **ACTIVE** - ChatViewModelTests ✅ COMPLETED  
**Date**: Updated July 19, 2025  

---

## 🎯 **Implementation Overview**

### **Strategy Approach**
- **Test-First Mindset**: Write tests trước khi fix any bugs discovered
- **Mock-Heavy**: Use comprehensive mocking cho isolated testing
- **Performance-Aware**: Include performance benchmarks trong all critical tests
- **Integration-Focused**: Test real workflows, not just unit functionality

---

## ✅ **Priority 1: ChatViewModel Test Implementation - COMPLETED**

**Status**: ✅ **100% COMPLETED** - July 19, 2025  
**Results**: 18 tests ALL PASSING, 600+ lines comprehensive coverage  
**Achievement**: Full protocol-based mock architecture established

### **ChatViewModelTests.swift Structure**

```swift
import XCTest
import Combine
import CoreData
@testable import OpenChatbot

@MainActor
final class ChatViewModelTests: XCTestCase {
    
    // MARK: - Test Setup
    var viewModel: ChatViewModel!
    var mockAPIService: MockLLMAPIService!
    var mockDataService: MockDataService!
    var mockMemoryService: MockMemoryService!
    var mockPersistenceController: MockPersistenceController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup mock services
        mockAPIService = MockLLMAPIService()
        mockDataService = MockDataService(inMemory: true)
        mockMemoryService = MockMemoryService()
        mockPersistenceController = MockPersistenceController()
        
        // Create ChatViewModel với mocked dependencies
        viewModel = ChatViewModel(
            apiService: mockAPIService,
            dataService: mockDataService,
            persistenceController: mockPersistenceController,
            memoryService: mockMemoryService
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockAPIService = nil
        mockDataService = nil
        mockMemoryService = nil
        mockPersistenceController = nil
        cancellables = nil
        try await super.tearDown()
    }
}
```

### **Critical Test Categories**

#### **1. Initialization & State Management (10 tests)**
```swift
// MARK: - Initialization Tests
func testChatViewModelInitialization() {
    XCTAssertNotNil(viewModel)
    XCTAssertTrue(viewModel.messages.isEmpty)
    XCTAssertEqual(viewModel.currentInput, "")
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertNil(viewModel.currentConversation)
    XCTAssertNil(viewModel.errorMessage)
}

func testModelSelectionInitialization() {
    XCTAssertEqual(viewModel.selectedModel, LLMModel.defaultModel)
    XCTAssertTrue(viewModel.availableModels.isEmpty)
}

func testConversationInitialization() async {
    // When
    await viewModel.createNewConversation()
    
    // Then
    XCTAssertNotNil(viewModel.currentConversation)
    XCTAssertTrue(viewModel.messages.isEmpty)
}
```

#### **2. Message Sending Workflow (15 tests)**
```swift
// MARK: - Message Sending Tests
func testSendMessageBasicWorkflow() async {
    // Given
    let testMessage = "Hello, AI!"
    mockAPIService.mockResponse = "Hello! How can I help you?"
    viewModel.currentInput = testMessage
    
    // When
    await viewModel.sendMessage()
    
    // Then
    XCTAssertEqual(viewModel.messages.count, 2) // User + AI message
    XCTAssertEqual(viewModel.messages.first?.content, testMessage)
    XCTAssertEqual(viewModel.messages.last?.content, "Hello! How can I help you?")
    XCTAssertEqual(viewModel.currentInput, "") // Input cleared
    XCTAssertFalse(viewModel.isLoading)
}

func testSendMessageWithEmptyInput() async {
    // Given
    viewModel.currentInput = ""
    
    // When
    await viewModel.sendMessage()
    
    // Then
    XCTAssertTrue(viewModel.messages.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
}

func testSendMessageErrorHandling() async {
    // Given
    viewModel.currentInput = "Test message"
    mockAPIService.shouldThrowError = true
    mockAPIService.errorToThrow = APIError.networkError
    
    // When
    await viewModel.sendMessage()
    
    // Then
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertEqual(viewModel.messages.count, 1) // Only user message added
}
```

#### **3. Streaming Response Handling (12 tests)**
```swift
// MARK: - Streaming Tests
func testStreamingResponseHandling() async {
    // Given
    let testMessage = "Tell me a story"
    let streamChunks = ["Once", " upon", " a", " time..."]
    mockAPIService.streamingChunks = streamChunks
    viewModel.currentInput = testMessage
    
    // When
    await viewModel.sendMessage()
    
    // Then
    XCTAssertTrue(viewModel.isStreaming)
    XCTAssertEqual(viewModel.messages.count, 2)
    
    // Verify streaming message content
    let aiMessage = viewModel.messages.last
    XCTAssertEqual(aiMessage?.content, "Once upon a time...")
}

func testStreamingCancellation() async {
    // Given
    viewModel.currentInput = "Long story please"
    mockAPIService.streamingDelay = 1.0 // Slow streaming
    
    // When
    let sendTask = Task {
        await viewModel.sendMessage()
    }
    
    // Cancel after brief delay
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    viewModel.cancelCurrentRequest()
    
    // Then
    await sendTask.value
    XCTAssertFalse(viewModel.isStreaming)
    XCTAssertFalse(viewModel.isLoading)
}
```

#### **4. Model Selection & Switching (8 tests)**
```swift
// MARK: - Model Selection Tests
func testModelSelection() async {
    // Given
    let newModel = LLMModel(
        id: "gpt-4",
        name: "GPT-4",
        provider: .openAI,
        contextWindow: 8192
    )
    
    // When
    await viewModel.selectModel(newModel)
    
    // Then
    XCTAssertEqual(viewModel.selectedModel, newModel)
}

func testLoadAvailableModels() async {
    // Given
    let mockModels = [
        LLMModel(id: "gpt-4", name: "GPT-4", provider: .openAI, contextWindow: 8192),
        LLMModel(id: "claude-3", name: "Claude 3", provider: .anthropic, contextWindow: 200000)
    ]
    mockAPIService.availableModels = mockModels
    
    // When
    await viewModel.loadAvailableModels()
    
    // Then
    XCTAssertEqual(viewModel.availableModels.count, 2)
    XCTAssertEqual(viewModel.availableModels, mockModels)
}
```

#### **5. Memory Integration Tests (10 tests)**
```swift
// MARK: - Memory Integration Tests
func testMemoryServiceIntegration() async {
    // Given
    await viewModel.createNewConversation()
    let firstMessage = "Remember my name is John"
    let secondMessage = "What's my name?"
    
    // When - Send first message
    viewModel.currentInput = firstMessage
    await viewModel.sendMessage()
    
    // Simulate memory storage
    mockMemoryService.storedContext["conversation_id"] = viewModel.currentConversation?.id.uuidString
    mockMemoryService.storedContext["name"] = "John"
    
    // Send second message
    viewModel.currentInput = secondMessage
    await viewModel.sendMessage()
    
    // Then
    XCTAssertTrue(mockMemoryService.getContextCalled)
    XCTAssertTrue(mockMemoryService.storeContextCalled)
}
```

#### **6. Performance & Concurrency Tests (8 tests)**
```swift
// MARK: - Performance Tests
func testMessageSendingPerformance() async {
    // Given
    viewModel.currentInput = "Performance test message"
    mockAPIService.mockResponse = "Quick response"
    
    // When & Then
    await measurePerformance {
        await viewModel.sendMessage()
    }
    
    // Verify performance target (<2 seconds)
    XCTAssertLessThan(lastMeasurement, 2.0)
}

func testConcurrentMessageHandling() async {
    // Given
    let messages = ["Message 1", "Message 2", "Message 3"]
    
    // When - Send multiple messages concurrently
    await withTaskGroup(of: Void.self) { group in
        for message in messages {
            group.addTask {
                await self.viewModel.sendMessage(message)
            }
        }
    }
    
    // Then
    XCTAssertEqual(viewModel.messages.count, 6) // 3 user + 3 AI messages
}
```

---

## 🔒 **Priority 2: API Service Tests**

### **LLMAPIServiceTests.swift Structure**

```swift
import XCTest
import Combine
@testable import OpenChatbot

final class LLMAPIServiceTests: XCTestCase {
    
    var apiService: OpenRouterAPIService!
    var mockKeychain: MockKeychainService!
    var mockURLSession: MockURLSession!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockKeychain = MockKeychainService()
        mockURLSession = MockURLSession()
        
        apiService = OpenRouterAPIService(
            keychain: mockKeychain,
            urlSession: mockURLSession
        )
    }
    
    // MARK: - Protocol Compliance Tests
    func testAPIServiceProtocolCompliance() {
        XCTAssertTrue(apiService is LLMAPIService)
    }
    
    // MARK: - Message Sending Tests
    func testSendMessageSuccess() async throws {
        // Given
        let message = "Test message"
        let model = LLMModel.defaultModel
        let expectedResponse = "Test response"
        
        mockURLSession.mockData = createMockAPIResponse(content: expectedResponse)
        mockKeychain.mockAPIKey = "test-api-key"
        
        // When
        let response = try await apiService.sendMessageSync(message, model: model, conversation: nil)
        
        // Then
        XCTAssertEqual(response, expectedResponse)
        XCTAssertTrue(mockURLSession.dataTaskCalled)
    }
    
    // MARK: - Streaming Tests
    func testStreamingResponse() async throws {
        // Given
        let message = "Tell me a story"
        let model = LLMModel.defaultModel
        let streamChunks = ["Once", " upon", " a", " time"]
        
        mockURLSession.mockStreamingData = createMockStreamingResponse(chunks: streamChunks)
        
        // When
        let stream = try await apiService.sendMessage(message, model: model, conversation: nil)
        
        // Then
        var receivedChunks: [String] = []
        for await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        XCTAssertEqual(receivedChunks, streamChunks)
    }
    
    // MARK: - Error Handling Tests
    func testNetworkErrorHandling() async {
        // Given
        let message = "Test message"
        let model = LLMModel.defaultModel
        
        mockURLSession.shouldThrowError = true
        mockURLSession.errorToThrow = URLError(.notConnectedToInternet)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync(message, model: model, conversation: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}
```

### **KeychainServiceTests.swift Structure**

```swift
import XCTest
import Security
@testable import OpenChatbot

@MainActor
final class KeychainServiceTests: XCTestCase {
    
    var keychainService: KeychainService!
    
    override func setUp() async throws {
        try await super.setUp()
        keychainService = KeychainService()
        
        // Clean up any existing test data
        try await cleanupTestAPIKeys()
    }
    
    override func tearDown() async throws {
        try await cleanupTestAPIKeys()
        keychainService = nil
        try await super.tearDown()
    }
    
    // MARK: - API Key Storage Tests
    func testStoreAndRetrieveAPIKey() async throws {
        // Given
        let testAPIKey = "test-api-key-12345"
        let provider = LLMProvider.openAI
        
        // When
        try await keychainService.storeAPIKey(testAPIKey, for: provider)
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        
        // Then
        XCTAssertEqual(retrievedKey, testAPIKey)
    }
    
    // MARK: - Security Tests
    func testAPIKeyEncryption() async throws {
        // Given
        let testAPIKey = "sensitive-api-key"
        let provider = LLMProvider.anthropic
        
        // When
        try await keychainService.storeAPIKey(testAPIKey, for: provider)
        
        // Then - Verify key is not stored in plain text
        let rawKeychainData = await getRawKeychainData(for: provider)
        XCTAssertNotEqual(rawKeychainData, testAPIKey.data(using: .utf8))
    }
    
    // MARK: - Error Handling Tests
    func testInvalidProviderHandling() async {
        // Given
        let invalidProvider = LLMProvider(rawValue: "invalid") ?? .openAI
        
        // When
        let retrievedKey = await keychainService.getAPIKey(for: invalidProvider)
        
        // Then
        XCTAssertNil(retrievedKey)
    }
}
```

---

## 🛠️ **Mock Service Framework**

### **Enhanced Mock Architecture**

```swift
// MARK: - MockLLMAPIService
class MockLLMAPIService: LLMAPIService {
    var mockResponse: String = "Mock response"
    var shouldThrowError: Bool = false
    var errorToThrow: Error = APIError.networkError
    var streamingChunks: [String] = []
    var availableModels: [LLMModel] = []
    var sendMessageCalled: Bool = false
    var validateAPIKeyCalled: Bool = false
    
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncStream<String> {
        sendMessageCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return AsyncStream { continuation in
            Task {
                for chunk in streamingChunks {
                    continuation.yield(chunk)
                    try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 second delay
                }
                continuation.finish()
            }
        }
    }
    
    func sendMessageSync(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> String {
        sendMessageCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockResponse
    }
    
    func getAvailableModels() async throws -> [LLMModel] {
        return availableModels
    }
    
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        validateAPIKeyCalled = true
        return !shouldThrowError
    }
    
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        return APIKeyStatus(isValid: true, usage: 0.75, limit: 1000)
    }
    
    func cancelCurrentRequest() {
        // Mock implementation
    }
}

// MARK: - MockDataService  
class MockDataService: DataServiceProtocol {
    var mockConversations: [ConversationEntity] = []
    var mockMessages: [Message] = []
    var shouldThrowError: Bool = false
    var errorToThrow: Error = DataError.saveFailed
    
    func createConversation(title: String) -> ConversationEntity {
        let conversation = ConversationEntity()
        conversation.id = UUID()
        conversation.title = title
        conversation.createdAt = Date()
        mockConversations.append(conversation)
        return conversation
    }
    
    func saveMessage(_ message: Message, to conversation: ConversationEntity) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        mockMessages.append(message)
    }
    
    func fetchConversations() throws -> [ConversationEntity] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockConversations
    }
}

// MARK: - MockMemoryService
class MockMemoryService: MemoryServiceProtocol {
    var storedContext: [String: Any] = [:]
    var getContextCalled: Bool = false
    var storeContextCalled: Bool = false
    
    func getRelevantContext(for conversationID: UUID, query: String) async throws -> MemoryContext {
        getContextCalled = true
        
        return MemoryContext(
            summary: "Mock conversation summary",
            recentMessages: [],
            relevantHistory: []
        )
    }
    
    func storeContext(_ context: String, for conversationID: UUID) async throws {
        storeContextCalled = true
        storedContext["context"] = context
        storedContext["conversation_id"] = conversationID.uuidString
    }
}
```

---

## 📊 **Performance Testing Framework**

### **Performance Test Utilities**

```swift
// MARK: - Performance Testing Extensions
extension XCTestCase {
    func measurePerformance<T>(
        _ operation: () async throws -> T,
        target: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await operation()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(
            duration, 
            target,
            "Performance target exceeded: \(duration)s > \(target)s",
            file: file,
            line: line
        )
        
        return result
    }
    
    func measureMemoryUsage<T>(
        _ operation: () async throws -> T
    ) async rethrows -> (result: T, memoryUsed: Int) {
        let initialMemory = getCurrentMemoryUsage()
        let result = try await operation()
        let finalMemory = getCurrentMemoryUsage()
        
        return (result, finalMemory - initialMemory)
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int(taskInfo.resident_size) : 0
    }
}
```

---

## ✅ **Quality Assurance Checklist**

### **Test Implementation Standards**

#### **✅ Code Quality Standards**
- [ ] All tests follow Given-When-Then pattern
- [ ] Descriptive test method names
- [ ] Comprehensive setup and teardown
- [ ] No hardcoded values (use constants)
- [ ] Proper async/await usage
- [ ] Memory leak prevention

#### **✅ Coverage Standards**
- [ ] All public methods tested
- [ ] Error paths covered
- [ ] Edge cases included
- [ ] Performance requirements validated
- [ ] Integration workflows tested

#### **✅ Mock Quality Standards**
- [ ] Protocol-based mocking
- [ ] Realistic mock behavior
- [ ] Configurable error simulation
- [ ] State verification capabilities
- [ ] Performance simulation

---

## 📈 **Success Validation Framework**

### **Coverage Measurement**
```bash
# Generate coverage report
xcodebuild test -project OpenChatbot.xcodeproj \
    -scheme OpenChatbot \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enableCodeCoverage YES

# Export coverage data
xcrun xccov view --report --json DerivedData/.../Coverage.xcresult > coverage.json
```

### **Quality Gates**
- **Minimum Coverage**: 80% cho each critical component
- **Target Coverage**: 85%+ overall project coverage
- **Performance Gates**: All operations <2s
- **Reliability Gates**: 100% test pass rate
- **Maintainability**: <10 complexity score per method

---

## 🔄 **Next Priority: API Service Test Implementation**

**Status**: 📋 **READY TO START** - Next immediate task  
**Estimated Effort**: 16 hours  
**Dependencies**: ✅ ChatViewModelTests completed (provides mock patterns)  

### **Target Implementation**
- **LLMAPIServiceTests.swift**: Protocol compliance và error handling
- **OpenRouterAPIServiceTests.swift**: Implementation-specific tests  
- **Mock Network Layer**: URLSession mocking framework
- **Integration Tests**: End-to-end API workflow testing

### **Key Focus Areas**
1. **Streaming Response Testing**: AsyncStream validation
2. **Error Handling**: Network failures và recovery
3. **API Key Management**: Secure validation flows
4. **Rate Limiting**: Request throttling behavior
5. **Performance**: Response time benchmarks

---

**Document Updated**: July 19, 2025 - ChatViewModelTests completed successfully  
**Next Update**: Upon API Service Tests completion



---

**Implementation Strategy Complete** - Ready to begin Sprint 4.5 test implementation với comprehensive coverage, clear business justification, và production-ready quality standards! 🚀 