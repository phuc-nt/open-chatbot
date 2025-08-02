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