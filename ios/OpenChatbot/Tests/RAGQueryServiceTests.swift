import XCTest
import CoreData
@testable import OpenChatbot

final class RAGQueryServiceTests: XCTestCase {
    
    private var ragService: RAGQueryService!
    private var embeddingService: EmbeddingService!
    private var vectorService: CoreDataVectorService!
    private var testContainer: NSPersistentContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup in-memory Core Data stack
        testContainer = NSPersistentContainer(name: "OpenChatbot")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        testContainer.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        let testPersistenceController = PersistenceController(container: testContainer)
        
        // Setup services
        embeddingService = EmbeddingService()
        vectorService = CoreDataVectorService(persistenceController: testPersistenceController)
        ragService = RAGQueryService(
            embeddingService: embeddingService,
            vectorService: vectorService
        )
    }
    
    override func tearDown() async throws {
        ragService = nil
        embeddingService = nil
        vectorService = nil
        testContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func testRAGServiceInitialization() {
        XCTAssertNotNil(ragService)
    }
    
    func testQueryDocumentsWithEmptyQuery() async {
        do {
            _ = try await ragService.queryDocuments(
                query: "",
                language: nil,
                topK: 5,
                threshold: 0.7
            )
            XCTFail("Should throw error for empty query")
        } catch let error as RAGQueryError {
            XCTAssertEqual(error, RAGQueryError.invalidQuery("Query cannot be empty"))
        } catch {
            XCTFail("Should throw RAGQueryError, got: \(error)")
        }
    }
    
    func testQueryDocumentsBasic() async {
        // Given: Setup test document
        let documentID = UUID()
        let testEmbedding = createTestEmbedding()
        
        do {
            // Save test document
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Test document about artificial intelligence and machine learning",
                embedding: testEmbedding,
                language: "en",
                metadata: ["title": "AI Guide"]
            )
            
            // When: Query documents
            let result = try await ragService.queryDocuments(
                query: "What is artificial intelligence?",
                language: "en",
                topK: 3,
                threshold: 0.5
            )
            
            // Then: Verify results
            XCTAssertEqual(result.query, "What is artificial intelligence?")
            XCTAssertEqual(result.language, "en")
            XCTAssertGreaterThan(result.processingTime, 0)
            XCTAssertGreaterThan(result.totalCandidates, 0)
            
            // Should have context
            XCTAssertFalse(result.context.contextText.isEmpty)
            XCTAssertGreaterThan(result.context.totalChunks, 0)
            XCTAssertGreaterThan(result.context.contextLength, 0)
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testQueryDocumentsWithMultipleDocuments() async {
        // Given: Setup multiple test documents
        let doc1ID = UUID()
        let doc2ID = UUID()
        let doc3ID = UUID()
        
        let embedding1 = createTestEmbedding()
        let embedding2 = createSimilarEmbedding(to: embedding1, similarity: 0.8)
        let embedding3 = createDifferentEmbedding()
        
        do {
            // Save multiple documents
            try await vectorService.saveEmbedding(
                documentID: doc1ID,
                chunkText: "Artificial intelligence is the simulation of human intelligence",
                embedding: embedding1,
                language: "en"
            )
            
            try await vectorService.saveEmbedding(
                documentID: doc2ID, 
                chunkText: "Machine learning is a subset of artificial intelligence",
                embedding: embedding2,
                language: "en"
            )
            
            try await vectorService.saveEmbedding(
                documentID: doc3ID,
                chunkText: "Cooking recipes for Vietnamese cuisine",
                embedding: embedding3,
                language: "en"
            )
            
            // When: Query for AI-related content
            let result = try await ragService.queryDocuments(
                query: "Tell me about AI and machine learning",
                language: "en",
                topK: 5,
                threshold: 0.6
            )
            
            // Then: Should find relevant AI documents
            XCTAssertGreaterThan(result.results.count, 0)
            XCTAssertLessThanOrEqual(result.results.count, 5)
            
            // Results should be sorted by relevance
            if result.results.count > 1 {
                for i in 0..<(result.results.count - 1) {
                    XCTAssertGreaterThanOrEqual(
                        result.results[i].relevanceScore,
                        result.results[i + 1].relevanceScore,
                        "Results should be sorted by relevance score"
                    )
                }
            }
            
            // Context should contain relevant information
            XCTAssertTrue(
                result.context.contextText.lowercased().contains("artificial") ||
                result.context.contextText.lowercased().contains("intelligence") ||
                result.context.contextText.lowercased().contains("machine"),
                "Context should contain AI-related terms"
            )
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testScopedQuery() async {
        // Given: Setup documents in different scopes
        let targetDocID = UUID()
        let otherDocID = UUID()
        
        let targetEmbedding = createTestEmbedding()
        let otherEmbedding = createTestEmbedding()
        
        do {
            // Save documents
            try await vectorService.saveEmbedding(
                documentID: targetDocID,
                chunkText: "Target document with specific information",
                embedding: targetEmbedding,
                language: "en"
            )
            
            try await vectorService.saveEmbedding(
                documentID: otherDocID,
                chunkText: "Other document with different information", 
                embedding: otherEmbedding,
                language: "en"
            )
            
            // When: Query with document scope
            let result = try await ragService.queryDocumentsInScope(
                query: "specific information",
                documentIDs: [targetDocID.uuidString],
                language: "en",
                topK: 5,
                threshold: 0.5
            )
            
            // Then: Should only find document in scope
            for scoredResult in result.results {
                XCTAssertEqual(
                    scoredResult.similarityResult.documentID,
                    targetDocID.uuidString,
                    "Should only return results from target document"
                )
            }
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testContextBuilding() async {
        // Given: Create similarity results
        let results = [
            SimilarityResult(
                id: "1",
                documentID: "doc1",
                chunkText: "First chunk of text",
                similarity: 0.9,
                chunkIndex: 0,
                metadata: [:]
            ),
            SimilarityResult(
                id: "2", 
                documentID: "doc2",
                chunkText: "Second chunk of text",
                similarity: 0.8,
                chunkIndex: 1,
                metadata: [:]
            )
        ]
        
        do {
            // When: Build context
            let context = try await ragService.buildContext(from: results)
            
            // Then: Verify context
            XCTAssertFalse(context.contextText.isEmpty)
            XCTAssertEqual(context.totalChunks, 2)
            XCTAssertEqual(context.sourceDocuments.count, 2)
            XCTAssertGreaterThan(context.contextLength, 0)
            XCTAssertGreaterThan(context.averageRelevance, 0)
            
            // Context should contain both chunks
            XCTAssertTrue(context.contextText.contains("First chunk"))
            XCTAssertTrue(context.contextText.contains("Second chunk"))
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testRelevanceScoring() async {
        // Given: Create test results
        let query = "artificial intelligence"
        let results = [
            SimilarityResult(
                id: "1",
                documentID: "doc1",
                chunkText: "Artificial intelligence is fascinating technology",
                similarity: 0.8,
                chunkIndex: 0,
                metadata: [:]
            ),
            SimilarityResult(
                id: "2",
                documentID: "doc2", 
                chunkText: "Cooking is an art form",
                similarity: 0.6,
                chunkIndex: 1,
                metadata: [:]
            )
        ]
        
        do {
            // When: Score relevance
            let scoredResults = try await ragService.scoreRelevance(query: query, results: results)
            
            // Then: Verify scoring
            XCTAssertGreaterThan(scoredResults.count, 0)
            
            // AI-related content should score higher
            if scoredResults.count > 1 {
                let aiResult = scoredResults.first { $0.similarityResult.chunkText.contains("intelligence") }
                let cookingResult = scoredResults.first { $0.similarityResult.chunkText.contains("Cooking") }
                
                if let ai = aiResult, let cooking = cookingResult {
                    XCTAssertGreaterThan(ai.relevanceScore, cooking.relevanceScore,
                                       "AI content should score higher for AI query")
                }
            }
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testPerformanceRequirement() async {
        // Given: Setup test document
        let documentID = UUID()
        let testEmbedding = createTestEmbedding()
        
        do {
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: "Performance test document",
                embedding: testEmbedding,
                language: "en"
            )
            
            // When: Measure query performance
            let startTime = Date()
            
            let result = try await ragService.queryDocuments(
                query: "test",
                language: "en",
                topK: 5,
                threshold: 0.5
            )
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            // Then: Verify performance requirement (<1 second)
            XCTAssertLessThan(executionTime, 1.0, "Query should complete in less than 1 second")
            XCTAssertLessThan(result.processingTime, 1.0, "Processing time should be less than 1 second")
            
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestEmbedding() -> [Float] {
        return (0..<512).map { _ in Float.random(in: -1...1) }
    }
    
    private func createSimilarEmbedding(to original: [Float], similarity: Float) -> [Float] {
        return original.map { value in
            let noise = Float.random(in: -0.1...0.1) * (1.0 - similarity)
            return value + noise
        }
    }
    
    private func createDifferentEmbedding() -> [Float] {
        // Create a clearly different embedding
        let base: Float = 0.5
        return (0..<512).map { index in
            index % 2 == 0 ? base : -base
        }
    }
} 