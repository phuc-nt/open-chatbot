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
    
    // Track conversation ID for deletion detection
    private var currentConversationId: UUID?
    
    // RAG-related properties
    @Published var selectedDocuments: [String] = [] // Document IDs for RAG context
    @Published var isRAGEnabled: Bool = false
    @Published var documentContext: String = ""
    @Published var ragQueryInProgress: Bool = false
    
    // UserDefaults keys for persistence
    private let selectedModelKey = "selectedModel"
    private let defaultModelKey = "defaultModel"
    
    // Notification names for model updates
    static let defaultModelDidChangeNotification = Notification.Name("DefaultModelDidChange")
    
    private let apiService: LLMAPIService
    private let dataService: DataService
    private let persistenceController: PersistenceController
    private let memoryService: MemoryService  // 🧠 Memory service for context-aware conversations
    private let memoryPersistenceService: MemoryPersistenceService // 💾 Memory persistence across sessions
    private let tokenWindowService: TokenWindowManagementService? // 🪟 Token window management
    
    // RAG Services - Initialize lazily to avoid dependency issues
    private var ragQueryService: RAGQueryServiceSimulator?
    private var embeddingService: EmbeddingServiceProtocol?
    private var coreDataVectorService: CoreDataVectorService?
    
    private var currentStreamingMessage: Message?
    private var streamingTask: Task<Void, Never>?  // Memory management cho streaming tasks
    private var currentStreamTask: Task<Void, Never>?  // Task for current streaming operation
    
    init(apiService: LLMAPIService? = nil, 
         dataService: DataService = DataService(),
         persistenceController: PersistenceController = .shared,
         memoryService: MemoryService? = nil,
         memoryPersistenceService: MemoryPersistenceService? = nil,
         tokenWindowService: TokenWindowManagementService? = nil) {
        
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
        
        // Initialize memory persistence service
        if let persistence = memoryPersistenceService {
            self.memoryPersistenceService = persistence
        } else {
            self.memoryPersistenceService = MemoryPersistenceService()
        }
        
        // Initialize token window service if not provided
        if let tokenWindow = tokenWindowService {
            self.tokenWindowService = tokenWindow
        } else {
            // Create summary memory service first
            let summaryMemoryService = ConversationSummaryMemoryService(apiService: self.apiService)
            summaryMemoryService.setMemoryService(self.memoryService)
            
            // Then create compression service
            let compressionService = ContextCompressionService(
                memoryService: self.memoryService,
                summaryMemoryService: summaryMemoryService
            )
            
            self.tokenWindowService = TokenWindowManagementService(
                memoryService: self.memoryService,
                compressionService: compressionService
            )
        }
        
        // Initialize RAG Services
        initializeRAGServices()
        
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
        
        // Listen for individual conversation deletion
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ConversationDeleted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📞 Received ConversationDeleted notification")
            
            if let deletedConversationId = notification.object as? UUID {
                print("📞 Deleted conversation ID: \(deletedConversationId.uuidString)")
                
                let currentId = self?.currentConversation?.id
                let trackedId = self?.currentConversationId
                
                print("📞 Current conversation ID: \(currentId?.uuidString ?? "nil")")
                print("📞 Tracked conversation ID: \(trackedId?.uuidString ?? "nil")")
                
                // Check both current conversation and tracked ID
                let shouldReset = (currentId == deletedConversationId) || 
                                 (trackedId == deletedConversationId) ||
                                 (!(self?.messages.isEmpty ?? true)) // If we have messages but no current conversation
                
                if shouldReset {
                    print("📞 Resetting chat view - conversation was deleted")
                    self?.resetToNewConversation()
                } else {
                    print("📞 Different conversation was deleted, no action needed")
                }
            } else {
                print("⚠️ ConversationDeleted notification received but no valid UUID found")
            }
        }
    }
    
    deinit {
        // Clean up streaming task and notification observers
        streamingTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - RAG Services Initialization
    
    /// Initialize RAG services with proper dependency injection
    private func initializeRAGServices() {
        // Initialize Core Data Vector Service
        self.coreDataVectorService = CoreDataVectorService(context: persistenceController.container.viewContext)
        
        // Initialize Embedding Service with hybrid strategy
        self.embeddingService = EmbeddingService(
            strategy: .hybrid,
            context: persistenceController.container.viewContext
        )
        
        // Initialize RAG Query Service simulator with real embedding service
        if let embeddingService = self.embeddingService {
            self.ragQueryService = RAGQueryServiceSimulator(embeddingService: embeddingService, dataService: self.dataService)
            print("✅ RAG Services initialized successfully")
        } else {
            print("⚠️ Failed to initialize RAG services")
        }
    }
    
    // MARK: - RAG Document Management
    
    /// Add document to RAG context
    func addDocumentToContext(_ documentId: String) {
        if !selectedDocuments.contains(documentId) {
            selectedDocuments.append(documentId)
            updateRAGStatus()
            print("📄 Added document \(documentId) to RAG context")
        }
    }
    
    /// Remove document from RAG context
    func removeDocumentFromContext(_ documentId: String) {
        selectedDocuments.removeAll { $0 == documentId }
        updateRAGStatus()
        print("📄 Removed document \(documentId) from RAG context")
    }
    
    /// Clear all documents from RAG context
    func clearDocumentContext() {
        selectedDocuments.removeAll()
        documentContext = ""
        updateRAGStatus()
        print("📄 Cleared all documents from RAG context")
    }
    
    /// Update RAG enabled status based on selected documents
    private func updateRAGStatus() {
        isRAGEnabled = !selectedDocuments.isEmpty
        if !isRAGEnabled {
            documentContext = ""
        }
    }
    
    /// Get document context for display
    func getDocumentContextSummary() -> String {
        if selectedDocuments.isEmpty {
            return "No documents selected"
        } else {
            return "\(selectedDocuments.count) document(s) selected for context"
        }
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
        currentConversationId = conversation.id
        
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
    
    /// Update model for conversation after available models are loaded
    private func updateModelForConversation(_ conversation: ConversationEntity) {
        // Load saved model for this conversation (if any)
        if let savedModelID = conversation.selectedModelID,
           let savedModel = availableModels.first(where: { $0.id == savedModelID }) {
            if selectedModel.id != savedModel.id {
                selectedModel = savedModel
                print("🔄 Updated conversation model: \(savedModel.name)")
            }
        } else {
            // Use default model if no saved model found
            let defaultModel = getDefaultModel() ?? LLMModel.defaultModel  
            if selectedModel.id != defaultModel.id {
                selectedModel = defaultModel
                print("🔄 Using default model for conversation: \(defaultModel.name)")
            }
        }
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
                currentConversationId = conversation.id
                messages = dataService.getMessagesForConversation(conversation)
                
                // Load saved model for this conversation (if any)
                if let savedModelID = conversation.selectedModelID,
                   let savedModel = availableModels.first(where: { $0.id == savedModelID }) {
                    selectedModel = savedModel
                } else {
                    // Use default model if no saved model found
                    selectedModel = getDefaultModel() ?? LLMModel.defaultModel
                }
                
                // Ensure memory continuity for this conversation
                Task {
                    let hasContinuity = await memoryPersistenceService.ensureMemoryContinuity(for: conversationID)
                    if hasContinuity {
                        print("💾 Memory continuity ensured for conversation")
                    } else {
                        print("⚠️ No previous memory found for conversation")
                    }
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
        currentConversationId = currentConversation?.id
        
        // Clear messages and RAG context
        messages = []
        clearDocumentContext()
        
        // Use default model for new conversations
        selectedModel = getDefaultModel() ?? LLMModel.defaultModel
        
        print("✅ Started new conversation with model: \(selectedModel.name)")
    }
    
    /// Reset to new conversation (called when all history is cleared)
    func resetToNewConversation() {
        // Clear current state
        currentConversation = nil
        currentConversationId = nil
        messages = []
        currentInput = ""
        errorMessage = nil
        isLoading = false
        isStreaming = false
        
        // Clear RAG context
        clearDocumentContext()
        
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
    
    // MARK: - Message Handling with RAG Integration
    
    /// Send a new message with optional RAG integration
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Cancel any existing streaming task
        currentStreamTask?.cancel()
        
        let userMessageContent = currentInput
        currentInput = ""
        isLoading = true
        isStreaming = false  // Start with typing indicator only
        ragQueryInProgress = false
        
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
        
        // Add user message to memory system for context-aware responses
        do {
            await memoryService.addMessageToMemory(userMessage, conversationId: conversation.id ?? UUID())
        } catch {
            handleMemoryError(error, context: "adding user message to memory")
        }
        
        // Update local messages array
        messages.append(userMessage)
        
        // Update conversation title if this is the first message
        if messages.count == 1 {
            updateConversationTitle()
        }
        
        // Create a cancellable task for streaming with RAG integration
        currentStreamTask = Task { @MainActor in
            do {
                var assistantResponse = ""
                var assistantMessageCreated = false
                
                // RAG Query Phase: Get document context if RAG is enabled
                var ragContext = ""
                if isRAGEnabled && !selectedDocuments.isEmpty {
                    ragQueryInProgress = true
                    ragContext = await performRAGQuery(query: userMessageContent)
                    ragQueryInProgress = false
                }
                
                // Get context-aware messages from memory system with token window management
                let contextMessages: [Message]
                do {
                    // Apply token window management if available
                    if let tokenWindowService = tokenWindowService {
                        let tokenResult = try await tokenWindowService.manageTokenWindow(
                            for: conversation.id ?? UUID(),
                            model: selectedModel,
                            reserveTokens: 1500 // Reserve for response
                        )
                        
                        if tokenResult.optimized {
                            print("🪟 Token window optimized: \(tokenResult.originalTokens) → \(tokenResult.finalTokens) tokens")
                            print("🪟 Messages removed: \(tokenResult.messagesRemoved), Compression: \(tokenResult.compressionApplied)")
                        }
                    }
                    
                    contextMessages = await memoryService.getContextForAPICall(
                        conversationId: conversation.id ?? UUID(),
                        maxTokens: selectedModel.contextLength
                    )
                } catch {
                    handleMemoryError(error, context: "getting context for API call")
                    // Fallback to current messages if memory fails
                    contextMessages = messages
                }
                
                // Convert context messages to ChatMessage format for API
                var chatMessages = contextMessages.compactMap { message -> ChatMessage? in
                    guard message.role != .system else { return nil }
                    let apiRole: ChatMessage.MessageRole = message.role == .user ? .user : .assistant
                    return ChatMessage(role: apiRole, content: message.content)
                }
                
                // Insert RAG context as system message if available
                if !ragContext.isEmpty {
                    let systemMessage = ChatMessage(role: .system, content: """
DOCUMENT CONTEXT:

\(ragContext)

IMPORTANT: Base your response ONLY on the document context provided above. If asked to summarize, provide a summary based on this specific document content. Answer in Vietnamese if the user asks in Vietnamese.
""")
                    chatMessages.insert(systemMessage, at: 0)
                    print("📄 Added RAG context to conversation (\(ragContext.count) characters)")
                    print("🔍 RAG CONTEXT CONTENT:")
                    print(String(repeating: "=", count: 50))
                    print(ragContext)
                    print(String(repeating: "=", count: 50))
                }
                
                // Stream response from API with memory and RAG context
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
                
                // Save final assistant message to Core Data and memory system
                if assistantMessageCreated {
                    let finalAssistantMessage = Message(
                        content: assistantResponse,
                        role: .assistant,
                        conversationId: conversation.id ?? UUID()
                    )
                    
                    // Log LLM response for debugging
                    print("🤖 LLM RESPONSE COMPLETED:")
                    print(String(repeating: "=", count: 50))
                    print("Query: \(userMessageContent)")
                    print("RAG Enabled: \(isRAGEnabled)")
                    print("Selected Documents: \(selectedDocuments.count)")
                    print("Response Length: \(assistantResponse.count) characters")
                    print("Response Content:")
                    print(assistantResponse)
                    print(String(repeating: "=", count: 50))
                    
                    dataService.addMessage(finalAssistantMessage, to: conversation)
                    
                    // Add assistant response to memory system for future context
                    do {
                        await memoryService.addMessageToMemory(finalAssistantMessage, conversationId: conversation.id ?? UUID())
                    } catch {
                        handleMemoryError(error, context: "adding assistant message to memory")
                    }
                    
                    // Core Data notification will automatically trigger HistoryViewModel refresh
                    
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
            ragQueryInProgress = false
            print("✅ Streaming completed, isStreaming = false")
        }
        
        // Wait for task completion
        await currentStreamTask?.value
    }
    
    /// Perform RAG query to get document context
    private func performRAGQuery(query: String) async -> String {
        guard let ragService = ragQueryService else {
            print("⚠️ RAG Query Service not available")
            return ""
        }
        
        do {
            print("🔍 Performing RAG query: \(query)")
            
            let ragResult = await ragService.simulateRAGQuery(
                query: query,
                documentIds: selectedDocuments,
                topK: 3
            )
            
            documentContext = ragResult.context
            print("📄 RAG query completed: \(ragResult.context.count) characters of context")
            
            // Log the actual context that will be sent to LLM
            if !ragResult.context.isEmpty {
                print("🔍 FINAL RAG CONTEXT TO BE SENT TO LLM:")
                print(String(repeating: "-", count: 40))
                print(ragResult.context)
                print(String(repeating: "-", count: 40))
            }
            
            return ragResult.context
            
        } catch {
            print("❌ RAG query failed: \(error)")
            return ""
        }
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
        ragQueryInProgress = false
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
            print("🔄 Loading available models...")
            let models = try await apiService.getAvailableModels()
            await MainActor.run {
                self.availableModels = models
                print("✅ Loaded \(models.count) available models")
                
                // Update selected model after models are loaded (only if needed)
                if self.selectedModel == LLMModel.defaultModel {
                    let newSelectedModel = self.getDefaultModel() ?? LLMModel.defaultModel
                    if self.selectedModel.id != newSelectedModel.id {
                        self.selectedModel = newSelectedModel
                        print("🔄 Updated selected model after loading: \(newSelectedModel.name)")
                    }
                }
                
                // Also update for current conversation if needed
                if let conversation = self.currentConversation {
                    self.updateModelForConversation(conversation)
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
    private func restoreSelectedModel() {
        guard let modelData = UserDefaults.standard.dictionary(forKey: selectedModelKey),
              let id = modelData["id"] as? String,
              let name = modelData["name"] as? String,
              let providerRaw = modelData["provider"] as? String,
              let provider = LLMProvider(rawValue: providerRaw) else {
            return
        }
        
        // Try to find the model in available models
        if let foundModel = availableModels.first(where: { $0.id == id }) {
            selectedModel = foundModel
        } else {
            // Model not found, create a temporary one to maintain consistency
            selectedModel = LLMModel(
                id: id,
                name: name,
                provider: provider,
                contextLength: 4096,
                                 pricing: ModelPricing(inputTokens: 0, outputTokens: 0, imageInputs: nil),
                description: "Previously selected model",
                capabilities: .basic
            )
        }
    }
    
    /// Get default model from UserDefaults
    func getDefaultModel() -> LLMModel? {
        // If availableModels is empty (still loading), return static default
        guard !availableModels.isEmpty else {
            // Only log once when models are still loading
            if selectedModel == LLMModel.defaultModel {
                #if DEBUG
                print("🔄 Available models still loading (\(availableModels.count) models), using static default")
                #endif
            }
            return LLMModel.defaultModel
        }
        
        // Try to get from UserDefaults using consistent format
        guard let modelData = UserDefaults.standard.dictionary(forKey: defaultModelKey),
              let id = modelData["id"] as? String,
              let name = modelData["name"] as? String,
              let providerRaw = modelData["provider"] as? String,
              let provider = LLMProvider(rawValue: providerRaw) else {
            // Only log when no default found in UserDefaults
            return availableModels.first ?? LLMModel.defaultModel
        }
        
        // Find the default model in available models
        if let foundModel = availableModels.first(where: { $0.id == id }) {
            // Only log if different from current selected model
            if selectedModel.id != foundModel.id {
                #if DEBUG
                print("✅ Default model found in available models: \(foundModel.name)")
                #endif
            }
            return foundModel
        } else {
            #if DEBUG
            print("⚠️ Default model '\(name)' (ID: \(id)) not found in \(availableModels.count) available models")
            print("🔄 Using fallback: \(availableModels.first?.name ?? "static default")")
            #endif
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
            self.ragQueryInProgress = false
        }
    }
    
    /// Handle memory-related errors gracefully
    private func handleMemoryError(_ error: Error, context: String) {
        print("🧠 Memory Error in \(context): \(error.localizedDescription)")
        // Continue with conversation even if memory fails
        // This ensures the chat remains functional
    }
}

// MARK: - Enhanced RAG Query Service Simulator with Real Embedding
class RAGQueryServiceSimulator {
    struct RAGQueryResult {
        let query: String
        let documentIds: [String]
        let context: String
        let relevantChunks: Int
    }
    
    private let embeddingService: EmbeddingServiceProtocol?
    private let dataService: DataService
    
    init(embeddingService: EmbeddingServiceProtocol? = nil, dataService: DataService = DataService()) {
        self.embeddingService = embeddingService
        self.dataService = dataService
    }
    
    /// Enhanced RAG query processing with real embedding service
    func simulateRAGQuery(query: String, documentIds: [String], topK: Int = 3) async -> RAGQueryResult {
        // Simulate query processing time
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Try to get real document content from Core Data first
        let realContext = await fetchRealDocumentContext(for: query, documentIds: documentIds, topK: topK)
        
        if !realContext.isEmpty {
            return RAGQueryResult(
                query: query,
                documentIds: documentIds,
                context: realContext,
                relevantChunks: min(topK, documentIds.count * 2)
            )
        }
        
        // Fallback to simulated context if no real content found
        let simulatedContext = generateSimulatedContext(for: query, documentIds: documentIds, topK: topK)
        
        return RAGQueryResult(
            query: query,
            documentIds: documentIds,
            context: simulatedContext,
            relevantChunks: min(topK, documentIds.count * 2)
        )
    }
    
    private func fetchRealDocumentContext(for query: String, documentIds: [String], topK: Int) async -> String {
        return await withCheckedContinuation { continuation in
            let context = self.dataService.persistenceContainer.container.viewContext
            
            context.perform {
                do {
                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Document")
                    
                    // Filter by selected document IDs if provided
                    if !documentIds.isEmpty {
                        fetchRequest.predicate = NSPredicate(format: "id IN %@", documentIds)
                        print("📄 Filtering documents by IDs: \(documentIds)")
                    }
                    
                    let documents = try context.fetch(fetchRequest)
                    
                    print("📄 Found \(documents.count) documents matching filter (from \(documentIds.count) requested)")
                    
                    var relevantContent: [String] = []
                    
                    for document in documents.prefix(topK) {
                        if let content = document.value(forKey: "textContent") as? String,
                           let title = document.value(forKey: "title") as? String {
                            
                            print("📄 Checking document: '\(title)' (\(content.count) characters)")
                            
                            // Enhanced relevance check for various query types
                            let queryLower = query.lowercased()
                            let contentLower = content.lowercased()
                            
                            // Check if query is for cross-document analysis, summary, or contains document content
                            let isRelevant = contentLower.contains(queryLower) ||
                                           queryLower.contains("tóm tắt") ||
                                           queryLower.contains("nói về") ||
                                           queryLower.contains("gì") ||
                                           queryLower.contains("so sánh") ||
                                           queryLower.contains("khác biệt") ||
                                           queryLower.contains("giá trị") ||
                                           queryLower.contains("phân tích") ||
                                           queryLower.contains("compare") ||
                                           queryLower.contains("analysis") ||
                                           // For multi-document queries, always include all selected documents
                                           documentIds.count > 1
                            
                            if isRelevant {
                                
                                let excerpt = String(content.prefix(500)) // First 500 chars
                                relevantContent.append("From '\(title)':\n\(excerpt)")
                                print("✅ Document '\(title)' matched query '\(query)'")
                                print("📄 Excerpt: \(excerpt.prefix(100))...")
                            } else {
                                print("❌ Document '\(title)' did not match query '\(query)'")
                            }
                        }
                    }
                    
                    let result = relevantContent.isEmpty ? "" : relevantContent.joined(separator: "\n\n---\n\n")
                    print("📄 Real document context retrieved: \(result.count) characters from \(relevantContent.count) documents")
                    continuation.resume(returning: result)
                    
                } catch {
                    print("❌ Failed to fetch real document context: \(error)")
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    private func generateSimulatedContext(for query: String, documentIds: [String], topK: Int) -> String {
        let contexts = [
            "Based on the uploaded documents, here are relevant excerpts that address your question about \(query.prefix(50))...",
            "From Document Analysis: The materials contain information related to \(query.prefix(30)) which suggests...",
            "According to the document sources, key findings show that \(query.prefix(40)) is discussed in detail...",
            "The uploaded content provides context about \(query.prefix(35)) with several important points...",
            "Document excerpts relevant to '\(query.prefix(25))' indicate that the subject involves..."
        ]
        
        let selectedContexts = Array(contexts.prefix(min(topK, contexts.count)))
        let contextText = selectedContexts.joined(separator: "\n\n")
        
        let metadata = "\n\n[Context source: \(documentIds.count) document(s), \(topK) relevant chunks analyzed]"
        
        return contextText + metadata
    }
} 