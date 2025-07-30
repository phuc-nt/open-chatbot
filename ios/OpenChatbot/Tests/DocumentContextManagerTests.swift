import XCTest
import Combine
@testable import OpenChatbot

class DocumentContextManagerTests: XCTestCase {
    
    var contextManager: DocumentContextManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        contextManager = DocumentContextManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        contextManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Helpers
    
    private func createMockDocument(id: String, title: String, content: String, type: DocumentType = .text) -> ProcessedDocument {
        return ProcessedDocument(
            id: id,
            title: title,
            fileName: "\(title).txt",
            fileURL: URL(string: "file://\(title).txt")!,
            fileSize: Int64(content.count),
            type: type,
            pageCount: 1,
            content: content,
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
    
    private let shortContent = "Short document content"
    private let mediumContent = String(repeating: "Medium content. ", count: 1000) // ~15k chars
    private let longContent = String(repeating: "Long content that may exceed limits. ", count: 2000) // ~74k chars
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertTrue(contextManager.selectedDocuments.isEmpty)
        XCTAssertEqual(contextManager.currentChatMode, .rag)
        XCTAssertNil(contextManager.contextSizeResult)
        XCTAssertEqual(contextManager.recommendedMode, .rag)
        XCTAssertTrue(contextManager.canUseFullContext)
        XCTAssertNil(contextManager.warningMessage)
    }
    
    // MARK: - Document Management Tests
    
    func testAddDocument() {
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        
        contextManager.addDocument(document)
        
        XCTAssertEqual(contextManager.selectedDocuments.count, 1)
        XCTAssertEqual(contextManager.selectedDocuments.first?.id, "1")
        XCTAssertNotNil(contextManager.contextSizeResult)
    }
    
    func testAddDuplicateDocument() {
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        
        contextManager.addDocument(document)
        contextManager.addDocument(document) // Add same document again
        
        XCTAssertEqual(contextManager.selectedDocuments.count, 1, "Should not add duplicate documents")
    }
    
    func testRemoveDocument() {
        let document1 = createMockDocument(id: "1", title: "Test1", content: shortContent)
        let document2 = createMockDocument(id: "2", title: "Test2", content: mediumContent)
        
        contextManager.addDocument(document1)
        contextManager.addDocument(document2)
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
        
        contextManager.removeDocument(document1)
        XCTAssertEqual(contextManager.selectedDocuments.count, 1)
        XCTAssertEqual(contextManager.selectedDocuments.first?.id, "2")
    }
    
    func testRemoveDocumentById() {
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        
        contextManager.addDocument(document)
        contextManager.removeDocument(withId: "1")
        
        XCTAssertTrue(contextManager.selectedDocuments.isEmpty)
    }
    
    func testClearAllDocuments() {
        let document1 = createMockDocument(id: "1", title: "Test1", content: shortContent)
        let document2 = createMockDocument(id: "2", title: "Test2", content: mediumContent)
        
        contextManager.addDocument(document1)
        contextManager.addDocument(document2)
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
        
        contextManager.clearAllDocuments()
        XCTAssertTrue(contextManager.selectedDocuments.isEmpty)
        XCTAssertNil(contextManager.contextSizeResult)
    }
    
    func testSetDocuments() {
        let document1 = createMockDocument(id: "1", title: "Test1", content: shortContent)
        let document2 = createMockDocument(id: "2", title: "Test2", content: mediumContent)
        let documents = [document1, document2]
        
        contextManager.setDocuments(documents)
        
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
        XCTAssertEqual(Set(contextManager.selectedDocuments.map { $0.id }), Set(["1", "2"]))
    }
    
    func testToggleDocument() {
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        
        // Toggle to add
        contextManager.toggleDocument(document)
        XCTAssertEqual(contextManager.selectedDocuments.count, 1)
        
        // Toggle to remove
        contextManager.toggleDocument(document)
        XCTAssertTrue(contextManager.selectedDocuments.isEmpty)
    }
    
    // MARK: - Context Analysis Tests
    
    func testContextAnalysisWithShortDocument() {
        let document = createMockDocument(id: "1", title: "Short", content: shortContent)
        
        contextManager.updateCurrentModel("gpt-4")
        contextManager.addDocument(document)
        
        XCTAssertNotNil(contextManager.contextSizeResult)
        XCTAssertEqual(contextManager.contextSizeResult?.status, .optimal)
        XCTAssertEqual(contextManager.recommendedMode, .fullContext)
        XCTAssertTrue(contextManager.canUseFullContext)
        XCTAssertNil(contextManager.warningMessage)
    }
    
    func testContextAnalysisWithLongDocument() {
        let document = createMockDocument(id: "1", title: "Long", content: longContent)
        
        contextManager.updateCurrentModel("llama-2") // Lower threshold
        contextManager.addDocument(document)
        
        XCTAssertNotNil(contextManager.contextSizeResult)
        XCTAssertTrue(contextManager.contextSizeResult?.status == .large || contextManager.contextSizeResult?.status == .excessive)
        XCTAssertEqual(contextManager.recommendedMode, .rag)
    }
    
    func testModelUpdate() {
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        contextManager.addDocument(document)
        
        // Test with GPT-4 (high threshold)
        contextManager.updateCurrentModel("gpt-4")
        let gpt4Result = contextManager.contextSizeResult
        
        // Test with Llama (low threshold)
        contextManager.updateCurrentModel("llama-2")
        let llamaResult = contextManager.contextSizeResult
        
        // Same document should have different analysis based on model
        XCTAssertNotEqual(gpt4Result?.threshold, llamaResult?.threshold)
    }
    
    // MARK: - Chat Mode Tests
    
    func testUpdateChatMode() {
        contextManager.updateChatMode(.fullContext)
        XCTAssertEqual(contextManager.currentChatMode, .fullContext)
    }
    
    func testChatModeValidation() {
        // Add a very large document
        let largeDocument = createMockDocument(id: "1", title: "Large", content: String(repeating: "A", count: 100_000))
        contextManager.updateCurrentModel("llama-2") // Low threshold
        contextManager.addDocument(largeDocument)
        
        // Try to set Full Context mode when not available
        contextManager.updateChatMode(.fullContext)
        
        XCTAssertNotNil(contextManager.warningMessage)
        XCTAssertTrue(contextManager.warningMessage!.contains("too large"))
    }
    
    func testAutoModeAdjustment() {
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        contextManager.addDocument(document)
        
        // Set to Full Context mode
        contextManager.updateChatMode(.fullContext)
        XCTAssertEqual(contextManager.currentChatMode, .fullContext)
        
        // Add a very large document that would make Full Context unavailable
        let largeDocument = createMockDocument(id: "2", title: "Large", content: String(repeating: "A", count: 200_000))
        contextManager.updateCurrentModel("llama-2")
        contextManager.addDocument(largeDocument)
        
        // Mode should auto-adjust to RAG
        XCTAssertEqual(contextManager.currentChatMode, .rag)
    }
    
    // MARK: - Context Information Tests
    
    func testGetContextSummary() {
        // Empty context
        XCTAssertEqual(contextManager.getContextSummary(), "No documents selected")
        
        // Single document
        let document1 = createMockDocument(id: "1", title: "Test1", content: shortContent)
        contextManager.addDocument(document1)
        let summary1 = contextManager.getContextSummary()
        XCTAssertTrue(summary1.contains("1 document"))
        
        // Multiple documents
        let document2 = createMockDocument(id: "2", title: "Test2", content: mediumContent)
        contextManager.addDocument(document2)
        let summary2 = contextManager.getContextSummary()
        XCTAssertTrue(summary2.contains("2 documents"))
    }
    
    func testGetDetailedContextInfo() {
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        contextManager.addDocument(document)
        
        let info = contextManager.getDetailedContextInfo()
        
        XCTAssertEqual(info.documentCount, 1)
        XCTAssertGreaterThan(info.totalCharacters, 0)
        XCTAssertGreaterThan(info.estimatedTokens, 0)
        XCTAssertEqual(info.modelName, "gpt-4") // Default model
        XCTAssertFalse(info.formattedSize.isEmpty)
        XCTAssertFalse(info.formattedTokens.isEmpty)
    }
    
    func testWouldExceedLimits() {
        let document1 = createMockDocument(id: "1", title: "Test1", content: mediumContent)
        contextManager.addDocument(document1)
        
        let largeDocument = createMockDocument(id: "2", title: "Large", content: String(repeating: "A", count: 200_000))
        contextManager.updateCurrentModel("llama-2") // Low threshold
        
        XCTAssertTrue(contextManager.wouldExceedLimits(withAdditionalDocument: largeDocument))
    }
    
    func testProcessingTimeEstimate() {
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        contextManager.addDocument(document)
        
        let ragTime = contextManager.getProcessingTimeEstimate()
        XCTAssertGreaterThan(ragTime, 0)
        
        contextManager.updateChatMode(.fullContext)
        let fullContextTime = contextManager.getProcessingTimeEstimate()
        XCTAssertGreaterThan(fullContextTime, 0)
    }
    
    func testReadingTimeEstimate() {
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        contextManager.addDocument(document)
        
        let readingTime = contextManager.getReadingTimeEstimate()
        XCTAssertGreaterThan(readingTime, 0)
        XCTAssertLessThan(readingTime, 3600) // Should be reasonable (< 1 hour)
    }
    
    // MARK: - Batch Operations Tests
    
    func testAddDocumentsWithValidation() {
        let document1 = createMockDocument(id: "1", title: "Small1", content: shortContent)
        let document2 = createMockDocument(id: "2", title: "Small2", content: shortContent)
        let largeDocument = createMockDocument(id: "3", title: "Large", content: String(repeating: "A", count: 200_000))
        
        contextManager.updateCurrentModel("llama-2") // Low threshold
        
        let result = contextManager.addDocuments([document1, document2, largeDocument])
        
        XCTAssertEqual(result.successCount, 2) // Small documents should succeed
        XCTAssertEqual(result.failureCount, 1) // Large document should fail
        XCTAssertTrue(result.hasFailures)
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
    }
    
    func testRemoveDocumentsByType() {
        let pdfDoc = createMockDocument(id: "1", title: "PDF", content: shortContent, type: .pdf)
        let textDoc = createMockDocument(id: "2", title: "Text", content: shortContent, type: .text)
        let imageDoc = createMockDocument(id: "3", title: "Image", content: shortContent, type: .image)
        
        contextManager.setDocuments([pdfDoc, textDoc, imageDoc])
        XCTAssertEqual(contextManager.selectedDocuments.count, 3)
        
        contextManager.removeDocuments(ofType: .pdf)
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
        XCTAssertFalse(contextManager.selectedDocuments.contains { $0.type == .pdf })
    }
    
    func testOptimizeDocumentsForSize() {
        let smallDoc1 = createMockDocument(id: "1", title: "Small1", content: String(repeating: "A", count: 1000))
        let smallDoc2 = createMockDocument(id: "2", title: "Small2", content: String(repeating: "B", count: 1000))
        let largeDoc = createMockDocument(id: "3", title: "Large", content: String(repeating: "C", count: 10000))
        
        contextManager.setDocuments([largeDoc, smallDoc1, smallDoc2]) // Add large doc first
        
        // Optimize for 3000 characters (should keep only the 2 small docs)
        contextManager.optimizeDocumentsForSize(targetLimit: 3000)
        
        XCTAssertEqual(contextManager.selectedDocuments.count, 2)
        XCTAssertFalse(contextManager.selectedDocuments.contains { $0.id == "3" })
    }
    
    // MARK: - Extension Properties Tests
    
    func testExtensionProperties() {
        // Empty state
        XCTAssertFalse(contextManager.hasDocuments)
        XCTAssertEqual(contextManager.documentCount, 0)
        XCTAssertFalse(contextManager.hasWarning)
        XCTAssertEqual(contextManager.contextUtilization, 0.0)
        
        // With documents
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        contextManager.addDocument(document)
        
        XCTAssertTrue(contextManager.hasDocuments)
        XCTAssertEqual(contextManager.documentCount, 1)
        XCTAssertGreaterThan(contextManager.contextUtilization, 0.0)
    }
    
    func testIsOptimalForFullContext() {
        let smallDocument = createMockDocument(id: "1", title: "Small", content: shortContent)
        contextManager.addDocument(smallDocument)
        
        XCTAssertTrue(contextManager.isOptimalForFullContext)
    }
    
    // MARK: - Reactive Updates Tests
    
    func testAutoAnalysisOnDocumentChange() {
        let expectation = XCTestExpectation(description: "Context analysis should update automatically")
        
        var analysisCount = 0
        contextManager.$contextSizeResult
            .sink { result in
                analysisCount += 1
                if analysisCount == 2 { // Initial nil + first document
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let document = createMockDocument(id: "1", title: "Test", content: shortContent)
        contextManager.addDocument(document)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(analysisCount, 2)
    }
    
    // MARK: - DocumentContextInfo Tests
    
    func testDocumentContextInfoFormatting() {
        let info = DocumentContextInfo(
            documentCount: 2,
            totalCharacters: 1500,
            estimatedTokens: 375,
            contextStatus: .optimal,
            recommendedMode: .fullContext,
            canUseFullContext: true,
            warningMessage: nil,
            modelName: "gpt-4",
            threshold: 120000
        )
        
        XCTAssertEqual(info.formattedSize, "1.5k chars")
        XCTAssertEqual(info.formattedTokens, "375 tokens")
        XCTAssertEqual(info.percentageString, "1%")
        XCTAssertLessThan(info.percentageUsed, 0.02)
    }
    
    func testDocumentAdditionResult() {
        let doc1 = createMockDocument(id: "1", title: "Success", content: shortContent)
        let doc2 = createMockDocument(id: "2", title: "Fail", content: longContent)
        
        let result = DocumentAdditionResult(
            successfulDocuments: [doc1],
            failedDocuments: [(doc2, "Too large")]
        )
        
        XCTAssertEqual(result.successCount, 1)
        XCTAssertEqual(result.failureCount, 1)
        XCTAssertTrue(result.hasFailures)
    }
    
    // MARK: - Performance Tests
    
    func testContextAnalysisPerformance() {
        let documents = (1...10).map { i in
            createMockDocument(id: "\(i)", title: "Doc\(i)", content: mediumContent)
        }
        
        measure {
            contextManager.setDocuments(documents)
        }
    }
    
    func testBatchOperationPerformance() {
        let documents = (1...50).map { i in
            createMockDocument(id: "\(i)", title: "Doc\(i)", content: shortContent)
        }
        
        measure {
            let _ = contextManager.addDocuments(documents)
        }
    }
}