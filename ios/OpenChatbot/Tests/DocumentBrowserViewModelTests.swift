import XCTest
import SwiftUI
import CoreData
@testable import OpenChatbot

@MainActor
class DocumentBrowserViewModelTests: XCTestCase {
    var viewModel: DocumentBrowserViewModel!
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
                fatalError("Failed to load store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        viewModel = DocumentBrowserViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.documents.isEmpty)
        XCTAssertTrue(viewModel.filteredDocuments.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.selectedFilter, .all)
        XCTAssertEqual(viewModel.sortOption, .dateModified)
        XCTAssertFalse(viewModel.sortAscending)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testDocumentStats() {
        // Create test documents
        let testDocuments = createTestDocuments()
        viewModel.documents = testDocuments
        
        let stats = viewModel.documentStats
        XCTAssertEqual(stats.total, 4)
        XCTAssertEqual(stats.pdf, 2)
        XCTAssertEqual(stats.text, 1)
        XCTAssertEqual(stats.images, 1)
    }
    
    func testSearchFunctionality() {
        // Setup test documents
        let testDocuments = createTestDocuments()
        viewModel.documents = testDocuments
        
        // Test search
        viewModel.updateSearchFilter("Test")
        
        // Should filter documents containing "Test" in title
        XCTAssertEqual(viewModel.filteredDocuments.count, 4) // All test documents contain "Test"
    }
    
    func testFilterFunctionality() {
        // Setup test documents
        let testDocuments = createTestDocuments()
        viewModel.documents = testDocuments
        
        // Test PDF filter
        viewModel.updateFilter(.pdf)
        XCTAssertEqual(viewModel.filteredDocuments.count, 2)
        
        // Test text filter
        viewModel.updateFilter(.text)
        XCTAssertEqual(viewModel.filteredDocuments.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDocuments() -> [ProcessedDocument] {
        let doc1 = ProcessedDocument(
            id: "1",
            title: "Test PDF 1",
            fileName: "test1.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test1.pdf"),
            fileSize: 1024,
            type: .pdf,
            pageCount: 5,
            content: "Test content 1",
            detectedLanguage: "en",
            createdAt: Date()
        )
        
        let doc2 = ProcessedDocument(
            id: "2", 
            title: "Test PDF 2",
            fileName: "test2.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test2.pdf"),
            fileSize: 2048,
            type: .pdf,
            pageCount: 10,
            content: "Test content 2",
            detectedLanguage: "en",
            createdAt: Date()
        )
        
        let doc3 = ProcessedDocument(
            id: "3",
            title: "Test Text",
            fileName: "test.txt", 
            fileURL: URL(fileURLWithPath: "/tmp/test.txt"),
            fileSize: 512,
            type: .text,
            pageCount: 1,
            content: "Test text content",
            detectedLanguage: "en",
            createdAt: Date()
        )
        
        let doc4 = ProcessedDocument(
            id: "4",
            title: "Test Image",
            fileName: "test.jpg",
            fileURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            fileSize: 4096,
            type: .image,
            pageCount: 1,
            content: "Image description",
            detectedLanguage: "en",
            createdAt: Date()
        )
        
        return [doc1, doc2, doc3, doc4]
    }
}

// MARK: - Mock DataService for Testing
class MockDataService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchDocuments() async throws -> [ProcessedDocument] {
        // Return mock data for testing
        return []
    }
    
    func deleteDocument(withId id: String) async throws {
        // Mock delete implementation
    }
}

// MARK: - Test Extensions
extension DocumentType {
    static var allTestCases: [DocumentType] {
        return [.pdf, .text, .image, .unknown]
    }
} 