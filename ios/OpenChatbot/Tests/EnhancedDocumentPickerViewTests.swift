import XCTest
import SwiftUI
@testable import OpenChatbot

class EnhancedDocumentPickerViewTests: XCTestCase {
    
    var chatViewModel: ChatViewModel!
    var documentContextManager: DocumentContextManager!
    
    override func setUp() {
        super.setUp()
        chatViewModel = ChatViewModel()
        documentContextManager = DocumentContextManager()
    }
    
    override func tearDown() {
        chatViewModel = nil
        documentContextManager = nil
        super.tearDown()
    }
    
    // MARK: - Enhanced UI Component Tests
    
    func testEnhancedDocumentRowDisplaysCorrectInfo() {
        // Given: A sample document
        let document = createSampleDocument(size: 15000)
        let contextSizeResult = ContextSizeCalculator.calculateSize(
            for: [document],
            modelName: "gpt-4"
        )
        
        // When: Creating EnhancedDocumentRow
        let row = EnhancedDocumentRow(
            document: document,
            isSelected: false,
            contextSizeResult: contextSizeResult,
            wouldExceedLimits: false,
            onToggle: { _ in }
        )
        
        // Then: Row should display document information correctly
        XCTAssertNotNil(row.document)
        XCTAssertEqual(row.document.title, "Sample Document")
        XCTAssertFalse(row.isSelected)
        XCTAssertFalse(row.wouldExceedLimits)
        XCTAssertNotNil(row.contextSizeResult)
    }
    
    func testContextSizeIndicatorColors() {
        // Given: Documents with different sizes
        let optimalDoc = createSampleDocument(size: 10000)  // Optimal
        let largeDoc = createSampleDocument(size: 60000)    // Large  
        let excessiveDoc = createSampleDocument(size: 150000) // Excessive
        
        // When: Calculating context size results
        let optimalResult = ContextSizeCalculator.calculateSize(for: [optimalDoc], modelName: "gpt-4")
        let largeResult = ContextSizeCalculator.calculateSize(for: [largeDoc], modelName: "gpt-4")
        let excessiveResult = ContextSizeCalculator.calculateSize(for: [excessiveDoc], modelName: "gpt-4")
        
        // Then: Status should match expected categories
        XCTAssertEqual(optimalResult.status, .optimal)
        XCTAssertEqual(largeResult.status, .large)
        XCTAssertEqual(excessiveResult.status, .excessive)
    }
    
    func testBatchDocumentSelection() {
        // Given: Multiple documents with varying sizes
        let documents = [
            createSampleDocument(id: "1", size: 10000),
            createSampleDocument(id: "2", size: 15000),
            createSampleDocument(id: "3", size: 80000),  // This one might be excessive when combined
        ]
        
        // When: Adding documents to context manager
        for document in documents {
            documentContextManager.addDocument(document)
        }
        
        // Then: Context manager should have all documents
        XCTAssertEqual(documentContextManager.selectedDocuments.count, 3)
        XCTAssertTrue(documentContextManager.hasDocuments)
        
        // And: Should have context size result
        XCTAssertNotNil(documentContextManager.contextSizeResult)
        
        // And: Should provide recommendations
        XCTAssertNotEqual(documentContextManager.recommendedMode, ChatMode.rag) // Will depend on total size
    }
    
    func testContextUtilizationCalculation() {
        // Given: Documents that use specific percentage of context
        let document = createSampleDocument(size: 30000) // Should be around 25% of GPT-4 limit
        
        // When: Adding to context manager
        documentContextManager.updateCurrentModel("gpt-4")
        documentContextManager.addDocument(document)
        
        // Then: Context utilization should be reasonable
        let utilization = documentContextManager.contextUtilization
        XCTAssertGreaterThan(utilization, 0.0)
        XCTAssertLessThan(utilization, 1.0)
        XCTAssertGreaterThan(utilization, 0.2) // Should be at least 20%
        XCTAssertLessThan(utilization, 0.5)   // Should be less than 50%
    }
    
    func testExceedLimitsWarning() {
        // Given: A very large document that would exceed limits
        let largeDocument = createSampleDocument(size: 200000) // Exceeds most model limits
        
        // When: Checking if it would exceed limits
        let wouldExceed = documentContextManager.wouldExceedLimits(withAdditionalDocument: largeDocument)
        
        // Then: Should return true for excessive document
        XCTAssertTrue(wouldExceed)
    }
    
    func testModeRecommendationLogic() {
        // Given: Small documents (optimal for full context)
        let smallDoc1 = createSampleDocument(id: "1", size: 5000)
        let smallDoc2 = createSampleDocument(id: "2", size: 8000)
        
        // When: Adding small documents
        documentContextManager.setDocuments([smallDoc1, smallDoc2])
        
        // Then: Should recommend full context mode
        XCTAssertEqual(documentContextManager.recommendedMode, .fullContext)
        XCTAssertTrue(documentContextManager.canUseFullContext)
        
        // Given: Large documents
        let largeDoc = createSampleDocument(id: "3", size: 80000)
        
        // When: Adding large document
        documentContextManager.addDocument(largeDoc)
        
        // Then: Recommendation might change to RAG mode
        // (This depends on the total size and model limits)
        let hasWarning = documentContextManager.hasWarning
        XCTAssertNotNil(documentContextManager.contextSizeResult)
    }
    
