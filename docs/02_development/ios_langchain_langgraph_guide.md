# 🛠️ **LangChain & LangGraph Technical Integration Guide cho OpenChatbot iOS**

**Mục tiêu**: Cung cấp hướng dẫn kỹ thuật chi tiết để tích hợp LangChain và LangGraph vào OpenChatbot iOS hiện tại, tạo foundation cho AI coding assistant có thể tự động implement các tính năng theo roadmap.

## **🏗️ Architecture Overview**

### **Current OpenChatbot Architecture**
```
OpenChatbot/
├── Services/
│   ├── APIService/           # LLM API integration
│   ├── KeychainService/      # Secure storage
│   └── DataService/          # Core Data persistence
├── ViewModels/               # MVVM pattern
├── Views/                    # SwiftUI interfaces
└── Models/                   # Data models
```

### **Target Architecture với LangChain/LangGraph**
```
OpenChatbot/
├── Services/
│   ├── APIService/           # Existing LLM APIs
│   ├── LangChain/            # 🆕 LangChain services
│   │   ├── Core/
│   │   ├── Memory/
│   │   ├── Tools/
│   │   └── Agents/
│   ├── LangGraph/            # 🆕 LangGraph workflows
│   │   ├── Workflows/
│   │   ├── States/
│   │   └── Orchestration/
│   └── Integration/          # 🆕 Bridge services
├── ViewModels/               # Enhanced với AI capabilities
├── Views/                    # Enhanced UI components
└── Models/                   # Extended data models
```

## **📦 Dependencies & Setup**

### **Package Dependencies**
```swift
// Package.swift
dependencies: [
    // Existing dependencies...
    .package(url: "https://github.com/langchain-ai/langchain-swift.git", from: "0.1.0"),
    .package(url: "https://github.com/langchain-ai/langgraph-swift.git", from: "0.1.0"),
    
    // Supporting packages
    .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0")
]
```

### **Import Structure**
```swift
// Core imports for all LangChain/LangGraph files
import LangChain
import LangGraph
import Foundation
import Combine
import SwiftUI
```

## **🔧 Core Integration Layer**

### **1. LangChain Bridge Service**
```swift
// Services/Integration/LangChainBridge.swift
import LangChain

@MainActor
class LangChainBridge: ObservableObject {
    // Bridge existing APIService to LangChain
    private let apiService: LLMAPIService
    private var llmCache: [String: LLM] = [:]
    
    init(apiService: LLMAPIService) {
        self.apiService = apiService
    }
    
    // Convert existing LLMModel to LangChain LLM
    func createLLM(from model: LLMModel, provider: LLMProvider) -> LLM {
        let cacheKey = "\(provider.rawValue)-\(model.id)"
        
        if let cached = llmCache[cacheKey] {
            return cached
        }
        
        let llm = switch provider {
        case .openRouter:
            OpenRouterLLM(
                apiKey: apiService.apiKey,
                model: model.id,
                baseURL: apiService.baseURL
            )
        case .openAI:
            OpenAILLM(
                apiKey: apiService.apiKey,
                model: model.id
            )
        case .anthropic:
            AnthropicLLM(
                apiKey: apiService.apiKey,
                model: model.id
            )
        // Add other providers...
        }
        
        llmCache[cacheKey] = llm
        return llm
    }
    
    // Bridge streaming responses
    func createStreamingLLM(from model: LLMModel, provider: LLMProvider) -> StreamingLLM {
        return StreamingLLM(
            baseLLM: createLLM(from: model, provider: provider),
            streamingCallback: { chunk in
                // Bridge to existing streaming mechanism
                await self.handleStreamingChunk(chunk)
            }
        )
    }
    
    private func handleStreamingChunk(_ chunk: String) async {
        // Integrate with existing streaming UI updates
    }
}
```

