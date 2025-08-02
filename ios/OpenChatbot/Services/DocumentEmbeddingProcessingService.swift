import Foundation
import CoreData
import NaturalLanguage

/// Complete implementation of document embedding processing service
/// Transforms documents into searchable vector embeddings with semantic chunking
class DocumentEmbeddingProcessingService {
    
    // MARK: - Dependencies
    private let embeddingService: EmbeddingServiceProtocol
    private let vectorService: CoreDataVectorService
    private let context: NSManagedObjectContext
    
    // MARK: - Configuration
    private let defaultChunkSize: Int = 1000
    private let defaultOverlap: Int = 100
    private let minChunkSize: Int = 200
    private let maxChunkSize: Int = 2000
    
    // MARK: - Initialization
    init(
        embeddingService: EmbeddingServiceProtocol,
        vectorService: CoreDataVectorService,
        context: NSManagedObjectContext
    ) {
        self.embeddingService = embeddingService
        self.vectorService = vectorService
        self.context = context
    }
    
    /// Process document to generate embeddings with semantic chunking
    func processDocumentEmbeddings(for documentID: UUID) async throws {
        print("🧠 Processing embeddings for document: \(documentID)")
        
        // 1. Fetch document content
        guard let document = try await fetchDocument(documentID: documentID) else {
            throw EmbeddingProcessingError.documentNotFound(documentID)
        }
        
        // 2. Clean and prepare text
        let cleanedText = cleanText(document.content)
        guard !cleanedText.isEmpty else {
            throw EmbeddingProcessingError.emptyContent(documentID)
        }
        
        // 3. Detect language for optimal processing
        let detectedLanguage = embeddingService.detectLanguage(for: cleanedText) ?? "en"
        print("📝 Detected language: \(detectedLanguage)")
        
        // 4. Create semantic chunks
        let chunks = createSemanticChunks(
            text: cleanedText,
            language: detectedLanguage,
            documentType: document.type?.rawValue ?? "unknown"
        )
        print("📊 Created \(chunks.count) semantic chunks")
        
        // 5. Generate embeddings for each chunk
        let embeddings = try await generateEmbeddings(for: chunks, language: detectedLanguage)
        print("🎯 Generated \(embeddings.count) embeddings")
        
        // 6. Store embeddings in vector database
        try await storeEmbeddings(
            embeddings: embeddings,
            chunks: chunks,
            documentID: documentID,
            language: detectedLanguage
        )
        
        // 7. Update document processing status
        try await markDocumentAsProcessed(documentID: documentID)
        
        print("✅ Embedding processing completed for document: \(documentID)")
    }
    
    // MARK: - Text Chunking
    
    /// Create semantic chunks from text with language awareness
    private func createSemanticChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        // Use Vietnamese-specific chunking for Vietnamese text
        if language == "vi" {
            return createVietnameseAwareChunks(text: text, language: language, documentType: documentType)
        }
        
