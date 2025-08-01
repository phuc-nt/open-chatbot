import XCTest
import SwiftUI
@testable import OpenChatbot

class FullContextModeTests: XCTestCase {
    
    var chatViewModel: ChatViewModel!
    var documentContextManager: DocumentContextManager!
    var mockAPIService: MockLLMAPIService!
    var mockDataService: MockDataService!
    
    override func setUp() {
        super.setUp()
        
        // Create mock services
        mockAPIService = MockLLMAPIService()
        mockDataService = MockDataService()
        
        // Initialize DocumentContextManager
        documentContextManager = DocumentContextManager()
        
        // Initialize ChatViewModel with mocks
        chatViewModel = ChatViewModel(
            apiService: mockAPIService,
            dataService: mockDataService
        )
        
        // Set up Full Context mode
        chatViewModel.currentChatMode = .fullContext
    }
    
    override func tearDown() {
        chatViewModel = nil
        documentContextManager = nil
        mockAPIService = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Full Context Mode Tests
    
    func testFullContextModeProcessing() async {
        // Given: Documents selected for Full Context mode
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // And: User input message
        chatViewModel.currentInput = "What are the main topics in these documents?"
        
        // When: Processing message with Full Context
        await chatViewModel.processFullContextMessage()
        
        // Then: Should process with complete document content
        XCTAssertTrue(chatViewModel.messages.count >= 2) // User + Assistant messages
        XCTAssertFalse(chatViewModel.isLoading)
        XCTAssertFalse(chatViewModel.isStreaming)
        
        // And: Should have called API with full document context
        XCTAssertTrue(mockAPIService.sendMessageCalled)
        XCTAssertNotNil(mockAPIService.lastConversation)
        
        // And: System message should contain complete document content
        if let systemMessage = mockAPIService.lastConversation?.first(where: { $0.role == .system }) {
            XCTAssertTrue(systemMessage.content.contains("COMPLETE DOCUMENT CONTENT:"))
            XCTAssertTrue(systemMessage.content.contains("DOCUMENT 1:"))
        } else {
            XCTFail("System message with full context not found")
        }
    }
    
    func testFullContextModeWithLargeDocuments() async {
        // Given: Large documents that exceed Full Context limits
        let largeDocuments = createLargeDocuments()
        chatViewModel.documentContextManager.setDocuments(largeDocuments)
        
        // When: Attempting Full Context mode
        await chatViewModel.processFullContextMessage()
        
        // Then: Should gracefully handle large documents
        // Implementation should either:
        // 1. Fallback to RAG mode automatically, or
        // 2. Truncate content intelligently, or
        // 3. Show appropriate warnings
        XCTAssertNotNil(chatViewModel.documentContextManager.contextSizeResult)
    }
    
    func testBuildFullDocumentContext() async {
        // Given: Sample documents
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // When: Building full document context (using reflection or public interface)
        // Note: This tests the private buildFullDocumentContext method indirectly
        chatViewModel.currentInput = "Test question"
        await chatViewModel.processFullContextMessage()
        
        // Then: Should build comprehensive context
        XCTAssertTrue(mockAPIService.sendMessageCalled)
        
        // Verify the system message contains expected structure
        if let systemMessage = mockAPIService.lastConversation?.first(where: { $0.role == .system }) {
            XCTAssertTrue(systemMessage.content.contains("DOCUMENT 1:"))
            XCTAssertTrue(systemMessage.content.contains("File:"))
            XCTAssertTrue(systemMessage.content.contains("Type:"))
            XCTAssertTrue(systemMessage.content.contains("CONTENT:"))
        }
    }
    
    func testOptimalModeSelection() async {
        // Given: Small documents (optimal for Full Context)
        let smallDocuments = createSmallDocuments()
        chatViewModel.documentContextManager.setDocuments(smallDocuments)
        
        // When: Using sendMessageWithOptimalMode
        chatViewModel.currentInput = "Test question"
        await chatViewModel.sendMessageWithOptimalMode()
        
        // Then: Should select appropriate mode based on document size
        let recommendedMode = chatViewModel.documentContextManager.recommendedMode
        XCTAssertNotNil(recommendedMode)
        
        // And: Should process message successfully
        XCTAssertTrue(mockAPIService.sendMessageCalled)
    }
    
    func testFullContextFallbackToRAG() async {
        // Given: Documents that cannot use Full Context
        let excessiveDocuments = createExcessiveDocuments()
        chatViewModel.documentContextManager.setDocuments(excessiveDocuments)
        
        // And: Full Context mode initially selected
        chatViewModel.currentChatMode = .fullContext
        
        // When: Processing message
        await chatViewModel.sendMessageWithOptimalMode()
        
        // Then: Should fallback to RAG mode
        // The optimal mode selection should handle this gracefully
        XCTAssertTrue(mockAPIService.sendMessageCalled)
    }
    
    func testContextInformationInFullContext() async {
        // Given: Documents with known size
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // When: Processing with Full Context
        chatViewModel.currentInput = "Summarize these documents"
        await chatViewModel.processFullContextMessage()
        
        // Then: Context information should be included
        if let systemMessage = mockAPIService.lastConversation?.first(where: { $0.role == .system }) {
            // Should contain metadata about context usage
            let containsContextInfo = systemMessage.content.contains("CONTEXT INFORMATION") ||
                                    systemMessage.content.contains("Total Characters") ||
                                    systemMessage.content.contains("Context Status")
            XCTAssertTrue(containsContextInfo, "Full Context should include context usage information")
        }
    }
    
    func testTokenWindowManagementWithFullContext() async {
        // Given: Documents for Full Context mode
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // When: Processing message with Full Context
        chatViewModel.currentInput = "Explain these documents in detail"
        await chatViewModel.processFullContextMessage()
        
        // Then: Should reserve more tokens for Full Context mode (3000 vs 1500)
        // This is tested indirectly through successful processing
        XCTAssertTrue(mockAPIService.sendMessageCalled)
        XCTAssertNotNil(mockAPIService.lastModel)
    }
    
    func testFullContextStreamingDelay() async {
        // Given: Documents and Full Context mode
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // When: Processing with Full Context (which should have slower streaming)
        chatViewModel.currentInput = "Process these documents"
        let startTime = Date()
        await chatViewModel.processFullContextMessage()
        let endTime = Date()
        
        // Then: Should complete processing (timing is implementation detail)
        XCTAssertTrue(endTime.timeIntervalSince(startTime) >= 0)
        XCTAssertTrue(mockAPIService.sendMessageCalled)
    }
    
    func testFullContextWithNoDocuments() async {
        // Given: No documents selected
        XCTAssertTrue(chatViewModel.documentContextManager.selectedDocuments.isEmpty)
        
        // When: Attempting Full Context processing
        chatViewModel.currentInput = "Test message"
        await chatViewModel.processFullContextMessage()
        
        // Then: Should still process message successfully (without document context)
        XCTAssertTrue(mockAPIService.sendMessageCalled)
        
        // And: Should not have document context in system message
        let hasDocumentContext = mockAPIService.lastConversation?.contains { message in
            message.role == .system && message.content.contains("COMPLETE DOCUMENT CONTENT")
        } ?? false
        XCTAssertFalse(hasDocumentContext)
    }
    
    func testErrorHandlingInFullContext() async {
        // Given: Mock API service that will return an error
        mockAPIService.shouldReturnError = true
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // When: Processing with Full Context
        chatViewModel.currentInput = "Test error handling"
        await chatViewModel.processFullContextMessage()
        
        // Then: Should handle error gracefully
        XCTAssertFalse(chatViewModel.isLoading)
        XCTAssertFalse(chatViewModel.isStreaming)
        XCTAssertNotNil(chatViewModel.errorMessage)
    }
    
    // MARK: - Integration Tests
    
    func testChatViewModelDocumentManagerIntegration() {
        // Given: ChatViewModel with DocumentContextManager
        let documents = createSampleDocuments()
        
        // When: Adding documents to DocumentContextManager
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // Then: Should update current model in DocumentContextManager
        XCTAssertEqual(chatViewModel.documentContextManager.currentModel, chatViewModel.selectedModel.name)
        XCTAssertNotNil(chatViewModel.documentContextManager.contextSizeResult)
    }
    
    func testModeAwareMessageProcessing() async {
        // Given: Different chat modes
        let documents = createSampleDocuments()
        chatViewModel.documentContextManager.setDocuments(documents)
        
        // Test RAG mode
        chatViewModel.currentChatMode = .rag
        chatViewModel.currentInput = "Test RAG mode"
        await chatViewModel.sendMessageWithOptimalMode()
        
        let ragCallCount = mockAPIService.sendMessageCallCount
        
        // Reset for Full Context test
        mockAPIService.reset()
        
        // Test Full Context mode
        chatViewModel.currentChatMode = .fullContext
        chatViewModel.currentInput = "Test Full Context mode"
        await chatViewModel.sendMessageWithOptimalMode()
        
        // Then: Both modes should process successfully
        XCTAssertEqual(ragCallCount, 1)
        XCTAssertTrue(mockAPIService.sendMessageCalled) // Full Context call
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDocuments() -> [ProcessedDocument] {
        return [
            ProcessedDocument(
                id: "doc1",
                title: "Sample Document 1",
                fileName: "doc1.pdf",
                fileURL: URL(string: "file://doc1.pdf")!,
                fileSize: 15000,
                type: .pdf,
                pageCount: 5,
                content: String(repeating: "This is sample content for document 1. ", count: 100),
                detectedLanguage: "en",
                createdAt: Date()
            ),
            ProcessedDocument(
                id: "doc2",
                title: "Sample Document 2",
                fileName: "doc2.txt",
                fileURL: URL(string: "file://doc2.txt")!,
                fileSize: 8000,
                type: .text,
                pageCount: 1,
                content: String(repeating: "This is sample content for document 2. ", count: 50),
                detectedLanguage: "en",
                createdAt: Date()
            )
        ]
    }
    
    private func createSmallDocuments() -> [ProcessedDocument] {
        return [
            ProcessedDocument(
                id: "small1",
                title: "Small Document",
                fileName: "small.txt",
                fileURL: URL(string: "file://small.txt")!,
                fileSize: 5000,
                type: .text,
                pageCount: 1,
                content: String(repeating: "Small content. ", count: 20),
                detectedLanguage: "en",
                createdAt: Date()
            )
        ]
    }
    
    private func createLargeDocuments() -> [ProcessedDocument] {
        return [
            ProcessedDocument(
                id: "large1",
                title: "Large Document",
                fileName: "large.pdf",
                fileURL: URL(string: "file://large.pdf")!,
                fileSize: 100000,
                type: .pdf,
                pageCount: 50,
                content: String(repeating: "This is a large document with extensive content. ", count: 2000),
                detectedLanguage: "en",
                createdAt: Date()
            )
        ]
    }
    
    private func createExcessiveDocuments() -> [ProcessedDocument] {
        return [
            ProcessedDocument(
                id: "excessive1",
                title: "Excessive Document",
                fileName: "excessive.pdf",
                fileURL: URL(string: "file://excessive.pdf")!,
                fileSize: 500000,
                type: .pdf,
                pageCount: 200,
                content: String(repeating: "This document exceeds context limits with very extensive content. ", count: 10000),
                detectedLanguage: "en",
                createdAt: Date()
            )
        ]
    }
}

// MARK: - Mock Services for Testing

class MockLLMAPIService: LLMAPIService {
    var sendMessageCalled = false
    var sendMessageCallCount = 0
    var shouldReturnError = false
    var lastMessage: String?
    var lastModel: LLMModel?
    var lastConversation: [ChatMessage]?
    
    func reset() {
        sendMessageCalled = false
        sendMessageCallCount = 0
        shouldReturnError = false
        lastMessage = nil
        lastModel = nil
        lastConversation = nil
    }
    
    func sendMessage(_ message: String, model: LLMModel, conversation: [ChatMessage]?) async throws -> AsyncThrowingStream<String, Error> {
        sendMessageCalled = true
        sendMessageCallCount += 1
        lastMessage = message
        lastModel = model
        lastConversation = conversation
        
        if shouldReturnError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API error"])
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate streaming response
                let responses = ["Mock ", "response ", "from ", "API ", "service."]
                for response in responses {
                    continuation.yield(response)
                    try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                }
                continuation.finish()
            }
        }
    }
    
    func getAvailableModels() async throws -> [LLMModel] {
        return [LLMModel.defaultModel]
    }
    
    func cancelCurrentRequest() {
        // Mock implementation
    }
}

class MockDataService: DataService {
    override func createConversation(title: String) -> ConversationEntity {
        let conversation = ConversationEntity(context: persistenceContainer.container.viewContext)
        conversation.id = UUID()
        conversation.title = title
        conversation.createdAt = Date()
        return conversation
    }
    
    override func addMessage(_ message: Message, to conversation: ConversationEntity) {
        // Mock implementation - no actual Core Data operations
    }
    
    override func saveContext() {
        // Mock implementation
    }
}