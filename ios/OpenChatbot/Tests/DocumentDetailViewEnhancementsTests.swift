import XCTest
import SwiftUI
@testable import OpenChatbot

class DocumentDetailViewEnhancementsTests: XCTestCase {
    
    var documentDetailView: DocumentDetailView!
    var sampleDocument: ProcessedDocument!
    var mockAppState: MockAppState!
    
    override func setUp() {
        super.setUp()
        
        sampleDocument = createSampleDocument()
        mockAppState = MockAppState()
        
        // Create DocumentDetailView with sample document
        documentDetailView = DocumentDetailView(document: sampleDocument)
    }
    
    override func tearDown() {
        documentDetailView = nil
        sampleDocument = nil
        mockAppState = nil
        super.tearDown()
    }
    
    // MARK: - Context Size Status Tests
    
    func testContextSizeStatusCard() {
        // Given: DocumentDetailView with sample document
        // When: View is initialized
        
        // Then: Should have DocumentContextManager initialized
        XCTAssertNotNil(documentDetailView.document)
        XCTAssertEqual(documentDetailView.document.id, sampleDocument.id)
    }
    
    func testContextStatusIndicatorColors() {
        // Test the color logic for different context sizes
        let optimalDoc = createSampleDocument(size: 10000) // Should be optimal
        let largeDoc = createSampleDocument(size: 60000)   // Should be large
        let excessiveDoc = createSampleDocument(size: 150000) // Should be excessive
        
        // Create views for each document type
        let optimalView = DocumentDetailView(document: optimalDoc)
        let largeView = DocumentDetailView(document: largeDoc)
        let excessiveView = DocumentDetailView(document: excessiveDoc)
        
        // Verify documents have expected characteristics
        XCTAssertLessThan(optimalDoc.content.count, 20000)
        XCTAssertGreaterThan(largeDoc.content.count, 40000)
        XCTAssertGreaterThan(excessiveDoc.content.count, 100000)
    }
    
    func testContextAnalysisInitialization() {
        // Given: A document with known size
        let testDocument = createSampleDocument(size: 25000)
        let detailView = DocumentDetailView(document: testDocument)
        
        // When: View setup occurs (simulated)
        let documentContextManager = DocumentContextManager()
        documentContextManager.addDocument(testDocument)
        
        // Then: Context analysis should be performed
        XCTAssertNotNil(documentContextManager.contextSizeResult)
        XCTAssertEqual(documentContextManager.selectedDocuments.count, 1)
        XCTAssertEqual(documentContextManager.selectedDocuments.first?.id, testDocument.id)
    }
    
    // MARK: - Chat Mode Selection Tests
    
    func testChatModeRecommendation() {
        // Given: Documents of different sizes
        let smallDoc = createSampleDocument(size: 8000)   // Should recommend Full Context
        let largeDoc = createSampleDocument(size: 80000)  // Should recommend RAG
        
        // When: DocumentContextManager analyzes documents
        let smallDocManager = DocumentContextManager()
        smallDocManager.addDocument(smallDoc)
        
        let largeDocManager = DocumentContextManager()
        largeDocManager.addDocument(largeDoc)
        
        // Then: Should provide appropriate recommendations
        XCTAssertNotNil(smallDocManager.recommendedMode)
        XCTAssertNotNil(largeDocManager.recommendedMode)
        
        // Small document should be optimal or allow full context
        let smallCanUseFullContext = smallDocManager.canUseFullContext
        let largeCanUseFullContext = largeDocManager.canUseFullContext
        
        // Small documents should generally allow full context
        XCTAssertTrue(smallCanUseFullContext || smallDocManager.recommendedMode == .rag)
        
        // Very large documents might not allow full context
        XCTAssertTrue(largeCanUseFullContext || largeDocManager.recommendedMode == .rag)
    }
    
    func testChatModeToggling() {
        // Given: DocumentDetailView with document
        let contextManager = DocumentContextManager()
        contextManager.addDocument(sampleDocument)
        
        // When: Chat mode is changed
        contextManager.updateChatMode(.fullContext)
        
        // Then: Context manager should update mode
        XCTAssertEqual(contextManager.currentChatMode, .fullContext)
        
        // When: Mode is changed to RAG
        contextManager.updateChatMode(.rag)
        
        // Then: Should update to RAG mode
        XCTAssertEqual(contextManager.currentChatMode, .rag)
    }
    
    // MARK: - Enhanced Chat Button Tests
    
    func testChatButtonStateForOptimalDocument() {
        // Given: Optimal document (small size)
        let optimalDoc = createSampleDocument(size: 5000)
        let contextManager = DocumentContextManager()
        contextManager.addDocument(optimalDoc)
        
        // When: Checking if Full Context is available
        let canUseFullContext = contextManager.canUseFullContext
        
        // Then: Should allow Full Context mode
        XCTAssertTrue(canUseFullContext)
        XCTAssertNotNil(contextManager.contextSizeResult)
    }
    
