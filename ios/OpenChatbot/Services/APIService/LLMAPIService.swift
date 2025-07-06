import Foundation
import Combine

// MARK: - LLM API Service Protocol
protocol LLMAPIService {
    /// Send a message to the specified model and receive streaming response
    /// - Parameters:
    ///   - message: The user message to send
    ///   - model: The LLM model to use
    ///   - conversation: Optional conversation history for context
    /// - Returns: AsyncStream of response chunks
    func sendMessage(
        _ message: String, 
        model: LLMModel,
        conversation: [ChatMessage]?
    ) async throws -> AsyncStream<String>
    
    /// Send a message and get complete response (non-streaming)
    /// - Parameters:
    ///   - message: The user message to send
    ///   - model: The LLM model to use
    ///   - conversation: Optional conversation history for context
    /// - Returns: Complete response text
    func sendMessageSync(
        _ message: String,
        model: LLMModel,
        conversation: [ChatMessage]?
    ) async throws -> String
    
    /// Get list of available models from the provider
    /// - Returns: Array of available LLM models
    func getAvailableModels() async throws -> [LLMModel]
    
    /// Validate API key by making a test request
    /// - Parameter apiKey: The API key to validate
    /// - Returns: True if valid, false otherwise
    func validateAPIKey(_ apiKey: String) async throws -> Bool
    
    /// Get current API key status and usage
    /// - Returns: API key status information
    func getAPIKeyStatus() async throws -> APIKeyStatus
    
    /// Cancel current streaming request
    func cancelCurrentRequest()
}

// MARK: - Chat Message for API Requests
struct ChatMessage: Codable {
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String, Codable, CaseIterable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .user: return "You"
            case .assistant: return "Assistant"
            }
        }
    }
    
    init(role: MessageRole, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - API Key Status
struct APIKeyStatus: Codable {
    let isValid: Bool
    let remainingCredits: Double?
    let usageToday: Double?
    let rateLimitRemaining: Int?
    let rateLimitReset: Date?
    
    var hasCredits: Bool {
        guard let credits = remainingCredits else { return true }
        return credits > 0
    }
    
    var formattedCredits: String {
        guard let credits = remainingCredits else { return "Unknown" }
        return String(format: "$%.2f", credits)
    }
}

// MARK: - API Errors
enum LLMAPIError: LocalizedError {
    case invalidAPIKey
    case invalidModel
    case networkError(Error)
    case rateLimitExceeded
    case insufficientCredits
    case contentFiltered
    case serverError(Int, String)
    case decodingError(Error)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your API key in Settings."
        case .invalidModel:
            return "The selected model is not available or supported."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .insufficientCredits:
            return "Insufficient credits. Please add more credits to your account."
        case .contentFiltered:
            return "Content was filtered by the provider's safety system."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Go to Settings and update your API key."
        case .invalidModel:
            return "Try selecting a different model."
        case .networkError:
            return "Check your internet connection and try again."
        case .rateLimitExceeded:
            return "Wait a few minutes before sending another message."
        case .insufficientCredits:
            return "Add credits to your OpenRouter account."
        case .contentFiltered:
            return "Try rephrasing your message."
        case .serverError:
            return "The service might be temporarily unavailable. Try again later."
        case .decodingError:
            return "This might be a temporary issue. Try again."
        case .unknownError:
            return "Try again or contact support if the issue persists."
        }
    }
}

// MARK: - API Request Configuration
struct APIRequestConfig {
    let temperature: Double
    let maxTokens: Int?
    let topP: Double?
    let topK: Int?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let stream: Bool
    
    static let defaultConfig = APIRequestConfig(
        temperature: 0.7,
        maxTokens: nil,
        topP: nil,
        topK: nil,
        frequencyPenalty: nil,
        presencePenalty: nil,
        stream: true
    )
    
    static let creativeConfig = APIRequestConfig(
        temperature: 0.9,
        maxTokens: nil,
        topP: 0.95,
        topK: nil,
        frequencyPenalty: 0.5,
        presencePenalty: 0.5,
        stream: true
    )
    
    static let preciseConfig = APIRequestConfig(
        temperature: 0.3,
        maxTokens: nil,
        topP: 0.9,
        topK: nil,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0,
        stream: true
    )
}

// MARK: - API Response Models
struct APIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [APIChoice]
    let usage: APIUsage?
}

struct APIChoice: Codable {
    let index: Int
    let message: APIMessage?
    let delta: APIMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case delta
        case finishReason = "finish_reason"
    }
}

struct APIMessage: Codable {
    let role: String?
    let content: String?
}

struct APIUsage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
    
    var estimatedCost: Double {
        // This would be calculated based on the model's pricing
        // For now, return a placeholder
        return 0.0
    }
} 