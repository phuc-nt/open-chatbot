import XCTest
@testable import OpenChatbot

class ContextSizeCalculatorTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let shortText = "This is a short document with minimal content."
    private let mediumText = String(repeating: "This is medium length content. ", count: 1000) // ~30k chars
    private let longText = String(repeating: "This is long content that exceeds thresholds. ", count: 2000) // ~94k chars
    
    // MARK: - ContextThresholds Tests
    
    func testContextThresholds_GPT4() {
        let threshold = ContextThresholds.getThreshold(for: "gpt-4")
        XCTAssertEqual(threshold, 120_000, "GPT-4 threshold should be 120k characters")
        
        let displayName = ContextThresholds.getModelDisplayName(for: "gpt-4-turbo")
        XCTAssertEqual(displayName, "GPT-4 (120k chars)", "GPT-4 display name should be correct")
    }
    
    func testContextThresholds_Claude3() {
        let threshold = ContextThresholds.getThreshold(for: "claude-3-opus")
        XCTAssertEqual(threshold, 180_000, "Claude 3 threshold should be 180k characters")
        
        let displayName = ContextThresholds.getModelDisplayName(for: "claude-3-haiku")
        XCTAssertEqual(displayName, "Claude 3 (180k chars)", "Claude 3 display name should be correct")
    }
    
    func testContextThresholds_Llama() {
        let threshold = ContextThresholds.getThreshold(for: "llama-2-70b")
        XCTAssertEqual(threshold, 60_000, "Llama threshold should be 60k characters")
        
        let displayName = ContextThresholds.getModelDisplayName(for: "llama-3")
        XCTAssertEqual(displayName, "Llama (60k chars)", "Llama display name should be correct")
    }
    
    func testContextThresholds_DefaultModel() {
        let threshold = ContextThresholds.getThreshold(for: "unknown-model")
        XCTAssertEqual(threshold, 80_000, "Unknown model should use default threshold")
        
        let displayName = ContextThresholds.getModelDisplayName(for: "unknown-model")
        XCTAssertEqual(displayName, "Default (80k chars)", "Unknown model should use default display name")
    }
    
    // MARK: - ContextSizeStatus Tests
    
    func testContextSizeStatus_Properties() {
        XCTAssertEqual(ContextSizeStatus.optimal.displayName, "Perfect for Full Context")
        XCTAssertEqual(ContextSizeStatus.large.displayName, "Consider RAG for speed")
        XCTAssertEqual(ContextSizeStatus.excessive.displayName, "RAG Mode recommended")
        
        XCTAssertEqual(ContextSizeStatus.optimal.systemImageName, "checkmark.circle.fill")
        XCTAssertEqual(ContextSizeStatus.large.systemImageName, "exclamationmark.triangle.fill")
        XCTAssertEqual(ContextSizeStatus.excessive.systemImageName, "xmark.circle.fill")
        
        XCTAssertEqual(ContextSizeStatus.optimal.color, "green")
        XCTAssertEqual(ContextSizeStatus.large.color, "orange")
        XCTAssertEqual(ContextSizeStatus.excessive.color, "red")
    }
    
    // MARK: - ContextSizeCalculator String Content Tests
    
    func testCalculateSize_StringContent_Short() {
        let result = ContextSizeCalculator.calculateSize(for: shortText, modelName: "gpt-4")
        
        XCTAssertEqual(result.totalCharacters, shortText.count)
        XCTAssertEqual(result.threshold, 120_000)
        XCTAssertEqual(result.status, .optimal)
        XCTAssertTrue(result.canUseFullContext)
        XCTAssertLessThan(result.percentage, 0.5)
        XCTAssertEqual(result.modelName, "gpt-4")
    }
    
    func testCalculateSize_StringContent_Medium() {
        let result = ContextSizeCalculator.calculateSize(for: mediumText, modelName: "gpt-4")
        
        XCTAssertEqual(result.status, .optimal) // 30k chars should be optimal for 120k threshold
        XCTAssertTrue(result.canUseFullContext)
        XCTAssertGreaterThan(result.percentage, 0.0)
        XCTAssertLessThan(result.percentage, 0.5)
    }
    
    func testCalculateSize_StringContent_Large() {
        let result = ContextSizeCalculator.calculateSize(for: longText, modelName: "gpt-4")
        
        XCTAssertEqual(result.status, .large) // 94k chars should be large for 120k threshold
        XCTAssertTrue(result.canUseFullContext) // Still under 80% threshold
        XCTAssertGreaterThan(result.percentage, 0.5)
        XCTAssertLessThan(result.percentage, 0.8)
    }
    
    func testCalculateSize_StringContent_Excessive() {
        let excessiveText = String(repeating: "Excessive content. ", count: 5000) // ~100k chars
        let result = ContextSizeCalculator.calculateSize(for: excessiveText, modelName: "llama-2") // 60k threshold
        
        XCTAssertEqual(result.status, .excessive)
        XCTAssertFalse(result.canUseFullContext)
        XCTAssertGreaterThan(result.percentage, 0.8)
    }
    
    // MARK: - ContextSizeResult Formatting Tests
    
    func testContextSizeResult_FormattedSize() {
        let shortResult = ContextSizeCalculator.calculateSize(for: shortText, modelName: "gpt-4")
        XCTAssertTrue(shortResult.formattedSize.hasSuffix("chars"))
        XCTAssertFalse(shortResult.formattedSize.contains("k"))
        
        let longResult = ContextSizeCalculator.calculateSize(for: longText, modelName: "gpt-4")
        XCTAssertTrue(longResult.formattedSize.contains("k chars"))
    }
    
    func testContextSizeResult_FormattedTokens() {
        let result = ContextSizeCalculator.calculateSize(for: mediumText, modelName: "gpt-4")
        XCTAssertTrue(result.formattedTokens.contains("k tokens"))
        XCTAssertGreaterThan(result.estimatedTokens, 0)
    }
    
    func testContextSizeResult_PercentageString() {
        let result = ContextSizeCalculator.calculateSize(for: shortText, modelName: "gpt-4")
        XCTAssertTrue(result.percentageString.contains("%"))
        XCTAssertFalse(result.percentageString.contains(".")) // Should be rounded
    }
    
    // MARK: - Character Counting Tests
    
    func testCharacterCounting_WhitespaceNormalization() {
        let messyText = "Text   with    excessive   whitespace\n\n\n\nand multiple newlines"
        let result = ContextSizeCalculator.calculateSize(for: messyText, modelName: "gpt-4")
        
        // Should normalize whitespace but preserve structure
        XCTAssertLessThan(result.totalCharacters, messyText.count)
        XCTAssertGreaterThan(result.totalCharacters, 0)
    }
    
    func testCharacterCounting_EmptyString() {
        let result = ContextSizeCalculator.calculateSize(for: "", modelName: "gpt-4")
        
        XCTAssertEqual(result.totalCharacters, 0)
        XCTAssertEqual(result.estimatedTokens, 0)
        XCTAssertEqual(result.status, .optimal)
        XCTAssertTrue(result.canUseFullContext)
    }
    
    // MARK: - Token Estimation Tests
    
    func testTokenEstimation_Accuracy() {
        let sampleText = "This is a sample text for token estimation testing."
        let result = ContextSizeCalculator.calculateSize(for: sampleText, modelName: "gpt-4")
        
        // Token estimation should be roughly 1/4 of character count
        let expectedTokens = sampleText.count / 4
        XCTAssertEqual(result.estimatedTokens, expectedTokens, accuracy: 2)
    }
    
    // MARK: - ChatMode Enum Tests
    
    func testChatMode_Properties() {
        XCTAssertEqual(ChatMode.rag.displayName, "RAG Mode")
        XCTAssertEqual(ChatMode.fullContext.displayName, "Full Context")
        
        XCTAssertEqual(ChatMode.rag.description, "Search relevant information")
        XCTAssertEqual(ChatMode.fullContext.description, "Include complete document")
        
        XCTAssertEqual(ChatMode.rag.systemImageName, "magnifyingglass.circle")
        XCTAssertEqual(ChatMode.fullContext.systemImageName, "doc.text.fill")
        
        XCTAssertTrue(ChatMode.rag.isDefault)
        XCTAssertFalse(ChatMode.fullContext.isDefault)
    }
    
    func testChatMode_CaseIterable() {
        let allModes = ChatMode.allCases
        XCTAssertEqual(allModes.count, 2)
        XCTAssertTrue(allModes.contains(.rag))
        XCTAssertTrue(allModes.contains(.fullContext))
    }
    
    func testChatMode_Identifiable() {
        XCTAssertEqual(ChatMode.rag.id, "rag")
        XCTAssertEqual(ChatMode.fullContext.id, "full_context")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCalculateSize_VeryLongText() {
        let veryLongText = String(repeating: "A", count: 200_000) // 200k chars
        let result = ContextSizeCalculator.calculateSize(for: veryLongText, modelName: "claude-3")
        
        XCTAssertEqual(result.totalCharacters, 200_000)
        XCTAssertEqual(result.status, .excessive) // Should exceed even Claude 3 threshold
        XCTAssertFalse(result.canUseFullContext)
    }
    
    func testCalculateSize_DifferentModels() {
        let shortText = String(repeating: "Test ", count: 1_000) // ~5k chars
        let longText = String(repeating: "Test ", count: 8_000) // ~40k chars
        
        let gpt4ShortResult = ContextSizeCalculator.calculateSize(for: shortText, modelName: "gpt-4")
        let llamaLongResult = ContextSizeCalculator.calculateSize(for: longText, modelName: "llama-2")
        
        // Short text should be optimal for GPT-4 (5k << 120k)
        XCTAssertEqual(gpt4ShortResult.status, .optimal)
        XCTAssertTrue(gpt4ShortResult.canUseFullContext)
        
        // Long text should be large for Llama (40k > 30k but < 48k)  
        XCTAssertEqual(llamaLongResult.status, .large)
        XCTAssertTrue(llamaLongResult.canUseFullContext)
    }
    
    // MARK: - Performance Tests
    
    func testCalculateSize_Performance() {
        let largeText = String(repeating: "Performance test content. ", count: 5000)
        
        measure {
            for _ in 0..<100 {
                let _ = ContextSizeCalculator.calculateSize(for: largeText, modelName: "gpt-4")
            }
        }
    }
}