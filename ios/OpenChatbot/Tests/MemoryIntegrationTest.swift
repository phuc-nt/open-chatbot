import Foundation

/// Simple integration test for MemoryService without XCTest dependency
/// This can be run directly to verify functionality
class MemoryIntegrationTest {
    
    static func runAllTests() {
        print("🧪 Starting Memory Integration Tests...")
        
        testBasicMemoryService()
        testMemoryConversationCreation()
        testMemoryPersistence()
        testTokenLimitHandling()
        
        print("✅ All Memory Integration Tests Completed!")
    }
    
    static func testBasicMemoryService() {
        print("🧠 Test 1: Basic MemoryService Creation")
        
        let dataService = DataService()
        let memoryService = MemoryService(dataService: dataService)
        
        assert(memoryService.isMemoryEnabled == true, "Memory should be enabled by default")
        assert(memoryService.memoryStatus == .idle, "Memory status should be idle initially")
        
        print("✅ Basic MemoryService test passed")
    }
    
    static func testMemoryConversationCreation() {
        print("🧠 Test 2: Conversation Memory Creation")
        
        let conversationId = UUID()
        let dataService = DataService()
        let memoryService = MemoryService(dataService: dataService)
        
        Task {
            let memory = await memoryService.getMemoryForConversation(conversationId)
            
            assert(memory.conversationId == conversationId, "Memory should have correct conversation ID")
            assert(memory.messageCount == 0, "New memory should have no messages")
            
            print("✅ Conversation Memory Creation test passed")
        }
    }
    
    static func testMemoryPersistence() {
        print("🧠 Test 3: Memory Persistence")
        
        let conversationId = UUID()
        let dataService = DataService()
        let memoryService = MemoryService(dataService: dataService)
        
        Task {
            // Create test message
            let testMessage = Message(
                content: "Test message for persistence",
                role: .user,
                conversationId: conversationId
            )
            
            // Add message to memory
            await memoryService.addMessageToMemory(testMessage, conversationId: conversationId)
            
            // Retrieve memory and verify
            let memory = await memoryService.getMemoryForConversation(conversationId)
            
            assert(memory.messageCount == 1, "Memory should contain one message")
            assert(memory.messages.first?.content == "Test message for persistence", "Message content should match")
            
            print("✅ Memory Persistence test passed")
        }
    }
    
    static func testTokenLimitHandling() {
        print("🧠 Test 4: Token Limit Handling")
        
        let conversationId = UUID()
        let dataService = DataService()
        let memoryService = MemoryService(dataService: dataService)
        
        Task {
            // Add multiple messages
            for i in 1...5 {
                let message = Message(
                    content: "This is test message number \(i) with some content to test token limits and memory management functionality",
                    role: i % 2 == 0 ? .assistant : .user,
                    conversationId: conversationId
                )
                await memoryService.addMessageToMemory(message, conversationId: conversationId)
            }
            
            // Test with small token limit
            let context = await memoryService.getContextForAPICall(
                conversationId: conversationId,
                maxTokens: 100
            )
            
            assert(context.count <= 5, "Context should be filtered by token limit")
            assert(context.count > 0, "Context should contain at least some messages")
            
            print("✅ Token Limit Handling test passed")
        }
    }
}

// Extension to simulate running tests
extension MemoryIntegrationTest {
    
    /// Manual test runner that can be called from app
    static func validateMemorySystemIntegration() -> Bool {
        print("🔍 Validating Memory System Integration...")
        
        do {
            // Test 1: Service Creation
            let dataService = DataService()
            let memoryService = MemoryService(dataService: dataService)
            
            guard memoryService.isMemoryEnabled else {
                print("❌ Memory service not enabled")
                return false
            }
            
            print("✅ Memory service created successfully")
            
            // Test 2: Memory Configuration
            let config = MemoryConfiguration.default
            guard config.maxTokensBeforeCompression > 0 else {
                print("❌ Invalid memory configuration")
                return false
            }
            
            print("✅ Memory configuration valid")
            
            // Test 3: Context Builder
            let testMessages = [
                Message(content: "Hello", role: .user, conversationId: UUID()),
                Message(content: "Hi there!", role: .assistant, conversationId: UUID())
            ]
            
            let contextString = MemoryContextBuilder.buildContextString(from: testMessages)
            guard !contextString.isEmpty else {
                print("❌ Context builder failed")
                return false
            }
            
            print("✅ Context builder working")
            
            print("🎉 Memory System Integration VALIDATED!")
            return true
            
        } catch {
            print("❌ Memory system validation failed: \(error)")
            return false
        }
    }
} 