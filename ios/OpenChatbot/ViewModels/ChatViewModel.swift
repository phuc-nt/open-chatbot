import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var currentConversation: Conversation?
    @Published var errorMessage: String?
    @Published var selectedModel: LLMModel?
    @Published var availableModels: [LLMModel] = []
    
    private let apiService: LLMAPIService
    private var currentStreamingMessage: Message?
    private var streamingTask: Task<Void, Never>?  // Memory management cho streaming tasks
    
    init(apiService: LLMAPIService? = nil) {
        // Use dependency injection or create default service
        if let service = apiService {
            self.apiService = service
        } else {
            let keychain = KeychainService()
            self.apiService = OpenRouterAPIService(keychain: keychain)
        }
        
        // Load mock data for initial UI
        loadMockData()
        
        // Load available models
        Task {
            await loadAvailableModels()
        }
    }
    
    deinit {
        // Clean up streaming task on dealloc
        streamingTask?.cancel()
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let conversationId = currentConversation?.id ?? UUID()
        let userMessage = Message(content: content, role: .user, conversationId: conversationId)
        
        messages.append(userMessage)
        isLoading = true
        isStreaming = true
        errorMessage = nil
        
        // Create empty assistant message for streaming
        let assistantMessage = Message(content: "", role: .assistant, conversationId: conversationId)
        messages.append(assistantMessage)
        currentStreamingMessage = assistantMessage
        
        guard let selectedModel = selectedModel ?? getDefaultModel() else {
            errorMessage = "Không thể chọn model AI"
            isLoading = false
            isStreaming = false
            return
        }
        
        // Convert messages for API
        let chatMessages = messages.dropLast().compactMap { message -> ChatMessage? in
            guard message.role != .system else { return nil }
            let apiRole: ChatMessage.MessageRole = message.role == .user ? .user : .assistant
            return ChatMessage(role: apiRole, content: message.content)
        }
        
        // Cancel previous streaming task
        streamingTask?.cancel()
        
        // Start new streaming task
        streamingTask = Task { @MainActor in
            do {
                let stream = try await apiService.sendMessage(
                    content,
                    model: selectedModel,
                    conversation: chatMessages.isEmpty ? nil : chatMessages
                )
                
                var accumulatedContent = ""
                
                for await chunk in stream {
                    // Check for cancellation
                    guard !Task.isCancelled else {
                        print("⚠️ Streaming task cancelled")
                        break
                    }
                    
                    accumulatedContent += chunk
                    
                    // Update UI on main thread
                    if let lastMessageIndex = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                        messages[lastMessageIndex].content = accumulatedContent
                    }
                }
                
                // Streaming completed
                isLoading = false
                isStreaming = false
                currentStreamingMessage = nil
                streamingTask = nil
                
            } catch {
                // Handle error
                await MainActor.run {
                    errorMessage = "Lỗi: \(error.localizedDescription)"
                    isLoading = false
                    isStreaming = false
                    currentStreamingMessage = nil
                    streamingTask = nil
                    
                    // Remove empty assistant message on error
                    if let lastMessage = messages.last, lastMessage.content.isEmpty {
                        messages.removeLast()
                    }
                }
            }
        }
    }
    
    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        isLoading = false
        currentStreamingMessage = nil
        
        // Clean up empty assistant message if exists
        if let lastMessage = messages.last, lastMessage.content.isEmpty && lastMessage.role == .assistant {
            messages.removeLast()
        }
    }
    
    private func convertToAPIFormat() -> [ChatMessage] {
        return messages.compactMap { message in
            guard message.role != .system else { return nil }
            return ChatMessage(
                role: message.role == .user ? .user : .assistant,
                content: message.content
            )
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
    
    private func loadAvailableModels() async {
        do {
            let models = try await apiService.getAvailableModels()
            await MainActor.run {
                self.availableModels = models.prefix(10).map { $0 } // Limit to 10 for performance
                if self.selectedModel == nil {
                    self.selectedModel = self.getDefaultModel()
                }
            }
        } catch {
            print("⚠️ Failed to load models: \(error.localizedDescription)")
            // Use default model
            await MainActor.run {
                self.selectedModel = self.getDefaultModel()
            }
        }
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
            self.isStreaming = false
        }
    }
    
    private func loadMockData() {
        let conversation = Conversation(title: "OpenRouter Chat")
        currentConversation = conversation
        
        messages = [
            Message(content: "Hello! I'm ready to help you with any questions. I'm powered by OpenRouter and can access various AI models.", role: .assistant, conversationId: conversation.id)
        ]
    }
    
    func clearConversation() {
        messages.removeAll()
        currentConversation = Conversation(title: "New Chat")
        loadMockData()
    }
    
    func selectModel(_ model: LLMModel) {
        selectedModel = model
    }
} 