### **2. Memory Integration Service**
```swift
// Services/LangChain/Memory/MemoryIntegrationService.swift
import LangChain
import CoreData

class MemoryIntegrationService {
    private let dataService: DataService
    private var memoryCache: [UUID: ConversationBufferMemory] = [:]
    
    init(dataService: DataService) {
        self.dataService = dataService
    }
    
    // Convert Core Data messages to LangChain memory
    func getMemoryForConversation(_ conversationId: UUID) async -> ConversationBufferMemory {
        if let cached = memoryCache[conversationId] {
            return cached
        }
        
        let messages = await dataService.getMessages(for: conversationId)
        let memory = ConversationBufferMemory()
        
        for message in messages {
            let chatMessage = switch message.role {
            case .user:
                HumanMessage(content: message.content)
            case .assistant:
                AIMessage(content: message.content)
            case .system:
                SystemMessage(content: message.content)
            }
            
            memory.chatMemory.addMessage(chatMessage)
        }
        
        memoryCache[conversationId] = memory
        return memory
    }
    
    // Save LangChain memory back to Core Data
    func saveMemory(_ memory: ConversationBufferMemory, for conversationId: UUID) async {
        memoryCache[conversationId] = memory
        
        // Extract new messages from memory and save to Core Data
        let messages = memory.chatMemory.messages
        for message in messages {
            let messageEntity = MessageEntity(context: dataService.context)
            messageEntity.id = UUID()
            messageEntity.content = message.content
            messageEntity.role = MessageRole.from(langChainMessage: message)
            messageEntity.timestamp = Date()
            messageEntity.conversationId = conversationId
        }
        
        await dataService.saveContext()
    }
}
```

### **3. Tools Integration Framework**
```swift
// Services/LangChain/Tools/ToolsIntegrationService.swift
import LangChain

class ToolsIntegrationService {
    private let apiService: LLMAPIService
    
    init(apiService: LLMAPIService) {
        self.apiService = apiService
    }
    
    // Create tool registry based on enabled features
    func createToolRegistry(enabledFeatures: Set) -> [Tool] {
        var tools: [Tool] = []
        
        if enabledFeatures.contains(.webSearch) {
            tools.append(createWebSearchTool())
        }
        
        if enabledFeatures.contains(.calculator) {
            tools.append(createCalculatorTool())
        }
        
        if enabledFeatures.contains(.documentAnalysis) {
            tools.append(createDocumentAnalysisTool())
        }
        
        if enabledFeatures.contains(.iosIntegration) {
            tools.append(contentsOf: createiOSTools())
        }
        
        return tools
    }
    
    private func createWebSearchTool() -> Tool {
        return Tool(
            name: "web_search",
            description: "Search the web for current information about any topic",
            parameters: [
                "query": .string(description: "The search query")
            ]
        ) { parameters in
            guard let query = parameters["query"] as? String else {
                throw ToolError.invalidParameters
            }
            
            return await self.performWebSearch(query: query)
        }
    }
    
    private func createDocumentAnalysisTool() -> Tool {
        return Tool(
            name: "analyze_document",
            description: "Analyze uploaded documents (PDF, images) and extract information",
            parameters: [
                "document_path": .string(description: "Path to the document"),
                "analysis_type": .string(description: "Type of analysis: summary, qa, extraction")
            ]
        ) { parameters in
            guard let documentPath = parameters["document_path"] as? String,
                  let analysisType = parameters["analysis_type"] as? String else {
                throw ToolError.invalidParameters
            }
            
            return await self.analyzeDocument(path: documentPath, type: analysisType)
        }
    }
    
    private func createiOSTools() -> [Tool] {
        return [
            // Contacts tool
            Tool(name: "search_contacts", description: "Search device contacts") { params in
                return await self.searchContacts(query: params["query"] as? String ?? "")
            },
            
            // Calendar tool
            Tool(name: "get_calendar_events", description: "Get calendar events") { params in
                return await self.getCalendarEvents(dateRange: params["date_range"] as? String ?? "today")
            },
            
            // Reminders tool
            Tool(name: "create_reminder", description: "Create a reminder") { params in
                return await self.createReminder(
                    title: params["title"] as? String ?? "",
                    dueDate: params["due_date"] as? String
                )
            }
        ]
    }
}

enum ToolFeature: String, CaseIterable {
    case webSearch = "web_search"
    case calculator = "calculator"
    case documentAnalysis = "document_analysis"
    case iosIntegration = "ios_integration"
    case codeGeneration = "code_generation"
}
```

