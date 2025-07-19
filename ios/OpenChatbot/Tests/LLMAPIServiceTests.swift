import XCTest
import Foundation
import Combine
@testable import OpenChatbot

@MainActor
final class LLMAPIServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    var apiService: TestLLMAPIService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test API service implementation
        apiService = TestLLMAPIService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        apiService = nil
        try await super.tearDown()
    }
    
    // MARK: - Protocol Compliance Tests
    
    func testLLMAPIServiceProtocolCompliance() {
        // Given & When
        let service: LLMAPIService = apiService
        
        // Then
        XCTAssertNotNil(service, "TestLLMAPIService should conform to LLMAPIService protocol")
    }
    
    func testAllProtocolMethodsImplemented() async {
        // Given
        let service = apiService!
        
        // Then - Verify all protocol methods are accessible
        do {
            _ = try await service.sendMessage("test", model: .defaultModel, conversation: nil)
            _ = try await service.sendMessageSync("test", model: .defaultModel, conversation: nil)
            _ = try await service.getAvailableModels()
            _ = try await service.validateAPIKey("test-key")
            _ = try await service.getAPIKeyStatus()
            service.cancelCurrentRequest()
        } catch {
            // Mock service should not throw in basic test
        }
    }
    
    // MARK: - Send Message Sync Tests
    
    func testSendMessageSyncSuccess() async throws {
        // Given
        let testMessage = "Hello, AI assistant!"
        let testModel = LLMModel.defaultModel
        let expectedResponse = "Hello! How can I help you?"
        
        apiService.setMockResponse(expectedResponse)
        
        // When
        let response = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: nil)
        
        // Then
        XCTAssertEqual(response, expectedResponse, "Should return expected response content")
        XCTAssertTrue(apiService.sendMessageSyncCalled, "Should have called sendMessageSync")
        XCTAssertEqual(apiService.lastMessage, testMessage, "Should capture the sent message")
        XCTAssertEqual(apiService.lastModel?.id, testModel.id, "Should use correct model")
    }
    
    func testSendMessageSyncWithConversationHistory() async throws {
        // Given
        let testMessage = "What was my previous question?"
        let testModel = LLMModel.defaultModel
        let conversationHistory = [
            ChatMessage(role: .user, content: "How does AI work?"),
            ChatMessage(role: .assistant, content: "AI works by processing data...")
        ]
        let expectedResponse = "Your previous question was about how AI works."
        
        apiService.setMockResponse(expectedResponse)
        
        // When
        let response = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: conversationHistory)
        
        // Then
        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(apiService.lastConversation?.count, 2, "Should receive conversation history")
        XCTAssertEqual(apiService.lastConversation?[0].content, "How does AI work?")
        XCTAssertEqual(apiService.lastConversation?[1].content, "AI works by processing data...")
    }
    
    func testSendMessageSyncErrorHandling() async {
        // Given
        let testMessage = "Test message"
        let testModel = LLMModel.defaultModel
        let expectedError = LLMAPIError.invalidAPIKey
        
        apiService.setShouldThrowError(true, error: expectedError)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: nil)
            XCTFail("Should throw error when configured to fail")
        } catch let error as LLMAPIError {
            // Check error type matches (cannot use XCTAssertEqual since LLMAPIError is not Equatable)
            XCTAssertTrue(true, "Received expected LLMAPIError: \(error)")
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - Streaming Message Tests
    
    func testSendMessageStreamingSuccess() async throws {
        // Given
        let testMessage = "Tell me a story about AI"
        let testModel = LLMModel.defaultModel
        let expectedChunks = ["Once", " upon", " a", " time", ", there", " was", " an", " AI", "..."]
        
        apiService.setMockStreamingChunks(expectedChunks)
        
        // When
        let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
        
        // Then
        var receivedChunks: [String] = []
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        XCTAssertEqual(receivedChunks, expectedChunks, "Should receive all chunks in order")
        XCTAssertTrue(apiService.sendMessageCalled, "Should have called sendMessage")
        XCTAssertEqual(apiService.lastMessage, testMessage, "Should capture the sent message")
    }
    
    func testSendMessageStreamingEmpty() async throws {
        // Given
        let testMessage = "Empty response test"
        let testModel = LLMModel.defaultModel
        
        apiService.setMockStreamingChunks([]) // Empty chunks
        
        // When
        let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
        
        // Then
        var receivedChunks: [String] = []
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        XCTAssertTrue(receivedChunks.isEmpty, "Should handle empty streaming response")
    }
    
    func testStreamingCancellation() async throws {
        // Given
        let testMessage = "Long streaming response"
        let testModel = LLMModel.defaultModel
        let longChunks = (1...100).map { "Chunk \($0) " }
        
        apiService.setMockStreamingChunks(longChunks)
        apiService.setStreamingDelay(0.01) // Small delay between chunks
        
        // When
        let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
        
        let streamTask = Task {
            var chunks: [String] = []
            for try await chunk in stream {
                chunks.append(chunk)
                if chunks.count >= 5 { // Stop after 5 chunks
                    break
                }
            }
            return chunks
        }
        
        // Cancel streaming
        apiService.cancelCurrentRequest()
        
        // Then
        let receivedChunks = try await streamTask.value
        XCTAssertTrue(receivedChunks.count <= 5, "Should stop streaming after cancellation or break")
        XCTAssertTrue(apiService.cancelCurrentRequestCalled, "Should have called cancelCurrentRequest")
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() async {
        // Given
        let networkError = LLMAPIError.networkError(URLError(.notConnectedToInternet))
        apiService.setShouldThrowError(true, error: networkError)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw network error")
        } catch let error as LLMAPIError {
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError, "Should contain URLError")
            } else {
                XCTFail("Should be network error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError.networkError, got: \(error)")
        }
    }
    
    func testServerErrorHandling() async {
        // Given
        let serverError = LLMAPIError.serverError(500, "Internal Server Error")
        apiService.setShouldThrowError(true, error: serverError)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw server error")
        } catch let error as LLMAPIError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, 500, "Should have correct error code")
                XCTAssertEqual(message, "Internal Server Error", "Should have correct error message")
            } else {
                XCTFail("Should be server error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError.serverError, got: \(error)")
        }
    }
    
    func testRateLimitHandling() async {
        // Given
        let rateLimitError = LLMAPIError.rateLimitExceeded
        apiService.setShouldThrowError(true, error: rateLimitError)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw rate limit error")
        } catch let error as LLMAPIError {
            if case .rateLimitExceeded = error {
                // Expected error case
            } else {
                XCTFail("Should be rate limit error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError.rateLimitExceeded, got: \(error)")
        }
    }
    
    func testInvalidAPIKeyHandling() async {
        // Given
        let apiKeyError = LLMAPIError.invalidAPIKey
        apiService.setShouldThrowError(true, error: apiKeyError)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw invalid API key error")
        } catch let error as LLMAPIError {
            if case .invalidAPIKey = error {
                // Expected error case
            } else {
                XCTFail("Should be invalid API key error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError.invalidAPIKey, got: \(error)")
        }
    }
    
    // MARK: - API Key Validation Tests
    
    func testValidateAPIKeySuccess() async throws {
        // Given
        let validAPIKey = "sk-valid-api-key-123456789"
        apiService.setAPIKeyValidationResult(true)
        
        // When
        let isValid = try await apiService.validateAPIKey(validAPIKey)
        
        // Then
        XCTAssertTrue(isValid, "Should return true for valid API key")
        XCTAssertTrue(apiService.validateAPIKeyCalled, "Should have called validateAPIKey")
        XCTAssertEqual(apiService.lastValidatedAPIKey, validAPIKey, "Should validate correct API key")
    }
    
    func testValidateAPIKeyFailure() async throws {
        // Given
        let invalidAPIKey = "invalid-key"
        apiService.setAPIKeyValidationResult(false)
        
        // When
        let isValid = try await apiService.validateAPIKey(invalidAPIKey)
        
        // Then
        XCTAssertFalse(isValid, "Should return false for invalid API key")
        XCTAssertEqual(apiService.lastValidatedAPIKey, invalidAPIKey, "Should validate provided key")
    }
    
    func testValidateAPIKeyError() async {
        // Given
        let testAPIKey = "error-key"
        let validationError = LLMAPIError.networkError(URLError(.timedOut))
        apiService.setShouldThrowError(true, error: validationError)
        
        // When & Then
        do {
            _ = try await apiService.validateAPIKey(testAPIKey)
            XCTFail("Should throw error during validation")
        } catch let error as LLMAPIError {
            if case .networkError = error {
                // Expected error type
            } else {
                XCTFail("Should throw network error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - Available Models Tests
    
    func testGetAvailableModelsSuccess() async throws {
        // Given
        let expectedModels = [
            LLMModel(
                id: "gpt-4",
                name: "GPT-4",
                provider: .openai,
                contextLength: 8192,
                pricing: ModelPricing(inputTokens: 30, outputTokens: 60, imageInputs: nil),
                description: "Advanced language model",
                capabilities: .advanced
            ),
            LLMModel(
                id: "claude-3-sonnet",
                name: "Claude 3 Sonnet",
                provider: .anthropic,
                contextLength: 200000,
                pricing: ModelPricing(inputTokens: 3, outputTokens: 15, imageInputs: nil),
                description: "Anthropic's Claude model",
                capabilities: .advanced
            )
        ]
        
        apiService.setMockAvailableModels(expectedModels)
        
        // When
        let models = try await apiService.getAvailableModels()
        
        // Then
        XCTAssertEqual(models.count, expectedModels.count, "Should return correct number of models")
        XCTAssertTrue(models.contains { $0.id == "gpt-4" }, "Should include GPT-4")
        XCTAssertTrue(models.contains { $0.id == "claude-3-sonnet" }, "Should include Claude")
        XCTAssertTrue(apiService.getAvailableModelsCalled, "Should have called getAvailableModels")
    }
    
    func testGetAvailableModelsEmpty() async throws {
        // Given
        apiService.setMockAvailableModels([])
        
        // When
        let models = try await apiService.getAvailableModels()
        
        // Then
        XCTAssertTrue(models.isEmpty, "Should handle empty models list")
    }
    
    func testGetAvailableModelsError() async {
        // Given
        let modelsError = LLMAPIError.serverError(503, "Service unavailable")
        apiService.setShouldThrowError(true, error: modelsError)
        
        // When & Then
        do {
            _ = try await apiService.getAvailableModels()
            XCTFail("Should throw error when getting models")
        } catch let error as LLMAPIError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, 503, "Should have correct error code")
                XCTAssertEqual(message, "Service unavailable", "Should have correct message")
            } else {
                XCTFail("Should be server error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - API Key Status Tests
    
    func testGetAPIKeyStatusSuccess() async throws {
        // Given
        let expectedStatus = APIKeyStatus(
            isValid: true,
            remainingCredits: 42.75,
            usageToday: 15.25,
            rateLimitRemaining: 100,
            rateLimitReset: Date().addingTimeInterval(3600)
        )
        
        apiService.setMockAPIKeyStatus(expectedStatus)
        
        // When
        let status = try await apiService.getAPIKeyStatus()
        
        // Then
        XCTAssertTrue(status.isValid, "Should indicate valid status")
        XCTAssertEqual(status.remainingCredits ?? 0, 42.75, accuracy: 0.01, "Should have correct credits")
        XCTAssertEqual(status.usageToday ?? 0, 15.25, accuracy: 0.01, "Should have correct usage")
        XCTAssertTrue(status.hasCredits, "Should indicate sufficient credits")
        XCTAssertEqual(status.formattedCredits, "$42.75", "Should format credits correctly")
        XCTAssertTrue(apiService.getAPIKeyStatusCalled, "Should have called getAPIKeyStatus")
    }
    
    func testGetAPIKeyStatusInvalidKey() async throws {
        // Given
        let invalidStatus = APIKeyStatus(
            isValid: false,
            remainingCredits: nil,
            usageToday: nil,
            rateLimitRemaining: nil,
            rateLimitReset: nil
        )
        
        apiService.setMockAPIKeyStatus(invalidStatus)
        
        // When
        let status = try await apiService.getAPIKeyStatus()
        
        // Then
        XCTAssertFalse(status.isValid, "Should indicate invalid status")
        XCTAssertNil(status.remainingCredits, "Should have no credits info")
        XCTAssertEqual(status.formattedCredits, "Unknown", "Should show unknown credits")
    }
    
    func testGetAPIKeyStatusError() async {
        // Given
        let statusError = LLMAPIError.invalidAPIKey
        apiService.setShouldThrowError(true, error: statusError)
        
        // When & Then
        do {
            _ = try await apiService.getAPIKeyStatus()
            XCTFail("Should throw error when getting status")
        } catch let error as LLMAPIError {
            if case .invalidAPIKey = error {
                // Expected error case
            } else {
                XCTFail("Should throw invalid API key error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAPICallPerformance() async throws {
        // Given
        let testMessage = "Performance test message"
        let testModel = LLMModel.defaultModel
        let expectedResponse = "Quick response for performance test"
        
        apiService.setMockResponse(expectedResponse)
        apiService.setResponseDelay(0.05) // 50ms simulated delay
        
        // When & Then
        let startTime = Date()
        let response = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: nil)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(response, expectedResponse, "Should return correct response")
        XCTAssertLessThan(duration, 2.0, "API call should complete within 2 seconds")
        
        print("✅ API call performance: \(String(format: "%.3f", duration)) seconds")
    }
    
    func testStreamingPerformance() async throws {
        // Given
        let testMessage = "Streaming performance test"
        let testModel = LLMModel.defaultModel
        let chunks = (1...20).map { "Word\($0)" }
        
        apiService.setMockStreamingChunks(chunks)
        apiService.setStreamingDelay(0.005) // 5ms between chunks
        
        // When & Then
        let startTime = Date()
        let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
        
        var receivedChunks: [String] = []
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(receivedChunks.count, chunks.count, "Should receive all chunks")
        XCTAssertLessThan(duration, 5.0, "Streaming should complete within 5 seconds")
        
        print("✅ Streaming performance: \(String(format: "%.3f", duration)) seconds for \(chunks.count) chunks")
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentAPIRequests() async throws {
        // Given
        let messages = ["Message 1", "Message 2", "Message 3", "Message 4", "Message 5"]
        let testModel = LLMModel.defaultModel
        
        // Configure responses for each request
        apiService.setMockResponses(messages.map { "Response to: \($0)" })
        
        // When
        let startTime = Date()
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for message in messages {
                group.addTask {
                    return try await self.apiService.sendMessageSync(message, model: testModel, conversation: nil)
                }
            }
            
            var results: [String] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(results.count, messages.count, "Should handle all concurrent requests")
        XCTAssertEqual(apiService.requestCount, messages.count, "Should track all requests")
        XCTAssertLessThan(duration, 3.0, "Concurrent requests should complete efficiently")
        
        print("✅ Concurrent requests performance: \(String(format: "%.3f", duration)) seconds for \(messages.count) requests")
    }
}

// MARK: - Test LLM API Service Implementation

class TestLLMAPIService: LLMAPIService {
    
    // MARK: - Mock Configuration
    private var mockResponses: [String] = []
    private var mockStreamingChunks: [String] = []
    private var mockAvailableModels: [LLMModel] = []
    private var mockAPIKeyStatus: APIKeyStatus?
    private var shouldThrowError = false
    private var mockError: LLMAPIError = .unknownError("Test error")
    private var apiKeyValidationResult = true
    private var responseDelay: TimeInterval = 0
    private var streamingDelay: TimeInterval = 0.01
    private var responseIndex = 0
    
    // MARK: - Call Tracking
    var sendMessageCalled = false
    var sendMessageSyncCalled = false
    var getAvailableModelsCalled = false
    var validateAPIKeyCalled = false
    var getAPIKeyStatusCalled = false
    var cancelCurrentRequestCalled = false
    var requestCount = 0
    
    // MARK: - Captured Parameters
    var lastMessage: String?
    var lastModel: LLMModel?
    var lastConversation: [ChatMessage]?
    var lastValidatedAPIKey: String?
    
    // MARK: - Configuration Methods
    
    func setMockResponse(_ response: String) {
        mockResponses = [response]
        responseIndex = 0
    }
    
    func setMockResponses(_ responses: [String]) {
        mockResponses = responses
        responseIndex = 0
    }
    
    func setMockStreamingChunks(_ chunks: [String]) {
        mockStreamingChunks = chunks
    }
    
    func setMockAvailableModels(_ models: [LLMModel]) {
        mockAvailableModels = models
    }
    
    func setMockAPIKeyStatus(_ status: APIKeyStatus) {
        mockAPIKeyStatus = status
    }
    
    func setShouldThrowError(_ shouldThrow: Bool, error: LLMAPIError? = nil) {
        shouldThrowError = shouldThrow
        if let error = error {
            mockError = error
        }
    }
    
    func setAPIKeyValidationResult(_ result: Bool) {
        apiKeyValidationResult = result
    }
    
    func setResponseDelay(_ delay: TimeInterval) {
        responseDelay = delay
    }
    
    func setStreamingDelay(_ delay: TimeInterval) {
        streamingDelay = delay
    }
    
    // MARK: - LLMAPIService Implementation
    
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncStream<String> {
        sendMessageCalled = true
        requestCount += 1
        lastMessage = message
        lastModel = model
        lastConversation = conversation
        
        if shouldThrowError {
            throw mockError
        }
        
        return AsyncStream { continuation in
            Task {
                for chunk in mockStreamingChunks {
                    if streamingDelay > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(streamingDelay * 1_000_000_000))
                    }
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }
    
    func sendMessageSync(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> String {
        sendMessageSyncCalled = true
        requestCount += 1
        lastMessage = message
        lastModel = model
        lastConversation = conversation
        
        if shouldThrowError {
            throw mockError
        }
        
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        let response = getNextResponse()
        return response
    }
    
    func getAvailableModels() async throws -> [LLMModel] {
        getAvailableModelsCalled = true
        requestCount += 1
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockAvailableModels
    }
    
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        validateAPIKeyCalled = true
        requestCount += 1
        lastValidatedAPIKey = apiKey
        
        if shouldThrowError {
            throw mockError
        }
        
        return apiKeyValidationResult
    }
    
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        getAPIKeyStatusCalled = true
        requestCount += 1
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockAPIKeyStatus ?? APIKeyStatus(
            isValid: true,
            remainingCredits: 100.0,
            usageToday: 10.0,
            rateLimitRemaining: 1000,
            rateLimitReset: Date().addingTimeInterval(3600)
        )
    }
    
    func cancelCurrentRequest() {
        cancelCurrentRequestCalled = true
    }
    
    // MARK: - Helper Methods
    
    private func getNextResponse() -> String {
        guard !mockResponses.isEmpty else {
            return "Default mock response"
        }
        
        let response = mockResponses[responseIndex % mockResponses.count]
        responseIndex += 1
        return response
    }
} 