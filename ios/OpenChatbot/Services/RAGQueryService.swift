import Foundation
import CoreData

// MARK: - RAG Query Service Protocol
protocol RAGQueryServiceProtocol {
    func queryDocuments(query: String, language: String?, topK: Int, threshold: Float) async throws -> RAGQueryResult
    func queryDocumentsInScope(query: String, documentIDs: [String]?, language: String?, topK: Int, threshold: Float) async throws -> RAGQueryResult
    func buildContext(from results: [SimilarityResult]) async throws -> RAGContext
    func scoreRelevance(query: String, results: [SimilarityResult]) async throws -> [ScoredResult]
}

// MARK: - RAG Query Service Implementation
class RAGQueryService: RAGQueryServiceProtocol {
    
    // MARK: - Dependencies  
    private let embeddingService: EmbeddingServiceProtocol
    private let vectorService: CoreDataVectorService
    
    // MARK: - Configuration
    private let maxContextLength: Int
    private let deduplicationThreshold: Float
    private let minimumRelevanceScore: Float
    
    // MARK: - Initialization
    init(
        embeddingService: EmbeddingServiceProtocol,
        vectorService: CoreDataVectorService,
        maxContextLength: Int = 4000,
        deduplicationThreshold: Float = 0.95,
        minimumRelevanceScore: Float = 0.3
    ) {
        self.embeddingService = embeddingService
        self.vectorService = vectorService
        self.maxContextLength = maxContextLength
        self.deduplicationThreshold = deduplicationThreshold
        self.minimumRelevanceScore = minimumRelevanceScore
    }
    
    // MARK: - Main Query Methods
    
    /// Main RAG query method - orchestrates the complete pipeline
    func queryDocuments(
        query: String,
        language: String? = nil,
        topK: Int = 5,
        threshold: Float = 0.7
    ) async throws -> RAGQueryResult {
        return try await queryDocumentsInScope(
            query: query,
            documentIDs: nil,
            language: language,
            topK: topK,
            threshold: threshold
        )
    }
    
    /// Scoped RAG query - allows filtering by specific documents
    func queryDocumentsInScope(
        query: String,
        documentIDs: [UUID]? = nil,
        language: String? = nil,
        topK: Int = 5,
        threshold: Float = 0.7
    ) async throws -> RAGQueryResult {
        
        let startTime = Date()
        
        // Step 1: Validate query
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RAGQueryError.invalidQuery("Query cannot be empty")
        }
        
        print("🔍 RAG Query Pipeline starting for: '\(query)'")
        
        // Step 2: Detect language if not provided
        let detectedLanguage = language ?? embeddingService.detectLanguage(for: query)
        print("🌐 Detected language: \(detectedLanguage ?? "unknown")")
        
        // Step 3: Generate query embedding
        let queryEmbedding: [Float]
        do {
            queryEmbedding = try await embeddingService.generateEmbedding(for: query, language: detectedLanguage)
            print("🧠 Generated query embedding (dim: \(queryEmbedding.count))")
        } catch {
            throw RAGQueryError.queryEmbeddingFailed(error.localizedDescription)
        }
        
        // Step 4: Perform similarity search
        let similarityResults: [SimilarityResult]
        do {
            similarityResults = try await vectorService.similaritySearch(
                queryEmbedding: queryEmbedding,
                topK: topK * 2, // Get more results for filtering
                threshold: threshold,
                documentIDs: documentIDs,
                language: detectedLanguage
            )
            print("📊 Found \(similarityResults.count) similarity results")
        } catch {
            throw RAGQueryError.similaritySearchFailed(error.localizedDescription)
        }
        
        // Step 5: Score relevance and filter
        let scoredResults = try await scoreRelevance(query: query, results: similarityResults)
        
        // Step 6: Deduplicate and rank
        let finalResults = deduplicateAndRank(scoredResults: scoredResults, topK: topK)
        
        // Step 7: Build context
        let context = try await buildContext(from: finalResults.map { $0.similarityResult })
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let result = RAGQueryResult(
            query: query,
            language: detectedLanguage,
            results: finalResults,
            context: context,
            processingTime: processingTime,
            totalCandidates: similarityResults.count
        )
        
        print("✅ RAG Query completed in \(String(format: "%.3f", processingTime))s")
        print("📝 Final results: \(finalResults.count), Context length: \(context.contextLength)")
        