    func testContextSummaryText() {
        // Given: No documents selected
        // When: Getting context summary
        var summary = documentContextManager.getContextSummary()
        
        // Then: Should indicate no documents
        XCTAssertEqual(summary, "No documents selected")
        
        // Given: One document selected
        let document = createSampleDocument(size: 15000)
        documentContextManager.addDocument(document)
        
        // When: Getting context summary
        summary = documentContextManager.getContextSummary()
        
        // Then: Should show document count and size info
        XCTAssertTrue(summary.contains("1 document"))
        XCTAssertFalse(summary.isEmpty)
        
        // Given: Multiple documents
        let secondDoc = createSampleDocument(id: "2", size: 20000)
        documentContextManager.addDocument(secondDoc)
        
        // When: Getting context summary
        summary = documentContextManager.getContextSummary()
        
        // Then: Should show multiple documents
        XCTAssertTrue(summary.contains("2 documents"))
    }
    
    func testModelSpecificThresholds() {
        // Given: Same document with different models
        let document = createSampleDocument(size: 100000)
        
        // When: Testing with different models
        documentContextManager.updateCurrentModel("gpt-4")
        documentContextManager.addDocument(document)
        let gpt4Result = documentContextManager.contextSizeResult
        
        documentContextManager.updateCurrentModel("claude")
        documentContextManager.analyzeCurrentContext()
        let claudeResult = documentContextManager.contextSizeResult
        
        // Then: Results should be different due to different thresholds
        XCTAssertNotNil(gpt4Result)
        XCTAssertNotNil(claudeResult)
        
        // Claude has higher threshold, so utilization should be lower
        if let gpt4Percentage = gpt4Result?.percentage,
           let claudePercentage = claudeResult?.percentage {
            XCTAssertLessThan(claudePercentage, gpt4Percentage)
        }
    }
    
    func testProcessingTimeEstimate() {
        // Given: Documents of different sizes
        let smallDoc = createSampleDocument(size: 5000)
        let largeDoc = createSampleDocument(size: 50000)
        
        // When: Getting processing time estimates
        documentContextManager.addDocument(smallDoc)
        let smallDocTime = documentContextManager.getProcessingTimeEstimate()
        
        documentContextManager.addDocument(largeDoc)
        let bothDocsTime = documentContextManager.getProcessingTimeEstimate()
        
        // Then: Larger content should take more time
        XCTAssertGreaterThan(bothDocsTime, smallDocTime)
        XCTAssertGreaterThan(bothDocsTime, 0.0)
    }
    
    func testDocumentRemovalUpdatesContext() {
        // Given: Multiple documents in context
        let doc1 = createSampleDocument(id: "1", size: 20000)
        let doc2 = createSampleDocument(id: "2", size: 30000)
        
        documentContextManager.setDocuments([doc1, doc2])
        let initialUtilization = documentContextManager.contextUtilization
        
        // When: Removing one document
        documentContextManager.removeDocument(doc1)
        
        // Then: Context utilization should decrease
        let newUtilization = documentContextManager.contextUtilization
        XCTAssertLessThan(newUtilization, initialUtilization)
        XCTAssertEqual(documentContextManager.selectedDocuments.count, 1)
    }
    
    func testClearAllDocuments() {
        // Given: Documents in context
        let documents = [
            createSampleDocument(id: "1", size: 10000),
            createSampleDocument(id: "2", size: 15000)
        ]
        documentContextManager.setDocuments(documents)
        
        // When: Clearing all documents
        documentContextManager.clearAllDocuments()
        
        // Then: Context should be empty
        XCTAssertFalse(documentContextManager.hasDocuments)
        XCTAssertEqual(documentContextManager.selectedDocuments.count, 0)
        XCTAssertEqual(documentContextManager.contextUtilization, 0.0)
    }
    
    // MARK: - Integration Tests
    
    func testChatViewModelIntegration() {
        // Given: ChatViewModel with document context
        let document = createSampleDocument()
        
        // When: Adding document to ChatViewModel context
        chatViewModel.addDocumentToContext(document.id)
        
        // Then: ChatViewModel should track the document
        XCTAssertTrue(chatViewModel.selectedDocuments.contains(document.id))
        XCTAssertTrue(chatViewModel.isRAGEnabled)
    }
    
    func testDocumentContextManagerIntegration() {
        // Given: DocumentContextManager and sample documents
        let documents = [
            createSampleDocument(id: "1", size: 15000),
            createSampleDocument(id: "2", size: 25000)
        ]
        
        // When: Setting documents and updating mode
        documentContextManager.setDocuments(documents)
        documentContextManager.updateChatMode(.fullContext)
        
        // Then: Context manager should be properly configured
        XCTAssertEqual(documentContextManager.selectedDocuments.count, 2)
        XCTAssertEqual(documentContextManager.currentChatMode, .fullContext)
        XCTAssertNotNil(documentContextManager.contextSizeResult)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDocument(id: String = "test-doc", size: Int = 15000) -> ProcessedDocument {
        return ProcessedDocument(
            id: id,
            title: "Sample Document",
            fileName: "sample.pdf",
            fileURL: URL(string: "file://sample.pdf")!,
            fileSize: size,
            type: .pdf,
            pageCount: 10,
            content: String(repeating: "Sample content. ", count: size / 16), // Approximate character count
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
}