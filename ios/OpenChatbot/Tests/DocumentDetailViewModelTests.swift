import XCTest
@testable import OpenChatbot

@MainActor
final class DocumentDetailViewModelTests: XCTestCase {
    
    var viewModel: DocumentDetailViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DocumentDetailViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.tags.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    // MARK: - Document Loading Tests
    
    func testLoadDocument() {
        // Given
        let testDocument = createTestProcessedDocument()
        
        // When
        viewModel.loadDocument(testDocument)
        
        // Then
        XCTAssertEqual(viewModel.tags.count, 0) // Initially empty
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Tag Management Tests
    
    func testAddTag() {
        // Given
        let newTag = "test-tag"
        
        // When
        viewModel.tags.append(newTag)
        
        // Then
        XCTAssertEqual(viewModel.tags.count, 1)
        XCTAssertTrue(viewModel.tags.contains(newTag))
    }
    
    func testRemoveTag() {
        // Given
        let tag1 = "tag1"
        let tag2 = "tag2"
        viewModel.tags = [tag1, tag2]
        
        // When
        if let index = viewModel.tags.firstIndex(of: tag1) {
            viewModel.tags.remove(at: index)
        }
        
        // Then
        XCTAssertEqual(viewModel.tags.count, 1)
        XCTAssertFalse(viewModel.tags.contains(tag1))
        XCTAssertTrue(viewModel.tags.contains(tag2))
    }
    
    // MARK: - Save Changes Tests
    
    func testSaveChanges() async {
        // Given
        let testDocument = createTestProcessedDocument()
        viewModel.loadDocument(testDocument)
        let newTitle = "Updated Title"
        let newTags = ["tag1", "tag2"]
        
        // When
        await viewModel.saveChanges(title: newTitle, tags: newTags)
        
        // Then
        XCTAssertEqual(viewModel.tags, newTags)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Given
        let errorMessage = "Test error"
        
        // When
        viewModel.errorMessage = errorMessage
        viewModel.showError = true
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - Test Helpers
    
    private func createTestProcessedDocument() -> ProcessedDocument {
        return ProcessedDocument(
            id: UUID().uuidString,
            title: "Test Document",
            fileName: "test.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            fileSize: 1024,
            type: .pdf,
            pageCount: 1,
            content: "Test content",
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
} 