        return result
    }
    
    // MARK: - Context Building
    
    func buildContext(from results: [SimilarityResult]) async throws -> RAGContext {
        guard !results.isEmpty else {
            throw RAGQueryError.contextBuildingFailed("No results to build context from")
        }
        
        var contextBuilder = ContextBuilder(maxLength: maxContextLength)
        var sourceDocuments: Set<UUID> = []
        var totalRelevance: Float = 0
        
        for result in results {
            sourceDocuments.insert(result.documentID)
            totalRelevance += result.similarity
            
            // Add chunk to context with metadata
            contextBuilder.addChunk(
                text: result.chunkText,
                documentID: result.documentID,
                similarity: result.similarity,
                chunkIndex: result.chunkIndex
            )
        }
        
        let contextText = contextBuilder.build()
        let averageRelevance = results.isEmpty ? 0 : totalRelevance / Float(results.count)
        
        // Detect dominant language in context
        let contextLanguage = embeddingService.detectLanguage(for: contextText)
        
        return RAGContext(
            contextText: contextText,
            sourceDocuments: Array(sourceDocuments),
            totalChunks: results.count,
            averageRelevance: averageRelevance,
            language: contextLanguage,
            contextLength: contextText.count
        )
    }
    
    // MARK: - Relevance Scoring
    
    func scoreRelevance(query: String, results: [SimilarityResult]) async throws -> [ScoredResult] {
        guard !results.isEmpty else {
            return []
        }
        
        var scoredResults: [ScoredResult] = []
        
        for (index, result) in results.enumerated() {
            do {
                // Calculate enhanced relevance score
                let relevanceScore = try await calculateRelevanceScore(
                    query: query,
                    result: result,
                    position: index
                )
                
                let scoredResult = ScoredResult(
                    similarityResult: result,
                    relevanceScore: relevanceScore,
                    contextRank: index,
                    isFiltered: relevanceScore >= minimumRelevanceScore
                )
                
                scoredResults.append(scoredResult)
                
            } catch {
                print("⚠️ Failed to score result \(index): \(error)")
                // Create a fallback scored result with base similarity
                let fallbackResult = ScoredResult(
                    similarityResult: result,
                    relevanceScore: result.similarity,
                    contextRank: index,
                    isFiltered: result.similarity >= minimumRelevanceScore
                )
                scoredResults.append(fallbackResult)
            }
        }
        
        return scoredResults.filter { $0.isFiltered }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateRelevanceScore(query: String, result: SimilarityResult, position: Int) async throws -> Float {
        // Base similarity score
        var score = result.similarity
        
        // Position penalty (earlier results get slight boost)
        let positionPenalty = Float(position) * 0.01
        score = max(0, score - positionPenalty)
        
        // Length bonus for substantial content
        let lengthBonus = min(0.1, Float(result.chunkText.count) / 1000.0 * 0.1)
        score += lengthBonus
        
        // Keyword overlap bonus
        let keywordBonus = calculateKeywordOverlap(query: query, text: result.chunkText)
        score += keywordBonus
        
        return min(1.0, score)
    }
    
    private func calculateKeywordOverlap(query: String, text: String) -> Float {
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespacesAndPunctuation).filter { !$0.isEmpty })
        let textWords = Set(text.lowercased().components(separatedBy: .whitespacesAndPunctuation).filter { !$0.isEmpty })
        
        guard !queryWords.isEmpty else { return 0 }
        
        let overlap = queryWords.intersection(textWords)
        return Float(overlap.count) / Float(queryWords.count) * 0.1 // Max 0.1 bonus
    }
    
    private func deduplicateAndRank(scoredResults: [ScoredResult], topK: Int) -> [ScoredResult] {
        var deduplicated: [ScoredResult] = []
        
        // Sort by relevance score descending
        let sorted = scoredResults.sorted { $0.relevanceScore > $1.relevanceScore }
        
        for result in sorted {
            let isDuplicate = deduplicated.contains { existing in
                calculateTextSimilarity(result.similarityResult.chunkText, existing.similarityResult.chunkText) > deduplicationThreshold
            }
            
            if !isDuplicate {
                deduplicated.append(result)
            }
            
            if deduplicated.count >= topK {
                break
            }
        }
        
        return deduplicated
    }
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndPunctuation).filter { !$0.isEmpty })
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndPunctuation).filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0 }
        
        return Float(intersection.count) / Float(union.count)
    }
}

// MARK: - Context Builder Helper
private class ContextBuilder {
    private var chunks: [(text: String, metadata: String)] = []
    private let maxLength: Int
    private var currentLength = 0
    
    init(maxLength: Int) {
        self.maxLength = maxLength
    }
    
    func addChunk(text: String, documentID: UUID, similarity: Float, chunkIndex: Int) {
        let metadata = "[Doc: \(documentID.uuidString.prefix(8)), Chunk: \(chunkIndex), Similarity: \(String(format: "%.3f", similarity))]"
        let chunkWithMetadata = "\(metadata)\n\(text)\n"
        
        if currentLength + chunkWithMetadata.count <= maxLength {
            chunks.append((text: text, metadata: metadata))
            currentLength += chunkWithMetadata.count
        }
    }
    
    func build() -> String {
        return chunks.map { "\($0.metadata)\n\($0.text)" }.joined(separator: "\n\n")
    }
} 