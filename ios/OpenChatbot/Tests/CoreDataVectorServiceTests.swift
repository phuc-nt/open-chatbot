import XCTest
import CoreData
@testable import OpenChatbot

/// Tests for CoreDataVectorService - Vector database với Core Data Vector Search
class CoreDataVectorServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var vectorService: CoreDataVectorService!
    var testContext: NSManagedObjectContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        setupInMemoryPersistenceStack()
    }
    
    override func tearDown() {
        vectorService = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupInMemoryPersistenceStack() {
        let container = NSPersistentContainer(name: "OpenChatbot")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test stores")
        }
        
        testContext = container.viewContext
        vectorService = CoreDataVectorService(context: testContext)
    }
    
    // MARK: - Test Data Helpers
    
    private func createTestEmbedding() -> [Float] {
        // Create consistent test embedding vector (512 dimensions)
        return (0..<512).map { Float($0) / 512.0 }
    }
    
    private func createSimilarEmbedding(to original: [Float], similarity: Float = 0.9) -> [Float] {
        // Create slightly modified embedding to test similarity
        return original.enumerated().map { index, value in
            let noise = Float.random(in: -0.1...0.1) * (1.0 - similarity)
            return value + noise
        }
    }
    
    // MARK: - Basic Functionality Tests
    
    func testVectorServiceInitialization() {
        XCTAssertNotNil(vectorService, "VectorService should initialize successfully")
    }
    
    func testSaveEmbedding() async {
        // Given
        let documentID = UUID()
        let chunkText = "Test document content for embedding"
        let embedding = createTestEmbedding()
        let metadata: [String: Any] = ["document_title": "Test Document", "chunk_index": 0]
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: chunkText,
                embedding: embedding,
                chunkIndex: 0,
                metadata: metadata,
                language: "vi"
            )
            
            // Then
            let count = try await vectorService.getEmbeddingCount(forDocumentID: documentID)
            XCTAssertEqual(count, 1, "Should save one embedding")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testBatchInsertEmbeddings() async {
        // Given
        let documentID = UUID()
        let embeddings = [
            (documentID, "First chunk", createTestEmbedding(), 0, ["title": "Test"], "vi"),
            (documentID, "Second chunk", createTestEmbedding(), 1, ["title": "Test"], "vi"),
            (documentID, "Third chunk", createTestEmbedding(), 2, ["title": "Test"], "vi")
        ]
        
        // When
        do {
            try await vectorService.batchInsertEmbeddings(embeddings)
            
            // Then
            let count = try await vectorService.getEmbeddingCount(forDocumentID: documentID)
            XCTAssertEqual(count, 3, "Should save three embeddings")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testGetEmbeddingCount() async {
        // Given
        let documentID1 = UUID()
        let documentID2 = UUID()
        let embedding = createTestEmbedding()
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID1,
                chunkText: "Document 1 content",
                embedding: embedding
            )
            
            try await vectorService.saveEmbedding(
                documentID: documentID2,
                chunkText: "Document 2 content",
                embedding: embedding
            )
            
            // Then
            let totalCount = try await vectorService.getEmbeddingCount()
            let doc1Count = try await vectorService.getEmbeddingCount(forDocumentID: documentID1)
            let doc2Count = try await vectorService.getEmbeddingCount(forDocumentID: documentID2)
            
            XCTAssertEqual(totalCount, 2, "Should have 2 total embeddings")
            XCTAssertEqual(doc1Count, 1, "Document 1 should have 1 embedding")
            XCTAssertEqual(doc2Count, 1, "Document 2 should have 1 embedding")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testDeleteEmbeddings() async {
        // Given
        let documentID = UUID()
        let embedding = createTestEmbedding()
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Test content",
                embedding: embedding
            )
            
            let countBefore = try await vectorService.getEmbeddingCount(forDocumentID: documentID)
            XCTAssertEqual(countBefore, 1, "Should have 1 embedding before deletion")
            
            try await vectorService.deleteEmbeddings(forDocumentID: documentID)
            
            // Then
            let countAfter = try await vectorService.getEmbeddingCount(forDocumentID: documentID)
            XCTAssertEqual(countAfter, 0, "Should have 0 embeddings after deletion")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    // MARK: - Similarity Search Tests
    
    func testSimilaritySearchBasic() async {
        // Given
        let documentID = UUID()
        let originalEmbedding = createTestEmbedding()
        let similarEmbedding = createSimilarEmbedding(to: originalEmbedding, similarity: 0.9)
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Test document for similarity search",
                embedding: originalEmbedding,
                metadata: ["test": "value"]
            )
            
            let results = try await vectorService.similaritySearch(
                queryEmbedding: similarEmbedding,
                topK: 5,
                threshold: 0.5
            )
            
            // Then
            XCTAssertFalse(results.isEmpty, "Should find similar results")
            XCTAssertEqual(results.first?.documentID, documentID.uuidString, "Should find correct document")
            XCTAssertEqual(results.first?.chunkText, "Test document for similarity search", "Should return correct text")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testSimilaritySearchWithLanguageFilter() async {
        // Given
        let documentID = UUID()
        let embedding = createTestEmbedding()
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Vietnamese content",
                embedding: embedding,
                language: "vi"
            )
            
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "English content",
                embedding: embedding,
                language: "en"
            )
            
            let vietnameseResults = try await vectorService.similaritySearch(
                queryEmbedding: embedding,
                language: "vi"
            )
            
            let englishResults = try await vectorService.similaritySearch(
                queryEmbedding: embedding,
                language: "en"
            )
            
            // Then
            XCTAssertEqual(vietnameseResults.count, 1, "Should find 1 Vietnamese result")
            XCTAssertEqual(englishResults.count, 1, "Should find 1 English result")
            XCTAssertEqual(vietnameseResults.first?.chunkText, "Vietnamese content")
            XCTAssertEqual(englishResults.first?.chunkText, "English content")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testSimilaritySearchWithDocumentFilter() async {
        // Given
        let documentID1 = UUID()
        let documentID2 = UUID()
        let embedding = createTestEmbedding()
        
        // When
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID1,
                chunkText: "Document 1 content",
                embedding: embedding
            )
            
            try await vectorService.saveEmbedding(
                documentID: documentID2,
                chunkText: "Document 2 content",
                embedding: embedding
            )
            
            let filteredResults = try await vectorService.similaritySearch(
                queryEmbedding: embedding,
                documentIDs: [documentID1]
            )
            
            // Then
            XCTAssertEqual(filteredResults.count, 1, "Should find 1 filtered result")
            XCTAssertEqual(filteredResults.first?.documentID, documentID1.uuidString)
            XCTAssertEqual(filteredResults.first?.chunkText, "Document 1 content")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testSimilaritySearchTopK() async {
        // Given
        let documentID = UUID()
        let baseEmbedding = createTestEmbedding()
        
        // When
        do {
            // Insert 5 similar embeddings
            for i in 0..<5 {
                let embedding = createSimilarEmbedding(to: baseEmbedding, similarity: 0.8)
                try await vectorService.saveEmbedding(
                    documentID: documentID,
                    chunkText: "Content \(i)",
                    embedding: embedding,
                    chunkIndex: i
                )
            }
            
            let results = try await vectorService.similaritySearch(
                queryEmbedding: baseEmbedding,
                topK: 3
            )
            
            // Then
            XCTAssertEqual(results.count, 3, "Should return top 3 results")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingInvalidEmbedding() async {
        // Given
        let documentID = UUID()
        let invalidEmbedding: [Float] = [] // Empty embedding
        
        // When/Then
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Test",
                embedding: invalidEmbedding
            )
            // Should still succeed as Core Data handles empty data
        } catch {
            // Expected behavior for invalid input
            XCTAssertTrue(error is VectorDatabaseError, "Should throw VectorDatabaseError")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceBatchInsert() async {
        // Given
        let documentID = UUID()
        let embedding = createTestEmbedding()
        let batchSize = 100
        
        let embeddings = (0..<batchSize).map { index in
            (documentID, "Content \(index)", embedding, index, ["index": index], "vi")
        }
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try await vectorService.batchInsertEmbeddings(embeddings)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // Then
            let count = try await vectorService.getEmbeddingCount(forDocumentID: documentID)
            XCTAssertEqual(count, batchSize, "Should insert all embeddings")
            XCTAssertLessThan(executionTime, 5.0, "Batch insert should complete within 5 seconds")
            
            print("Batch insert of \(batchSize) embeddings took \(executionTime) seconds")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPerformanceSimilaritySearch() async {
        // Given
        let documentID = UUID()
        let embedding = createTestEmbedding()
        let searchSize = 50
        
        // Setup data
        do {
            let embeddings = (0..<searchSize).map { index in
                (documentID, "Content \(index)", createSimilarEmbedding(to: embedding), index, ["index": index], "vi")
            }
            
            try await vectorService.batchInsertEmbeddings(embeddings)
            
            // When
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let results = try await vectorService.similaritySearch(
                queryEmbedding: embedding,
                topK: 10
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // Then
            XCTAssertFalse(results.isEmpty, "Should find similar results")
            XCTAssertLessThan(executionTime, 1.0, "Similarity search should complete within 1 second")
            
            print("Similarity search among \(searchSize) embeddings took \(executionTime) seconds")
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
} 