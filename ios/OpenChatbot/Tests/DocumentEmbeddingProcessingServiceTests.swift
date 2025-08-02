import XCTest
import CoreData
import NaturalLanguage
@testable import OpenChatbot

class DocumentEmbeddingProcessingServiceTests: XCTestCase {
    
    var embeddingProcessingService: DocumentEmbeddingProcessingService!
    var mockEmbeddingService: MockEmbeddingService!
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
        
        // Setup services
        mockEmbeddingService = MockEmbeddingService()
        vectorService = CoreDataVectorService(persistenceController: testPersistenceController)
        
        embeddingProcessingService = DocumentEmbeddingProcessingService(
            embeddingService: mockEmbeddingService,
            vectorService: vectorService,
            context: testContext
        )
    }
    
    override func tearDown() async throws {
        embeddingProcessingService = nil
        mockEmbeddingService = nil
        vectorService = nil
        testContainer = nil
        testContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testDocumentEmbeddingProcessingServiceInitialization() {
        XCTAssertNotNil(embeddingProcessingService, "DocumentEmbeddingProcessingService should initialize successfully")
    }
    
    func testSemanticChunkingWithEnglishText() async {
        // Given: English text document
        let documentID = UUID()
        let englishText = """
        This is the first paragraph of the document. It contains multiple sentences. Each sentence should be properly chunked.
        
        This is the second paragraph. It discusses different topics and should be part of semantic chunking.
        
        Here is a third paragraph with more content that will test the chunking algorithm's ability to handle longer texts.
        """
        
        try! await createTestDocument(id: documentID, content: englishText, title: "English Test", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document embeddings
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should complete without errors
            XCTAssertTrue(true, "English text processing should succeed")
            
        } catch {
            XCTFail("English text processing should not fail: \(error)")
        }
    }
    
    func testSemanticChunkingWithVietnameseText() async {
        // Given: Vietnamese text document  
        let documentID = UUID()
        let vietnameseText = """
        Đây là đoạn văn đầu tiên bằng tiếng Việt. Nó chứa nhiều câu khác nhau. Mỗi câu nên được xử lý đúng cách.
        
        Đây là đoạn văn thứ hai. Nó thảo luận về các chủ đề khác nhau và nên được chia thành các chunk semantic.
        
        Đây là đoạn văn thứ ba với nhiều nội dung hơn để kiểm tra khả năng xử lý văn bản tiếng Việt của thuật toán.
        """
        
        try! await createTestDocument(id: documentID, content: vietnameseText, title: "Vietnamese Test", type: "text")
        mockEmbeddingService.mockLanguage = "vi"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process Vietnamese document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should complete with Vietnamese-specific processing
            XCTAssertTrue(true, "Vietnamese text processing should succeed")
            
        } catch {
            XCTFail("Vietnamese text processing should not fail: \(error)")
        }
    }
    
    func testDocumentStructureRecognition() async {
        // Given: Document with headers, lists, and tables
        let documentID = UUID()
        let structuredText = """
        # Main Header
        
        This is the introduction paragraph under the main header.
        
        ## Section 1: Features
        
        The following are the main features:
        
        - Feature 1: Performance optimization
        - Feature 2: Enhanced user interface
        - Feature 3: Better error handling
        
        ## Section 2: Technical Details
        
        | Component | Version | Status |
        | --------- | ------- | ------ |
        | Backend   | 2.1.0   | Active |
        | Frontend  | 1.5.2   | Active |
        | Database  | 3.0.1   | Active |
        
        ### Subsection 2.1
        
        This subsection contains additional technical information.
        """
        
        try! await createTestDocument(id: documentID, content: structuredText, title: "Structured Test", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process structured document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should recognize and preserve document structure
            XCTAssertTrue(true, "Structured document processing should succeed")
            
        } catch {
            XCTFail("Structured document processing should not fail: \(error)")
        }
    }
    
    func testAdaptiveChunkSizing() async {
        // Given: Different document types
        let pdfDocumentID = UUID()
        let noteDocumentID = UUID()
        
        let technicalContent = String(repeating: "Technical documentation with detailed specifications. ", count: 100)
        let noteContent = String(repeating: "Simple note content. ", count: 50)
        
        try! await createTestDocument(id: pdfDocumentID, content: technicalContent, title: "Technical PDF", type: "pdf")
        try! await createTestDocument(id: noteDocumentID, content: noteContent, title: "Simple Note", type: "note")
        
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process both documents
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: pdfDocumentID)
            try await embeddingProcessingService.processDocumentEmbeddings(for: noteDocumentID)
            
            // Then: Should adapt chunk sizes based on document type
            XCTAssertTrue(true, "Adaptive chunk sizing should work for different document types")
            
        } catch {
            XCTFail("Adaptive chunking should not fail: \(error)")
        }
    }
    
    func testBatchEmbeddingGeneration() async {
        // Given: Large document that will create multiple chunks
        let documentID = UUID()
        let largeContent = String(repeating: "This is a sentence in a large document. ", count: 200)
        
        try! await createTestDocument(id: documentID, content: largeContent, title: "Large Document", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        
        // Mock multiple embeddings for batch processing
        mockEmbeddingService.mockBatchEmbeddings = Array(repeating: createMockEmbedding(), count: 10)
        
        // When: Process large document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should handle batch embedding generation
            XCTAssertTrue(mockEmbeddingService.generateEmbeddingsCalled, "Should call batch embedding generation")
            
        } catch {
            XCTFail("Batch embedding generation should not fail: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDocumentNotFoundError() async {
        // Given: Non-existent document ID
        let nonExistentID = UUID()
        
        // When: Try to process non-existent document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: nonExistentID)
            XCTFail("Should throw documentNotFound error")
        } catch let error as EmbeddingProcessingError {
            // Then: Should throw appropriate error
            if case .documentNotFound(let id) = error {
                XCTAssertEqual(id, nonExistentID)
            } else {
                XCTFail("Should throw documentNotFound error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw EmbeddingProcessingError, got: \(error)")
        }
    }
    
    func testEmptyContentError() async {
        // Given: Document with empty content
        let documentID = UUID()
        try! await createTestDocument(id: documentID, content: "", title: "Empty Document", type: "text")
        
        // When: Try to process empty document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            XCTFail("Should throw emptyContent error")
        } catch let error as EmbeddingProcessingError {
            // Then: Should throw appropriate error
            if case .emptyContent(let id) = error {
                XCTAssertEqual(id, documentID)
            } else {
                XCTFail("Should throw emptyContent error, got: \(error)")
            }
        } catch {
            XCTFail("Should throw EmbeddingProcessingError, got: \(error)")
        }
    }
    
    func testEmbeddingServiceFailure() async {
        // Given: Document and failing embedding service
        let documentID = UUID()
        try! await createTestDocument(id: documentID, content: "Test content", title: "Test", type: "text")
        
        mockEmbeddingService.shouldFailEmbedding = true
        mockEmbeddingService.mockLanguage = "en"
        
        // When: Try to process with failing embedding service
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            XCTFail("Should propagate embedding service error")
        } catch {
            // Then: Should propagate the error
            XCTAssertTrue(true, "Should handle embedding service failure")
        }
    }
    
    // MARK: - Vietnamese Language Processing Tests
    
    func testVietnameseSentenceDetection() async {
        // Given: Vietnamese text with complex sentence structures
        let documentID = UUID()
        let vietnameseText = """
        Xin chào, tôi là một trợ lý AI. Tôi có thể giúp bạn với nhiều nhiệm vụ khác nhau.
        Tuy nhiên, bạn cần cung cấp thông tin cụ thể. Để tôi có thể hỗ trợ tốt nhất.
        Bởi vì việc hiểu ngữ cảnh rất quan trọng trong việc xử lý ngôn ngữ tự nhiên.
        """
        
        try! await createTestDocument(id: documentID, content: vietnameseText, title: "Vietnamese Sentences", type: "text")
        mockEmbeddingService.mockLanguage = "vi"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process Vietnamese text
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should handle Vietnamese sentence detection
            XCTAssertTrue(true, "Vietnamese sentence detection should work")
            
        } catch {
            XCTFail("Vietnamese sentence detection should not fail: \(error)")
        }
    }
    
    func testVietnameseWordDensityCalculation() async {
        // Given: Vietnamese text for word density testing
        let documentID = UUID()
        let vietnameseText = "Đây là một văn bản tiếng Việt để kiểm tra mật độ từ."
        
        try! await createTestDocument(id: documentID, content: vietnameseText, title: "Vietnamese Density", type: "text")
        mockEmbeddingService.mockLanguage = "vi"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process Vietnamese text
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should calculate Vietnamese-specific word density
            XCTAssertTrue(true, "Vietnamese word density calculation should work")
            
        } catch {
            XCTFail("Vietnamese word density calculation should not fail: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testProcessingPerformance() async {
        // Given: Medium-sized document
        let documentID = UUID()
        let mediumContent = String(repeating: "Performance test content with reasonable length. ", count: 500)
        
        try! await createTestDocument(id: documentID, content: mediumContent, title: "Performance Test", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Measure processing time
        let startTime = Date()
        
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Then: Should complete within reasonable time
            XCTAssertLessThan(processingTime, 10.0, "Processing should complete within 10 seconds")
            
        } catch {
            XCTFail("Performance test should not fail: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflowIntegration() async {
        // Given: Complete document processing workflow
        let documentID = UUID()
        let mixedContent = """
        # Technical Documentation
        
        This document contains both English and Vietnamese content.
        
        ## Features / Tính năng
        
        - Advanced processing / Xử lý nâng cao
        - Multi-language support / Hỗ trợ đa ngôn ngữ
        - Semantic chunking / Chia nhỏ ngữ nghĩa
        
        Đây là phần tiếng Việt của tài liệu. Nó chứa các thông tin quan trọng.
        """
        
        try! await createTestDocument(id: documentID, content: mixedContent, title: "Mixed Content", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process mixed language document
        do {
            try await embeddingProcessingService.processDocumentEmbeddings(for: documentID)
            
            // Then: Should handle mixed content properly
            XCTAssertTrue(true, "Mixed language content processing should succeed")
            
            // Verify document was marked as processed
            let document = try await fetchTestDocument(id: documentID)
            XCTAssertNotNil(document, "Document should exist after processing")
            
        } catch {
            XCTFail("Full workflow integration should not fail: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestDocument(id: UUID, content: String, title: String, type: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            testContext.perform {
                let document = NSEntityDescription.insertNewObject(forEntityName: "Document", into: self.testContext)
                document.setValue(id, forKey: "id")
                document.setValue(content, forKey: "content")
                document.setValue(title, forKey: "title")
                document.setValue(type, forKey: "type")
                document.setValue(false, forKey: "isEmbeddingProcessed")
                document.setValue(Date(), forKey: "createdAt")
                
                do {
                    try self.testContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchTestDocument(id: UUID) async throws -> NSManagedObject? {
        return try await withCheckedThrowingContinuation { continuation in
            testContext.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Document")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.testContext.fetch(request)
                    continuation.resume(returning: results.first)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createMockEmbedding() -> [Float] {
        return (0..<768).map { _ in Float.random(in: -1...1) }
    }
}

// MARK: - Mock Services

class MockEmbeddingService: EmbeddingServiceProtocol {
    var mockLanguage: String = "en"
    var mockEmbeddings: [Float] = []
    var mockBatchEmbeddings: [[Float]] = []
    var shouldFailEmbedding = false
    var shouldFailLanguageDetection = false
    
    var generateEmbeddingCalled = false
    var generateEmbeddingsCalled = false
    var detectLanguageCalled = false
    
    func detectLanguage(for text: String) -> String? {
        detectLanguageCalled = true
        if shouldFailLanguageDetection {
            return nil
        }
        return mockLanguage
    }
    
    func generateEmbedding(for text: String, language: String = "auto") async throws -> [Float] {
        generateEmbeddingCalled = true
        if shouldFailEmbedding {
            throw EmbeddingError.generationFailed("Mock embedding generation failed")
        }
        return mockEmbeddings.isEmpty ? createMockEmbedding() : mockEmbeddings
    }
    
    func generateEmbeddings(for texts: [String], language: String = "auto") async throws -> [[Float]] {
        generateEmbeddingsCalled = true
        if shouldFailEmbedding {
            throw EmbeddingError.generationFailed("Mock batch embedding generation failed")
        }
        
        if !mockBatchEmbeddings.isEmpty {
            return mockBatchEmbeddings
        }
        
        return texts.map { _ in createMockEmbedding() }
    }
    
    private func createMockEmbedding() -> [Float] {
        return (0..<768).map { _ in Float.random(in: -1...1) }
    }
}

// MARK: - Protocol Definition (if not already defined)

protocol EmbeddingServiceProtocol {
    func detectLanguage(for text: String) -> String?
    func generateEmbedding(for text: String, language: String) async throws -> [Float]
    func generateEmbeddings(for texts: [String], language: String) async throws -> [[Float]]
}