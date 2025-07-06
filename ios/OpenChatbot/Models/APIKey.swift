import Foundation

struct APIKey: Identifiable, Codable {
    let id: UUID
    let name: String
    let provider: APIProvider
    let createdAt: Date
    
    init(name: String, provider: APIProvider) {
        self.id = UUID()
        self.name = name
        self.provider = provider
        self.createdAt = Date()
    }
}

enum APIProvider: String, Codable, CaseIterable {
    case openRouter = "openrouter"
    case openAI = "openai"
    case claude = "claude"
    case gemini = "gemini"
    
    var displayName: String {
        switch self {
        case .openRouter: return "OpenRouter"
        case .openAI: return "OpenAI"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        }
    }
    
    var baseURL: String {
        switch self {
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .openAI: return "https://api.openai.com/v1"
        case .claude: return "https://api.anthropic.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1"
        }
    }
} 