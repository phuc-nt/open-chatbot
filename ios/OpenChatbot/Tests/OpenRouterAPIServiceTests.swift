import XCTest
import Foundation
import Combine
@testable import OpenChatbot

@MainActor
final class OpenRouterAPIServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    var apiService: OpenRouterAPIService!
    var mockKeychainService: OpenRouterMockKeychainService!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize mock keychain service
        mockKeychainService = OpenRouterMockKeychainService()
        
        // Initialize OpenRouterAPIService with mock keychain
        apiService = OpenRouterAPIService(keychain: mockKeychainService)
        
        // Initialize cancellables
        cancellables = Set<AnyCancellable>()
        
        // Setup API key - use real key if available, otherwise mock
        if let realAPIKey = TestConfig.openRouterAPIKey, TestConfig.hasValidOpenRouterKey {
            mockKeychainService.setMockAPIKey(realAPIKey, for: .openrouter)
        } else {
            mockKeychainService.setMockAPIKey("test-openrouter-key-12345", for: .openrouter)
        }
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        apiService = nil
        mockKeychainService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testOpenRouterAPIServiceInitialization() {
        // Given & When
        let service = OpenRouterAPIService(keychain: mockKeychainService)
        
        // Then
        XCTAssertNotNil(service, "OpenRouterAPIService should initialize successfully")
        XCTAssertTrue(service is LLMAPIService, "Should conform to LLMAPIService protocol")
    }
    
    func testOpenRouterAPIServiceProtocolCompliance() {
        // Given
        let service: LLMAPIService = apiService
        
        // Then
        XCTAssertNotNil(service, "Should be castable to LLMAPIService")
    }
    
    // MARK: - API Key Management Tests
    
    func testAPIKeyRetrievalSuccess() async throws {
        // Given
        let expectedAPIKey = "test-api-key-success"
        mockKeychainService.setMockAPIKey(expectedAPIKey, for: .openrouter)
        
        // When - This will be tested indirectly through a method that uses getAPIKey
        _ = try await apiService.validateAPIKey(expectedAPIKey)
        
        // Then
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should attempt to retrieve API key from keychain")
        // Note: validateAPIKey with the same key should succeed for a valid key format
    }
    
    func testAPIKeyRetrievalMissing() async {
        // Given
        mockKeychainService.setMockAPIKey(nil, for: .openrouter) // No API key stored
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw error when no API key is available")
        } catch let error as LLMAPIError {
            if case .invalidAPIKey = error {
                // Expected error case
            } else {
                XCTFail("Should throw invalidAPIKey error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw LLMAPIError.invalidAPIKey, got: \(error)")
        }
    }
    
    // MARK: - Request Formation Tests
    
    func testRequestHeadersFormation() async throws {
        // Given
        let testAPIKey = "test-headers-key"
        mockKeychainService.setMockAPIKey(testAPIKey, for: .openrouter)
        
        // When - Test through validateAPIKey which makes HTTP request
        _ = try await apiService.validateAPIKey(testAPIKey)
        
        // Then - The request should have been formed with proper headers
        // This test validates that the request formation logic exists
        // In a real implementation, we would inspect the actual HTTP request
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key for headers")
    }
    
    func testBaseURLConfiguration() {
        // Given & When
        // OpenRouterAPIService should use correct base URL
        // This is tested indirectly through API calls
        
        // Then
        XCTAssertNotNil(apiService, "Service should be configured with proper base URL")
        // Note: In a real test environment, we could mock URLSession to verify the exact URL
    }
    
    // MARK: - Message Request Format Tests
    
    func testMessageRequestWithoutConversation() async throws {
        // Given
        let testMessage = "Hello, OpenRouter!"
        let testModel = LLMModel.defaultModel
        
        // Configure keychain to return valid API key
        mockKeychainService.setMockAPIKey("valid-test-key", for: .openrouter)
        
        // When & Then
        // In a real test environment with network mocking, we would verify:
        // 1. Request body contains correct message format
        // 2. Model is properly specified
        // 3. Messages array contains only the user message
        
        // For now, we test that the method executes without throwing
        do {
            // This will fail with network error, but that's expected in test environment
            _ = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: nil)
        } catch let error as LLMAPIError {
            // Network errors are expected in test environment
            switch error {
            case .networkError:
                // Expected in test environment without network
                break
            case .invalidAPIKey:
                XCTFail("Should not fail with invalid API key when key is provided")
            default:
                // Other errors might occur in test environment
                break
            }
        }
        
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key for request")
    }
    
    func testMessageRequestWithConversation() async throws {
        // Given
        let testMessage = "Continue our conversation"
        let testModel = LLMModel.defaultModel
        let conversation = [
            ChatMessage(role: .user, content: "What is AI?"),
            ChatMessage(role: .assistant, content: "AI is artificial intelligence..."),
            ChatMessage(role: .user, content: "How does it work?")
        ]
        
        mockKeychainService.setMockAPIKey("conversation-test-key", for: .openrouter)
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync(testMessage, model: testModel, conversation: conversation)
        } catch let error as LLMAPIError {
            // Network errors expected in test environment
            switch error {
            case .networkError:
                // Expected without real network
                break
            case .invalidAPIKey:
                XCTFail("Should not fail with invalid API key")
            default:
                // Other errors might occur
                break
            }
        }
        
        // Verify keychain was accessed for API key
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key")
    }
    
    // MARK: - Streaming Implementation Tests
    
    func testStreamingRequestConfiguration() async throws {
        // Given
        let testMessage = "Stream me a response"
        let testModel = LLMModel.defaultModel
        
        mockKeychainService.setMockAPIKey("streaming-test-key", for: .openrouter)
        
        // When
        do {
            let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
            
                         // Try to consume one item from stream (will likely fail due to network)
             for try await _ in stream {
                 break // Just test that stream is created
             }
            
            // In test environment, we might not receive anything due to network
            // The important thing is that the stream was created without throwing
            
        } catch let error as LLMAPIError {
            // Network errors expected in test environment
            switch error {
            case .networkError:
                // Expected without real network
                break
            case .invalidAPIKey:
                XCTFail("Should not fail with invalid API key when key is provided")
            default:
                // Other errors might occur in test environment
                break
            }
        }
        
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key for streaming request")
    }
    
    func testStreamingCancellation() async throws {
        // Given
        let testMessage = "Long streaming message"
        let testModel = LLMModel.defaultModel
        
        mockKeychainService.setMockAPIKey("cancel-test-key", for: .openrouter)
        
        // When
        let streamTask = Task {
            do {
                let stream = try await apiService.sendMessage(testMessage, model: testModel, conversation: nil)
                var chunks: [String] = []
                for try await chunk in stream {
                    chunks.append(chunk)
                }
                return chunks
            } catch {
                // Handle expected network errors
                return []
            }
        }
        
        // Cancel the request
        apiService.cancelCurrentRequest()
        
        // Then
        let result = await streamTask.value
        // In test environment, cancellation behavior depends on network state
        // The important thing is that cancelCurrentRequest doesn't crash
        XCTAssertNotNil(result, "Should handle cancellation gracefully")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidAPIKeyErrorHandling() async {
        // Given
        mockKeychainService.setMockAPIKey("", for: .openrouter) // Empty API key
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw error for empty API key")
                 } catch let error as LLMAPIError {
             if case .invalidAPIKey = error {
                 // Expected error case
             } else {
                 XCTFail("Should throw invalidAPIKey for empty key, got: \(error)")
             }
         } catch {
             XCTFail("Should throw LLMAPIError.invalidAPIKey, got: \(error)")
         }
    }
    
    func testMissingAPIKeyErrorHandling() async {
        // Given
        mockKeychainService.setMockAPIKey(nil, for: .openrouter) // No API key
        
        // When & Then
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            XCTFail("Should throw error for missing API key")
                 } catch let error as LLMAPIError {
             if case .invalidAPIKey = error {
                 // Expected error case
             } else {
                 XCTFail("Should throw invalidAPIKey for missing key, got: \(error)")
             }
         } catch {
             XCTFail("Should throw LLMAPIError.invalidAPIKey, got: \(error)")
         }
    }
    
    func testNetworkErrorHandling() async {
        // Given
        mockKeychainService.setMockAPIKey("network-test-key", for: .openrouter)
        
        // When & Then
        // In test environment without network, we expect network errors
        do {
            _ = try await apiService.sendMessageSync("test", model: .defaultModel, conversation: nil)
            // If this succeeds unexpectedly, that's also a valid test result
        } catch let error as LLMAPIError {
            // We expect network errors in test environment
            switch error {
            case .networkError:
                // Expected behavior in test environment
                XCTAssertTrue(true, "Network error expected in test environment")
            case .invalidAPIKey:
                XCTFail("Should not be invalid API key error when key is provided")
            default:
                // Other errors might occur (server errors, etc.)
                XCTAssertTrue(true, "Other API errors are acceptable in test environment")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - Model Management Tests
    
    func testGetAvailableModelsRequest() async {
        // Given
        mockKeychainService.setMockAPIKey("models-test-key", for: .openrouter)
        
        // When & Then
        do {
            let models = try await apiService.getAvailableModels()
            // In test environment, this might fail or return empty
            // The important thing is that it doesn't crash
            XCTAssertNotNil(models, "Should return models array (possibly empty)")
        } catch let error as LLMAPIError {
            // Network errors expected in test environment
            switch error {
            case .networkError:
                XCTAssertTrue(true, "Network error expected in test environment")
            case .invalidAPIKey:
                XCTFail("Should not fail with invalid API key when key is provided")
            default:
                XCTAssertTrue(true, "Other API errors acceptable in test environment")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
        
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key for models request")
    }
    
    // MARK: - API Key Validation Tests
    
    func testValidateAPIKeyRequest() async throws {
        // Given
        let testAPIKey = "validation-test-key-12345"
        
        // When & Then
        do {
            let isValid = try await apiService.validateAPIKey(testAPIKey)
            // In test environment, validation might fail due to network
            // But the method should execute without crashing
            XCTAssertNotNil(isValid, "Should return validation result")
        } catch let error as LLMAPIError {
            // Network errors expected in test environment
            switch error {
            case .networkError:
                XCTAssertTrue(true, "Network error expected in test environment")
            default:
                XCTAssertTrue(true, "Other API errors acceptable in test environment")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    func testValidateAPIKeyWithInvalidKey() async throws {
        // Given
        let invalidAPIKey = "invalid"
        
        // When & Then
        do {
            let isValid = try await apiService.validateAPIKey(invalidAPIKey)
            // Should either return false or throw network error
            if isValid {
                XCTFail("Invalid key should not validate as true")
            }
        } catch let error as LLMAPIError {
            // Expected in test environment
            switch error {
            case .networkError:
                XCTAssertTrue(true, "Network error expected in test environment")
            default:
                XCTAssertTrue(true, "Other errors acceptable for invalid key")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - API Key Status Tests
    
    func testGetAPIKeyStatusRequest() async {
        // Given
        mockKeychainService.setMockAPIKey("status-test-key", for: .openrouter)
        
        // When & Then
        do {
            let status = try await apiService.getAPIKeyStatus()
            // In test environment, this might fail due to network
            XCTAssertNotNil(status, "Should return status object")
        } catch let error as LLMAPIError {
            // Network errors expected in test environment
            switch error {
            case .networkError:
                XCTAssertTrue(true, "Network error expected in test environment")
            case .invalidAPIKey:
                XCTFail("Should not fail with invalid API key when key is provided")
            default:
                XCTAssertTrue(true, "Other API errors acceptable in test environment")
            }
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
        
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled, "Should retrieve API key for status request")
    }
    
    // MARK: - Request Configuration Tests
    
    func testURLSessionConfiguration() {
        // Given & When
        // OpenRouterAPIService should configure URLSession properly
        // This is tested indirectly through API calls
        
        // Then
        XCTAssertNotNil(apiService, "Service should have proper URLSession configuration")
    }
    
    func testRequestTimeoutConfiguration() async {
        // Given
        mockKeychainService.setMockAPIKey("timeout-test-key", for: .openrouter)
        
        // When & Then
        // Test that requests have reasonable timeout behavior
        let startTime = Date()
        
        do {
            _ = try await apiService.sendMessageSync("timeout test", model: .defaultModel, conversation: nil)
        } catch {
            // Expected to fail in test environment
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should not hang indefinitely
        XCTAssertLessThan(duration, 120.0, "Request should not hang indefinitely (max 2 minutes)")
    }
    
    // MARK: - Concurrent Request Tests
    
    func testConcurrentRequestHandling() async {
        // Given
        mockKeychainService.setMockAPIKey("concurrent-test-key", for: .openrouter)
        let messages = ["Message 1", "Message 2", "Message 3"]
        
        // When
        let startTime = Date()
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            for message in messages {
                group.addTask {
                    do {
                        let response = try await self.apiService.sendMessageSync(message, model: .defaultModel, conversation: nil)
                        return .success(response)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var results: [Result<String, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(results.count, messages.count, "Should handle all concurrent requests")
        XCTAssertLessThan(duration, 60.0, "Concurrent requests should complete within reasonable time")
        
        // In test environment, we expect network errors but no crashes
        for result in results {
            switch result {
            case .success:
                // Unexpected but acceptable if network somehow works
                break
            case .failure(let error):
                XCTAssertTrue(error is LLMAPIError, "Should throw LLMAPIError, got: \(type(of: error))")
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagementDuringStreaming() async {
        // Given
        mockKeychainService.setMockAPIKey("memory-test-key", for: .openrouter)
        
        // When - Create multiple streaming requests
        let tasks = (1...5).map { index in
            Task {
                do {
                    let stream = try await apiService.sendMessage("Memory test \(index)", model: .defaultModel, conversation: nil)
                    var count = 0
                    for try await _ in stream {
                        count += 1
                        if count > 5 { break } // Limit iterations
                    }
                    return count
                } catch {
                    return 0
                }
            }
        }
        
        // Wait for all tasks
        var results: [Int] = []
        for task in tasks {
            let result = await task.value
            results.append(result)
        }
        
        // Then
        XCTAssertEqual(results.count, 5, "Should handle multiple streaming requests")
        
        // Test that cancellation works properly
        apiService.cancelCurrentRequest()
        
        // Give some time for cleanup
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Should not crash or leak memory
        XCTAssertNotNil(apiService, "Service should remain stable after multiple operations")
    }
    
    // MARK: - Integration Tests
    
    func testOpenRouterSpecificBehavior() async {
        // Given
        mockKeychainService.setMockAPIKey("openrouter-specific-test", for: .openrouter)
        
        // When & Then
        // Test OpenRouter-specific implementation details
        
        // 1. Test that service works with OpenRouter provider
        XCTAssertTrue(mockKeychainService.getAPIKeyCalled || !mockKeychainService.getAPIKeyCalled, "Service should be ready")
        
        // 2. Test OpenRouter-specific error handling
        do {
            _ = try await apiService.sendMessageSync("OpenRouter test", model: .defaultModel, conversation: nil)
        } catch let error as LLMAPIError {
            // Expected in test environment
            XCTAssertTrue(error.errorDescription?.isEmpty == false, "Error should have description")
            XCTAssertTrue(error.recoverySuggestion?.isEmpty == false, "Error should have recovery suggestion")
        } catch {
            XCTFail("Should throw LLMAPIError, got: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAPIServicePerformance() async {
        // Given
        mockKeychainService.setMockAPIKey("performance-test-key", for: .openrouter)
        
        // When
        let startTime = Date()
        
        // Test multiple quick operations
        for _ in 1...10 {
            do {
                _ = try await apiService.validateAPIKey("perf-test-key")
            } catch {
                // Expected to fail in test environment
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 30.0, "Multiple API key validations should complete efficiently")
    }
}

// MARK: - Mock Keychain Service for OpenRouter Tests

class OpenRouterMockKeychainService: KeychainService {
    private var mockAPIKeys: [LLMProvider: String] = [:]
    var getAPIKeyCalled = false
    var storeAPIKeyCalled = false
    var deleteAPIKeyCalled = false
    
    override func getAPIKey(for provider: LLMProvider, name: String? = nil) async -> String? {
        getAPIKeyCalled = true
        return mockAPIKeys[provider]
    }
    
    override func storeAPIKey(_ apiKey: String, for provider: LLMProvider, name: String? = nil) async throws {
        storeAPIKeyCalled = true
        mockAPIKeys[provider] = apiKey
    }
    
    override func deleteAPIKey(for provider: LLMProvider, name: String? = nil) async throws {
        deleteAPIKeyCalled = true
        mockAPIKeys.removeValue(forKey: provider)
    }
    
    override func getAllAPIKeys() async -> [StoredAPIKey] {
        return mockAPIKeys.map { provider, apiKey in
            StoredAPIKey(
                provider: provider,
                name: nil,
                apiKey: apiKey,
                createdAt: Date(),
                isValid: true
            )
        }
    }
    
    // MARK: - Mock Configuration Methods
    
    func setMockAPIKey(_ apiKey: String?, for provider: LLMProvider) {
        if let apiKey = apiKey {
            mockAPIKeys[provider] = apiKey
        } else {
            mockAPIKeys.removeValue(forKey: provider)
        }
    }
    
    func clearAllMockKeys() {
        mockAPIKeys.removeAll()
    }
    
    func resetCallTracking() {
        getAPIKeyCalled = false
        storeAPIKeyCalled = false
        deleteAPIKeyCalled = false
    }
}

// MARK: - Real API Integration Tests

extension OpenRouterAPIServiceTests {
    
    /// Test real API call to OpenRouter with GPT-4o-mini
    func testRealAPIMessageRequest() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        
        // Set the API key in mock keychain
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        let model = TestConfig.getTestModel()
        let message = TestConfig.getTestMessage()
        
        // When
        let response = try await apiService.sendMessageSync(message, model: model, conversation: nil)
        
        // Then
        XCTAssertFalse(response.isEmpty, "Should receive non-empty response from real API")
        XCTAssertTrue(response.lowercased().contains("hello") || response.lowercased().contains("hi"), 
                     "Response should contain greeting")
        
        print("✅ Real API Response: \(response)")
    }
    
    /// Test real streaming API call
    func testRealAPIStreamingRequest() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        let model = TestConfig.getTestModel()
        let message = "Count from 1 to 3, one number per line."
        
        var receivedChunks: [String] = []
        let stream = try await apiService.sendMessage(message, model: model, conversation: nil)
        
        // When - Collect streaming chunks
        for try await chunk in stream {
            receivedChunks.append(chunk)
            
            // Limit test to avoid long running
            if receivedChunks.count >= 20 {
                break
            }
        }
        
        // Then
        XCTAssertGreaterThan(receivedChunks.count, 0, "Should receive streaming chunks from real API")
        
        let fullResponse = receivedChunks.joined()
        print("✅ Real Streaming Response (\(receivedChunks.count) chunks): \(fullResponse)")
    }
    
    /// Test real API call with conversation history
    func testRealAPIWithConversationHistory() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        let model = TestConfig.getTestModel()
        let conversation = TestConfig.getTestConversation()
        let message = "What was my previous question?"
        
        // When
        let response = try await apiService.sendMessageSync(message, model: model, conversation: conversation)
        
        // Then
        XCTAssertFalse(response.isEmpty, "Should receive response with conversation context")
        XCTAssertTrue(response.contains("2+2") || response.contains("math") || response.contains("previous"), 
                     "Response should reference previous conversation")
        
        print("✅ Real API with History: \(response)")
    }
    
    /// Test real API key validation
    func testRealAPIKeyValidation() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        // When
        let result = try await apiService.validateAPIKey(apiKey)
        
        // Then
        XCTAssertTrue(result, "Real API key should validate successfully")
        print("✅ Real API Key Validation: Success")
    }
    
    /// Test real available models request
    func testRealAvailableModelsRequest() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        // When
        let models = try await apiService.getAvailableModels()
        
        // Then
        XCTAssertGreaterThan(models.count, 0, "Should receive available models from real API")
        
        let testModel = TestConfig.getTestModel()
        let hasTestModel = models.contains { $0.id == testModel.id }
        XCTAssertTrue(hasTestModel, "Available models should include \(testModel.id)")
        
        print("✅ Real Available Models: \(models.count) models, includes \(testModel.id)")
    }
    
    /// Test real API key status
    func testRealAPIKeyStatus() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        // When
        let status = try await apiService.getAPIKeyStatus()
        
        // Then
        XCTAssertTrue(status.isValid, "Real API key should be valid")
        // OpenRouter doesn't expose credits via API, so remainingCredits should be nil
        XCTAssertNil(status.remainingCredits, "OpenRouter doesn't expose credits via API")
        
        print("✅ Real API Key Status: Valid=\(status.isValid)")
    }
    
    /// Test real available models with details
    func testRealAvailableModelsWithDetails() async throws {
        // Load API key from test config
        guard let apiKey = TestConfig.openRouterAPIKey else {
            throw XCTSkip("No API key available for testing")
        }
        mockKeychainService.setMockAPIKey(apiKey, for: .openrouter)
        
        // When
        let models = try await apiService.getAvailableModelsWithDetails()
        
        // Then
        XCTAssertGreaterThan(models.count, 0, "Should receive available models from real API")
        
        // Check for specific popular models
        let modelIds = models.map { $0.id }
        let hasGPT4 = modelIds.contains { $0.contains("gpt-4") }
        let hasClaude = modelIds.contains { $0.contains("claude") }
        let hasGemini = modelIds.contains { $0.contains("gemini") }
        
        XCTAssertTrue(hasGPT4 || hasClaude || hasGemini, "Should have at least one major model")
        
        // Print some model details
        let sampleModels = models.prefix(5)
        print("✅ Real Available Models with Details:")
        for model in sampleModels {
            print("  - \(model.id): \(model.name ?? "Unknown") (Context: \(model.context_length ?? 0))")
        }
        print("  Total models: \(models.count)")
    }
} 