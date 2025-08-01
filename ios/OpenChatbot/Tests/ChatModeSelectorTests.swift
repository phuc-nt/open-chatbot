import XCTest
import SwiftUI
import Combine
@testable import OpenChatbot

class ChatModeSelectorTests: XCTestCase {
    
    var documentContextManager: DocumentContextManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        documentContextManager = DocumentContextManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        documentContextManager = nil
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
    
    // MARK: - ChatModeSelector Component Tests
    
    func testChatModeSelectorInitialization() {
        // Given
        let selectedMode = ChatMode.rag
        
        // When - Component should initialize properly
        let selector = ChatModeSelector(
            documentContextManager: documentContextManager,
            selectedMode: .constant(selectedMode)
        )
        
        // Then - Component exists and has expected initial state
        XCTAssertNotNil(selector)
        XCTAssertEqual(documentContextManager.currentChatMode, .rag)
        XCTAssertTrue(documentContextManager.canUseFullContext) // Default state
    }
    
    func testModeSelectionWithOptimalDocument() {
        // Given
        let shortDocument = createMockDocument(id: "1", title: "Short", content: shortContent)
        documentContextManager.addDocument(shortDocument)
        documentContextManager.updateCurrentModel("gpt-4")
        
        var selectedMode = ChatMode.rag
        
        // When - Document is optimal size
        let contextInfo = documentContextManager.getDetailedContextInfo()
        
        // Then - Both modes should be available
        XCTAssertTrue(documentContextManager.canUseFullContext)
        XCTAssertEqual(documentContextManager.recommendedMode, .fullContext)
        XCTAssertEqual(contextInfo.contextStatus, .optimal)
        
        // Mode selection should work for both options
        selectedMode = .fullContext
        documentContextManager.updateChatMode(selectedMode)
        XCTAssertEqual(documentContextManager.currentChatMode, .fullContext)
        
        selectedMode = .rag
        documentContextManager.updateChatMode(selectedMode)
        XCTAssertEqual(documentContextManager.currentChatMode, .rag)
    }
    
    func testModeSelectionWithLargeDocument() {
        // Given
        let largeDocument = createMockDocument(id: "1", title: "Large", content: longContent)
        documentContextManager.addDocument(largeDocument)
        documentContextManager.updateCurrentModel("llama-2") // Lower threshold
        
        // When - Document exceeds limits
        let contextInfo = documentContextManager.getDetailedContextInfo()
        
        // Then - Full Context should be restricted
        XCTAssertFalse(documentContextManager.canUseFullContext)
        XCTAssertEqual(documentContextManager.recommendedMode, .rag)
        XCTAssertTrue(contextInfo.contextStatus == .large || contextInfo.contextStatus == .excessive)
        
        // Attempting to select Full Context should show warning
        documentContextManager.updateChatMode(.fullContext)
        XCTAssertNotNil(documentContextManager.warningMessage)
        XCTAssertTrue(documentContextManager.warningMessage!.contains("too large"))
    }
    
    func testContextSizeVisualization() {
        // Test optimal document
        let shortDocument = createMockDocument(id: "1", title: "Short", content: shortContent)
        documentContextManager.addDocument(shortDocument)
        documentContextManager.updateCurrentModel("gpt-4")
        
        let contextInfo1 = documentContextManager.getDetailedContextInfo()
        XCTAssertEqual(contextInfo1.contextStatus, .optimal)
        
        // Test large document
        documentContextManager.clearAllDocuments()
        let mediumDocument = createMockDocument(id: "2", title: "Medium", content: mediumContent)
        documentContextManager.addDocument(mediumDocument)
        documentContextManager.updateCurrentModel("llama-2")
        
        let contextInfo2 = documentContextManager.getDetailedContextInfo()
        XCTAssertTrue(contextInfo2.contextStatus == .optimal || contextInfo2.contextStatus == .large)
    }
    
    func testWarningIndicators() {
        // Given - Large document that triggers warnings
        let largeDocument = createMockDocument(id: "1", title: "Large", content: String(repeating: "A", count: 100_000))
        documentContextManager.updateCurrentModel("llama-2") // Low threshold
        documentContextManager.addDocument(largeDocument)
        
        // When - Full Context mode is attempted
        documentContextManager.updateChatMode(.fullContext)
        
        // Then - Warning should be present
        XCTAssertNotNil(documentContextManager.warningMessage)
        XCTAssertTrue(documentContextManager.hasWarning)
        XCTAssertFalse(documentContextManager.canUseFullContext)
        
        // RAG mode should work without warnings
        documentContextManager.updateChatMode(.rag)
        XCTAssertNil(documentContextManager.warningMessage)
    }
    
    func testProcessingTimeEstimates() {
        // Given
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        documentContextManager.addDocument(document)
        
        // When - Get processing time estimates
        documentContextManager.updateChatMode(.rag)
        let ragTime = documentContextManager.getProcessingTimeEstimate()
        
        documentContextManager.updateChatMode(.fullContext)
        let fullContextTime = documentContextManager.getProcessingTimeEstimate()
        
        // Then - Processing times should be reasonable
        XCTAssertGreaterThan(ragTime, 0)
        XCTAssertGreaterThan(fullContextTime, 0)
        XCTAssertLessThan(ragTime, 60) // Should be under 1 minute
        XCTAssertLessThan(fullContextTime, 120) // Should be under 2 minutes
    }
    
