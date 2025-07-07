import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    var content: String
    let role: MessageRole
    let timestamp: Date
    let conversationId: UUID
    
    init(content: String, role: MessageRole, conversationId: UUID) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
        self.conversationId = conversationId
    }
}

enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        }
    }
} 