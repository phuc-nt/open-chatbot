import XCTest
import CoreData
@testable import OpenChatbot

class CoreDataVectorServiceOptimizationTests: XCTestCase {
    
    var vectorService: CoreDataVectorService!
    var testContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    
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
        
        testContext = testContainer.viewContext
        let testPersistenceController = PersistenceController(container: testContainer)
        vectorService = CoreDataVectorService(persistenceController: testPersistenceController)
    }
    
    override func tearDown() async throws {
        vectorService = nil
        testContainer = nil
        testContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Optimization Strategy Tests
    
    func testSmallCollectionOptimizationStrategy() async {
        // Given: Small collection (≤500 embeddings)
        let testDocumentID = UUID()
        let smallCollectionSize = 50
        
        // Create small collection of embeddings
        for i in 0..<smallCollectionSize {
            let embedding = createMockEmbedding(dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Small collection test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Perform similarity search
        let queryEmbedding = createMockEmbedding(dimension: 768)
        let startTime = Date()
        
        do {
            let results = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 5,
                threshold: 0.1
            )
            
            let searchTime = Date().timeIntervalSince(startTime)
            
            // Then: Should use fast small collection strategy
            XCTAssertGreaterThan(results.count, 0, "Should find results in small collection")
            XCTAssertLessThan(searchTime, 0.5, "Small collection search should be fast")
            
            print("🏃‍♂️ Small collection search time: \(String(format: "%.3f", searchTime))s")
            
        } catch {
            XCTFail("Small collection search should not fail: \(error)")
        }
    }
    
    func testLargeCollectionOptimizationStrategy() async {
        // Given: Large collection (>500 embeddings)
        let testDocumentID = UUID()
        let largeCollectionSize = 600
        
        // Create large collection of embeddings
        for i in 0..<largeCollectionSize {
            let embedding = createMockEmbedding(dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Large collection test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Perform similarity search
        let queryEmbedding = createMockEmbedding(dimension: 768)
        let startTime = Date()
        
        do {
            let results = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 10,
                threshold: 0.1
            )
            
            let searchTime = Date().timeIntervalSince(startTime)
            
            // Then: Should use optimized large collection strategy with early termination
            XCTAssertGreaterThan(results.count, 0, "Should find results in large collection")
            XCTAssertLessThan(searchTime, 5.0, "Large collection search should complete within reasonable time")
            
            print("🎯 Large collection search time: \(String(format: "%.3f", searchTime))s")
            
        } catch {
            XCTFail("Large collection search should not fail: \(error)")
        }
    }
    
    func testBatchProcessingEfficiency() async {
        // Given: Collection designed to test batch processing
        let testDocumentID = UUID()
        let batchTestSize = 300
        
        // Create embeddings with varied similarity
        for i in 0..<batchTestSize {
            let embedding = createVariedSimilarityEmbedding(index: i, dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Batch test chunk \(i) with content variation",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Perform similarity search with different batch sizes
        let queryEmbedding = createMockEmbedding(dimension: 768)
        
        do {
            let results = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 20,
                threshold: 0.1
            )
            
            // Then: Should process in batches efficiently
            XCTAssertGreaterThan(results.count, 0, "Should find results with batch processing")
            
            // Results should be sorted by similarity
            for i in 0..<(results.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    results[i].similarity,
                    results[i + 1].similarity,
                    "Results should be sorted by similarity score"
                )
            }
            
        } catch {
            XCTFail("Batch processing search should not fail: \(error)")
        }
    }
    
    func testDynamicThresholdAdjustment() async {
        // Given: Collection with mixed quality results
        let testDocumentID = UUID()
        let mixedQualitySize = 100
        
        // Create embeddings with intentionally varied quality
        for i in 0..<mixedQualitySize {
            let embedding = createQualityVariedEmbedding(index: i, dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Quality test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Search with low threshold to test dynamic adjustment
        let queryEmbedding = createHighQualityEmbedding(dimension: 768)
        
        do {
            let results = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 10,
                threshold: 0.1  // Low threshold to test dynamic adjustment
            )
            
            // Then: Should dynamically adjust threshold to filter poor results
            XCTAssertGreaterThan(results.count, 0, "Should find results")
            XCTAssertLessThanOrEqual(results.count, 10, "Should respect topK limit")
            
            // All results should be above minimum quality
            for result in results {
                XCTAssertGreaterThanOrEqual(result.similarity, 0.1, "All results should meet minimum threshold")
            }
            
        } catch {
            XCTFail("Dynamic threshold adjustment search should not fail: \(error)")
        }
    }
    
    func testEarlyTerminationEfficiency() async {
        // Given: Large collection with high-quality results at the beginning
        let testDocumentID = UUID()
        let frontLoadedSize = 800
        
        // Create high-quality results first, then lower quality
        for i in 0..<frontLoadedSize {
            let embedding: [Float]
            if i < 50 {
                // High-quality embeddings first
                embedding = createHighQualityEmbedding(dimension: 768)
            } else {
                // Lower quality embeddings later
                embedding = createLowQualityEmbedding(dimension: 768)
            }
            
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Early termination test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Search with query similar to high-quality embeddings
        let queryEmbedding = createHighQualityEmbedding(dimension: 768)
        let startTime = Date()
        
        do {
            let results = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 5,
                threshold: 0.7  // High threshold to trigger early termination
            )
            
            let searchTime = Date().timeIntervalSince(startTime)
            
            // Then: Should terminate early when enough high-quality results found
            XCTAssertGreaterThan(results.count, 0, "Should find high-quality results")
            XCTAssertLessThan(searchTime, 3.0, "Should terminate early and be faster")
            
            // Results should be high quality
            for result in results {
                XCTAssertGreaterThanOrEqual(result.similarity, 0.7, "Results should be high quality")
            }
            
            print("⚡ Early termination search time: \(String(format: "%.3f", searchTime))s")
            
        } catch {
            XCTFail("Early termination search should not fail: \(error)")
        }
    }
    
    func testMemoryEfficiencyOptimization() async {
        // Given: Memory-intensive scenario
        let testDocumentID = UUID()
        let memoryTestSize = 200
        
        // Create embeddings to test memory efficiency
        for i in 0..<memoryTestSize {
            let embedding = createMockEmbedding(dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Memory test chunk \(i) with longer content to test memory usage patterns",
                    embedding: embedding,
                    chunkIndex: i,
                    metadata: [
                        "memory_test": true,
                        "chunk_size": "large",
                        "test_metadata": String(repeating: "data", count: 100)
                    ],
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Perform multiple searches to test memory efficiency
        let queryEmbedding = createMockEmbedding(dimension: 768)
        
        for iteration in 0..<5 {
            do {
                let results = try await vectorService.similaritySearch(
                    queryEmbedding: queryEmbedding,
                    topK: 10,
                    threshold: 0.1
                )
                
                // Then: Should handle memory efficiently without crashes
                XCTAssertGreaterThan(results.count, 0, "Should find results in iteration \(iteration)")
                
            } catch {
                XCTFail("Memory efficiency test iteration \(iteration) should not fail: \(error)")
            }
        }
    }
    
    func testFilterOptimization() async {
        // Given: Mixed document and language data
        let documentID1 = UUID()
        let documentID2 = UUID()
        let documentID3 = UUID()
        
        // Create embeddings for different documents and languages
        for i in 0..<50 {
            let embedding = createMockEmbedding(dimension: 768)
            
            let docID = i % 3 == 0 ? documentID1 : (i % 3 == 1 ? documentID2 : documentID3)
            let language = i % 2 == 0 ? "en" : "vi"
            
            do {
                try await vectorService.saveEmbedding(
                    documentID: docID,
                    chunkText: "Filter test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: language
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Search with document ID filter
        let queryEmbedding = createMockEmbedding(dimension: 768)
        
        do {
            let filteredResults = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 10,
                threshold: 0.1,
                documentIDs: [documentID1, documentID2],
                language: "en"
            )
            
            // Then: Should efficiently filter results
            XCTAssertGreaterThan(filteredResults.count, 0, "Should find filtered results")
            
            // All results should match filters
            for result in filteredResults {
                let resultDocID = UUID(uuidString: result.documentID)
                XCTAssertTrue(
                    resultDocID == documentID1 || resultDocID == documentID2,
                    "Result should match document ID filter"
                )
            }
            
        } catch {
            XCTFail("Filter optimization search should not fail: \(error)")
        }
    }
    
    func testPerformanceComparison() async {
        // Given: Performance test setup
        let testDocumentID = UUID()
        let performanceTestSize = 400
        
        // Create performance test data
        for i in 0..<performanceTestSize {
            let embedding = createMockEmbedding(dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Performance test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Measure search performance with different parameters
        let queryEmbedding = createMockEmbedding(dimension: 768)
        
        // Test 1: Small topK
        let startTime1 = Date()
        do {
            let results1 = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 5,
                threshold: 0.1
            )
            let time1 = Date().timeIntervalSince(startTime1)
            
            // Test 2: Large topK
            let startTime2 = Date()
            let results2 = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: 50,
                threshold: 0.1
            )
            let time2 = Date().timeIntervalSince(startTime2)
            
            // Then: Should scale reasonably with topK size
            XCTAssertGreaterThan(results1.count, 0, "Should find results with small topK")
            XCTAssertGreaterThan(results2.count, 0, "Should find results with large topK")
            XCTAssertLessThan(time1, 2.0, "Small topK search should be fast")
            XCTAssertLessThan(time2, 5.0, "Large topK search should complete within reasonable time")
            
            print("📊 Performance comparison:")
            print("   Small topK (5): \(String(format: "%.3f", time1))s")
            print("   Large topK (50): \(String(format: "%.3f", time2))s")
            
        } catch {
            XCTFail("Performance comparison should not fail: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockEmbedding(dimension: Int = 768) -> [Float] {
        return (0..<dimension).map { _ in Float.random(in: -1...1) }
    }
    
    private func createVariedSimilarityEmbedding(index: Int, dimension: Int = 768) -> [Float] {
        let baseValue = Float(index % 10) / 10.0 - 0.5  // Varies from -0.5 to 0.4
        return (0..<dimension).map { i in
            baseValue + Float.random(in: -0.1...0.1)
        }
    }
    
    private func createQualityVariedEmbedding(index: Int, dimension: Int = 768) -> [Float] {
        if index < 20 {
            // High quality embeddings (more consistent)
            let baseValue: Float = 0.8
            return (0..<dimension).map { _ in baseValue + Float.random(in: -0.1...0.1) }
        } else {
            // Lower quality embeddings (more random)
            return (0..<dimension).map { _ in Float.random(in: -1...1) }
        }
    }
    
    private func createHighQualityEmbedding(dimension: Int = 768) -> [Float] {
        // Consistent high-quality embedding for testing
        let baseValue: Float = 0.9
        return (0..<dimension).map { i in
            baseValue * cos(Float(i) * 0.1) + Float.random(in: -0.05...0.05)
        }
    }
    
    private func createLowQualityEmbedding(dimension: Int = 768) -> [Float] {
        // Random low-quality embedding
        return (0..<dimension).map { _ in Float.random(in: -0.3...0.3) }
    }
}

extension CoreDataVectorServiceOptimizationTests {
    
    func testOptimizationMetrics() async {
        // Given: Test data for measuring optimization effectiveness
        let testDocumentID = UUID()
        let metricsTestSize = 300
        
        // Create test embeddings
        for i in 0..<metricsTestSize {
            let embedding = createMockEmbedding(dimension: 768)
            do {
                try await vectorService.saveEmbedding(
                    documentID: testDocumentID,
                    chunkText: "Metrics test chunk \(i)",
                    embedding: embedding,
                    chunkIndex: i,
                    language: "en"
                )
            } catch {
                XCTFail("Failed to save embedding \(i): \(error)")
            }
        }
        
        // When: Perform multiple searches to gather metrics
        let queryEmbedding = createMockEmbedding(dimension: 768)
        var searchTimes: [TimeInterval] = []
        
        for _ in 0..<10 {
            let startTime = Date()
            do {
                let _ = try await vectorService.similaritySearch(
                    queryEmbedding: queryEmbedding,
                    topK: 10,
                    threshold: 0.1
                )
                let searchTime = Date().timeIntervalSince(startTime)
                searchTimes.append(searchTime)
            } catch {
                XCTFail("Metrics test search should not fail: \(error)")
            }
        }
        
        // Then: Analyze optimization metrics
        let averageTime = searchTimes.reduce(0, +) / Double(searchTimes.count)
        let maxTime = searchTimes.max() ?? 0
        let minTime = searchTimes.min() ?? 0
        
        XCTAssertLessThan(averageTime, 1.0, "Average search time should be under 1 second")
        XCTAssertLessThan(maxTime - minTime, 2.0, "Search time variance should be reasonable")
        
        print("📈 Optimization Metrics:")
        print("   Average search time: \(String(format: "%.3f", averageTime))s")
        print("   Min/Max search time: \(String(format: "%.3f", minTime))s / \(String(format: "%.3f", maxTime))s")
        print("   Time variance: \(String(format: "%.3f", maxTime - minTime))s")
    }
}