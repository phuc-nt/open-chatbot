import Foundation
@testable import OpenChatbot

// MARK: - Test Configuration
struct TestConfig {
    
    // MARK: - API Keys for Testing
    static var openRouterAPIKey: String? {
        return loadAPIKey(from: "test_openrouter_api_key")
    }
    
    // MARK: - Private Methods
    private static func loadAPIKey(from filename: String) -> String? {
        // Try to load from test bundle first
        let testBundle = Bundle(for: TestConfigClass.self)
        if let path = testBundle.path(forResource: filename, ofType: "txt"),
           let apiKey = try? String(contentsOfFile: path, encoding: .utf8) {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback to main bundle
        if let path = Bundle.main.path(forResource: filename, ofType: "txt"),
           let apiKey = try? String(contentsOfFile: path, encoding: .utf8) {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    // MARK: - Validation
    static var hasValidOpenRouterKey: Bool {
        guard let key = openRouterAPIKey else { return false }
        return !key.isEmpty && key.hasPrefix("sk-or-v1-")
    }
    
    // MARK: - Test Helpers
    
    /// Get recommended test model
    static func getTestModel() -> LLMModel {
        return LLMModel(
            id: "openai/gpt-4o-mini",
            name: "GPT-4o Mini",
            provider: .openrouter,
            contextLength: 128000,
            pricing: ModelPricing(inputTokens: 0.15, outputTokens: 0.60, imageInputs: 0.001),
            description: "GPT-4o Mini test model",
            capabilities: ModelCapabilities(
                supportsImages: false,
                supportsDocuments: false,
                supportsWebSearch: false,
                supportsToolCalling: false,
                supportsStreaming: true
            )
        )
    }
    
    /// Get test message for API calls
    static func getTestMessage() -> String {
        return "Hello! Please respond with a brief greeting. This is a test message."
    }
    
    /// Get test conversation for history testing
    static func getTestConversation() -> [ChatMessage] {
        return [
            ChatMessage(role: .user, content: "What is 2+2?"),
            ChatMessage(role: .assistant, content: "2+2 equals 4.")
        ]
    }
}

// MARK: - Helper Class for Bundle Access
private class TestConfigClass {} 