## **🔄 LangGraph Workflow Integration**

### **1. Workflow State Management**
```swift
// Services/LangGraph/States/WorkflowState.swift
import LangGraph

// Base state for all workflows
struct BaseWorkflowState: Codable {
    var conversationId: UUID
    var messages: [ChatMessage]
    var currentStep: String
    var metadata: [String: Any]
    var error: String?
    var needsHumanApproval: Bool
    
    // Workflow-specific data
    var toolResults: [String: Any]
    var documentPaths: [String]
    var searchResults: [String]
    var analysisResults: [String: Any]
}

// Specialized states for different workflows
struct DocumentAnalysisState: Codable {
    var baseState: BaseWorkflowState
    var documentType: DocumentType
    var extractedText: String?
    var analysisType: AnalysisType
    var chunks: [DocumentChunk]
    var embeddings: [Float]?
}

struct ResearchWorkflowState: Codable {
    var baseState: BaseWorkflowState
    var researchQuery: String
    var sources: [ResearchSource]
    var synthesizedResult: String?
    var confidenceScore: Float
}
```

### **2. Workflow Factory**
```swift
// Services/LangGraph/Workflows/WorkflowFactory.swift
import LangGraph

class WorkflowFactory {
    private let langChainBridge: LangChainBridge
    private let toolsService: ToolsIntegrationService
    private let memoryService: MemoryIntegrationService
    
    init(
        langChainBridge: LangChainBridge,
        toolsService: ToolsIntegrationService,
        memoryService: MemoryIntegrationService
    ) {
        self.langChainBridge = langChainBridge
        self.toolsService = toolsService
        self.memoryService = memoryService
    }
    
    // Create workflow based on user intent
    func createWorkflow(for intent: WorkflowIntent) -> StateGraph {
        switch intent {
        case .simpleChat:
            return createSimpleChatWorkflow()
        case .documentAnalysis:
            return createDocumentAnalysisWorkflow()
        case .webResearch:
            return createResearchWorkflow()
        case .multiAgent:
            return createMultiAgentWorkflow()
        }
    }
    
    private func createSimpleChatWorkflow() -> StateGraph {
        let workflow = StateGraph()
        
        // Define nodes
        workflow.addNode("load_memory", loadMemoryNode)
        workflow.addNode("process_message", processMessageNode)
        workflow.addNode("generate_response", generateResponseNode)
        workflow.addNode("save_memory", saveMemoryNode)
        
        // Define flow
        workflow.setEntryPoint("load_memory")
        workflow.addEdge("load_memory", "process_message")
        workflow.addEdge("process_message", "generate_response")
        workflow.addEdge("generate_response", "save_memory")
        
        return workflow
    }
    
    private func createDocumentAnalysisWorkflow() -> StateGraph {
        let workflow = StateGraph()
        
        // Define nodes
        workflow.addNode("validate_document", validateDocumentNode)
        workflow.addNode("extract_text", extractTextNode)
        workflow.addNode("chunk_document", chunkDocumentNode)
        workflow.addNode("analyze_content", analyzeContentNode)
        workflow.addNode("generate_summary", generateSummaryNode)
        workflow.addNode("create_embeddings", createEmbeddingsNode)
        
        // Define conditional flow
        workflow.setEntryPoint("validate_document")
        
        workflow.addConditionalEdges(
            "validate_document",
            documentValidationCondition,
            [
                "valid": "extract_text",
                "invalid": "END"
            ]
        )
        
        workflow.addEdge("extract_text", "chunk_document")
        workflow.addEdge("chunk_document", "analyze_content")
        workflow.addEdge("analyze_content", "generate_summary")
        workflow.addEdge("generate_summary", "create_embeddings")
        
        return workflow
    }
    
    private func createResearchWorkflow() -> StateGraph {
        let workflow = StateGraph()
        
        // Multi-step research process
        workflow.addNode("analyze_query", analyzeQueryNode)
        workflow.addNode("web_search", webSearchNode)
        workflow.addNode("filter_results", filterResultsNode)
        workflow.addNode("synthesize_information", synthesizeInformationNode)
        workflow.addNode("fact_check", factCheckNode)
        workflow.addNode("generate_report", generateReportNode)
        
        // Define research flow with quality checks
        workflow.setEntryPoint("analyze_query")
        workflow.addEdge("analyze_query", "web_search")
        workflow.addEdge("web_search", "filter_results")
        workflow.addEdge("filter_results", "synthesize_information")
        
        workflow.addConditionalEdges(
            "synthesize_information",
            qualityCheckCondition,
            [
                "needs_more_info": "web_search",  // Loop back for more info
                "sufficient": "fact_check"
            ]
        )
        
        workflow.addEdge("fact_check", "generate_report")
        
        return workflow
    }
}

enum WorkflowIntent {
    case simpleChat
    case documentAnalysis
    case webResearch
    case multiAgent
}
```

