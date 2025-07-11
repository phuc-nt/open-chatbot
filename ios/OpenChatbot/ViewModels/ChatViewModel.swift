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
    
    // UserDefaults keys for persistence
    private let selectedModelKey = "selectedModel"
    private let defaultModelKey = "defaultModel"
    
    // Notification names for model updates
    static let defaultModelDidChangeNotification = Notification.Name("DefaultModelDidChange")
    
    private let apiService: LLMAPIService
    private let dataService: DataService
    private let persistenceController: PersistenceController
    private let memoryService: MemoryService  // 🧠 Memory service for context-aware conversations
    private var currentStreamingMessage: Message?
    private var streamingTask: Task<Void, Never>?  // Memory management cho streaming tasks
    private var currentStreamTask: Task<Void, Never>?  // Task for current streaming operation
    
    init(apiService: LLMAPIService? = nil, 
         dataService: DataService = DataService(),
         persistenceController: PersistenceController = .shared,
         memoryService: MemoryService? = nil) {
        // Use dependency injection or create default service
        if let service = apiService {
            self.apiService = service
        } else {
            let keychain = KeychainService()
            self.apiService = OpenRouterAPIService(keychain: keychain)
        }
        self.dataService = dataService
        self.persistenceController = persistenceController
        
        // Initialize memory service
        if let memory = memoryService {
            self.memoryService = memory
        } else {
            self.memoryService = MemoryService(dataService: dataService)
        }
        
        // Initialize with a new conversation or load existing one
        loadOrCreateConversation()
        
        // Load available models
        Task {
            await loadAvailableModels()
        }
        
        // Listen for default model changes
        NotificationCenter.default.addObserver(
            forName: ChatViewModel.defaultModelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newDefaultModel = notification.object as? LLMModel {
                // Update current selected model if we're in a new conversation
                if self?.currentConversation == nil || self?.messages.isEmpty == true {
                    self?.selectedModel = newDefaultModel
                    print("✅ Updated selected model to new default: \(newDefaultModel.name)")
                }
            }
        }
        
        // Listen for history clear events
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AllConversationsCleared"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📞 Received AllConversationsCleared notification, resetting ChatViewModel")
            self?.resetToNewConversation()
        }
    }
    
    deinit {
        // Clean up streaming task and notification observers
        streamingTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Conversation Management
    
    /// Load most recent conversation or create new one
    private func loadOrCreateConversation() {
        if currentConversation == nil {
            // Try to load most recent conversation first
            if let recentConversation = dataService.getMostRecentConversation() {
                loadRecentConversation(recentConversation)
            } else {
                // No existing conversations, create new one
                startNewConversation()
            }
        } else {
            loadMessagesForCurrentConversation()
        }
    }
    
    /// Load the most recent conversation on app startup
    private func loadRecentConversation(_ conversation: ConversationEntity) {
        currentConversation = conversation
        
        // Load messages for this conversation
        messages = dataService.getMessagesForConversation(conversation)
        
        // Load saved model for this conversation (if any)
        if let savedModelID = conversation.selectedModelID,
           let savedModel = availableModels.first(where: { $0.id == savedModelID }) {
            selectedModel = savedModel
        } else {
            // Use default model if no saved model found
            selectedModel = getDefaultModel() ?? LLMModel.defaultModel
        }
        
        print("✅ Loaded recent conversation: \(conversation.title ?? "Untitled"), Model: \(selectedModel.name)")
    }
    
    /// Load messages for current conversation
    private func loadMessagesForCurrentConversation() {
        guard let conversation = currentConversation else { return }
        messages = dataService.getMessagesForConversation(conversation)
    }
    
    /// Create a new conversation
    func createNewConversation(title: String = "New Conversation") {
        currentConversation = dataService.createConversation(title: title)
        messages = []
    }
    
    /// Load existing conversation by UUID
    func loadConversationByID(conversationID: UUID) {
        // Find conversation in Core Data by ID
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conversationID as CVarArg)
        
        do {
            let conversations = try context.fetch(request)
            if let conversation = conversations.first {
                currentConversation = conversation
                messages = dataService.getMessagesForConversation(conversation)
                
                // Load saved model for this conversation (if any)
                if let savedModelID = conversation.selectedModelID,
                   let savedModel = availableModels.first(where: { $0.id == savedModelID }) {
                    selectedModel = savedModel
                } else {
                    // Use default model if no saved model found
                    selectedModel = getDefaultModel() ?? LLMModel.defaultModel
                }
                
                print("✅ Loaded conversation: \(conversation.title ?? "Untitled"), Model: \(selectedModel.name)")
            }
        } catch {
            print("❌ Error loading conversation by ID: \(error)")
        }
    }
    
    /// Start new conversation
    func startNewConversation() {
        // Create new conversation using DataService
        currentConversation = dataService.createConversation()
        
        // Clear messages
        messages = []
        
        // Use default model for new conversations
        selectedModel = getDefaultModel() ?? LLMModel.defaultModel
        
        print("✅ Started new conversation with model: \(selectedModel.name)")
    }
    
    /// Reset to new conversation (called when all history is cleared)
    func resetToNewConversation() {
        // Clear current state
        currentConversation = nil
        messages = []
        currentInput = ""
        errorMessage = nil
        isLoading = false
        isStreaming = false
        
        // Cancel any ongoing requests
        apiService.cancelCurrentRequest()
        
        // Start fresh conversation
        startNewConversation()
        
        print("🔄 Reset to new conversation after history clear")
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
        
        // Cancel any existing streaming task
        currentStreamTask?.cancel()
        
        let userMessageContent = currentInput
        currentInput = ""
        isLoading = true
        isStreaming = false  // Start with typing indicator only
        
        // Ensure we have a conversation
        if currentConversation == nil {
            currentConversation = dataService.createConversation(title: "New Conversation")
        }
        
        guard let conversation = currentConversation else {
            isLoading = false
            isStreaming = false
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
        
        // Create a cancellable task for streaming
        currentStreamTask = Task { @MainActor in
            do {
                var assistantResponse = ""
                var assistantMessageCreated = false
                
                // Convert messages to ChatMessage format for API
                let chatMessages = messages.compactMap { message -> ChatMessage? in
                    guard message.role != .system else { return nil }
                    let apiRole: ChatMessage.MessageRole = message.role == .user ? .user : .assistant
                    return ChatMessage(role: apiRole, content: message.content)
                }
                
                // Stream response from API
                let stream = try await apiService.sendMessage(userMessageContent, model: selectedModel, conversation: chatMessages.isEmpty ? nil : chatMessages)
                
                for try await chunk in stream {
                    // Check if task was cancelled
                    if Task.isCancelled {
                        print("🛑 Streaming task was cancelled")
                        break
                    }
                // Check for error messages from API service
                if chunk.hasPrefix("__NETWORK_ERROR__:") {
                    let errorMsg = String(chunk.dropFirst("__NETWORK_ERROR__:".count)).trimmingCharacters(in: .whitespaces)
                    await handleError("🌐 Lỗi kết nối mạng: \(errorMsg)")
                    return
                } else if chunk.hasPrefix("__HTTP_ERROR__") {
                    let errorMsg = String(chunk.dropFirst("__HTTP_ERROR__".count))
                    await handleError("🚨 Lỗi từ server: \(errorMsg)")
                    return
                } else if chunk.hasPrefix("__ERROR__:") {
                    let errorMsg = String(chunk.dropFirst("__ERROR__:".count)).trimmingCharacters(in: .whitespaces)
                    await handleError("❌ Lỗi: \(errorMsg)")
                    return
                }
                
                // Switch from loading to streaming when we receive first chunk
                if isLoading {
                    isLoading = false
                    isStreaming = true
                }
                
                assistantResponse += chunk
                
                // Create assistant message only when we have content
                if !assistantMessageCreated {
                    let assistantMessage = Message(
                        content: assistantResponse,
                        role: .assistant,
                        conversationId: conversation.id ?? UUID()
                    )
                    
                    await MainActor.run {
                        messages.append(assistantMessage)
                        assistantMessageCreated = true
                        print("🔄 Streaming started, isStreaming = \(isStreaming)")
                    }
                } else {
                    // Update existing assistant message
                    await MainActor.run {
                        if let lastIndex = messages.lastIndex(where: { $0.role == .assistant }) {
                            var updatedMessage = Message(
                                content: assistantResponse,
                                role: .assistant,
                                conversationId: conversation.id ?? UUID()
                            )
                            updatedMessage.id = messages[lastIndex].id
                            updatedMessage.timestamp = messages[lastIndex].timestamp
                            
                            // Update with smooth animation
                            withAnimation(.easeOut(duration: 0.1)) {
                                messages[lastIndex] = updatedMessage
                            }
                        }
                    }
                }
                
                // Small delay for smoother character-by-character effect
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            
            // Save final assistant message to Core Data
            if assistantMessageCreated {
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
            }
            
            } catch {
                // No need to remove placeholder since we don't create it upfront
                print("Error sending message: \(error)")
                await handleError("Failed to send message: \(error.localizedDescription)")
            }
            
            isLoading = false
            isStreaming = false  // Stop streaming indicator (backup)
            print("✅ Streaming completed, isStreaming = false")
        }
        
        // Wait for task completion
        await currentStreamTask?.value
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
        print("🛑 Stop button pressed, canceling streaming")
        
        // Cancel the streaming task first
        currentStreamTask?.cancel()
        currentStreamTask = nil
        
        // Then cancel API request
        apiService.cancelCurrentRequest()
        
        isLoading = false
        isStreaming = false  // Stop streaming indicator
        print("✅ Streaming canceled, isStreaming = false")
        
        // No need to remove placeholder since we don't create empty ones anymore
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
    
    func loadAvailableModels() async {
        do {
            let models = try await apiService.getAvailableModels()
            await MainActor.run {
                self.availableModels = models // Remove .prefix(10) limitation
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
    
    // MARK: - Model Persistence Methods
    
    /// Save selected model to UserDefaults
    private func saveSelectedModel() {
        let modelData = [
            "id": selectedModel.id,
            "name": selectedModel.name,
            "provider": selectedModel.provider.rawValue
        ]
        UserDefaults.standard.set(modelData, forKey: selectedModelKey)
    }
    
    /// Restore selected model from UserDefaults
    private func restoreSelectedModel() async {
        guard let modelData = UserDefaults.standard.dictionary(forKey: selectedModelKey),
              let id = modelData["id"] as? String,
              let name = modelData["name"] as? String,
              let providerRaw = modelData["provider"] as? String,
              let provider = LLMProvider(rawValue: providerRaw) else {
            // No saved model, use default
            await MainActor.run {
                self.selectedModel = self.getDefaultModel() ?? LLMModel.defaultModel
            }
            return
        }
        
        // Find the model in available models or create from saved data
        await MainActor.run {
            if let savedModel = availableModels.first(where: { $0.id == id }) {
                self.selectedModel = savedModel
            } else {
                // Create model from saved data (in case it's no longer available)
                self.selectedModel = LLMModel(
                    id: id,
                    name: name,
                    provider: provider,
                    contextLength: 128000,
                    pricing: ModelPricing(inputTokens: 0.0, outputTokens: 0.0, imageInputs: nil),
                    description: "Previously selected model",
                    capabilities: .basic
                )
            }
        }
    }
    
    /// Get user's default model preference
    func getDefaultModel() -> LLMModel? {
        // Try to get from UserDefaults using consistent format
        guard let modelData = UserDefaults.standard.dictionary(forKey: defaultModelKey),
              let id = modelData["id"] as? String,
              let name = modelData["name"] as? String,
              let providerRaw = modelData["provider"] as? String,
              let provider = LLMProvider(rawValue: providerRaw) else {
            print("⚠️ No default model found in UserDefaults")
            // Return first available model as fallback
            return availableModels.first ?? LLMModel.defaultModel
        }
        
        print("📱 Found default model in UserDefaults: \(name)")
        
        // Find the default model in available models
        if let foundModel = availableModels.first(where: { $0.id == id }) {
            print("✅ Default model found in available models: \(foundModel.name)")
            return foundModel
        } else {
            print("⚠️ Default model not found in available models, using fallback")
            return availableModels.first ?? LLMModel.defaultModel
        }
    }
    
    /// Set default model for new conversations
    func setDefaultModel(_ model: LLMModel) {
        // Use consistent dictionary format (same as getDefaultModel)
        let modelData = [
            "id": model.id,
            "name": model.name,
            "provider": model.provider.rawValue
        ]
        UserDefaults.standard.set(modelData, forKey: defaultModelKey)
        UserDefaults.standard.synchronize() // Force immediate sync
        
        print("✅ Set default model: \(model.name) (ID: \(model.id))")
        
        // Broadcast default model change
        NotificationCenter.default.post(
            name: ChatViewModel.defaultModelDidChangeNotification,
            object: model
        )
    }
    
    /// Update selected model and save to conversation
    func updateSelectedModel(_ model: LLMModel) {
        selectedModel = model
        
        // Save to UserDefaults (global preference)
        saveSelectedModel()
        
        // Save to current conversation (if exists)
        if let conversation = currentConversation {
            conversation.selectedModelID = model.id
            dataService.saveContext()
            print("✅ Saved model \(model.name) to conversation: \(conversation.title ?? "Untitled")")
        }
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
            self.isStreaming = false
        }
    }
} 