        // Standard chunking for other languages
        return createStandardChunks(text: text, language: language, documentType: documentType)
    }
    
    /// Create Vietnamese-aware semantic chunks using inline processing
    private func createVietnameseAwareChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        print("🇻🇳 Using Vietnamese-aware chunking")
        
        let adaptiveChunkSize = determineOptimalChunkSize(for: documentType, language: language)
        let adaptiveOverlap = Int(Double(defaultOverlap) * 1.1) // Slightly more overlap for Vietnamese
        
        // Vietnamese-specific sentence detection
        let sentences = detectVietnameseSentences(in: text)
        print("📝 Detected \(sentences.count) Vietnamese sentences")
        
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentSentences: [String] = []
        var chunkIndex = 0
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if adding this sentence would exceed chunk size
            if !currentChunk.isEmpty && (currentChunk.count + trimmedSentence.count) > adaptiveChunkSize {
                // Finalize current chunk
                let chunk = createVietnameseChunkWithMetadata(
                    text: currentChunk,
                    sentences: currentSentences,
                    index: chunkIndex,
                    language: language
                )
                chunks.append(chunk)
                
                // Start new chunk with overlap from previous
                let overlapText = createVietnameseOverlap(from: currentSentences, maxSize: adaptiveOverlap)
                currentChunk = overlapText + (overlapText.isEmpty ? "" : " ") + trimmedSentence
                currentSentences = extractOverlapSentences(from: currentSentences, maxSize: adaptiveOverlap)
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
            let chunk = createVietnameseChunkWithMetadata(
                text: currentChunk,
                sentences: currentSentences,
                index: chunkIndex,
                language: language
            )
            chunks.append(chunk)
        }
        
        // Handle edge case: if no chunks created, create single chunk
        if chunks.isEmpty && !text.isEmpty {
            let chunk = createVietnameseChunkWithMetadata(
                text: text,
                sentences: [text],
                index: 0,
                language: language
            )
            chunks.append(chunk)
        }
        
        print("✅ Created \(chunks.count) Vietnamese-aware chunks")
        return chunks
    }
    
    /// Create standard semantic chunks for non-Vietnamese languages
    private func createStandardChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        let adaptiveChunkSize = determineOptimalChunkSize(for: documentType, language: language)
        
        // Split by paragraphs first to preserve structure
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var chunkIndex = 0
        
        for paragraph in paragraphs {
            let cleanParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // If adding this paragraph would exceed chunk size, finalize current chunk
            if !currentChunk.isEmpty && (currentChunk.count + cleanParagraph.count) > adaptiveChunkSize {
                chunks.append(createChunkWithMetadata(
                    text: currentChunk,
                    index: chunkIndex,
                    language: language
                ))
                
                // Start new chunk with overlap from previous
                currentChunk = createOverlapText(from: currentChunk) + "\n\n" + cleanParagraph
                chunkIndex += 1
            } else {
                // Add paragraph to current chunk
                if currentChunk.isEmpty {
                    currentChunk = cleanParagraph
                } else {
                    currentChunk += "\n\n" + cleanParagraph
                }
            }
        }
        
        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            chunks.append(createChunkWithMetadata(
                text: currentChunk,
                index: chunkIndex,
                language: language
            ))
        }
        
        // Handle edge case: if no chunks created, create single chunk
        if chunks.isEmpty {
            chunks.append(createChunkWithMetadata(
                text: text,
                index: 0,
                language: language
            ))
        }
        
        return chunks
    }
    
    /// Determine optimal chunk size based on document type and language
    private func determineOptimalChunkSize(for documentType: String, language: String) -> Int {
        var baseSize = defaultChunkSize
        
        // Adjust for document type
        switch documentType.lowercased() {
        case "pdf", "technical", "manual":
            baseSize = Int(Double(defaultChunkSize) * 1.2) // Larger chunks for technical content
        case "text", "note":
            baseSize = Int(Double(defaultChunkSize) * 0.8) // Smaller chunks for notes
        default:
            baseSize = defaultChunkSize
        }
        
        // Adjust for Vietnamese (longer words, different sentence structure)
        if language == "vi" {
            baseSize = Int(Double(baseSize) * 1.1)
        }
        
        return min(max(baseSize, minChunkSize), maxChunkSize)
    }
    
    /// Create overlap text from the end of previous chunk
    private func createOverlapText(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let overlapWords = min(defaultOverlap / 10, words.count) // Approximate word count
        
        if overlapWords > 0 {
            return words.suffix(overlapWords).joined(separator: " ")
        }
        return ""
    }
    
    /// Create chunk with metadata
    private func createChunkWithMetadata(text: String, index: Int, language: String) -> TextChunk {
        return TextChunk(
            text: text,
            index: index,
            characterCount: text.count,
            wordCount: text.components(separatedBy: .whitespacesAndNewlines).count,
            language: language,
            metadata: [
                "chunk_type": "semantic",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "word_density": calculateWordDensity(text)
            ]
        )
    }
    
    /// Calculate word density for chunk quality metrics
    private func calculateWordDensity(_ text: String) -> Double {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return Double(words.count) / Double(text.count) * 1000 // words per 1000 characters
    }
    
    // MARK: - Vietnamese Text Processing
    
    /// Detect Vietnamese sentences using language-aware tokenization
    private func detectVietnameseSentences(in text: String) -> [String] {
        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.setLanguage(.vietnamese)
        sentenceTokenizer.string = text
        
        var sentences: [String] = []
        sentenceTokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let sentence = String(text[tokenRange])
            sentences.append(sentence)
            return true
        }
        
        // Apply Vietnamese-specific refinement
        return refineVietnameseSentenceBoundaries(sentences)
    }
    
    /// Refine sentence boundaries using Vietnamese grammar rules
    private func refineVietnameseSentenceBoundaries(_ sentences: [String]) -> [String] {
        var refinedSentences: [String] = []
        var currentSentence = ""
        
        let vietnameseConjunctions: Set<String> = [
            "và", "hoặc", "nhưng", "mà", "hay", "thì", "nên", "để", "vì", "do", "bởi vì", "tuy nhiên", "tuy", "dù", "dẫu"
        ]
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this should be merged with previous sentence
            let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            let shouldMerge = !currentSentence.isEmpty && (
                (words.first.map { vietnameseConjunctions.contains($0.lowercased()) } ?? false) ||
                (trimmed.count < 20 && words.count < 4) ||
                !currentSentence.hasSuffix(".") && !currentSentence.hasSuffix("!") && !currentSentence.hasSuffix("?")
            )
            
            if shouldMerge {
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
        
        return refinedSentences.filter { !$0.isEmpty }
    }
    
    /// Create Vietnamese chunk with enhanced metadata
    private func createVietnameseChunkWithMetadata(
        text: String,
        sentences: [String],
        index: Int,
        language: String
    ) -> TextChunk {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordDensity = calculateVietnameseWordDensity(text: text, words: words)
        
        return TextChunk(
            text: text,
            index: index,
            characterCount: text.count,
            wordCount: words.count,
            language: language,
            metadata: [
                "chunk_type": "vietnamese_semantic",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "word_density": wordDensity,
                "sentence_count": sentences.count,
                "vietnamese_enhanced": true,
                "sentence_boundary_detection": "vietnamese_grammar_aware",
                "tokenization_method": "nl_tokenizer_vietnamese"
            ]
        )
    }
    
    /// Calculate Vietnamese-specific word density
    private func calculateVietnameseWordDensity(text: String, words: [String]) -> Double {
        guard !text.isEmpty else { return 0.0 }
        
        // Vietnamese has different word density characteristics than English
        let adjustedWordCount = Double(words.count)
        let characterCount = Double(text.count)
        
        // Vietnamese words are typically longer, so adjust the density calculation
        return (adjustedWordCount / characterCount) * 1000 * 1.15 // 1.15 adjustment for Vietnamese
    }
    
    /// Create overlap text from previous Vietnamese sentences
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
    
    /// Extract sentences for Vietnamese overlap
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
    
    // MARK: - Text Cleaning
    
    /// Clean and normalize text for optimal processing
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // Normalize whitespace
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression) // Normalize line breaks
    }
    
    // MARK: - Embedding Generation
    
    /// Generate embeddings for all chunks with batch processing
    private func generateEmbeddings(for chunks: [TextChunk], language: String) async throws -> [ChunkEmbedding] {
        var embeddings: [ChunkEmbedding] = []
        
        // Process chunks in batches for better performance
        let batchSize = 10
        for i in stride(from: 0, to: chunks.count, by: batchSize) {
            let endIndex = min(i + batchSize, chunks.count)
            let batch = Array(chunks[i..<endIndex])
            
            let batchTexts = batch.map { $0.text }
            let batchEmbeddings = try await embeddingService.generateEmbeddings(for: batchTexts, language: language)
            
            for (index, embedding) in batchEmbeddings.enumerated() {
                let chunkIndex = i + index
                embeddings.append(ChunkEmbedding(
                    chunk: batch[index],
                    embedding: embedding,
                    chunkIndex: chunkIndex
                ))
            }
            
            // Small delay to prevent overwhelming the system
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        return embeddings
    }
    
    // MARK: - Storage
    
    /// Store embeddings in vector database with metadata
    private func storeEmbeddings(
        embeddings: [ChunkEmbedding],
        chunks: [TextChunk],
        documentID: UUID,
        language: String
    ) async throws {
        for embedding in embeddings {
            let metadata: [String: Any] = [
                "language": language,
                "chunk_index": embedding.chunkIndex,
                "character_count": embedding.chunk.characterCount,
                "word_count": embedding.chunk.wordCount,
                "word_density": embedding.chunk.metadata["word_density"] ?? 0.0,
                "processing_date": embedding.chunk.metadata["processing_date"] ?? "",
                "chunk_type": embedding.chunk.metadata["chunk_type"] ?? "semantic"
            ]
            
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: embedding.chunk.text,
                embedding: embedding.embedding,
                chunkIndex: embedding.chunkIndex,
                metadata: metadata,
                language: language
            )
        }
    }
    
    // MARK: - Database Operations
    
    /// Fetch document from Core Data
    private func fetchDocument(documentID: UUID) async throws -> DocumentContent? {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Document")
                request.predicate = NSPredicate(format: "id == %@", documentID as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.context.fetch(request)
                    if let document = results.first {
                        let content = DocumentContent(
                            id: documentID,
                            content: document.value(forKey: "content") as? String ?? "",
                            title: document.value(forKey: "title") as? String ?? "",
                            type: ProcessingDocumentType(rawValue: document.value(forKey: "type") as? String ?? "unknown")
                        )
                        continuation.resume(returning: content)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Mark document as processed
    private func markDocumentAsProcessed(documentID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Document")
                request.predicate = NSPredicate(format: "id == %@", documentID as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.context.fetch(request)
                    if let document = results.first {
                        document.setValue(true, forKey: "isEmbeddingProcessed")
                        document.setValue(Date(), forKey: "embeddingProcessedAt")
                        try self.context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct TextChunk {
    let text: String
    let index: Int
    let characterCount: Int
    let wordCount: Int
    let language: String
    let metadata: [String: Any]
}

struct ChunkEmbedding {
    let chunk: TextChunk
    let embedding: [Float]
    let chunkIndex: Int
}

struct DocumentContent {
    let id: UUID
    let content: String
    let title: String
    let type: ProcessingDocumentType?
}

enum ProcessingDocumentType: String {
    case pdf = "pdf"
    case text = "text"
    case image = "image"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Document"
        case .text: return "Text Document"
        case .image: return "Image Document"
        case .unknown: return "Unknown Document"
        }
    }
}

// MARK: - Errors

enum EmbeddingProcessingError: Error, LocalizedError {
    case documentNotFound(UUID)
    case emptyContent(UUID)
    case chunkingFailed(String)
    case embeddingGenerationFailed(String)
    case storageFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .emptyContent(let id):
            return "Document has no content: \(id)"
        case .chunkingFailed(let message):
            return "Text chunking failed: \(message)"
        case .embeddingGenerationFailed(let message):
            return "Embedding generation failed: \(message)"
        case .storageFailed(let message):
            return "Storage operation failed: \(message)"
        }
    }
} 