### **3. Workflow Execution Service**
```swift
// Services/LangGraph/Orchestration/WorkflowExecutionService.swift
import LangGraph

@MainActor
class WorkflowExecutionService: ObservableObject {
    @Published var currentWorkflow: StateGraph?
    @Published var workflowState: BaseWorkflowState?
    @Published var isExecuting: Bool = false
    @Published var executionProgress: Float = 0.0
    
    private let workflowFactory: WorkflowFactory
    private var executionTask: Task?
    
    init(workflowFactory: WorkflowFactory) {
        self.workflowFactory = workflowFactory
    }
    
    func executeWorkflow(
        intent: WorkflowIntent,
        initialState: BaseWorkflowState
    ) async throws -> BaseWorkflowState {
        
        isExecuting = true
        executionProgress = 0.0
        
        defer {
            isExecuting = false
            executionProgress = 1.0
        }
        
        let workflow = workflowFactory.createWorkflow(for: intent)
        currentWorkflow = workflow
        workflowState = initialState
        
        // Execute workflow with progress tracking
        let result = try await workflow.invoke(
            initialState,
            config: WorkflowConfig(
                progressCallback: { progress in
                    await MainActor.run {
                        self.executionProgress = progress
                    }
                },
                stateCallback: { state in
                    await MainActor.run {
                        self.workflowState = state
                    }
                }
            )
        )
        
        return result
    }
    
    func cancelExecution() {
        executionTask?.cancel()
        isExecuting = false
    }
    
    // Human-in-the-loop support
    func requestHumanApproval(for action: String) async -> Bool {
        workflowState?.needsHumanApproval = true
        
        // Wait for user response through UI
        return await withCheckedContinuation { continuation in
            // UI will call continuation.resume(returning: true/false)
        }
    }
}
```

## **🔌 Integration Points với Existing Code**

