import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var isStreaming = false
    @Published var currentConversation: ConversationEntity?
    @Published var errorMessage: String?
    @Published var selectedModel: LLMModel = LLMModel.defaultModel
    @Published var availableModels: [LLMModel] = []
    
    private let apiService: LLMAPIService
    private let dataService: DataService
    private let persistenceController: PersistenceController
    private var currentStreamingMessage: Message?
    private var streamingTask: Task<Void, Never>?  // Memory management cho streaming tasks
    
    init(apiService: LLMAPIService? = nil, 
         dataService: DataService = DataService(),
         persistenceController: PersistenceController = .shared) {
        // Use dependency injection or create default service
        if let service = apiService {
            self.apiService = service
        } else {
            let keychain = KeychainService()
            self.apiService = OpenRouterAPIService(keychain: keychain)
        }
        self.dataService = dataService
        self.persistenceController = persistenceController
        
        // Initialize with a new conversation or load existing one
        loadOrCreateConversation()
        
        // Load available models
        Task {
            await loadAvailableModels()
        }
    }
    
    deinit {
        // Clean up streaming task on dealloc
        streamingTask?.cancel()
    }
    
    // MARK: - Conversation Management
    
    /// Load existing conversation or create new one
    private func loadOrCreateConversation() {
        if currentConversation == nil {
            createNewConversation()
        } else {
            loadMessagesForCurrentConversation()
        }
    }
    
    /// Create a new conversation
    func createNewConversation(title: String = "New Conversation") {
        currentConversation = dataService.createConversation(title: title)
        messages = []
    }
    
    /// Load a specific conversation
    func loadConversation(_ conversation: ConversationEntity) {
        currentConversation = conversation
        loadMessagesForCurrentConversation()
    }
    
    /// Load messages for current conversation
    private func loadMessagesForCurrentConversation() {
        guard let conversation = currentConversation else { return }
        messages = dataService.getMessagesForConversation(conversation)
    }
    
    /// Update conversation title based on first message
    private func updateConversationTitle() {
        guard let conversation = currentConversation,
              let firstUserMessage = messages.first(where: { $0.role == .user }),
              conversation.title == "New Conversation" else { return }
        
        // Use first few words of first message as title
        let words = firstUserMessage.content.components(separatedBy: .whitespaces)
        let title = words.prefix(5).joined(separator: " ")
        dataService.updateConversation(conversation, title: title.isEmpty ? "Untitled" : title)
    }
    
    // MARK: - Message Handling
    
    /// Send a new message
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessageContent = currentInput
        currentInput = ""
        isLoading = true
        
        // Ensure we have a conversation
        if currentConversation == nil {
            createNewConversation()
        }
        
        guard let conversation = currentConversation else {
            isLoading = false
            return
        }
        
        // Create and save user message
        let userMessage = Message(
            content: userMessageContent,
            role: .user,
            conversationId: conversation.id ?? UUID()
        )
        
        dataService.addMessage(userMessage, to: conversation)
        
        // Update local messages array
        messages.append(userMessage)
        
        // Update conversation title if this is the first message
        if messages.count == 1 {
            updateConversationTitle()
        }
        
        do {
            var assistantResponse = ""
            let assistantMessage = Message(
                content: "",
                role: .assistant,
                conversationId: conversation.id ?? UUID()
            )
            
            // Add assistant message placeholder
            messages.append(assistantMessage)
            
            // Convert messages to ChatMessage format for API
            let chatMessages = messages.dropLast().compactMap { message -> ChatMessage? in
                guard message.role != .system else { return nil }
                let apiRole: ChatMessage.MessageRole = message.role == .user ? .user : .assistant
                return ChatMessage(role: apiRole, content: message.content)
            }
            
            // Stream response from API
            let stream = try await apiService.sendMessage(userMessageContent, model: selectedModel, conversation: chatMessages.isEmpty ? nil : chatMessages)
            
            for try await chunk in stream {
                assistantResponse += chunk
                // Update the last message (assistant message) in real-time
                if let lastIndex = messages.lastIndex(where: { $0.role == .assistant }) {
                    var updatedMessage = Message(
                        content: assistantResponse,
                        role: .assistant,
                        conversationId: conversation.id ?? UUID()
                    )
                    updatedMessage.id = messages[lastIndex].id
                    updatedMessage.timestamp = messages[lastIndex].timestamp
                    messages[lastIndex] = updatedMessage
                }
            }
            
            // Save final assistant message to Core Data
            let finalAssistantMessage = Message(
                content: assistantResponse,
                role: .assistant,
                conversationId: conversation.id ?? UUID()
            )
            
            dataService.addMessage(finalAssistantMessage, to: conversation)
            
            // Update local array with final message
            if let lastIndex = messages.lastIndex(where: { $0.role == .assistant }) {
                messages[lastIndex] = finalAssistantMessage
            }
            
        } catch {
            // Remove the placeholder assistant message on error
            if messages.last?.role == .assistant && messages.last?.content.isEmpty == true {
                messages.removeLast()
            }
            
            print("Error sending message: \(error)")
            // TODO: Show error to user
        }
        
        isLoading = false
    }
    
    /// Clear all messages in current conversation
    func clearMessages() {
        guard let conversation = currentConversation else { return }
        
        dataService.clearMessagesInConversation(conversation)
        messages = []
    }
    
    /// Delete a specific message
    func deleteMessage(_ message: Message) {
        guard let conversation = currentConversation else { return }
        
        dataService.deleteMessage(message, from: conversation)
        messages.removeAll { $0.id == message.id }
    }
    
    /// Cancel current request
    func cancelCurrentRequest() {
        apiService.cancelCurrentRequest()
        isLoading = false
        
        // Remove placeholder assistant message if exists
        if messages.last?.role == .assistant && messages.last?.content.isEmpty == true {
            messages.removeLast()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get conversation preview (for history view)
    var conversationPreview: String {
        guard let lastMessage = messages.last else { return "No messages" }
        let words = lastMessage.content.components(separatedBy: .whitespaces)
        return words.prefix(10).joined(separator: " ")
    }
    
    /// Get conversation title
    var conversationTitle: String {
        return currentConversation?.title ?? "New Conversation"
    }
    
    /// Check if conversation has messages
    var hasMessages: Bool {
        return !messages.isEmpty
    }
    
    /// Save conversation state
    func saveConversation() {
        guard let conversation = currentConversation else { return }
        dataService.saveContext()
    }
    
    private func loadAvailableModels() async {
        do {
            let models = try await apiService.getAvailableModels()
            await MainActor.run {
                self.availableModels = models.prefix(10).map { $0 } // Limit to 10 for performance
                if self.selectedModel == LLMModel.defaultModel {
                    self.selectedModel = self.getDefaultModel() ?? LLMModel.defaultModel
                }
            }
        } catch {
            print("⚠️ Failed to load models: \(error.localizedDescription)")
            // Use default model
            await MainActor.run {
                self.selectedModel = self.getDefaultModel() ?? LLMModel.defaultModel
            }
        }
    }
    
    private func getDefaultModel() -> LLMModel? {
        // Return first available model or a default one
        return availableModels.first ?? LLMModel(
            id: "openai/gpt-4o-mini",
            name: "GPT-4o Mini",
            provider: .openrouter,
            contextLength: 128000,
            pricing: ModelPricing(
                inputTokens: 0.15,
                outputTokens: 0.60,
                imageInputs: nil
            ),
            description: "Lightweight and affordable GPT-4 model",
            capabilities: .advanced
        )
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
            self.isStreaming = false
        }
    }
} 