import Foundation
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversation: Conversation?
    
    init() {
        loadMockData()
    }
    
    func filteredConversations(searchText: String) -> [Conversation] {
        if searchText.isEmpty {
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            return conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage?.localizedCaseInsensitiveContains(searchText) == true
            }.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    func selectConversation(_ conversation: Conversation) {
        selectedConversation = conversation
    }
    
    func createNewConversation() {
        let newConversation = Conversation()
        conversations.insert(newConversation, at: 0)
        selectedConversation = newConversation
    }
    
    func deleteConversations(at offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)
    }
    
    private func loadMockData() {
        conversations = [
            createMockConversation(title: "iOS Development Help", messages: [
                "I need help with SwiftUI",
                "SwiftUI is Apple's modern UI framework. What specific aspect would you like to learn?",
                "How do I create custom views?",
                "You can create custom views by conforming to the View protocol..."
            ]),
            createMockConversation(title: "API Integration", messages: [
                "How do I integrate REST APIs in iOS?",
                "There are several ways to integrate REST APIs in iOS. URLSession is the most common approach..."
            ]),
            createMockConversation(title: "Core Data Questions", messages: [
                "I'm having trouble with Core Data",
                "Core Data can be tricky. What specific issue are you facing?"
            ])
        ]
    }
    
    private func createMockConversation(title: String, messages: [String]) -> Conversation {
        var conversation = Conversation(title: title)
        
        for (index, messageContent) in messages.enumerated() {
            let role: MessageRole = index % 2 == 0 ? .user : .assistant
            let message = Message(content: messageContent, role: role, conversationId: conversation.id)
            conversation.addMessage(message)
        }
        
        return conversation
    }
} 