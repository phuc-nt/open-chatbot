import Foundation
import SwiftUI

/// Demo service to showcase ConversationBufferMemory integration
/// This demonstrates how the memory system works similar to LangChain
class MemoryIntegrationDemo: ObservableObject {
    
    @Published var demoResults: [String] = []
    @Published var isRunning: Bool = false
    
    private var memoryService: MemoryService?
    
    private func getMemoryService() async -> MemoryService {
        if memoryService == nil {
            memoryService = await MemoryService()
        }
        return memoryService!
    }
    
    /// Run a comprehensive demo of memory functionality
    func runMemoryDemo() async {
        await MainActor.run {
            isRunning = true
            demoResults = ["🧠 Starting Memory Integration Demo..."]
        }
        
        let conversationId = UUID()
        
        // Demo 1: Basic Memory Operations
        await demoBasicMemoryOperations(conversationId: conversationId)
        
        // Demo 2: Token Limit Handling
        await demoTokenLimitHandling(conversationId: conversationId)
        
        // Demo 3: Memory Statistics
        await demoMemoryStatistics(conversationId: conversationId)
        
        await MainActor.run {
            demoResults.append("✅ Memory Integration Demo Completed!")
            isRunning = false
        }
    }
    
    private func demoBasicMemoryOperations(conversationId: UUID) async {
        await addDemoResult("📝 Demo 1: Basic Memory Operations")
        
        // Create test messages
        let messages = [
            createTestMessage("Hello! I'm starting a conversation about iOS development.", role: .user, conversationId: conversationId),
            createTestMessage("Hi! I'd be happy to help you with iOS development. What specific topic are you interested in?", role: .assistant, conversationId: conversationId),
            createTestMessage("I want to learn about SwiftUI and memory management.", role: .user, conversationId: conversationId),
            createTestMessage("Great choice! SwiftUI is Apple's modern UI framework. For memory management, you should understand ARC (Automatic Reference Counting).", role: .assistant, conversationId: conversationId)
        ]
        
        let memoryService = await getMemoryService()
        
        // Add messages to memory
        for message in messages {
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
            await addDemoResult("  ➕ Added \(message.role.rawValue) message to memory")
        }
        
        // Get memory for conversation
        let memory = await memoryService.getMemoryForConversation(conversationId)
        await addDemoResult("  📊 Memory loaded: \(memory.messageCount) messages")
        
        // Get context for API call
        let context = await memoryService.getContextForAPICall(conversationId: conversationId, maxTokens: 4000)
        await addDemoResult("  🎯 Context retrieved: \(context.count) messages for API call")
    }
    
    private func demoTokenLimitHandling(conversationId: UUID) async {
        await addDemoResult("\n🎯 Demo 2: Token Limit Handling")
        
        // Add many more messages to test token limiting
        let memoryService = await getMemoryService()
        for i in 5...15 {
            let longMessage = "This is a longer message number \(i) that contains more content to demonstrate how the memory system handles token limits. It includes information about iOS development, SwiftUI patterns, and best practices for building robust applications."
            
            let message = createTestMessage(longMessage, role: i % 2 == 0 ? .assistant : .user, conversationId: conversationId)
            await memoryService.addMessageToMemory(message, conversationId: conversationId)
        }
        
        // Test different token limits
        let tokenLimits = [100, 500, 1000, 4000]
        for limit in tokenLimits {
            let context = await memoryService.getContextForAPICall(conversationId: conversationId, maxTokens: limit)
            await addDemoResult("  📏 Token limit \(limit): \(context.count) messages in context")
        }
    }
    
    private func demoMemoryStatistics(conversationId: UUID) async {
        await addDemoResult("\n📈 Demo 3: Memory Statistics")
        
        let memoryService = await getMemoryService()
        let stats = await memoryService.getMemoryStats(for: conversationId)
        await addDemoResult("  📊 Total messages: \(stats.messageCount)")
        await addDemoResult("  🎯 Estimated tokens: \(stats.estimatedTokens)")
        await addDemoResult("  💾 Cache status: \(stats.cacheStatus)")
        await addDemoResult("  ⏰ Last updated: \(stats.lastUpdated.formatted())")
        
        // Test memory clearing
        await memoryService.clearMemory(for: conversationId)
        await addDemoResult("  🗑️ Memory cache cleared")
        
        // Reload memory to show persistence
        let memory = await memoryService.getMemoryForConversation(conversationId)
        await addDemoResult("  🔄 Memory reloaded: \(memory.messageCount) messages (from persistent storage)")
    }
    
    private func createTestMessage(_ content: String, role: MessageRole, conversationId: UUID) -> Message {
        return Message(content: content, role: role, conversationId: conversationId)
    }
    
    @MainActor
    private func addDemoResult(_ result: String) async {
        demoResults.append(result)
        print(result) // Also log to console
    }
}

// MARK: - SwiftUI Demo View

struct MemoryDemoView: View {
    @StateObject private var demo = MemoryIntegrationDemo()
    
    var body: some View {
        NavigationView {
            VStack {
                if demo.isRunning {
                    ProgressView("Running Memory Demo...")
                        .padding()
                } else {
                    Button("Run Memory Demo") {
                        Task {
                            await demo.runMemoryDemo()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(demo.demoResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Memory Demo")
        }
    }
}

// MARK: - Usage Example

extension MemoryIntegrationDemo {
    
    /// Example of how to integrate memory with existing ChatViewModel
    static func integrateWithChatViewModel() {
        print("""
        🧠 Memory Integration Example:
        
        // In ChatViewModel init:
        private let memoryService = MemoryService()
        
        // When sending message:
        func sendMessage() async {
            let userMessage = Message(content: messageText, role: .user, conversationId: currentConversation.id)
            
            // Add to memory
            await memoryService.addMessageToMemory(userMessage, conversationId: currentConversation.id!)
            
            // Get context for API call
            let context = await memoryService.getContextForAPICall(
                conversationId: currentConversation.id!, 
                maxTokens: selectedModel.contextWindow
            )
            
            // Use context in API call
            let response = try await apiService.sendStreamingMessage(
                contextualMessage: context,
                model: selectedModel
            )
        }
        """)
    }
} 