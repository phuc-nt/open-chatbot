import XCTest
@testable import OpenChatbot

class TokenWindowManagementTests: XCTestCase {
    
    var tokenService: TokenWindowManagementService!
    var memoryService: MemoryService!
    var compressionService: ContextCompressionService!
    var dataService: DataService!
    
    override func setUp() async throws {
        try await super.setUp()
        dataService = DataService()
        memoryService = MemoryService(dataService: dataService)
        compressionService = ContextCompressionService(memoryService: memoryService)
        tokenService = await TokenWindowManagementService(
            memoryService: memoryService,
            compressionService: compressionService
        )
    }
    
    override func tearDown() async throws {
        tokenService = nil
        memoryService = nil
        compressionService = nil
        dataService = nil
        try await super.tearDown()
    }
    
    // MARK: - Token Counting Tests
    
    func testTokenCountingForDifferentModels() async throws {
        // Test messages
        let messages = [
            Message(content: "Hello, how are you?", role: .user, conversationId: UUID()),
            Message(content: "I'm doing well, thank you! How can I help you today?", role: .assistant, conversationId: UUID()),
            Message(content: "Can you explain quantum computing?", role: .user, conversationId: UUID())
        ]
        
        // Test GPT model
        let gptModel = LLMModel(
            id: "gpt-4",
            name: "GPT-4",
            provider: .openai,
            contextLength: 8192,
            pricing: ModelPricing(inputTokens: 30, outputTokens: 60, imageInputs: nil),
            description: "GPT-4 model",
            capabilities: .advanced
        )
        
        let gptTokens = await tokenService.countTokens(for: messages, model: gptModel)
        XCTAssertTrue(gptTokens > 0, "GPT token count should be positive")
        
        // Test Claude model
        let claudeModel = LLMModel(
            id: "claude-3-sonnet",
            name: "Claude 3 Sonnet",
            provider: .anthropic,
            contextLength: 200000,
            pricing: ModelPricing(inputTokens: 3, outputTokens: 15, imageInputs: nil),
            description: "Claude model",
            capabilities: .advanced
        )
        
        let claudeTokens = await tokenService.countTokens(for: messages, model: claudeModel)
        XCTAssertTrue(claudeTokens > 0, "Claude token count should be positive")
        
        // Token counts should be different for different models
        XCTAssertNotEqual(gptTokens, claudeTokens, "Different models should have different token counts")
    }
    
