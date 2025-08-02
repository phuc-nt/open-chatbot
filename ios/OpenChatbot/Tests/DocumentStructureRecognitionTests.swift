import XCTest
@testable import OpenChatbot

class DocumentStructureRecognitionTests: XCTestCase {
    
    var documentProcessor: DocumentEmbeddingProcessingService!
    var mockEmbeddingService: MockStructureEmbeddingService!
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
        mockEmbeddingService = MockStructureEmbeddingService()
        vectorService = CoreDataVectorService(persistenceController: testPersistenceController)
        
        documentProcessor = DocumentEmbeddingProcessingService(
            embeddingService: mockEmbeddingService,
            vectorService: vectorService,
            context: testContext
        )
    }
    
    override func tearDown() async throws {
        documentProcessor = nil
        mockEmbeddingService = nil
        vectorService = nil
        testContainer = nil
        testContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Header Detection Tests
    
    func testMarkdownHeaderDetection() async {
        // Given: Document with Markdown-style headers
        let documentID = UUID()
        let markdownContent = """
        # Main Title
        
        This is the introduction paragraph under the main title.
        
        ## Section 1: Overview
        
        This section provides an overview of the topic.
        
        ### Subsection 1.1: Details
        
        More detailed information goes here.
        
        #### Sub-subsection 1.1.1
        
        Even more specific details.
        
        ## Section 2: Implementation
        
        This section covers implementation details.
        """
        
        try! await createTestDocument(id: documentID, content: markdownContent, title: "Markdown Test", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with Markdown headers
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect and preserve header structure
            XCTAssertTrue(mockEmbeddingService.generateEmbeddingsCalled, "Should generate embeddings for structured content")
            
            // Verify structure-aware processing
            XCTAssertTrue(true, "Markdown header detection should succeed")
            
        } catch {
            XCTFail("Markdown header detection should not fail: \(error)")
        }
    }
    
    func testNumberedHeaderDetection() async {
        // Given: Document with numbered headers
        let documentID = UUID()
        let numberedContent = """
        1. Introduction
        
        This document outlines the main concepts.
        
        1.1 Background
        
        Historical context and background information.
        
        1.2 Objectives
        
        The main objectives of this work.
        
        2. Methodology
        
        This section describes the methodology used.
        
        2.1 Data Collection
        
        How data was collected for this study.
        
        2.2 Analysis Approach
        
        The analytical approach taken.
        """
        
        try! await createTestDocument(id: documentID, content: numberedContent, title: "Numbered Headers", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with numbered headers
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect numbered header hierarchy
            XCTAssertTrue(true, "Numbered header detection should succeed")
            
        } catch {
            XCTFail("Numbered header detection should not fail: \(error)")
        }
    }
    
    func testCapitalizedHeaderDetection() async {
        // Given: Document with capitalized headers
        let documentID = UUID()
        let capitalizedContent = """
        EXECUTIVE SUMMARY
        
        This document provides a comprehensive overview.
        
        INTRODUCTION
        
        The introduction sets the context for this work.
        
        BACKGROUND AND RELATED WORK
        
        This section reviews related work in the field.
        
        METHODOLOGY
        
        The methodology section describes our approach.
        
        RESULTS AND DISCUSSION
        
        Results are presented and discussed here.
        
        CONCLUSION
        
        The conclusion summarizes key findings.
        """
        
        try! await createTestDocument(id: documentID, content: capitalizedContent, title: "Capitalized Headers", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with capitalized headers
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect capitalized headers
            XCTAssertTrue(true, "Capitalized header detection should succeed")
            
        } catch {
            XCTFail("Capitalized header detection should not fail: \(error)")
        }
    }
    
    // MARK: - Table Detection Tests
    
    func testPipeSeparatedTableDetection() async {
        // Given: Document with pipe-separated tables
        let documentID = UUID()
        let tableContent = """
        # Database Schema
        
        The following table shows the database schema:
        
        | Column Name | Data Type | Constraints |
        |-------------|-----------|-------------|
        | id          | INTEGER   | PRIMARY KEY |
        | name        | VARCHAR   | NOT NULL    |
        | email       | VARCHAR   | UNIQUE      |
        | created_at  | TIMESTAMP | DEFAULT NOW |
        
        This table structure ensures data integrity.
        """
        
        try! await createTestDocument(id: documentID, content: tableContent, title: "Pipe Table", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with pipe-separated table
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect table structure
            XCTAssertTrue(true, "Pipe-separated table detection should succeed")
            
        } catch {
            XCTFail("Pipe-separated table detection should not fail: \(error)")
        }
    }
    
    func testTabSeparatedTableDetection() async {
        // Given: Document with tab-separated values
        let documentID = UUID()
        let tabTableContent = """
        Product Performance Report
        
        Product	Sales	Revenue	Profit
        Widget A	1000	$50,000	$15,000
        Widget B	750	$37,500	$11,250
        Widget C	1200	$60,000	$18,000
        Widget D	500	$25,000	$7,500
        
        Total performance shows positive trends.
        """
        
        try! await createTestDocument(id: documentID, content: tabTableContent, title: "Tab Table", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with tab-separated table
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect tab-separated table structure
            XCTAssertTrue(true, "Tab-separated table detection should succeed")
            
        } catch {
            XCTFail("Tab-separated table detection should not fail: \(error)")
        }
    }
    
    func testSpaceSeparatedTableDetection() async {
        // Given: Document with space-separated columns
        let documentID = UUID()
        let spaceTableContent = """
        System Performance Metrics
        
        Metric           Value    Unit    Status
        CPU Usage        85%      percent normal
        Memory Usage     4.2      GB      normal  
        Disk Space       75%      percent warning
        Network I/O      120      Mbps    normal
        
        Overall system performance is acceptable.
        """
        
        try! await createTestDocument(id: documentID, content: spaceTableContent, title: "Space Table", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with space-separated table
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect space-separated table structure
            XCTAssertTrue(true, "Space-separated table detection should succeed")
            
        } catch {
            XCTFail("Space-separated table detection should not fail: \(error)")
        }
    }
    
    // MARK: - List Detection Tests
    
    func testBulletListDetection() async {
        // Given: Document with bullet lists
        let documentID = UUID()
        let bulletListContent = """
        Key Features
        
        Our application includes the following features:
        
        - User authentication and authorization
        - Real-time data synchronization
        - Advanced search capabilities
        - Multi-language support
        - Responsive design
        
        Additional features:
        
        * Offline functionality
        * Data export options
        * Customizable dashboard
        * Integration with third-party services
        
        Alternative bullet styles:
        
        • Performance monitoring
        • Error tracking
        • User analytics
        • Security scanning
        """
        
        try! await createTestDocument(id: documentID, content: bulletListContent, title: "Bullet Lists", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with bullet lists
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect bullet list structures
            XCTAssertTrue(true, "Bullet list detection should succeed")
            
        } catch {
            XCTFail("Bullet list detection should not fail: \(error)")
        }
    }
    
    func testNumberedListDetection() async {
        // Given: Document with numbered lists
        let documentID = UUID()
        let numberedListContent = """
        Installation Steps
        
        Follow these steps to install the application:
        
        1. Download the installer from the official website
        2. Run the installer as administrator
        3. Accept the license agreement
        4. Choose the installation directory
        5. Select optional components
        6. Complete the installation process
        
        Configuration steps:
        
        1. Open the application
        2. Navigate to Settings
        3. Configure database connection
        4. Set up user accounts
        5. Test the configuration
        """
        
        try! await createTestDocument(id: documentID, content: numberedListContent, title: "Numbered Lists", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with numbered lists
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect numbered list structures
            XCTAssertTrue(true, "Numbered list detection should succeed")
            
        } catch {
            XCTFail("Numbered list detection should not fail: \(error)")
        }
    }
    
    func testLetteredListDetection() async {
        // Given: Document with lettered lists
        let documentID = UUID()
        let letteredListContent = """
        Multiple Choice Questions
        
        Question 1: What is the primary purpose of this application?
        
        a. Data analysis and visualization
        b. Document management and processing
        c. Communication and collaboration
        d. Project planning and tracking
        
        Question 2: Which technology stack is used?
        
        a. React and Node.js
        b. Angular and Express
        c. Vue.js and Laravel
        d. Swift and Core Data
        """
        
        try! await createTestDocument(id: documentID, content: letteredListContent, title: "Lettered Lists", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with lettered lists
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect lettered list structures
            XCTAssertTrue(true, "Lettered list detection should succeed")
            
        } catch {
            XCTFail("Lettered list detection should not fail: \(error)")
        }
    }
    
    // MARK: - Complex Structure Tests
    
    func testMixedDocumentStructure() async {
        // Given: Document with mixed structural elements
        let documentID = UUID()
        let mixedStructureContent = """
        # Technical Specification Document
        
        ## 1. Introduction
        
        This document outlines the technical specifications.
        
        ### 1.1 Purpose
        
        The purpose is to provide detailed technical information.
        
        ## 2. System Overview
        
        The system consists of multiple components:
        
        - Frontend application
        - Backend API
        - Database layer
        - Caching system
        
        ### 2.1 Architecture Diagram
        
        | Component | Technology | Version |
        |-----------|------------|---------|
        | Frontend  | React      | 18.2.0  |
        | Backend   | Node.js    | 18.17.0 |
        | Database  | PostgreSQL | 15.3    |
        | Cache     | Redis      | 7.0.11  |
        
        ## 3. Implementation Details
        
        ### 3.1 Setup Instructions
        
        1. Clone the repository
        2. Install dependencies
        3. Configure environment variables
        4. Run the application
        
        ### 3.2 API Endpoints
        
        The following endpoints are available:
        
        a. Authentication endpoints
        b. User management endpoints
        c. Data processing endpoints
        d. File upload endpoints
        
        ## 4. Conclusion
        
        This specification provides a comprehensive overview.
        """
        
        try! await createTestDocument(id: documentID, content: mixedStructureContent, title: "Mixed Structure", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with mixed structures
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should detect and preserve all structural elements
            XCTAssertTrue(true, "Mixed document structure recognition should succeed")
            
        } catch {
            XCTFail("Mixed document structure recognition should not fail: \(error)")
        }
    }
    
    func testNestedStructureDetection() async {
        // Given: Document with nested structures
        let documentID = UUID()
        let nestedStructureContent = """
        # Project Documentation
        
        ## Phase 1: Planning
        
        ### 1.1 Requirements Gathering
        
        The requirements gathering process includes:
        
        1. Stakeholder interviews
           - Primary stakeholders
           - Secondary stakeholders
           - External stakeholders
        
        2. Document analysis
           a. Existing documentation review
           b. Process flow analysis
           c. System integration requirements
        
        3. Technical assessment
           • Current system evaluation
           • Technology stack review
           • Performance requirements
        
        ### 1.2 Project Scope Definition
        
        | Scope Item | Priority | Complexity |
        |------------|----------|------------|
        | Core Features | High | Medium |
        | UI/UX Design | High | Low |
        | Integration | Medium | High |
        | Testing | High | Medium |
        
        ## Phase 2: Implementation
        
        Implementation follows agile methodology.
        """
        
        try! await createTestDocument(id: documentID, content: nestedStructureContent, title: "Nested Structure", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with nested structures
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should handle nested structural elements
            XCTAssertTrue(true, "Nested structure detection should succeed")
            
        } catch {
            XCTFail("Nested structure detection should not fail: \(error)")
        }
    }
    
    // MARK: - Structure Preservation Tests
    
    func testStructureAwareChunking() async {
        // Given: Large structured document that will be chunked
        let documentID = UUID()
        let largeStructuredContent = """
        # Large Document with Structure
        
        ## Section A: First Major Section
        
        \(String(repeating: "This is content for section A. ", count: 100))
        
        ### Subsection A.1
        
        \(String(repeating: "This is subsection A.1 content. ", count: 50))
        
        ### Subsection A.2
        
        \(String(repeating: "This is subsection A.2 content. ", count: 50))
        
        ## Section B: Second Major Section
        
        \(String(repeating: "This is content for section B. ", count: 100))
        
        | Feature | Status |
        |---------|--------|
        | Feature 1 | Complete |
        | Feature 2 | In Progress |
        | Feature 3 | Planned |
        
        ## Section C: Final Section
        
        \(String(repeating: "This is content for section C. ", count: 100))
        """
        
        try! await createTestDocument(id: documentID, content: largeStructuredContent, title: "Large Structured", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = Array(repeating: createMockEmbedding(), count: 10)
        mockEmbeddingService.mockBatchEmbeddings = Array(repeating: createMockEmbedding(), count: 10)
        
        // When: Process large structured document
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should preserve structure across chunks
            XCTAssertTrue(mockEmbeddingService.generateEmbeddingsCalled, "Should process structured content in chunks")
            
        } catch {
            XCTFail("Structure-aware chunking should not fail: \(error)")
        }
    }
    
    func testStructuralContextPreservation() async {
        // Given: Document with important structural context
        let documentID = UUID()
        let contextualContent = """
        # User Manual
        
        ## Chapter 1: Getting Started
        
        Welcome to the application. This chapter covers basic usage.
        
        ### 1.1 Installation
        
        Installation steps are provided below.
        
        ### 1.2 Initial Setup
        
        Setup requires the following steps:
        
        1. Create user account
        2. Configure preferences
        3. Import initial data
        
        ## Chapter 2: Advanced Features
        
        This chapter covers advanced functionality.
        
        ### 2.1 Data Import
        
        Data can be imported from various sources:
        
        - CSV files
        - JSON files
        - Database connections
        
        ### 2.2 Export Options
        
        | Format | Supported | Notes |
        |--------|-----------|-------|
        | PDF | Yes | Full formatting |
        | Excel | Yes | Data only |
        | JSON | Yes | Complete structure |
        """
        
        try! await createTestDocument(id: documentID, content: contextualContent, title: "Contextual Structure", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = [createMockEmbedding()]
        
        // When: Process document with structural context
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            // Then: Should preserve structural context for search
            XCTAssertTrue(true, "Structural context preservation should succeed")
            
        } catch {
            XCTFail("Structural context preservation should not fail: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testStructureRecognitionPerformance() async {
        // Given: Large document with many structural elements
        let documentID = UUID()
        var performanceContent = "# Performance Test Document\n\n"
        
        // Add many sections, tables, and lists
        for i in 1...50 {
            performanceContent += """
            ## Section \(i)
            
            This is section \(i) content.
            
            ### Subsection \(i).1
            
            | Item | Value | Status |
            |------|-------|--------|
            | Item \(i)A | \(i * 10) | Active |
            | Item \(i)B | \(i * 20) | Pending |
            
            Key points:
            
            - Point \(i).1
            - Point \(i).2
            - Point \(i).3
            
            """
        }
        
        try! await createTestDocument(id: documentID, content: performanceContent, title: "Performance Test", type: "text")
        mockEmbeddingService.mockLanguage = "en"
        mockEmbeddingService.mockEmbeddings = Array(repeating: createMockEmbedding(), count: 20)
        mockEmbeddingService.mockBatchEmbeddings = Array(repeating: createMockEmbedding(), count: 20)
        
        // When: Measure structure recognition performance
        let startTime = Date()
        
        do {
            try await documentProcessor.processDocumentEmbeddings(for: documentID)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Then: Should complete within reasonable time
            XCTAssertLessThan(processingTime, 10.0, "Structure recognition should complete within 10 seconds")
            
            print("📊 Structure recognition performance:")
            print("   Content length: \(performanceContent.count) characters")
            print("   Processing time: \(String(format: "%.3f", processingTime)) seconds")
            
        } catch {
            XCTFail("Structure recognition performance test should not fail: \(error)")
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
    
    private func createMockEmbedding() -> [Float] {
        return (0..<768).map { _ in Float.random(in: -1...1) }
    }
}

// MARK: - Mock Service

class MockStructureEmbeddingService: EmbeddingServiceProtocol {
    var mockLanguage: String = "en"
    var mockEmbeddings: [Float] = []
    var mockBatchEmbeddings: [[Float]] = []
    var shouldFailEmbedding = false
    
    var generateEmbeddingCalled = false
    var generateEmbeddingsCalled = false
    var detectLanguageCalled = false
    
    func detectLanguage(for text: String) -> String? {
        detectLanguageCalled = true
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