### **1. Enhanced ChatViewModel**
```swift
// ViewModels/ChatViewModel.swift - Enhanced version
@MainActor
class ChatViewModel: ObservableObject {
    // Existing properties...
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    
    // New LangChain/LangGraph properties
    @Published var isUsingAIWorkflow: Bool = false
    @Published var currentWorkflowStep: String = ""
    @Published var workflowProgress: Float = 0.0
    @Published var availableTools: [ToolFeature] = []
    
    // Services
    private let apiService: LLMAPIService
    private let dataService: DataService
    
    // New AI services
    private let langChainBridge: LangChainBridge
    private let workflowExecutionService: WorkflowExecutionService
    private let memoryService: MemoryIntegrationService
    
    init(
        apiService: LLMAPIService,
        dataService: DataService,
        langChainBridge: LangChainBridge,
        workflowExecutionService: WorkflowExecutionService,
        memoryService: MemoryIntegrationService
    ) {
        self.apiService = apiService
        self.dataService = dataService
        self.langChainBridge = langChainBridge
        self.workflowExecutionService = workflowExecutionService
        self.memoryService = memoryService
        
        setupWorkflowObservation()
    }
    
    func sendMessage() async {
        guard !messageText.isEmpty else { return }
        
        let userMessage = messageText
        messageText = ""
        
        await addMessage(content: userMessage, role: .user)
        
        if isUsingAIWorkflow {
            await executeAIWorkflow(userMessage)
        } else {
            await executeSimpleChat(userMessage)
        }
    }
    
    private func executeAIWorkflow(_ message: String) async {
        do {
            let intent = determineWorkflowIntent(from: message)
            let initialState = BaseWorkflowState(
                conversationId: currentConversation.id,
                messages: messages,
                currentStep: "",
                metadata: [:],
                error: nil,
                needsHumanApproval: false,
                toolResults: [:],
                documentPaths: [],
                searchResults: [],
                analysisResults: [:]
            )
            
            let result = try await workflowExecutionService.executeWorkflow(
                intent: intent,
                initialState: initialState
            )
            
            // Update UI with workflow results
            messages = result.messages
            
        } catch {
            await handleError(error)
        }
    }
    
    private func determineWorkflowIntent(from message: String) -> WorkflowIntent {
        // Use LLM to classify user intent
        // This could be enhanced with a dedicated intent classification model
        
        if message.contains("analyze") || message.contains("document") {
            return .documentAnalysis
        } else if message.contains("search") || message.contains("research") {
            return .webResearch
        } else {
            return .simpleChat
        }
    }
    
    private func setupWorkflowObservation() {
        // Observe workflow execution state
        workflowExecutionService.$workflowState
            .compactMap { $0 }
            .sink { [weak self] state in
                self?.currentWorkflowStep = state.currentStep
            }
            .store(in: &cancellables)
        
        workflowExecutionService.$executionProgress
            .assign(to: &$workflowProgress)
    }
}
```

### **2. Enhanced SettingsViewModel**
```swift
// ViewModels/SettingsViewModel.swift - Enhanced version
@MainActor
class SettingsViewModel: ObservableObject {
    // Existing properties...
    
    // New AI configuration
    @Published var enabledTools: Set = []
    @Published var workflowPreferences: WorkflowPreferences = WorkflowPreferences()
    @Published var aiCapabilities: AICapabilities = AICapabilities()
    
    private let toolsService: ToolsIntegrationService
    
    func updateToolConfiguration() async {
        // Update available tools based on user preferences
        let tools = toolsService.createToolRegistry(enabledFeatures: enabledTools)
        
        // Notify other services about tool changes
        NotificationCenter.default.post(
            name: .toolsConfigurationChanged,
            object: tools
        )
    }
    
    func testAICapabilities() async {
        // Test LangChain/LangGraph integration
        do {
            let testResult = try await performCapabilityTest()
            aiCapabilities = testResult
        } catch {
            // Handle test failures
        }
    }
}

struct WorkflowPreferences: Codable {
    var autoSelectWorkflow: Bool = true
    var requireHumanApproval: Bool = false
    var maxWorkflowSteps: Int = 10
    var timeoutSeconds: Int = 300
}

struct AICapabilities: Codable {
    var langChainAvailable: Bool = false
    var langGraphAvailable: Bool = false
    var availableTools: [String] = []
    var memoryEnabled: Bool = false
    var workflowsEnabled: Bool = false
}
```

## **📱 UI Integration Components**

### **1. Workflow Status Component**
```swift
// Views/Components/WorkflowStatusView.swift
struct WorkflowStatusView: View {
    let currentStep: String
    let progress: Float
    let isExecuting: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                
                Text("AI Workflow")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isExecuting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if !currentStep.isEmpty {
                HStack {
                    Text(currentStep.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
```

