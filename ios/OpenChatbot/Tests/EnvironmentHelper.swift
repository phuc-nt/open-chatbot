import Foundation
import XCTest
@testable import OpenChatbot

/// Helper class for Bundle access
private class EnvironmentHelperClass {}

/// Helper for loading environment variables from .env file for testing
struct EnvironmentHelper {
    
    /// Load environment variables from .env file in project root
    static func loadEnvironmentVariables() {
        // Try to find .env file in project root
        guard let projectRoot = findProjectRoot(),
              let envPath = findEnvFile(from: projectRoot) else {
            print("⚠️ .env file not found in project root")
            return
        }
        
        guard let envContent = try? String(contentsOfFile: envPath) else {
            print("⚠️ Cannot read .env file at: \(envPath)")
            return
        }
        
        let lines = envContent.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }
            
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
            
            setenv(key, value, 1)
        }
        
        print("✅ Loaded environment variables from: \(envPath)")
    }
    
    /// Get OpenRouter API key from environment
    static func getAPIKey() -> String? {
        return ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
    }
    
    /// Get OpenRouter base URL from environment (with default fallback)
    static func getBaseURL() -> String {
        return ProcessInfo.processInfo.environment["OPENROUTER_BASE_URL"] ?? "https://openrouter.ai/api/v1"
    }
    
    /// Check if real API key is available for integration tests
    static func hasRealAPIKey() -> Bool {
        guard let key = getAPIKey() else { return false }
        return !key.isEmpty && key.hasPrefix("sk-or-")
    }
    
    /// Skip test if no real API key available
    static func skipIfNoAPIKey() throws {
        guard hasRealAPIKey() else {
            throw XCTSkip("OpenRouter API key not found or invalid. Set OPENROUTER_API_KEY in .env file")
        }
    }
    
    // MARK: - Private Helpers
    
    private static func findProjectRoot() -> String? {
        var currentPath = FileManager.default.currentDirectoryPath
        
        // Start from test bundle path if available
        let testBundle = Bundle(for: EnvironmentHelperClass.self)
        currentPath = testBundle.bundlePath
        
        // Navigate up to find project root (contains .git or .env)
        var searchPath = currentPath
        for _ in 0..<10 { // Limit search depth
            let gitPath = (searchPath as NSString).appendingPathComponent(".git")
            let envPath = (searchPath as NSString).appendingPathComponent(".env")
            
            if FileManager.default.fileExists(atPath: gitPath) ||
               FileManager.default.fileExists(atPath: envPath) {
                return searchPath
            }
            
            let parentPath = (searchPath as NSString).deletingLastPathComponent
            if parentPath == searchPath { break } // Reached root
            searchPath = parentPath
        }
        
        return nil
    }
    
    private static func findEnvFile(from projectRoot: String) -> String? {
        let envPath = (projectRoot as NSString).appendingPathComponent(".env")
        
        if FileManager.default.fileExists(atPath: envPath) {
            return envPath
        }
        
        return nil
    }
}

// MARK: - Test Configuration

extension EnvironmentHelper {
    
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