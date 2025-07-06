import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var currentConversation: Conversation?
    
    init() {
        // Load mock data for testing
        loadMockData()
    }
    
    func sendMessage(_ content: String) {
        guard let conversationId = currentConversation?.id else {
            // Create new conversation if none exists
            currentConversation = Conversation()
            return sendMessage(content)
        }
        
        let userMessage = Message(content: content, role: .user, conversationId: conversationId)
        messages.append(userMessage)
        
        // Simulate API call
        isLoading = true
        
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            let assistantMessage = Message(
                content: "This is a mock response to: \(content)",
                role: .assistant,
                conversationId: conversationId
            )
            
            messages.append(assistantMessage)
            isLoading = false
        }
    }
    
    private func loadMockData() {
        let conversation = Conversation(title: "Test Conversation")
        currentConversation = conversation
        
        messages = [
            Message(content: "Hello! How can I help you today?", role: .assistant, conversationId: conversation.id),
            Message(content: "I need help with iOS development", role: .user, conversationId: conversation.id),
            Message(content: "I'd be happy to help you with iOS development! What specific topic would you like to learn about?", role: .assistant, conversationId: conversation.id)
        ]
    }
} 