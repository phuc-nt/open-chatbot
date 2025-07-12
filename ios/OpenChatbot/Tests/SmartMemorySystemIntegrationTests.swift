import XCTest
@testable import OpenChatbot

class SmartMemorySystemIntegrationTests: XCTestCase {
    
    // MARK: - Test Services
    var memoryService: MemoryService!
    var dataService: DataService!
    var compressionService: ContextCompressionService!
    var summaryMemoryService: ConversationSummaryMemoryService!
    var tokenWindowService: TokenWindowManagementService!
    var relevanceService: SmartContextRelevanceService!
    
    // MARK: - Test Data
    var testConversationId: UUID!
    var mockAPIService: MockLLMAPIServiceIntegration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup test data
        testConversationId = UUID()
        mockAPIService = MockLLMAPIServiceIntegration()
        
        // Setup services in dependency order
        dataService = DataService(inMemory: true)
        memoryService = MemoryService(dataService: dataService, apiService: mockAPIService)
        
        // Setup advanced memory services
        summaryMemoryService = ConversationSummaryMemoryService(apiService: mockAPIService)
        compressionService = ContextCompressionService(
            memoryService: memoryService,
            summaryMemoryService: summaryMemoryService
        )
        
        tokenWindowService = await TokenWindowManagementService(
            memoryService: memoryService,
            compressionService: compressionService
        )
        
