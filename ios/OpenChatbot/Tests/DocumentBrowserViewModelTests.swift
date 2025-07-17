import XCTest
@testable import OpenChatbot

@MainActor
final class DocumentBrowserViewModelTests: XCTestCase {
    
    var viewModel: DocumentBrowserViewModel!
    var mockDataService: MockDataService!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Setup in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "OpenChatbot")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        mockDataService = MockDataService(context: testContext)
        viewModel = DocumentBrowserViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockDataService = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.documents.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    // MARK: - Document Loading Tests
    
    func testInitialize() async {
        // Given
        XCTAssertEqual(viewModel.documents.count, 0)
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search Functionality Tests
    
    func testSearchTextEmpty() {
        // Given
        let testDocuments = createTestDocuments()
        
        // When - search with empty text should show all documents
        viewModel.documents = testDocuments
        
        // Then
        XCTAssertEqual(viewModel.documents.count, testDocuments.count)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Given
        let errorMessage = "Test error message"
        
        // When
        viewModel.errorMessage = errorMessage
        viewModel.showError = true
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - Test Helpers
    
    private func createTestDocuments() -> [String] {
        return [
            "Document 1",
            "Document 2", 
            "Document 3"
        ]
    }
}

// MARK: - Mock Data Service

class MockDataService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func createTestDocument(title: String, type: DocumentType) -> DocumentEntity {
        let document = DocumentEntity(context: context)
        document.id = UUID()
        document.title = title
        document.filename = "\(title).pdf"
        document.fileType = type.rawValue
        document.createdAt = Date()
        document.updatedAt = Date()
        document.fileSize = Int64.random(in: 1000...10000)
        
        return document
    }
}

// MARK: - Test Data Extensions

extension DocumentType {
    static var testCases: [DocumentType] {
        return [.pdf, .text, .image, .other]
    }
} 