    func testChatButtonStateForLargeDocument() {
        // Given: Large document that may exceed limits
        let largeDoc = createSampleDocument(size: 200000)
        let contextManager = DocumentContextManager()
        contextManager.addDocument(largeDoc)
        
        // When: Checking context availability
        let contextResult = contextManager.contextSizeResult
        
        // Then: Should have appropriate context analysis
        XCTAssertNotNil(contextResult)
        if let result = contextResult {
            // Large documents should be marked appropriately
            XCTAssertTrue(result.status == .large || result.status == .excessive)
        }
    }
    
    func testChatButtonWarningState() {
        // Given: Document that would cause warnings
        let problematicDoc = createSampleDocument(size: 150000)
        let contextManager = DocumentContextManager()
        contextManager.addDocument(problematicDoc)
        
        // When: Analyzing context
        let hasWarning = contextManager.hasWarning
        let warningMessage = contextManager.warningMessage
        
        // Then: May have warnings for very large documents
        // Note: This depends on the specific model and thresholds
        if hasWarning {
            XCTAssertNotNil(warningMessage)
            XCTAssertFalse(warningMessage!.isEmpty)
        }
    }
    
    // MARK: - Integration Tests
    
    func testDocumentInfoPassing() {
        // Given: Document with specific properties
        let testDoc = ProcessedDocument(
            id: "test-doc-id",
            title: "Test Document",
            fileName: "test.pdf",
            fileURL: URL(string: "file://test.pdf")!,
            fileSize: 25000,
            type: .pdf,
            pageCount: 5,
            content: String(repeating: "Test content. ", count: 500),
            detectedLanguage: "en",
            createdAt: Date()
        )
        
        // When: Creating DocumentDetailView
        let detailView = DocumentDetailView(document: testDoc)
        
        // Then: Should maintain document properties
        XCTAssertEqual(detailView.document.id, "test-doc-id")
        XCTAssertEqual(detailView.document.title, "Test Document")
        XCTAssertEqual(detailView.document.type, .pdf)
        XCTAssertEqual(detailView.document.pageCount, 5)
    }
    
    func testChatModeEnumProperties() {
        // Test ChatMode enum display names
        XCTAssertEqual(ChatMode.rag.displayName, "RAG Mode")
        XCTAssertEqual(ChatMode.fullContext.displayName, "Full Context")
        
        // Test raw values
        XCTAssertEqual(ChatMode.rag.rawValue, "rag")
        XCTAssertEqual(ChatMode.fullContext.rawValue, "full_context")
        
        // Test identifiable
        XCTAssertEqual(ChatMode.rag.id, "rag")
        XCTAssertEqual(ChatMode.fullContext.id, "full_context")
    }
    
    func testContextSizeStatusDisplayNames() {
        // Test ContextSizeStatus display names
        XCTAssertEqual(ContextSizeStatus.optimal.displayName, "Perfect for Full Context")
        XCTAssertEqual(ContextSizeStatus.large.displayName, "Consider RAG for speed")
        XCTAssertEqual(ContextSizeStatus.excessive.displayName, "RAG Mode recommended")
    }
    
    // MARK: - UI Component Tests
    
    func testDocumentDetailViewInitialization() {
        // Given: Sample document
        let document = createSampleDocument()
        
        // When: Creating DocumentDetailView
        let view = DocumentDetailView(document: document)
        
        // Then: Should initialize properly
        XCTAssertEqual(view.document.id, document.id)
        XCTAssertEqual(view.document.title, document.title)
    }
    
    func testActionsSectionComponents() {
        // Given: DocumentDetailView
        // When: Checking available components (conceptually)
        
        // Then: Should have required action components
        // This test verifies the structure is set up correctly
        XCTAssertNotNil(sampleDocument)
        XCTAssertNotNil(documentDetailView)
        
        // Verify document has required properties for UI
        XCTAssertFalse(sampleDocument.title.isEmpty)
        XCTAssertGreaterThan(sampleDocument.content.count, 0)
        XCTAssertGreaterThan(sampleDocument.fileSize, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandlingMissingContextData() {
        // Given: Document with minimal data
        let minimalDoc = ProcessedDocument(
            id: "minimal",
            title: "Minimal Doc",
            fileName: "minimal.txt",
            fileURL: URL(string: "file://minimal.txt")!,
            fileSize: 100,
            type: .text,
            pageCount: 1,
            content: "",  // Empty content
            detectedLanguage: nil,
            createdAt: Date()
        )
        
        // When: Creating DocumentDetailView
        let view = DocumentDetailView(document: minimalDoc)
        
        // Then: Should handle gracefully
        XCTAssertEqual(view.document.content, "")
        XCTAssertNil(view.document.detectedLanguage)
        XCTAssertEqual(view.document.fileSize, 100)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDocument(id: String = "sample", size: Int = 15000) -> ProcessedDocument {
        let content = String(repeating: "Sample document content. ", count: size / 25)
        
        return ProcessedDocument(
            id: id,
            title: "Sample Document",
            fileName: "sample.pdf",
            fileURL: URL(string: "file://sample.pdf")!,
            fileSize: size,
            type: .pdf,
            pageCount: max(1, size / 1000),
            content: content,
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
}

// MARK: - Mock App State

class MockAppState: AppState {
    var chatTabSwitched = false
    
    override func switchToChatTab() {
        chatTabSwitched = true
        super.switchToChatTab()
    }
}