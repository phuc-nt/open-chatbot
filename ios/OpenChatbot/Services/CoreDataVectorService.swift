import CoreData
import Foundation

/// CoreDataVectorService - Vector database implementation using Core Data Vector Search (iOS 17+)
/// Provides native Apple vector search integration với unified metadata + vector storage
class CoreDataVectorService {
    private let context: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        
        // Create background context for heavy operations
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.parent = context
        self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Vector Operations
    
    /// Save embedding vector to Core Data với vector indexing
    func saveEmbedding(
        documentID: UUID,
        chunkText: String,
        embedding: [Float],
        chunkIndex: Int = 0,
        metadata: [String: Any] = [:],
        language: String? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    let newEmbedding = DocumentEmbeddingEntity(context: self.backgroundContext)
                    newEmbedding.id = UUID()
                    newEmbedding.documentID = documentID
                    newEmbedding.chunkText = chunkText
                    newEmbedding.chunkIndex = Int32(chunkIndex)
                    newEmbedding.embeddingDimensions = Int32(embedding.count)
                    newEmbedding.language = language
                    newEmbedding.createdAt = Date()
                    
                    // Convert [Float] to Data for vector storage
                    let embeddingData = Data(bytes: embedding, count: embedding.count * MemoryLayout<Float>.size)
                    newEmbedding.embeddingVector = embeddingData
                    
                    // Store metadata as JSON string
                    if !metadata.isEmpty {
                        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
                        newEmbedding.metadata = String(data: metadataData, encoding: .utf8)
                    }
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: VectorDatabaseError.insertionFailed(error))
                }
            }
        }
    }
    
    /// Perform similarity search using hybrid approach: Core Data Vector Search + Manual fallback
    func similaritySearch(
        queryEmbedding: [Float],
        topK: Int = 5,
        threshold: Float = 0.7,
        documentIDs: [UUID]? = nil,
        language: String? = nil
    ) async throws -> [SimilarityResult] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[SimilarityResult], Error>) in
            backgroundContext.perform {
                do {
                    print("🔍 Starting hybrid similarity search...")
                    print("📊 Query embedding dimensions: \(queryEmbedding.count)")
                    print("📊 Search parameters: topK=\(topK), threshold=\(threshold)")
                    
                    // Always use manual similarity search for now (Core Data Vector Search debugging)
                    let results = try self.manualSimilaritySearch(
                        queryEmbedding: queryEmbedding,
                        topK: topK,
                        threshold: threshold,
                        documentIDs: documentIDs,
                        language: language
                    )
                    
                    print("✅ Similarity search completed: \(results.count) results")
                    continuation.resume(returning: results)
                } catch {
                    print("❌ Similarity search failed: \(error)")
                    continuation.resume(throwing: VectorDatabaseError.searchFailed(error))
                }
            }
        }
    }
    
    /// Manual similarity search - pure Swift calculation with Core Data filtering
    private func manualSimilaritySearch(
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float,
        documentIDs: [UUID]?,
        language: String?
    ) throws -> [SimilarityResult] {
        print("🔧 Starting manual similarity search...")
        
        let request = NSFetchRequest<DocumentEmbeddingEntity>(entityName: "DocumentEmbedding")
        
        // Build predicate for basic filtering (no vector search)
        var predicates: [NSPredicate] = []
        
        // Optional document ID filter
        if let documentIDs = documentIDs, !documentIDs.isEmpty {
            let documentPredicate = NSPredicate(format: "documentID IN %@", documentIDs)
            predicates.append(documentPredicate)
            print("📄 Filtering by document IDs: \(documentIDs.count)")
        }
        
        // Optional language filter
        if let language = language {
            let languagePredicate = NSPredicate(format: "language == %@", language)
            predicates.append(languagePredicate)
            print("🌐 Filtering by language: \(language)")
        }
        
        // Combine predicates if any
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Fetch all matching documents (no vector filtering yet)
        let allResults = try backgroundContext.fetch(request)
        print("📊 Fetched \(allResults.count) embeddings for manual calculation")
        
        // Calculate similarity for each result
        var similarityResults: [SimilarityResult] = []
        
        for (index, embedding) in allResults.enumerated() {
            // Safe unwrapping of optional properties
            guard let embeddingData = embedding.embeddingVector,
                  let chunkText = embedding.chunkText,
                  let documentID = embedding.documentID else {
                print("⚠️ Skipping embedding \(index) with missing data")
                continue
            }
            
            // Calculate cosine similarity
            let similarity = self.calculateCosineSimilarityFromData(
                queryEmbedding: queryEmbedding,
                embeddingData: embeddingData
            )
            
            // Apply threshold filter
            guard similarity >= threshold else {
                if index < 5 { // Log first few for debugging
                    print("📉 Embedding \(index): similarity \(String(format: "%.3f", similarity)) below threshold \(threshold)")
                }
                continue
            }
            
            // Parse metadata if available
            var metadata: [String: Any] = [:]
            if let metadataString = embedding.metadata {
                if let metadataData = metadataString.data(using: .utf8),
                   let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                    metadata = parsedMetadata
                }
            }
            
            let result = SimilarityResult(
                id: embedding.id?.uuidString ?? UUID().uuidString,
                documentID: documentID.uuidString,
                chunkText: chunkText,
                similarity: similarity,
                chunkIndex: Int(embedding.chunkIndex),
                metadata: metadata
            )
            
            similarityResults.append(result)
            print("✅ Added result \(similarityResults.count): similarity=\(String(format: "%.3f", similarity))")
        }
        
        print("🎯 Manual search found \(similarityResults.count) results above threshold")
        
        // Sort by similarity (highest first) and return top K
        let topResults = similarityResults
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map { $0 }
            
        print("📋 Returning top \(topResults.count) results")
        return topResults
    }
    
    /// Batch insert embeddings for performance
    func batchInsertEmbeddings(_ embeddings: [(UUID, String, [Float], Int, [String: Any], String?)]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    for (documentID, chunkText, embedding, chunkIndex, metadata, language) in embeddings {
                        let newEmbedding = DocumentEmbeddingEntity(context: self.backgroundContext)
                        newEmbedding.id = UUID()
                        newEmbedding.documentID = documentID
                        newEmbedding.chunkText = chunkText
                        newEmbedding.chunkIndex = Int32(chunkIndex)
                        newEmbedding.embeddingDimensions = Int32(embedding.count)
                        newEmbedding.language = language
                        newEmbedding.createdAt = Date()
                        
                        // Convert embedding to Data
                        let embeddingData = Data(bytes: embedding, count: embedding.count * MemoryLayout<Float>.size)
                        newEmbedding.embeddingVector = embeddingData
                        
                        // Store metadata
                        if !metadata.isEmpty {
                            let metadataData = try JSONSerialization.data(withJSONObject: metadata)
                            newEmbedding.metadata = String(data: metadataData, encoding: .utf8)
                        }
                    }
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: VectorDatabaseError.batchInsertionFailed(error))
                }
            }
        }
    }
    
    /// Get embedding count for statistics
    func getEmbeddingCount(forDocumentID documentID: UUID? = nil) async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<DocumentEmbeddingEntity>(entityName: "DocumentEmbedding")
                    
                    if let documentID = documentID {
                        request.predicate = NSPredicate(format: "documentID == %@", documentID as CVarArg)
                    }
                    
                    let count = try self.backgroundContext.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: VectorDatabaseError.countFailed(error))
                }
            }
        }
    }
    
    /// Delete embeddings by document ID
    func deleteEmbeddings(forDocumentID documentID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<DocumentEmbeddingEntity>(entityName: "DocumentEmbedding")
                    request.predicate = NSPredicate(format: "documentID == %@", documentID as CVarArg)
                    
                    let embeddings = try self.backgroundContext.fetch(request)
                    for embedding in embeddings {
                        self.backgroundContext.delete(embedding)
                    }
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: VectorDatabaseError.deletionFailed(error))
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculate cosine distance between query và stored embedding
    private func calculateDistance(queryEmbedding: [Float], embeddingData: Data) -> Float {
        let storedEmbedding = embeddingData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
        
        guard storedEmbedding.count == queryEmbedding.count else {
            return 1.0 // Maximum distance for dimension mismatch
        }
        
        return 1.0 - cosineSimilarity(queryEmbedding, storedEmbedding)
    }
    
    /// Calculate cosine similarity between two vectors
    private func cosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Float {
        guard vec1.count == vec2.count else { return 0.0 }
        
        let dotProduct = zip(vec1, vec2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    /// Calculate cosine similarity from Data format
    private func calculateCosineSimilarityFromData(
        queryEmbedding: [Float],
        embeddingData: Data
    ) -> Float {
        let storedEmbedding = embeddingData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
        
        guard storedEmbedding.count == queryEmbedding.count else {
            print("⚠️ Dimension mismatch: query=\(queryEmbedding.count), stored=\(storedEmbedding.count)")
            return 0.0 // Dimension mismatch
        }
        
        return cosineSimilarity(queryEmbedding, storedEmbedding)
    }
}

// MARK: - Supporting Types

/// Result từ similarity search
struct SimilarityResult {
    let id: String
    let documentID: String
    let chunkText: String
    let similarity: Float
    let chunkIndex: Int
    let metadata: [String: Any]
}

/// Vector database errors
enum VectorDatabaseError: LocalizedError {
    case insertionFailed(Error)
    case searchFailed(Error)
    case batchInsertionFailed(Error)
    case deletionFailed(Error)
    case countFailed(Error)
    case invalidVector
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .insertionFailed(let error):
            return "Failed to insert embedding: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Failed to search vectors: \(error.localizedDescription)"
        case .batchInsertionFailed(let error):
            return "Failed to batch insert embeddings: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete embeddings: \(error.localizedDescription)"
        case .countFailed(let error):
            return "Failed to count embeddings: \(error.localizedDescription)"
        case .invalidVector:
            return "Invalid vector format or dimensions"
        case .configurationError:
            return "Vector database configuration error"
        }
    }
} 

 