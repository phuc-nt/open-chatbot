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
    
    /// Optimized similarity search with batching and early termination
    private func manualSimilaritySearch(
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float,
        documentIDs: [UUID]?,
        language: String?
    ) throws -> [SimilarityResult] {
        print("🚀 Starting optimized similarity search...")
        
        // Use optimized batch search for better performance
        return try optimizedBatchSimilaritySearch(
            queryEmbedding: queryEmbedding,
            topK: topK,
            threshold: threshold,
            documentIDs: documentIDs,
            language: language
        )
    }
    
    /// Optimized batch similarity search with early termination and memory efficiency
    private func optimizedBatchSimilaritySearch(
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float,
        documentIDs: [UUID]?,
        language: String?
    ) throws -> [SimilarityResult] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Build optimized Core Data request
        let request = NSFetchRequest<DocumentEmbeddingEntity>(entityName: "DocumentEmbedding")
        
        // Build predicate for pre-filtering
        var predicates: [NSPredicate] = []
        
        // Document ID filter
        if let documentIDs = documentIDs, !documentIDs.isEmpty {
            predicates.append(NSPredicate(format: "documentID IN %@", documentIDs))
            print("📄 Filtering by \(documentIDs.count) document IDs")
        }
        
        // Language filter
        if let language = language {
            predicates.append(NSPredicate(format: "language == %@", language))
            print("🌐 Filtering by language: \(language)")
        }
        
        // Add dimension filter to avoid corrupted embeddings
        predicates.append(NSPredicate(format: "embeddingDimensions > 0"))
        
        // Combine predicates
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Optimize fetch request for performance
        request.fetchBatchSize = 100 // Process in batches to reduce memory usage
        request.includesPropertyValues = true
        request.returnsObjectsAsFaults = false
        
        // Priority-based sorting for faster convergence (newer embeddings first)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        // Get total count for optimization decisions
        let countRequest = NSFetchRequest<NSNumber>(entityName: "DocumentEmbedding")
        countRequest.predicate = request.predicate
        countRequest.resultType = .countResultType
        let totalCount = try backgroundContext.fetch(countRequest).first?.intValue ?? 0
        print("📊 Total embeddings to process: \(totalCount)")
        
        // Use different strategies based on collection size
        if totalCount <= 500 {
            return try fastSmallCollectionSearch(
                request: request,
                queryEmbedding: queryEmbedding,
                topK: topK,
                threshold: threshold
            )
        } else {
            return try optimizedLargeCollectionSearch(
                request: request,
                queryEmbedding: queryEmbedding,
                topK: topK,
                threshold: threshold,
                totalCount: totalCount,
                startTime: startTime
            )
        }
    }
    
    /// Fast search for small collections (≤500 embeddings)
    private func fastSmallCollectionSearch(
        request: NSFetchRequest<DocumentEmbeddingEntity>,
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float
    ) throws -> [SimilarityResult] {
        print("⚡ Using fast small collection strategy")
        
        let allEmbeddings = try backgroundContext.fetch(request)
        var results: [SimilarityResult] = []
        results.reserveCapacity(min(topK * 2, allEmbeddings.count))
        
        for embedding in allEmbeddings {
            guard let embeddingData = embedding.embeddingVector,
                  let chunkText = embedding.chunkText,
                  let documentID = embedding.documentID else {
                continue
            }
            
            let similarity = calculateCosineSimilarityFromData(
                queryEmbedding: queryEmbedding,
                embeddingData: embeddingData
            )
            
            if similarity >= threshold {
                let result = createSimilarityResult(
                    from: embedding,
                    similarity: similarity,
                    chunkText: chunkText,
                    documentID: documentID
                )
                results.append(result)
            }
        }
        
        return Array(results.sorted { $0.similarity > $1.similarity }.prefix(topK))
    }
    
    /// Optimized search for large collections with early termination
    private func optimizedLargeCollectionSearch(
        request: NSFetchRequest<DocumentEmbeddingEntity>,
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float,
        totalCount: Int,
        startTime: CFAbsoluteTime
    ) throws -> [SimilarityResult] {
        print("🎯 Using optimized large collection strategy")
        
        // Priority queue to maintain top-K results efficiently
        var topResults: [(similarity: Float, result: SimilarityResult)] = []
        var processedCount = 0
        let batchSize = 100
        
        // Dynamic threshold adjustment for early termination
        var dynamicThreshold = threshold
        var lastProgressTime = startTime
        var shouldTerminateEarly = false
        
        // Process in batches using fetchOffset pagination
        var offset = 0
        
        while offset < totalCount && !shouldTerminateEarly {
            autoreleasepool {
                request.fetchOffset = offset
                request.fetchLimit = batchSize
                
                do {
                    let batch = try backgroundContext.fetch(request)
                    
                    for embedding in batch {
                        guard let embeddingData = embedding.embeddingVector,
                              let chunkText = embedding.chunkText,
                              let documentID = embedding.documentID else {
                            continue
                        }
                        
                        let similarity = calculateCosineSimilarityFromData(
                            queryEmbedding: queryEmbedding,
                            embeddingData: embeddingData
                        )
                        
                        // Early skip if below threshold
                        if similarity < dynamicThreshold {
                            processedCount += 1
                            continue
                        }
                        
                        let result = createSimilarityResult(
                            from: embedding,
                            similarity: similarity,
                            chunkText: chunkText,
                            documentID: documentID
                        )
                        
                        // Maintain top-K results efficiently
                        topResults.append((similarity: similarity, result: result))
                        
                        // Keep only top-K + buffer for efficiency
                        if topResults.count > topK * 2 {
                            topResults.sort { $0.similarity > $1.similarity }
                            topResults = Array(topResults.prefix(topK + 10))
                            
                            // Adjust dynamic threshold to filter out poor results
                            if topResults.count >= topK {
                                dynamicThreshold = max(threshold, topResults[topK - 1].similarity * 0.95)
                            }
                        }
                        
                        processedCount += 1
                    }
                    
                    // Progress logging every 2 seconds
                    let currentTime = CFAbsoluteTimeGetCurrent()
                    if currentTime - lastProgressTime > 2.0 {
                        let progress = Double(processedCount) / Double(totalCount) * 100
                        print("📈 Progress: \(String(format: "%.1f", progress))% (\(processedCount)/\(totalCount)) - \(topResults.count) candidates")
                        lastProgressTime = currentTime
                    }
                    
                    // Early termination if we have enough high-quality results
                    if topResults.count >= topK * 3 && processedCount > totalCount / 2 {
                        let avgTopSimilarity = topResults.prefix(topK).map { $0.similarity }.reduce(0, +) / Float(topK)
                        if avgTopSimilarity > threshold * 1.5 {
                            print("🏁 Early termination: found enough high-quality results")
                            shouldTerminateEarly = true
                        }
                    }
                    
                } catch {
                    print("⚠️ Batch processing error: \(error)")
                }
            }
            
            offset += batchSize
        }
        
        // Final sorting and trimming
        let finalResults = topResults
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map { $0.result }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("🎯 Optimized search completed: \(finalResults.count) results in \(String(format: "%.2f", totalTime))s")
        print("📊 Processed \(processedCount)/\(totalCount) embeddings (\(String(format: "%.1f", Double(processedCount)/Double(totalCount)*100))%)")
        
        return Array(finalResults)
    }
    
    /// Helper to create SimilarityResult with parsed metadata
    private func createSimilarityResult(
        from embedding: DocumentEmbeddingEntity,
        similarity: Float,
        chunkText: String,
        documentID: UUID
    ) -> SimilarityResult {
        // Parse metadata efficiently
        var metadata: [String: Any] = [:]
        if let metadataString = embedding.metadata {
            if let metadataData = metadataString.data(using: .utf8),
               let parsedMetadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                metadata = parsedMetadata
            }
        }
        
        return SimilarityResult(
            id: embedding.id?.uuidString ?? UUID().uuidString,
            documentID: documentID.uuidString,
            chunkText: chunkText,
            similarity: similarity,
            chunkIndex: Int(embedding.chunkIndex),
            metadata: metadata
        )
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

 