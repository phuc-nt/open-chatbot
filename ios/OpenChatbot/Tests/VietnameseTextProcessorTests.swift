import XCTest
import NaturalLanguage
@testable import OpenChatbot

class VietnameseTextProcessorTests: XCTestCase {
    
    var vietnameseProcessor: VietnameseTextProcessor!
    
    override func setUp() {
        super.setUp()
        vietnameseProcessor = VietnameseTextProcessor()
    }
    
    override func tearDown() {
        vietnameseProcessor = nil
        super.tearDown()
    }
    
    // MARK: - Vietnamese Chunking Tests
    
    func testVietnameseAwareChunking() {
        // Given: Vietnamese text with multiple sentences
        let vietnameseText = """
        Xin chào, tôi là một trợ lý AI thông minh. Tôi có thể giúp bạn với nhiều nhiệm vụ khác nhau trong cuộc sống hàng ngày.
        Tuy nhiên, để tôi có thể hỗ trợ bạn một cách tốt nhất, bạn cần cung cấp thông tin cụ thể về vấn đề mà bạn đang gặp phải.
        Bởi vì việc hiểu ngữ cảnh rất quan trọng trong việc xử lý ngôn ngữ tự nhiên, đặc biệt là với tiếng Việt có cấu trúc phức tạp.
        """
        
        // When: Create Vietnamese-aware chunks
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: vietnameseText,
            baseChunkSize: 200,
            overlapSize: 50
        )
        
        // Then: Should create appropriate chunks
        XCTAssertGreaterThan(chunks.count, 0, "Should create at least one chunk")
        XCTAssertTrue(chunks.allSatisfy { $0.language == "vi" }, "All chunks should be marked as Vietnamese")
        
        // Check chunk content quality
        for chunk in chunks {
            XCTAssertGreaterThan(chunk.text.count, 0, "Chunk should not be empty")
            XCTAssertGreaterThan(chunk.wordCount, 0, "Chunk should have words")
            XCTAssertGreaterThan(chunk.sentenceCount, 0, "Chunk should have sentences")
        }
        
