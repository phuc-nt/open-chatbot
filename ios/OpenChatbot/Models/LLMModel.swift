import Foundation

// MARK: - LLM Model Representation
struct LLMModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let provider: LLMProvider
    let contextLength: Int
    let pricing: ModelPricing
    let description: String?
    let capabilities: ModelCapabilities
    
    var displayName: String {
        return name.isEmpty ? id : name
    }
    
    var fullName: String {
        return "\(provider.displayName): \(displayName)"
    }
}

// MARK: - LLM Provider
enum LLMProvider: String, CaseIterable, Codable {
    case openrouter = "openrouter"
    case openai = "openai"
    case anthropic = "anthropic"
    case google = "google"
    case groq = "groq"
    case xai = "xai"
    
    var displayName: String {
        switch self {
        case .openrouter: return "OpenRouter"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google"
        case .groq: return "Groq"
        case .xai: return "xAI"
        }
    }
    
    var baseURL: String {
        switch self {
        case .openrouter: return "https://openrouter.ai/api/v1"
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .google: return "https://generativelanguage.googleapis.com/v1"
        case .groq: return "https://api.groq.com/openai/v1"
        case .xai: return "https://api.x.ai/v1"
        }
    }
    
    var supportsStreaming: Bool {
        switch self {
        case .openrouter, .openai, .anthropic, .groq, .xai: return true
        case .google: return false
        }
    }
}

// MARK: - Model Pricing
struct ModelPricing: Codable, Hashable {
    let inputTokens: Double  // Price per million tokens
    let outputTokens: Double // Price per million tokens
    let imageInputs: Double? // Price per thousand images
    
    var formattedInputPrice: String {
        return String(format: "$%.2f/M tokens", inputTokens)
    }
    
    var formattedOutputPrice: String {
        return String(format: "$%.2f/M tokens", outputTokens)
    }
}

// MARK: - Model Capabilities
struct ModelCapabilities: Codable, Hashable {
    let supportsImages: Bool
    let supportsDocuments: Bool
    let supportsWebSearch: Bool
    let supportsToolCalling: Bool
    let supportsStreaming: Bool
    
    static let basic = ModelCapabilities(
        supportsImages: false,
        supportsDocuments: false,
        supportsWebSearch: false,
        supportsToolCalling: false,
        supportsStreaming: true
    )
    
    static let advanced = ModelCapabilities(
        supportsImages: true,
        supportsDocuments: true,
        supportsWebSearch: false,
        supportsToolCalling: true,
        supportsStreaming: true
    )
}

// MARK: - Predefined Popular Models
extension LLMModel {
    static let popularModels: [LLMModel] = [
        // OpenRouter Popular Models
        LLMModel(
            id: "openai/gpt-4o",
            name: "GPT-4o",
            provider: .openrouter,
            contextLength: 128_000,
            pricing: ModelPricing(inputTokens: 2.50, outputTokens: 10.00, imageInputs: 3.613),
            description: "Most capable GPT-4 model with vision capabilities",
            capabilities: .advanced
        ),
        LLMModel(
            id: "anthropic/claude-3.7-sonnet",
            name: "Claude 3.7 Sonnet",
            provider: .openrouter,
            contextLength: 200_000,
            pricing: ModelPricing(inputTokens: 3.00, outputTokens: 15.00, imageInputs: 4.80),
            description: "Advanced reasoning and coding capabilities",
            capabilities: .advanced
        ),
        LLMModel(
            id: "openai/gpt-4o-mini",
            name: "GPT-4o Mini",
            provider: .openrouter,
            contextLength: 128_000,
            pricing: ModelPricing(inputTokens: 0.15, outputTokens: 0.60, imageInputs: 0.001),
            description: "Lightweight and affordable GPT-4 model",
            capabilities: .advanced
        ),
        LLMModel(
            id: "anthropic/claude-3-haiku",
            name: "Claude 3 Haiku",
            provider: .openrouter,
            contextLength: 200_000,
            pricing: ModelPricing(inputTokens: 0.25, outputTokens: 1.25, imageInputs: 0.40),
            description: "Fast and lightweight Claude model",
            capabilities: .basic
        ),
        LLMModel(
            id: "meta-llama/llama-3.1-70b-instruct",
            name: "Llama 3.1 70B",
            provider: .openrouter,
            contextLength: 131_072,
            pricing: ModelPricing(inputTokens: 0.59, outputTokens: 0.79, imageInputs: nil),
            description: "High-performance open-source model",
            capabilities: .basic
        )
    ]
    
    static let defaultModel = popularModels.first!
}

// MARK: - OpenRouter API Response Models
struct OpenRouterModelsResponse: Codable {
    let data: [OpenRouterModel]
}

struct OpenRouterModel: Codable {
    let id: String
    let name: String?
    let description: String?
    let context_length: Int?
    let pricing: OpenRouterPricing?
    let architecture: OpenRouterArchitecture?
    
    func toLLMModel() -> LLMModel {
        return LLMModel(
            id: id,
            name: name ?? id,
            provider: .openrouter,
            contextLength: context_length ?? 4096,
            pricing: ModelPricing(
                inputTokens: Double(pricing?.prompt ?? "0") ?? 0,
                outputTokens: Double(pricing?.completion ?? "0") ?? 0,
                imageInputs: pricing?.image.flatMap { Double($0) }
            ),
            description: description,
            capabilities: ModelCapabilities(
                supportsImages: architecture?.input_modalities?.contains("image") ?? false,
                supportsDocuments: false,
                supportsWebSearch: false,
                supportsToolCalling: false,
                supportsStreaming: true
            )
        )
    }
}

struct OpenRouterPricing: Codable {
    let prompt: String?
    let completion: String?
    let image: String?
}

struct OpenRouterArchitecture: Codable {
    let input_modalities: [String]?
    let output_modalities: [String]?
} 