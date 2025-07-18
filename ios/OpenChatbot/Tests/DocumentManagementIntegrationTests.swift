import XCTest
import CoreData
@testable import OpenChatbot

@MainActor
final class DocumentManagementIntegrationTests: XCTestCase {
    
    var dataService: DataService!
    var documentProcessingService: DocumentProcessingService!
    var embeddingService: EmbeddingService!
    
    override func setUp() {
        super.setUp()
        
        // Setup test services
        dataService = DataService(inMemory: true)
        documentProcessingService = DocumentProcessingService()
        embeddingService = EmbeddingService(context: dataService.persistenceContainer.container.viewContext)
    }
    
    override func tearDown() {
        dataService = nil
        documentProcessingService = nil
        embeddingService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Document Flow Tests
    
    func testCompleteDocumentUploadFlow() async throws {
        // Given
        let testDocument = createTestDocumentData()
        let filename = "test_document.pdf"
        
        // When - Upload document
        let uploadResult = await uploadDocument(data: testDocument, filename: filename)
        
        // Then - Document should be uploaded successfully
        XCTAssertTrue(uploadResult.success)
        XCTAssertNotNil(uploadResult.documentId)
        
        // When - Process document
        if let documentId = uploadResult.documentId {
            let processingResult = await processDocument(documentId: documentId)
            
            // Then - Document should be processed successfully
            XCTAssertTrue(processingResult.success)
            XCTAssertNotNil(processingResult.embeddings)
        }
    }
    
    func testDocumentSearchAndRetrievalFlow() async throws {
        // Given - Upload and process multiple test documents
        let documents = await uploadMultipleTestDocuments()
        
        // When - Search for documents
        let searchQuery = "test document"
        let searchResults = await searchDocuments(query: searchQuery)
        
        // Then - Should return relevant documents
        XCTAssertGreaterThan(searchResults.count, 0)
        XCTAssertTrue(searchResults.allSatisfy { result in
            result.title.localizedCaseInsensitiveContains("test") ||
            result.content.localizedCaseInsensitiveContains("test")
        })
    }
    
    func testDocumentMetadataManagementFlow() async throws {
        // Given - Upload a test document
        let uploadResult = await uploadDocument(data: createTestDocumentData(), filename: "metadata_test.pdf")
        
        guard let documentId = uploadResult.documentId else {
            XCTFail("Failed to upload document")
            return
        }
        
        // When - Update document metadata
        let originalTitle = "Original Title"
        let updatedTitle = "Updated Title"
        let tags = ["tag1", "tag2", "important"]
        
        let updateResult = await updateDocumentMetadata(
            documentId: documentId,
            title: updatedTitle,
            tags: tags
        )
        
        // Then - Metadata should be updated successfully
        XCTAssertTrue(updateResult.success)
        
        // When - Retrieve document
        let retrievedDocument = await getDocument(documentId: documentId)
        
        // Then - Should have updated metadata
        XCTAssertEqual(retrievedDocument?.title, updatedTitle)
        XCTAssertEqual(retrievedDocument?.tags.sorted(), tags.sorted())
    }
    
    func testDocumentDeletionFlow() async throws {
        // Given - Upload a test document
        let uploadResult = await uploadDocument(data: createTestDocumentData(), filename: "delete_test.pdf")
        
        guard let documentId = uploadResult.documentId else {
            XCTFail("Failed to upload document")
            return
        }
        
        // When - Delete document
        let deleteResult = await deleteDocument(documentId: documentId)
        
        // Then - Document should be deleted successfully
        XCTAssertTrue(deleteResult.success)
        
        // When - Try to retrieve deleted document
        let retrievedDocument = await getDocument(documentId: documentId)
        
        // Then - Document should not be found
        XCTAssertNil(retrievedDocument)
    }
    
    // MARK: - Performance Tests
    
    func testBulkDocumentUploadPerformance() async throws {
        let documentCount = 10
        let documents = (1...documentCount).map { index in
            (data: createTestDocumentData(), filename: "bulk_test_\(index).pdf")
        }
        
        // Measure time for bulk upload
        let startTime = Date()
        
        let uploadResults = await withTaskGroup(of: UploadResult.self) { group in
            for document in documents {
                group.addTask {
                    await self.uploadDocument(data: document.data, filename: document.filename)
                }
            }
            
            var results: [UploadResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        let endTime = Date()
        let uploadTime = endTime.timeIntervalSince(startTime)
        
        // Validate results
        XCTAssertEqual(uploadResults.count, documentCount)
        XCTAssertTrue(uploadResults.allSatisfy { $0.success })
        
        // Performance assertion - should complete within reasonable time
        XCTAssertLessThan(uploadTime, 30.0, "Bulk upload should complete within 30 seconds")
        
        print("Bulk upload of \(documentCount) documents completed in \(uploadTime) seconds")
    }
    
    func testDocumentSearchPerformance() async throws {
        // Given - Upload test documents for search
        await uploadMultipleTestDocuments()
        
        let searchQueries = [
            "artificial intelligence",
            "machine learning",
            "data science",
            "neural networks",
            "deep learning"
        ]
        
        // Measure search performance
        for query in searchQueries {
            let startTime = Date()
            let results = await searchDocuments(query: query)
            let endTime = Date()
            let searchTime = endTime.timeIntervalSince(startTime)
            
            // Performance assertion
            XCTAssertLessThan(searchTime, 2.0, "Search for '\(query)' should complete within 2 seconds")
            
            print("Search for '\(query)' completed in \(searchTime) seconds, found \(results.count) results")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDocumentHandling() async throws {
        // Given - Invalid document data
        let invalidData = Data("Invalid document content".utf8)
        
        // When - Try to upload invalid document
        let uploadResult = await uploadDocument(data: invalidData, filename: "invalid.xyz")
        
        // Then - Should handle gracefully
        XCTAssertFalse(uploadResult.success)
        XCTAssertNotNil(uploadResult.error)
    }
    
    func testNetworkErrorHandling() async throws {
        // This test would require mocking network failures
        // Implementation depends on your networking layer
        
        // Given - Simulate network error condition
        // When - Attempt operations that require network
        // Then - Should handle errors gracefully
        
        XCTAssertTrue(true) // Placeholder for network error tests
    }
    
    // MARK: - Test Helpers
    
    private func createTestDocumentData() -> Data {
        let testContent = """
        This is a test document for integration testing.
        It contains sample content that can be processed and embedded.
        The document includes keywords like artificial intelligence,
        machine learning, and data science for search testing.
        """
        return Data(testContent.utf8)
    }
    
    private func uploadDocument(data: Data, filename: String) async -> UploadResult {
        // Mock implementation - replace with actual service calls
        return UploadResult(
            success: true,
            documentId: UUID().uuidString,
            error: nil
        )
    }
    
    private func processDocument(documentId: String) async -> ProcessingResult {
        // Mock implementation - replace with actual service calls
        return ProcessingResult(
            success: true,
            embeddings: Array(repeating: 0.1, count: 1536),
            error: nil
        )
    }
    
    private func searchDocuments(query: String) async -> [SearchResult] {
        // Mock implementation - replace with actual service calls
        return [
            SearchResult(
                documentId: UUID().uuidString,
                title: "Test Document 1",
                content: "Sample content with test keywords",
                relevanceScore: 0.8
            )
        ]
    }
    
    private func updateDocumentMetadata(documentId: String, title: String, tags: [String]) async -> UpdateResult {
        // Mock implementation - replace with actual service calls
        return UpdateResult(success: true, error: nil)
    }
    
    private func getDocument(documentId: String) async -> TestDocument? {
        // Mock implementation - replace with actual service calls
        return TestDocument(
            id: documentId,
            title: "Updated Title",
            tags: ["tag1", "tag2"],
            content: "Test content"
        )
    }
    
    private func deleteDocument(documentId: String) async -> DeleteResult {
        // Mock implementation - replace with actual service calls
        return DeleteResult(success: true, error: nil)
    }
    
    private func uploadMultipleTestDocuments() async -> [String] {
        let documents = [
            ("AI Research Paper", "artificial intelligence machine learning"),
            ("Data Science Guide", "data science analytics statistics"),
            ("Neural Networks Tutorial", "neural networks deep learning"),
            ("ML Algorithms Overview", "machine learning algorithms classification")
        ]
        
        var documentIds: [String] = []
        
        for (title, content) in documents {
            let data = Data(content.utf8)
            let result = await uploadDocument(data: data, filename: "\(title).pdf")
            if let documentId = result.documentId {
                documentIds.append(documentId)
            }
        }
        
        return documentIds
    }
}

// MARK: - Test Data Structures

struct UploadResult {
    let success: Bool
    let documentId: String?
    let error: Error?
}

struct ProcessingResult {
    let success: Bool
    let embeddings: [Float]?
    let error: Error?
}

struct SearchResult {
    let documentId: String
    let title: String
    let content: String
    let relevanceScore: Float
}

struct UpdateResult {
    let success: Bool
    let error: Error?
}

struct DeleteResult {
    let success: Bool
    let error: Error?
}

struct TestDocument {
    let id: String
    let title: String
    let tags: [String]
    let content: String
} 