        print("📊 Created \(chunks.count) Vietnamese chunks")
        for (index, chunk) in chunks.enumerated() {
            print("   Chunk \(index): \(chunk.text.count) chars, \(chunk.wordCount) words, \(chunk.sentenceCount) sentences")
        }
    }
    
    func testVietnameseChunkSizeAdjustment() {
        // Given: Vietnamese text that should trigger size adjustment
        let vietnameseText = String(repeating: "Đây là một câu tiếng Việt có độ dài trung bình. ", count: 50)
        
        // When: Create chunks with different base sizes
        let smallChunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: vietnameseText,
            baseChunkSize: 500,
            overlapSize: 50
        )
        
        let largeChunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: vietnameseText,
            baseChunkSize: 1000,
            overlapSize: 100
        )
        
        // Then: Should adjust chunk sizes for Vietnamese text characteristics
        XCTAssertGreaterThan(smallChunks.count, largeChunks.count, "Smaller base size should create more chunks")
        
        // Check that Vietnamese multiplier is applied
        for chunk in smallChunks {
            XCTAssertTrue(chunk.isVietnameseOptimized, "Chunks should be Vietnamese-optimized")
        }
    }
    
    func testVietnameseOverlapCreation() {
        // Given: Vietnamese text with multiple sentences
        let vietnameseText = """
        Câu đầu tiên trong văn bản này. Câu thứ hai có nội dung liên quan. Câu thứ ba kết nối với câu trước.
        Câu thứ tư bắt đầu đoạn mới. Câu thứ năm tiếp tục phát triển ý tưởng. Câu cuối cùng kết thúc đoạn văn.
        """
        
        // When: Create chunks with overlap
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: vietnameseText,
            baseChunkSize: 150,
            overlapSize: 80
        )
        
        // Then: Should create overlapping content for context preservation
        if chunks.count > 1 {
            for i in 1..<chunks.count {
                let previousChunk = chunks[i-1]
                let currentChunk = chunks[i]
                
                // Check for overlap (some common content between chunks)
                let hasOverlap = previousChunk.text.split(separator: " ").contains { word in
                    currentChunk.text.contains(String(word))
                }
                
                XCTAssertTrue(hasOverlap, "Consecutive chunks should have overlapping content")
            }
        }
    }
    
    // MARK: - Vietnamese Sentence Detection Tests
    
    func testVietnameseSentenceDetection() {
        // Given: Vietnamese text with various sentence patterns
        let vietnameseText = """
        Đây là câu đầu tiên. Đây là câu thứ hai! Đây có phải là câu hỏi không? 
        Tuy nhiên, câu này có liên từ ở đầu. Mà câu này cũng bắt đầu bằng liên từ.
        Câu này có dấu hai chấm: như thế này. Câu cuối cùng kết thúc bằng dấu chấm phẩy;
        """
        
        // When: Process Vietnamese text
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: vietnameseText,
            baseChunkSize: 500,
            overlapSize: 50
        )
        
        // Then: Should properly detect Vietnamese sentence boundaries
        XCTAssertGreaterThan(chunks.count, 0, "Should create chunks from Vietnamese text")
        
        let totalSentences = chunks.reduce(0) { $0 + $1.sentenceCount }
        XCTAssertGreaterThan(totalSentences, 5, "Should detect multiple sentences")
        
        // Verify sentence boundary detection quality
        for chunk in chunks {
            XCTAssertTrue(chunk.sentenceCount > 0, "Each chunk should contain sentences")
            XCTAssertTrue(
                chunk.text.contains(".") || chunk.text.contains("!") || chunk.text.contains("?") || chunk.text.contains(";"),
                "Chunks should contain sentence-ending punctuation"
            )
        }
    }
    
    func testVietnameseConjunctionHandling() {
        // Given: Vietnamese text with conjunctions that should affect sentence boundaries
        let textWithConjunctions = """
        Câu đầu tiên hoàn chỉnh. Và câu này bắt đầu bằng liên từ.
        Tuy nhiên câu này có liên từ khác. Nhưng câu này lại khác.
        Vì câu này có lý do. Do đó kết quả như vậy.
        """
        
        // When: Process text with conjunctions
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: textWithConjunctions,
            baseChunkSize: 300,
            overlapSize: 50
        )
        
        // Then: Should handle Vietnamese conjunctions properly
        XCTAssertGreaterThan(chunks.count, 0, "Should process text with conjunctions")
        
        // Check that conjunctions are preserved in context
        let allText = chunks.map { $0.text }.joined(separator: " ")
        let vietnameseConjunctions = ["Và", "Tuy nhiên", "Nhưng", "Vì", "Do đó"]
        
        for conjunction in vietnameseConjunctions {
            XCTAssertTrue(
                allText.contains(conjunction),
                "Vietnamese conjunction '\(conjunction)' should be preserved"
            )
        }
    }
    
    // MARK: - Vietnamese Text Analysis Tests
    
    func testVietnameseWordDensityCalculation() {
        // Given: Vietnamese text with different complexity levels
        let simpleText = "Xin chào tôi là AI."
        let complexText = "Xin chào, tôi là một trợ lý thông minh nhân tạo được phát triển để hỗ trợ người dùng."
        
        // When: Create chunks and analyze density
        let simpleChunks = vietnameseProcessor.createVietnameseAwareChunks(text: simpleText)
        let complexChunks = vietnameseProcessor.createVietnameseAwareChunks(text: complexText)
        
        // Then: Should calculate Vietnamese-specific word density
        XCTAssertGreaterThan(simpleChunks.count, 0, "Should create chunks from simple text")
        XCTAssertGreaterThan(complexChunks.count, 0, "Should create chunks from complex text")
        
        let simpleChunk = simpleChunks.first!
        let complexChunk = complexChunks.first!
        
        // Word density should reflect Vietnamese text characteristics
        XCTAssertGreaterThan(simpleChunk.wordDensity, 0, "Simple text should have word density")
        XCTAssertGreaterThan(complexChunk.wordDensity, 0, "Complex text should have word density")
        
        print("📊 Word density analysis:")
        print("   Simple text: \(simpleChunk.wordDensity)")
        print("   Complex text: \(complexChunk.wordDensity)")
    }
    
    func testVietnameseTextMetadata() {
        // Given: Vietnamese text for metadata testing
        let vietnameseText = """
        Văn bản này được viết bằng tiếng Việt. Nó chứa các từ và cụm từ đặc trưng.
        Có nhiều ký tự đặc biệt như ă, â, ê, ô, ơ, ư và các dấu thanh.
        Cấu trúc ngữ pháp tiếng Việt khác với tiếng Anh ở nhiều điểm.
        """
        
        // When: Process Vietnamese text
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(text: vietnameseText)
        
        // Then: Should include Vietnamese-specific metadata
        for chunk in chunks {
            XCTAssertEqual(chunk.language, "vi", "Language should be detected as Vietnamese")
            XCTAssertTrue(chunk.isVietnameseOptimized, "Should be marked as Vietnamese-optimized")
            
            // Check metadata completeness
            XCTAssertNotNil(chunk.processingDate, "Should have processing date")
            XCTAssertNotNil(chunk.chunkType, "Should have chunk type")
            XCTAssertTrue(chunk.hasVietnameseFeatures, "Should detect Vietnamese language features")
        }
    }
    
    // MARK: - Performance Tests
    
    func testVietnameseProcessingPerformance() {
        // Given: Large Vietnamese text for performance testing
        let largeVietnameseText = String(repeating: """
        Đây là một đoạn văn tiếng Việt dài để kiểm tra hiệu suất xử lý. 
        Văn bản này chứa nhiều câu và đoạn văn khác nhau. 
        Mục đích là đảm bảo thuật toán xử lý nhanh và chính xác. 
        """, count: 100)
        
        // When: Measure processing time
        let startTime = Date()
        
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: largeVietnameseText,
            baseChunkSize: 1000,
            overlapSize: 100
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Then: Should process efficiently
        XCTAssertGreaterThan(chunks.count, 0, "Should create chunks from large text")
        XCTAssertLessThan(processingTime, 5.0, "Processing should complete within 5 seconds")
        
        print("⚡ Vietnamese processing performance:")
        print("   Text length: \(largeVietnameseText.count) characters")
        print("   Chunks created: \(chunks.count)")
        print("   Processing time: \(String(format: "%.3f", processingTime)) seconds")
    }
    
    func testVietnameseMemoryEfficiency() {
        // Given: Multiple Vietnamese texts for memory testing
        let vietnameseTexts = [
            "Văn bản thứ nhất với nội dung đơn giản.",
            "Văn bản thứ hai có độ phức tạp trung bình và chứa nhiều thông tin hơn.",
            "Văn bản thứ ba rất dài và chứa nhiều đoạn văn, câu phức tạp với cấu trúc ngữ pháp đa dạng."
        ]
        
        // When: Process multiple texts
        for (index, text) in vietnameseTexts.enumerated() {
            let chunks = vietnameseProcessor.createVietnameseAwareChunks(text: text)
            
            // Then: Should handle each text efficiently
            XCTAssertGreaterThan(chunks.count, 0, "Should process text \(index + 1)")
            
            // Memory should be managed efficiently (no crashes or excessive memory usage)
            for chunk in chunks {
                XCTAssertNotNil(chunk.text, "Chunk text should be accessible")
                XCTAssertGreaterThan(chunk.wordCount, 0, "Word count should be calculated")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testVietnameseTextProcessorIntegration() {
        // Given: Mixed Vietnamese content (formal and informal)
        let mixedVietnameseText = """
        Chào bạn! Hôm nay trời đẹp quá nhỉ?
        
        Theo báo cáo chính thức, tình hình kinh tế đang có những chuyển biến tích cực.
        Tuy nhiên, chúng ta vẫn cần phải tiếp tục nỗ lực để đạt được các mục tiêu đề ra.
        
        Anyway, mình nghĩ chúng ta nên đi ăn gì đó. Bạn thích ăn gì?
        """
        
        // When: Process mixed style Vietnamese text
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(
            text: mixedVietnameseText,
            baseChunkSize: 200,
            overlapSize: 50
        )
        
        // Then: Should handle different Vietnamese text styles
        XCTAssertGreaterThan(chunks.count, 0, "Should process mixed Vietnamese content")
        
        // Should maintain context across different styles
        let hasInformalContent = chunks.any { $0.text.contains("Chào bạn") || $0.text.contains("Anyway") }
        let hasFormalContent = chunks.any { $0.text.contains("báo cáo chính thức") || $0.text.contains("mục tiêu") }
        
        XCTAssertTrue(hasInformalContent, "Should preserve informal Vietnamese content")
        XCTAssertTrue(hasFormalContent, "Should preserve formal Vietnamese content")
        
        // All chunks should be properly marked
        for chunk in chunks {
            XCTAssertEqual(chunk.language, "vi", "All chunks should be Vietnamese")
            XCTAssertTrue(chunk.isVietnameseOptimized, "All chunks should be Vietnamese-optimized")
        }
    }
    
    func testVietnameseTextWithSpecialCharacters() {
        // Given: Vietnamese text with special characters and diacritics
        let specialCharText = """
        Tiếng Việt có nhiều ký tự đặc biệt: ă, â, đ, ê, ô, ơ, ư.
        Các dấu thanh: à, á, ả, ã, ạ và ằ, ắ, ẳ, ẵ, ặ.
        Cũng có: è, é, ẻ, ẽ, ẹ và ề, ế, ể, ễ, ệ.
        """
        
        // When: Process text with Vietnamese diacritics
        let chunks = vietnameseProcessor.createVietnameseAwareChunks(text: specialCharText)
        
        // Then: Should preserve Vietnamese diacritics correctly
        XCTAssertGreaterThan(chunks.count, 0, "Should process text with diacritics")
        
        let combinedText = chunks.map { $0.text }.joined(separator: " ")
        let vietnameseDiacritics = ["ă", "â", "đ", "ê", "ô", "ơ", "ư", "ằ", "ắ", "ề", "ế"]
        
        for diacritic in vietnameseDiacritics {
            XCTAssertTrue(
                combinedText.contains(diacritic),
                "Vietnamese diacritic '\(diacritic)' should be preserved"
            )
        }
    }
}

// MARK: - Helper Extensions

extension Array {
    func any(_ predicate: (Element) -> Bool) -> Bool {
        return self.first(where: predicate) != nil
    }
}

// MARK: - Mock Data Structures (if not already defined)

struct VietnameseTextChunk {
    let text: String
    let index: Int
    let wordCount: Int
    let sentenceCount: Int
    let language: String
    let wordDensity: Double
    let isVietnameseOptimized: Bool
    let processingDate: Date?
    let chunkType: String?
    let hasVietnameseFeatures: Bool
    
    init(text: String, index: Int, wordCount: Int, sentenceCount: Int) {
        self.text = text
        self.index = index
        self.wordCount = wordCount
        self.sentenceCount = sentenceCount
        self.language = "vi"
        self.wordDensity = Double(wordCount) / Double(text.count) * 1000
        self.isVietnameseOptimized = true
        self.processingDate = Date()
        self.chunkType = "vietnamese_semantic"
        self.hasVietnameseFeatures = text.contains(where: { "ăâđêôơưàáảãạằắẳẵặèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ".contains($0) })
    }
}