### **2. Tools Configuration View**
```swift
// Views/Settings/ToolsConfigurationView.swift
struct ToolsConfigurationView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Available Tools") {
                ForEach(ToolFeature.allCases, id: \.self) { tool in
                    Toggle(tool.displayName, isOn: Binding(
                        get: { settingsViewModel.enabledTools.contains(tool) },
                        set: { isEnabled in
                            if isEnabled {
                                settingsViewModel.enabledTools.insert(tool)
                            } else {
                                settingsViewModel.enabledTools.remove(tool)
                            }
                        }
                    ))
                    .onChange(of: settingsViewModel.enabledTools) { _ in
                        Task {
                            await settingsViewModel.updateToolConfiguration()
                        }
                    }
                }
            }
            
            Section("Workflow Preferences") {
                Toggle("Auto-select Workflow", isOn: $settingsViewModel.workflowPreferences.autoSelectWorkflow)
                Toggle("Require Human Approval", isOn: $settingsViewModel.workflowPreferences.requireHumanApproval)
                
                Stepper("Max Steps: \(settingsViewModel.workflowPreferences.maxWorkflowSteps)", 
                       value: $settingsViewModel.workflowPreferences.maxWorkflowSteps, 
                       in: 1...20)
            }
            
            Section("AI Capabilities") {
                Button("Test AI Integration") {
                    Task {
                        await settingsViewModel.testAICapabilities()
                    }
                }
                
                if settingsViewModel.aiCapabilities.langChainAvailable {
                    Label("LangChain Available", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                if settingsViewModel.aiCapabilities.langGraphAvailable {
                    Label("LangGraph Available", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("AI Configuration")
    }
}

extension ToolFeature {
    var displayName: String {
        switch self {
        case .webSearch:
            return "Web Search"
        case .calculator:
            return "Calculator"
        case .documentAnalysis:
            return "Document Analysis"
        case .iosIntegration:
            return "iOS Integration"
        case .codeGeneration:
            return "Code Generation"
        }
    }
}
```

## **🔄 Service Dependency Injection**

### **1. Service Container**
```swift
// Services/ServiceContainer.swift
class ServiceContainer {
    static let shared = ServiceContainer()
    
    // Existing services
    lazy var apiService: LLMAPIService = OpenRouterAPIService()
    lazy var dataService: DataService = DataService()
    lazy var keychainService: KeychainService = KeychainService()
    
    // New AI services
    lazy var langChainBridge: LangChainBridge = LangChainBridge(apiService: apiService)
    
    lazy var memoryService: MemoryIntegrationService = MemoryIntegrationService(
        dataService: dataService
    )
    
    lazy var toolsService: ToolsIntegrationService = ToolsIntegrationService(
        apiService: apiService
    )
    
    lazy var workflowFactory: WorkflowFactory = WorkflowFactory(
        langChainBridge: langChainBridge,
        toolsService: toolsService,
        memoryService: memoryService
    )
    
    lazy var workflowExecutionService: WorkflowExecutionService = WorkflowExecutionService(
        workflowFactory: workflowFactory
    )
    
    private init() {}
}
```

### **2. App Initialization**
```swift
// OpenChatbotApp.swift
@main
struct OpenChatbotApp: App {
    let serviceContainer = ServiceContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer.apiService)
                .environmentObject(serviceContainer.dataService)
                .environmentObject(serviceContainer.langChainBridge)
                .environmentObject(serviceContainer.workflowExecutionService)
        }
    }
}
```

## **🧪 Testing Strategy**

