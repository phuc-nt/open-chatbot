import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [Message]
    
    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }
    
    var lastMessage: String? {
        messages.last?.content
    }
    
    var messageCount: Int {
        messages.count
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation", let firstUserMessage = messages.first(where: { $0.role == .user }) {
            title = String(firstUserMessage.content.prefix(50))
        }
    }
} 