import Foundation
import NaturalLanguage

/// Vietnamese text processing service for enhanced language-specific operations
/// Provides Vietnamese-aware text chunking, sentence boundary detection, and search optimization
class VietnameseTextProcessor {
    
    // MARK: - Configuration
    private let vietnameseTokenizer: NLTokenizer
    private let sentenceDetector: NLTokenizer
    
    // Vietnamese-specific settings
    private let vietnameseChunkSizeMultiplier: Double = 1.15 // Vietnamese words are typically longer
    private let vietnameseSentenceEndPatterns: [String] = [".", "!", "?", ":", ";"]
    private let vietnameseConjunctions: Set<String> = [
        "và", "hoặc", "nhưng", "mà", "hay", "thì", "nên", "để", "vì", "do", "bởi vì", "tuy nhiên", "tuy", "dù", "dẫu"
    ]
    
    // MARK: - Initialization
    init() {
        self.vietnameseTokenizer = NLTokenizer(unit: .word)
        self.sentenceDetector = NLTokenizer(unit: .sentence)
        
        // Set language for better Vietnamese processing
        vietnameseTokenizer.setLanguage(.vietnamese)
        sentenceDetector.setLanguage(.vietnamese)
    }
    
    // MARK: - Vietnamese Text Chunking
    
    /// Create Vietnamese-aware semantic chunks from text
    func createVietnameseAwareChunks(
        text: String,
        baseChunkSize: Int = 1000,
        overlapSize: Int = 100
    ) -> [VietnameseTextChunk] {
        
        print("🇻🇳 Creating Vietnamese-aware chunks for text (\(text.count) characters)")
        
        // Adjust chunk size for Vietnamese text characteristics
        let adjustedChunkSize = Int(Double(baseChunkSize) * vietnameseChunkSizeMultiplier)
        
        // First, detect sentence boundaries using Vietnamese-aware detection
        let sentences = detectVietnameseSentences(in: text)
        print("📝 Detected \(sentences.count) Vietnamese sentences")
        
        var chunks: [VietnameseTextChunk] = []
        var currentChunk = ""
        var currentSentences: [String] = []
        var chunkIndex = 0
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if adding this sentence would exceed chunk size
            if !currentChunk.isEmpty && (currentChunk.count + trimmedSentence.count) > adjustedChunkSize {
                // Finalize current chunk
                let chunk = createVietnameseChunk(
                    text: currentChunk,
                    sentences: currentSentences,
                    index: chunkIndex
                )
                chunks.append(chunk)
                
                // Start new chunk with overlap
                let overlapText = createVietnameseOverlap(
                    from: currentSentences,
                    maxSize: overlapSize
                )
                currentChunk = overlapText + (overlapText.isEmpty ? "" : " ") + trimmedSentence
                currentSentences = extractOverlapSentences(from: currentSentences, maxSize: overlapSize)
                currentSentences.append(trimmedSentence)
                chunkIndex += 1
            } else {
                // Add sentence to current chunk
                if currentChunk.isEmpty {
                    currentChunk = trimmedSentence
                } else {
                    currentChunk += " " + trimmedSentence
                }
                currentSentences.append(trimmedSentence)
            }
        }
        
        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            let chunk = createVietnameseChunk(
                text: currentChunk,
                sentences: currentSentences,
                index: chunkIndex
            )
            chunks.append(chunk)
        }
        
        // Handle edge case: if no chunks created, create single chunk
        if chunks.isEmpty && !text.isEmpty {
            let chunk = createVietnameseChunk(
                text: text,
                sentences: [text],
                index: 0
            )
            chunks.append(chunk)
        }
        
        print("✅ Created \(chunks.count) Vietnamese-aware chunks")
        return chunks
    }
    
    // MARK: - Vietnamese Sentence Detection
    
    /// Detect sentence boundaries with Vietnamese-specific rules
    private func detectVietnameseSentences(in text: String) -> [String] {
        var sentences: [String] = []
        
        // Use NLTokenizer for basic sentence detection
        sentenceDetector.string = text
        sentenceDetector.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let sentence = String(text[tokenRange])
            sentences.append(sentence)
            return true
        }
        
        // Apply Vietnamese-specific sentence boundary refinement
        sentences = refineVietnameseSentenceBoundaries(sentences)
        
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    /// Refine sentence boundaries using Vietnamese grammar rules
    private func refineVietnameseSentenceBoundaries(_ sentences: [String]) -> [String] {
        var refinedSentences: [String] = []
        var currentSentence = ""
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this should be merged with previous sentence
            if shouldMergeWithPrevious(sentence: trimmed, previousSentence: currentSentence) {
                if !currentSentence.isEmpty {
                    currentSentence += " " + trimmed
                } else {
                    currentSentence = trimmed
                }
            } else {
                // Finalize previous sentence if exists
                if !currentSentence.isEmpty {
                    refinedSentences.append(currentSentence)
                }
                currentSentence = trimmed
            }
        }
        
        // Add final sentence
        if !currentSentence.isEmpty {
            refinedSentences.append(currentSentence)
        }
        
        return refinedSentences
    }
    
    /// Check if sentence should be merged with previous based on Vietnamese grammar
    private func shouldMergeWithPrevious(sentence: String, previousSentence: String) -> Bool {
        // Don't merge if no previous sentence
        if previousSentence.isEmpty {
            return false
        }
        
        // Check if current sentence starts with conjunction
        let words = tokenizeVietnameseWords(in: sentence)
        if let firstWord = words.first?.lowercased(),
           vietnameseConjunctions.contains(firstWord) {
            return true
        }
        
        // Check if previous sentence doesn't end with proper punctuation
        let lastChar = previousSentence.last
        if let lastChar = lastChar,
           !vietnameseSentenceEndPatterns.contains(String(lastChar)) {
            return true
        }
        
        // Check if current sentence is very short (likely a fragment)
        if sentence.count < 20 && words.count < 4 {
            return true
        }
        
        return false
    }
    
    // MARK: - Vietnamese Word Tokenization
    
    /// Tokenize Vietnamese text into words using language-aware tokenization
    private func tokenizeVietnameseWords(in text: String) -> [String] {
        var words: [String] = []
        
        vietnameseTokenizer.string = text
        vietnameseTokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let word = String(text[tokenRange])
            words.append(word)
            return true
        }
        
        return words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Chunk Creation and Overlap
    
    /// Create Vietnamese chunk with metadata
    private func createVietnameseChunk(
        text: String,
        sentences: [String],
        index: Int
    ) -> VietnameseTextChunk {
        let words = tokenizeVietnameseWords(in: text)
        let wordDensity = calculateVietnameseWordDensity(text: text, words: words)
        
        return VietnameseTextChunk(
            text: text,
            index: index,
            sentences: sentences,
            characterCount: text.count,
            wordCount: words.count,
            sentenceCount: sentences.count,
            wordDensity: wordDensity,
            metadata: [
                "chunk_type": "vietnamese_semantic",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "language": "vi",
                "tokenization_method": "nl_tokenizer_vietnamese",
                "sentence_boundary_method": "vietnamese_grammar_aware"
            ]
        )
    }
    
    /// Create overlap text from previous sentences
    private func createVietnameseOverlap(from sentences: [String], maxSize: Int) -> String {
        guard !sentences.isEmpty else { return "" }
        
        // Try to include complete sentences within size limit
        var overlapText = ""
        var currentSize = 0
        
        for sentence in sentences.reversed() {
            let sentenceSize = sentence.count + 1 // +1 for space
            if currentSize + sentenceSize <= maxSize {
                if overlapText.isEmpty {
                    overlapText = sentence
                } else {
                    overlapText = sentence + " " + overlapText
                }
                currentSize += sentenceSize
            } else {
                break
            }
        }
        
        return overlapText
    }
    
    /// Extract sentences for overlap
    private func extractOverlapSentences(from sentences: [String], maxSize: Int) -> [String] {
        var overlapSentences: [String] = []
        var currentSize = 0
        
        for sentence in sentences.reversed() {
            let sentenceSize = sentence.count
            if currentSize + sentenceSize <= maxSize {
                overlapSentences.insert(sentence, at: 0)
                currentSize += sentenceSize
            } else {
                break
            }
        }
        
        return overlapSentences
    }
    
    // MARK: - Vietnamese Query Optimization
    
    /// Optimize query for Vietnamese search
    func optimizeForVietnameseSearch(query: String) -> String {
        print("🔍 Optimizing Vietnamese search query: '\(query)'")
        
        // Normalize Vietnamese text
        let normalizedQuery = normalizeVietnameseText(query)
        
        // Tokenize and analyze query
        let words = tokenizeVietnameseWords(in: normalizedQuery)
        
        // Expand query with Vietnamese-specific enhancements
        let expandedQuery = expandVietnameseQuery(words: words)
        
        print("🔍 Optimized query: '\(expandedQuery)'")
        return expandedQuery
    }
    
    /// Normalize Vietnamese text for consistent processing
    private func normalizeVietnameseText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // Normalize whitespace
            .lowercased() // Vietnamese search is typically case-insensitive
    }
    
    /// Expand Vietnamese query with linguistic variations
    private func expandVietnameseQuery(words: [String]) -> String {
        var expandedWords = words
        
        // Add common Vietnamese query expansions
        for (index, word) in words.enumerated() {
            // Add variations for common Vietnamese words
            if let variations = getVietnameseWordVariations(word) {
                expandedWords.append(contentsOf: variations)
            }
        }
        
        return expandedWords.joined(separator: " ")
    }
    
    /// Get Vietnamese word variations for search expansion
    private func getVietnameseWordVariations(_ word: String) -> [String]? {
        let commonVariations: [String: [String]] = [
            "tôi": ["mình", "ta", "em", "anh", "chị"],
            "làm": ["thực hiện", "tiến hành", "thực thi"],
            "tốt": ["hay", "giỏi", "xuất sắc", "ổn"],
            "xấu": ["dở", "tệ", "không tốt"],
            "lớn": ["to", "rộng", "khổng lồ"],
            "nhỏ": ["bé", "tí", "nhỏ xíu"]
        ]
        
        return commonVariations[word.lowercased()]
    }
    
    // MARK: - Vietnamese Text Analysis
    
    /// Calculate word density for Vietnamese text
    private func calculateVietnameseWordDensity(text: String, words: [String]) -> Double {
        guard !text.isEmpty else { return 0.0 }
        
        // Vietnamese has different word density characteristics than English
        let adjustedWordCount = Double(words.count)
        let characterCount = Double(text.count)
        
        // Vietnamese words are typically longer, so adjust the density calculation
        return (adjustedWordCount / characterCount) * 1000 * 1.1 // 1.1 adjustment for Vietnamese
    }
    
    /// Analyze Vietnamese text characteristics
    func analyzeVietnameseText(_ text: String) -> VietnameseTextAnalysis {
        let words = tokenizeVietnameseWords(in: text)
        let sentences = detectVietnameseSentences(in: text)
        let wordDensity = calculateVietnameseWordDensity(text: text, words: words)
        
        // Calculate average word length (Vietnamese words tend to be longer)
        let totalWordLength = words.reduce(0) { $0 + $1.count }
        let averageWordLength = words.isEmpty ? 0.0 : Double(totalWordLength) / Double(words.count)
        
        // Calculate average sentence length
        let averageSentenceLength = sentences.isEmpty ? 0.0 : Double(text.count) / Double(sentences.count)
        
        return VietnameseTextAnalysis(
            wordCount: words.count,
            sentenceCount: sentences.count,
            characterCount: text.count,
            wordDensity: wordDensity,
            averageWordLength: averageWordLength,
            averageSentenceLength: averageSentenceLength,
            language: "vi",
            analysisDate: Date()
        )
    }
}

// MARK: - Supporting Data Structures

struct VietnameseTextChunk {
    let text: String
    let index: Int
    let sentences: [String]
    let characterCount: Int
    let wordCount: Int
    let sentenceCount: Int
    let wordDensity: Double
    let metadata: [String: Any]
}

struct VietnameseTextAnalysis {
    let wordCount: Int
    let sentenceCount: Int
    let characterCount: Int
    let wordDensity: Double
    let averageWordLength: Double
    let averageSentenceLength: Double
    let language: String
    let analysisDate: Date
}

// MARK: - Errors

enum VietnameseProcessingError: Error, LocalizedError {
    case tokenizationFailed(String)
    case sentenceDetectionFailed(String)
    case chunkingFailed(String)
    case queryOptimizationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .tokenizationFailed(let message):
            return "Vietnamese tokenization failed: \(message)"
        case .sentenceDetectionFailed(let message):
            return "Vietnamese sentence detection failed: \(message)"
        case .chunkingFailed(let message):
            return "Vietnamese chunking failed: \(message)"
        case .queryOptimizationFailed(let message):
            return "Vietnamese query optimization failed: \(message)"
        }
    }
}