    func testContextSummaryDisplay() {
        // Test empty state
        var summary = documentContextManager.getContextSummary()
        XCTAssertEqual(summary, "No documents selected")
        
        // Test single document
        let document1 = createMockDocument(id: "1", title: "Test1", content: shortContent)
        documentContextManager.addDocument(document1)
        summary = documentContextManager.getContextSummary()
        XCTAssertTrue(summary.contains("1 document"))
        
        // Test multiple documents
        let document2 = createMockDocument(id: "2", title: "Test2", content: mediumContent)
        documentContextManager.addDocument(document2)
        summary = documentContextManager.getContextSummary()
        XCTAssertTrue(summary.contains("2 documents"))
    }
    
    func testReactiveUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Mode change should trigger update")
        var modeUpdateCount = 0
        
        documentContextManager.$currentChatMode
            .sink { _ in
                modeUpdateCount += 1
                if modeUpdateCount == 2 { // Initial + 1 change
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Mode is changed
        documentContextManager.updateChatMode(.fullContext)
        
        // Then - Reactive update should occur
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(documentContextManager.currentChatMode, .fullContext)
        XCTAssertEqual(modeUpdateCount, 2)
    }
    
    func testMultipleDocumentScenarios() {
        // Test combining documents with different sizes
        let smallDoc = createMockDocument(id: "1", title: "Small", content: String(repeating: "A", count: 1000))
        let mediumDoc = createMockDocument(id: "2", title: "Medium", content: String(repeating: "B", count: 10000))
        let largeDoc = createMockDocument(id: "3", title: "Large", content: String(repeating: "C", count: 50000))
        
        // Add progressively and check status
        documentContextManager.updateCurrentModel("gpt-4")
        
        documentContextManager.addDocument(smallDoc)
        XCTAssertTrue(documentContextManager.canUseFullContext)
        XCTAssertEqual(documentContextManager.recommendedMode, .fullContext)
        
        documentContextManager.addDocument(mediumDoc)
        let afterMedium = documentContextManager.canUseFullContext
        let recommendedAfterMedium = documentContextManager.recommendedMode
        
        documentContextManager.addDocument(largeDoc)
        let afterLarge = documentContextManager.canUseFullContext
        let recommendedAfterLarge = documentContextManager.recommendedMode
        
        // Context should become more restrictive as we add larger documents
        XCTAssertTrue(afterMedium) // Should still be fine with medium
        if !afterLarge {
            XCTAssertEqual(recommendedAfterLarge, .rag)
        }
    }
    
    func testModelSwitchingEffects() {
        // Given - Same document with different models
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        documentContextManager.addDocument(document)
        
        // Test with high-capacity model
        documentContextManager.updateCurrentModel("gpt-4")
        let gpt4CanUseFullContext = documentContextManager.canUseFullContext
        let gpt4Recommended = documentContextManager.recommendedMode
        
        // Test with low-capacity model
        documentContextManager.updateCurrentModel("llama-2")
        let llamaCanUseFullContext = documentContextManager.canUseFullContext
        let llamaRecommended = documentContextManager.recommendedMode
        
        // Different models should have different thresholds
        XCTAssertTrue(gpt4CanUseFullContext)
        XCTAssertEqual(gpt4Recommended, .fullContext)
        
        // Llama should be more restrictive
        if !llamaCanUseFullContext {
            XCTAssertEqual(llamaRecommended, .rag)
        }
    }
    
    // MARK: - ChatModeOptionView Tests
    
    func testChatModeOptionViewStates() {
        // Test enabled, selected state
        let enabledSelected = ChatModeOptionView(
            mode: .rag,
            isSelected: true,
            isRecommended: true,
            title: "RAG Mode",
            description: "Search relevant information",
            isEnabled: true,
            action: {}
        )
        XCTAssertNotNil(enabledSelected)
        
        // Test disabled state
        let disabled = ChatModeOptionView(
            mode: .fullContext,
            isSelected: false,
            isRecommended: false,
            title: "Full Context",
            description: "Include complete document",
            isEnabled: false,
            action: {}
        )
        XCTAssertNotNil(disabled)
    }
    
    // MARK: - Performance Tests
    
    func testComponentPerformance() {
        // Test with multiple documents
        let documents = (1...10).map { i in
            createMockDocument(id: "\(i)", title: "Doc\(i)", content: mediumContent)
        }
        
        measure {
            for document in documents {
                documentContextManager.addDocument(document)
            }
            
            let _ = ChatModeSelector(
                documentContextManager: documentContextManager,
                selectedMode: .constant(.rag)
            )
            
            documentContextManager.clearAllDocuments()
        }
    }
    
    func testReactivePerfomance() {
        // Test reactive updates performance
        let document = createMockDocument(id: "1", title: "Test", content: mediumContent)
        documentContextManager.addDocument(document)
        
        measure {
            for _ in 0..<100 {
                documentContextManager.updateChatMode(.rag)
                documentContextManager.updateChatMode(.fullContext)
            }
        }
    }
}