### **1. Unit Tests cho AI Services**
```swift
// Tests/LangChainIntegrationTests.swift
import XCTest
@testable import OpenChatbot

class LangChainIntegrationTests: XCTestCase {
    var langChainBridge: LangChainBridge!
    var mockAPIService: MockLLMAPIService!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockLLMAPIService()
        langChainBridge = LangChainBridge(apiService: mockAPIService)
    }
    
    func testLLMCreation() {
        let model = LLMModel(id: "gpt-4", name: "GPT-4")
        let llm = langChainBridge.createLLM(from: model, provider: .openAI)
        
        XCTAssertNotNil(llm)
        XCTAssertEqual(llm.modelName, "gpt-4")
    }
    
    func testMemoryIntegration() async throws {
        let conversationId = UUID()
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        XCTAssertNotNil(memory)
        XCTAssertEqual(memory.chatMemory.messages.count, 0)
    }
    
    func testWorkflowExecution() async throws {
        let initialState = BaseWorkflowState(
            conversationId: UUID(),
            messages: [],
            currentStep: "",
            metadata: [:],
            error: nil,
            needsHumanApproval: false,
            toolResults: [:],
            documentPaths: [],
            searchResults: [],
            analysisResults: [:]
        )
        
        let result = try await workflowExecutionService.executeWorkflow(
            intent: .simpleChat,
            initialState: initialState
        )
        
        XCTAssertEqual(result.currentStep, "finalize")
        XCTAssertNil(result.error)
    }
}
```

## **📊 Performance Monitoring**

### **1. AI Performance Metrics**
```swift
// Services/Monitoring/AIPerformanceMonitor.swift
class AIPerformanceMonitor {
    static let shared = AIPerformanceMonitor()
    
    private var metrics: [String: Any] = [:]
    
    func trackWorkflowExecution(
        intent: WorkflowIntent,
        duration: TimeInterval,
        stepsExecuted: Int,
        success: Bool
    ) {
        let metric = WorkflowMetric(
            intent: intent,
            duration: duration,
            stepsExecuted: stepsExecuted,
            success: success,
            timestamp: Date()
        )
        
        // Store metrics for analysis
        storeMetric(metric)
    }
    
    func trackToolUsage(tool: ToolFeature, duration: TimeInterval, success: Bool) {
        let metric = ToolUsageMetric(
            tool: tool,
            duration: duration,
            success: success,
            timestamp: Date()
        )
        
        storeMetric(metric)
    }
    
    func getPerformanceReport() -> AIPerformanceReport {
        // Generate comprehensive performance report
        return AIPerformanceReport(metrics: metrics)
    }
}
```

## **🚀 Deployment Checklist**

### **1. Pre-deployment Verification**
```swift
// Services/Deployment/DeploymentChecker.swift
class DeploymentChecker {
    func verifyAIIntegration() async -> DeploymentStatus {
        var status = DeploymentStatus()
        
        // Check LangChain integration
        status.langChainAvailable = await testLangChainIntegration()
        
        // Check LangGraph workflows
        status.langGraphAvailable = await testLangGraphWorkflows()
        
        // Check tool availability
        status.toolsAvailable = await testToolsIntegration()
        
        // Check memory system
        status.memorySystemWorking = await testMemorySystem()
        
        return status
    }
}

struct DeploymentStatus {
    var langChainAvailable: Bool = false
    var langGraphAvailable: Bool = false
    var toolsAvailable: Bool = false
    var memorySystemWorking: Bool = false
    
    var isReadyForDeployment: Bool {
        return langChainAvailable && langGraphAvailable && toolsAvailable && memorySystemWorking
    }
}
```

## **🎯 Implementation Priorities**

### **Phase 1: Core Integration (Week 1)**
1. ✅ Setup dependencies và imports
2. ✅ Implement LangChainBridge
3. ✅ Basic memory integration
4. ✅ Simple workflow execution

### **Phase 2: Tools & Workflows (Week 2)**
1. ✅ Tools integration framework
2. ✅ Basic workflow factory
3. ✅ UI components for workflow status
4. ✅ Settings integration

### **Phase 3: Advanced Features (Week 3)**
1. ✅ Complex workflow patterns
2. ✅ Human-in-the-loop integration
3. ✅ Performance monitoring
4. ✅ Testing framework

**Kết luận**: Guide này cung cấp foundation kỹ thuật hoàn chỉnh để tích hợp LangChain và LangGraph vào OpenChatbot iOS. Coding AI có thể sử dụng guide này như reference để implement các tính năng theo roadmap, với architecture đã được thiết kế để scale và mở rộng dễ dàng.