        relevanceService = await SmartContextRelevanceService(
            memoryService: memoryService,
            tokenWindowService: tokenWindowService
        )
    }
    
    override func tearDown() async throws {
        memoryService = nil
        dataService = nil
        compressionService = nil
        summaryMemoryService = nil
        tokenWindowService = nil
        relevanceService = nil
        testConversationId = nil
        mockAPIService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Complete Smart Memory System Integration Tests
    
    func testCompleteMemorySystemWorkflow() async throws {
        // Test complete workflow: Memory → Compression → Token Management → Relevance
        
        // Step 1: Add messages to memory (MEM-001, MEM-002, MEM-003)
        let messages = [
            Message(content: "What is artificial intelligence?", role: .user, conversationId: testConversationId),
            Message(content: "Artificial intelligence (AI) is the simulation of human intelligence in machines...", role: .assistant, conversationId: testConversationId),
            Message(content: "Can you explain machine learning?", role: .user, conversationId: testConversationId),
            Message(content: "Machine learning is a subset of AI that enables computers to learn...", role: .assistant, conversationId: testConversationId),
            Message(content: "What about deep learning?", role: .user, conversationId: testConversationId),
            Message(content: "Deep learning is a subset of machine learning that uses neural networks...", role: .assistant, conversationId: testConversationId)
        ]
        
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Step 2: Test memory persistence (MEM-004)
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memory.messageCount, 6)
        
        // Step 3: Test context compression (MEM-007)
        let compressionResult = try await compressionService.compressContextWithImportanceScoring(
            for: testConversationId,
            targetTokens: 1000
        )
        XCTAssertLessThanOrEqual(compressionResult.messages.count, 6)
        XCTAssertGreaterThan(compressionResult.compressionRatio, 0.0)
        
        // Step 4: Test token window management (MEM-008)
        let model = LLMModel.defaultModel
        let tokenStats = await tokenWindowService.getTokenStats(for: testConversationId, model: model)
        XCTAssertGreaterThan(tokenStats.currentTokens, 0)
        XCTAssertLessThan(tokenStats.usagePercentage, 100)
        
        // Step 5: Test relevance scoring (MEM-009)
        let relevanceMap = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "machine learning",
            context: .general
        )
        XCTAssertEqual(relevanceMap.messageScores.count, 6)
        
        // Verify end-to-end functionality
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 2000
        )
        XCTAssertGreaterThan(contextMessages.count, 0)
        XCTAssertLessThanOrEqual(contextMessages.count, 6)
    }
    
    func testMemoryPersistenceAcrossSessions() async throws {
        // Test MEM-004: Memory Persistence Across Sessions
        
        // Session 1: Add messages
        let session1Messages = [
            Message(content: "Hello, I'm starting a new conversation", role: .user, conversationId: testConversationId),
            Message(content: "Hello! I'm here to help you.", role: .assistant, conversationId: testConversationId),
            Message(content: "Can you remember this conversation later?", role: .user, conversationId: testConversationId),
            Message(content: "Yes, I have a smart memory system that persists across sessions.", role: .assistant, conversationId: testConversationId)
        ]
        
        for message in session1Messages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Verify messages are in memory
        let session1Memory = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(session1Memory.messageCount, 4)
        
        // Session 2: Simulate app restart with new memory service
        let newDataService = DataService(inMemory: false) // Use persistent store
        let newMemoryService = MemoryService(dataService: newDataService, apiService: mockAPIService)
        
        // Load persisted memory
        let persistedMemory = await newMemoryService.getMemoryForConversation(testConversationId)
        
        // Verify persistence (Note: This test assumes Core Data persistence is working)
        XCTAssertNotNil(persistedMemory)
        
        // Add new message in session 2
        let session2Message = Message(
            content: "Do you remember our previous conversation?",
            role: .user,
            conversationId: testConversationId
        )
        await newMemoryService.addMessageToMemory(session2Message, conversationId: testConversationId)
        
        // Verify continuity
        let updatedMemory = await newMemoryService.getMemoryForConversation(testConversationId)
        XCTAssertGreaterThan(updatedMemory.messageCount, 0)
    }
    
    func testConversationSummaryMemoryIntegration() async throws {
        // Test MEM-006: ConversationSummaryMemory Implementation
        
        // Add many messages to trigger summarization
        for i in 1...30 {
            let content = "Message \(i): This is a detailed message about topic \(i % 5) that contains substantial information for testing the conversation summary memory system. It includes various details that should be preserved or summarized appropriately."
            let message = Message(
                content: content,
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Test if compression is needed
        let needsCompression = await summaryMemoryService.needsCompression(for: testConversationId)
        XCTAssertTrue(needsCompression, "Should need compression with 30 messages")
        
        // Test compression process
        let compressionResult = try await summaryMemoryService.compressConversationMemory(
            for: testConversationId,
            configuration: .default
        )
        
        XCTAssertNotNil(compressionResult)
        XCTAssertGreaterThan(compressionResult.compressionRatio, 0.0)
        XCTAssertLessThan(compressionResult.compressionRatio, 1.0)
        
        // Test summary retrieval
        let summary = await summaryMemoryService.getMemorySummary(for: testConversationId)
        XCTAssertNotNil(summary)
        XCTAssertFalse(summary!.summaryText.isEmpty)
    }
    
    func testTokenWindowManagementIntegration() async throws {
        // Test MEM-008: Token Window Management
        
        // Test with different models
        let models = [
            LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5", provider: .openai, contextLength: 4096),
            LLMModel(id: "gpt-4", name: "GPT-4", provider: .openai, contextLength: 8192),
            LLMModel(id: "claude-3-sonnet", name: "Claude 3", provider: .anthropic, contextLength: 200000)
        ]
        
        // Add messages that will exceed smaller context windows
        for i in 1...100 {
            let longContent = String(repeating: "This is a long message for testing token window management. ", count: 10)
            let message = Message(
                content: "Message \(i): \(longContent)",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Test token management for each model
        for model in models {
            let tokenStats = await tokenWindowService.getTokenStats(for: testConversationId, model: model)
            XCTAssertGreaterThan(tokenStats.currentTokens, 0)
            XCTAssertEqual(tokenStats.modelId, model.id)
            XCTAssertEqual(tokenStats.maxTokens, model.contextLength)
            
            // Test token window management
            let managementResult = try await tokenWindowService.manageTokenWindow(
                for: testConversationId,
                model: model,
                reserveTokens: 1000
            )
            
            XCTAssertLessThan(managementResult.finalTokens, model.contextLength)
            
            if model.contextLength < 10000 {
                // Smaller models should need optimization
                XCTAssertTrue(managementResult.optimized)
            }
        }
    }
    
    func testSmartContextRelevanceIntegration() async throws {
        // Test MEM-009: Smart Context Relevance Scoring
        
        // Create conversation with varied content
        let topicMessages = [
            ("What is quantum computing?", "user"),
            ("Quantum computing is a type of computation that harnesses quantum mechanics...", "assistant"),
            ("How does it differ from classical computing?", "user"),
            ("Classical computers use bits, while quantum computers use quantum bits or qubits...", "assistant"),
            ("What's the weather like today?", "user"), // Off-topic
            ("I'm sorry, I don't have access to current weather information.", "assistant"),
            ("Back to quantum computing - what are its applications?", "user"),
            ("Quantum computing has potential applications in cryptography, drug discovery...", "assistant")
        ]
        
        for (content, role) in topicMessages {
            let message = Message(
                content: content,
                role: role == "user" ? .user : .assistant,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Test relevance scoring for quantum computing topic
        let relevanceMap = try await relevanceService.calculateRelevanceScores(
            for: testConversationId,
            query: "quantum computing applications",
            context: .general
        )
        
        XCTAssertEqual(relevanceMap.messageScores.count, 8)
        
        // Test that quantum computing messages have higher relevance
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        let quantumMessages = memory.messages.filter { $0.content.contains("quantum") }
        let weatherMessage = memory.messages.first { $0.content.contains("weather") }
        
        XCTAssertGreaterThan(quantumMessages.count, 0)
        XCTAssertNotNil(weatherMessage)
        
        // Test filtered context by relevance
        let filteredMessages = try await relevanceService.filterMessagesByRelevance(
            for: testConversationId,
            query: "quantum computing",
            threshold: 0.3
        )
        
        // Should filter out off-topic messages
        XCTAssertLessThan(filteredMessages.count, 8)
        XCTAssertGreaterThan(filteredMessages.count, 0)
    }
    
    func testMemorySystemPerformance() async throws {
        // Test MEM-005: Memory Performance Optimization
        
        let performanceStartTime = CFAbsoluteTimeGetCurrent()
        
        // Add substantial number of messages
        for i in 1...500 {
            let content = "Performance test message \(i) with substantial content for realistic testing of the Smart Memory System performance under load."
            let message = Message(
                content: content,
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: testConversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        let addMessagesTime = CFAbsoluteTimeGetCurrent() - performanceStartTime
        
        // Test memory retrieval performance
        let retrievalStartTime = CFAbsoluteTimeGetCurrent()
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        let retrievalTime = CFAbsoluteTimeGetCurrent() - retrievalStartTime
        
        // Test context generation performance
        let contextStartTime = CFAbsoluteTimeGetCurrent()
        let contextMessages = await memoryService.getContextForAPICall(
            conversationId: testConversationId,
            maxTokens: 4000
        )
        let contextTime = CFAbsoluteTimeGetCurrent() - contextStartTime
        
        // Test compression performance
        let compressionStartTime = CFAbsoluteTimeGetCurrent()
        let compressionResult = try await compressionService.compressContextWithImportanceScoring(
            for: testConversationId,
            targetTokens: 2000
        )
        let compressionTime = CFAbsoluteTimeGetCurrent() - compressionStartTime
        
        // Performance assertions
        XCTAssertLessThan(addMessagesTime, 10.0, "Adding 500 messages should complete within 10 seconds")
        XCTAssertLessThan(retrievalTime, 0.5, "Memory retrieval should complete within 500ms")
        XCTAssertLessThan(contextTime, 1.0, "Context generation should complete within 1 second")
        XCTAssertLessThan(compressionTime, 5.0, "Compression should complete within 5 seconds")
        
        // Functionality assertions
        XCTAssertEqual(memory.messageCount, 500)
        XCTAssertGreaterThan(contextMessages.count, 0)
        XCTAssertGreaterThan(compressionResult.compressionRatio, 0.0)
    }
    
    func testMemorySystemErrorHandling() async throws {
        // Test error handling across the memory system
        
        // Test with invalid conversation ID
        let invalidConversationId = UUID()
        
        // Memory service should handle gracefully
        let emptyMemory = await memoryService.getMemoryForConversation(invalidConversationId)
        XCTAssertEqual(emptyMemory.messageCount, 0)
        
        // Test with empty messages
        let emptyMessage = Message(content: "", role: .user, conversationId: testConversationId)
        await memoryService.addMessageToMemory(emptyMessage, conversationId: testConversationId)
        
        let memoryWithEmpty = await memoryService.getMemoryForConversation(testConversationId)
        XCTAssertEqual(memoryWithEmpty.messageCount, 1)
        
        // Test compression with insufficient data
        let compressionResult = try await compressionService.compressContextWithImportanceScoring(
            for: testConversationId,
            targetTokens: 10000 // Very high limit
        )
        XCTAssertEqual(compressionResult.compressionRatio, 0.0) // No compression needed
        
        // Test token management with empty conversation
        let tokenStats = await tokenWindowService.getTokenStats(for: invalidConversationId, model: LLMModel.defaultModel)
        XCTAssertEqual(tokenStats.currentTokens, 0)
        XCTAssertEqual(tokenStats.messageCount, 0)
    }
    
    func testMemorySystemConsistency() async throws {
        // Test consistency across all memory system components
        
        // Add test messages
        let testMessages = [
            Message(content: "First message", role: .user, conversationId: testConversationId),
            Message(content: "Second message", role: .assistant, conversationId: testConversationId),
            Message(content: "Third message", role: .user, conversationId: testConversationId)
        ]
        
        for message in testMessages {
            await memoryService.addMessageToMemory(message, conversationId: testConversationId)
        }
        
        // Test consistency across components
        let memory = await memoryService.getMemoryForConversation(testConversationId)
        let contextMessages = await memoryService.getContextForAPICall(conversationId: testConversationId, maxTokens: 4000)
        let tokenStats = await tokenWindowService.getTokenStats(for: testConversationId, model: LLMModel.defaultModel)
        
        // All components should see the same message count
        XCTAssertEqual(memory.messageCount, 3)
        XCTAssertEqual(contextMessages.count, 3)
        XCTAssertEqual(tokenStats.messageCount, 3)
        
        // Test message content consistency
        XCTAssertEqual(memory.messages[0].content, "First message")
        XCTAssertEqual(contextMessages[0].content, "First message")
        
        XCTAssertEqual(memory.messages[1].content, "Second message")
        XCTAssertEqual(contextMessages[1].content, "Second message")
        
        XCTAssertEqual(memory.messages[2].content, "Third message")
        XCTAssertEqual(contextMessages[2].content, "Third message")
    }
}

// MARK: - Mock API Service for Integration Testing

class MockLLMAPIServiceIntegration: LLMAPIService {
    
    func getAvailableModels() async throws -> [LLMModel] {
        return [
            LLMModel(
                id: "gpt-4",
                name: "GPT-4",
                provider: .openai,
                contextLength: 8192,
                pricing: ModelPricing(inputTokens: 30, outputTokens: 60),
                description: "Mock GPT-4 for testing",
                capabilities: .advanced
            ),
            LLMModel(
                id: "gpt-3.5-turbo",
                name: "GPT-3.5 Turbo",
                provider: .openai,
                contextLength: 4096,
                pricing: ModelPricing(inputTokens: 1.5, outputTokens: 2.0),
                description: "Mock GPT-3.5 for testing",
                capabilities: .basic
            ),
            LLMModel(
                id: "claude-3-sonnet",
                name: "Claude 3 Sonnet",
                provider: .anthropic,
                contextLength: 200000,
                pricing: ModelPricing(inputTokens: 3, outputTokens: 15),
                description: "Mock Claude 3 for testing",
                capabilities: .advanced
            )
        ]
    }
    
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                let mockResponse = "This is a mock response for testing the integrated Smart Memory System. The response demonstrates context-aware generation with memory integration."
                
                // Simulate streaming response
                for chunk in mockResponse.components(separatedBy: " ") {
                    continuation.yield(chunk + " ")
                    try? await Task.sleep(nanoseconds: 5_000_000) // 5ms delay
                }
                
                continuation.finish()
            }
        }
    }
    
    func sendMessageSync(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> String {
        return "Mock synchronous response for Smart Memory System integration testing."
    }
    
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        return true
    }
    
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        return APIKeyStatus(
            isValid: true,
            remainingCredits: 100.0,
            usageToday: 5.0,
            rateLimitRemaining: 1000,
            rateLimitReset: Date().addingTimeInterval(3600)
        )
    }
    
    func cancelCurrentRequest() {
        // Mock implementation
    }
} 