    func testTokenWindowManagementWithinLimit() async throws {
        let conversationId = UUID()
        let model = LLMModel(
            id: "gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            provider: .openai,
            contextLength: 4096,
            pricing: ModelPricing(inputTokens: 0.5, outputTokens: 1.5, imageInputs: nil),
            description: "Fast GPT model",
            capabilities: .basic
        )
        
        // Add a few messages that should fit within limit
        for i in 1...5 {
            let message = Message(
                content: "This is message \(i)",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Manage token window
        let result = try await tokenService.manageTokenWindow(
            for: conversationId,
            model: model
        )
        
        XCTAssertFalse(result.optimized, "Should not need optimization when within limit")
        XCTAssertEqual(result.messagesRemoved, 0, "No messages should be removed")
        XCTAssertFalse(result.compressionApplied, "No compression should be applied")
    }
    
    func testTokenWindowManagementWithOverflow() async throws {
        let conversationId = UUID()
        let model = LLMModel(
            id: "gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            provider: .openai,
            contextLength: 4096,
            pricing: ModelPricing(inputTokens: 0.5, outputTokens: 1.5, imageInputs: nil),
            description: "Fast GPT model",
            capabilities: .basic
        )
        
        // Add many long messages to exceed token limit
        for i in 1...50 {
            let longContent = String(repeating: "This is a very long message with lots of content. ", count: 20)
            let message = Message(
                content: "\(i). \(longContent)",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Manage token window
        let result = try await tokenService.manageTokenWindow(
            for: conversationId,
            model: model,
            reserveTokens: 1000
        )
        
        XCTAssertTrue(result.optimized, "Should be optimized when over limit")
        XCTAssertTrue(result.messagesRemoved > 0 || result.compressionApplied, "Should remove messages or apply compression")
        XCTAssertLessThan(result.finalTokens, model.contextLength - 1000, "Final tokens should be within limit")
        XCTAssertGreaterThan(result.tokensSaved, 0, "Should save some tokens")
    }
    
    func testTokenUsageStatistics() async throws {
        let conversationId = UUID()
        let model = LLMModel.defaultModel
        
        // Add some messages
        for i in 1...10 {
            let message = Message(
                content: "Message \(i) with some content for testing",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Get token statistics
        let stats = await tokenService.getTokenStats(for: conversationId, model: model)
        
        XCTAssertEqual(stats.conversationId, conversationId)
        XCTAssertEqual(stats.modelId, model.id)
        XCTAssertGreaterThan(stats.currentTokens, 0)
        XCTAssertEqual(stats.maxTokens, model.contextLength)
        XCTAssertEqual(stats.messageCount, 10)
        XCTAssertGreaterThan(stats.averageTokensPerMessage, 0)
        XCTAssertLessThan(stats.usagePercentage, 100)
    }
    
    func testTokenWarningLevels() async throws {
        let conversationId = UUID()
        let model = LLMModel(
            id: "test-model",
            name: "Test Model",
            provider: .openai,
            contextLength: 1000, // Small context for easier testing
            pricing: ModelPricing(inputTokens: 1, outputTokens: 2, imageInputs: nil),
            description: "Test model",
            capabilities: .basic
        )
        
        // Test normal usage (< 60%)
        for i in 1...5 {
            let message = Message(
                content: "Short message \(i)",
                role: .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        _ = try await tokenService.manageTokenWindow(for: conversationId, model: model)
        XCTAssertEqual(tokenService.tokenWarningLevel, .normal)
        
        // Add more messages to reach medium level (60-80%)
        for i in 6...15 {
            let message = Message(
                content: "Medium length message \(i) with more content",
                role: .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        _ = try await tokenService.manageTokenWindow(for: conversationId, model: model)
        XCTAssertTrue(
            tokenService.tokenWarningLevel == .medium || tokenService.tokenWarningLevel == .high,
            "Warning level should be elevated"
        )
    }
    
    func testTokenMonitoringReport() async throws {
        // Create multiple conversations
        let conversationIds = [UUID(), UUID(), UUID()]
        let model = LLMModel.defaultModel
        
        for (index, conversationId) in conversationIds.enumerated() {
            // Add different amounts of messages to each conversation
            for i in 1...(index + 1) * 5 {
                let message = Message(
                    content: "Conversation \(index + 1), Message \(i)",
                    role: i % 2 == 0 ? .assistant : .user,
                    conversationId: conversationId
                )
                await memoryService.addMessageToMemory(message, conversationId: conversationId)
            }
            
            // Trigger token counting to populate cache
            _ = try await tokenService.manageTokenWindow(for: conversationId, model: model)
        }
        
        // Get monitoring report
        let report = await tokenService.monitorTokenUsage(for: model)
        
        XCTAssertEqual(report.modelId, model.id)
        XCTAssertEqual(report.conversationStats.count, conversationIds.count)
        XCTAssertGreaterThan(report.totalTokens, 0)
        XCTAssertGreaterThan(report.totalMessages, 0)
        XCTAssertGreaterThan(report.averageTokensPerConversation, 0)
        
        // Verify summary format
        XCTAssertTrue(report.summary.contains("Token Monitoring Report"))
        XCTAssertTrue(report.summary.contains(model.id))
    }
    
    func testAggressiveTruncation() async throws {
        let conversationId = UUID()
        let model = LLMModel(
            id: "small-model",
            name: "Small Model",
            provider: .openai,
            contextLength: 500, // Very small for testing truncation
            pricing: ModelPricing(inputTokens: 1, outputTokens: 2, imageInputs: nil),
            description: "Small test model",
            capabilities: .basic
        )
        
        // Add many messages that will require truncation
        for i in 1...20 {
            let message = Message(
                content: "This is a relatively long message number \(i) that contains enough text to require truncation when we hit the token limit",
                role: i % 2 == 0 ? .assistant : .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Manage token window with aggressive truncation
        let result = try await tokenService.manageTokenWindow(
            for: conversationId,
            model: model,
            reserveTokens: 100
        )
        
        XCTAssertTrue(result.optimized, "Should be optimized")
        XCTAssertTrue(result.compressionApplied, "Compression should be applied")
        XCTAssertLessThanOrEqual(result.finalTokens, model.contextLength - 100, "Should be within token limit")
        
        // Verify recent messages are preserved
        let memory = await memoryService.getMemoryForConversation(conversationId)
        XCTAssertTrue(memory.messages.last?.content.contains("20") ?? false, "Most recent message should be preserved")
    }
    
    func testModelSpecificTokenCounting() async throws {
        let testMessage = Message(
            content: "This is a test message for token counting comparison",
            role: .user,
            conversationId: UUID()
        )
        
        // Test different model families
        let models = [
            ("gpt-4", "GPT"),
            ("claude-3-sonnet", "Claude"),
            ("llama-3-70b", "Llama"),
            ("unknown-model", "Unknown")
        ]
        
        var tokenCounts: [String: Int] = [:]
        
        for (modelId, family) in models {
            let model = LLMModel(
                id: modelId,
                name: family,
                provider: .openai,
                contextLength: 4096,
                pricing: ModelPricing(inputTokens: 1, outputTokens: 2, imageInputs: nil),
                description: "Test model",
                capabilities: .basic
            )
            
            let tokens = await tokenService.countTokens(for: [testMessage], model: model)
            tokenCounts[family] = tokens
            
            XCTAssertGreaterThan(tokens, 0, "\(family) should have positive token count")
        }
        
        // Verify different models may have different token counts
        print("Token counts by model family: \(tokenCounts)")
    }
    
    func testTokenUsageTracking() async throws {
        let conversationId = UUID()
        let model = LLMModel.defaultModel
        
        // Initially should have default values
        XCTAssertEqual(tokenService.currentTokenUsage.current, 0)
        
        // Add messages and manage window
        for i in 1...5 {
            let message = Message(
                content: "Test message \(i)",
                role: .user,
                conversationId: conversationId
            )
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        _ = try await tokenService.manageTokenWindow(for: conversationId, model: model)
        
        // Verify token usage is updated
        XCTAssertGreaterThan(tokenService.currentTokenUsage.current, 0)
        XCTAssertEqual(tokenService.currentTokenUsage.maximum, model.contextLength)
        XCTAssertGreaterThan(tokenService.currentTokenUsage.available, 0)
        XCTAssertFalse(tokenService.currentTokenUsage.isOverLimit)
    }
} 