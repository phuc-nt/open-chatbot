import Foundation

// MARK: - RAG Query Results
struct RAGQueryResult {
    let query: String
    let language: String?
    let results: [ScoredResult]
    let context: RAGContext
    let processingTime: TimeInterval
    let totalCandidates: Int
}

struct ScoredResult {
    let similarityResult: SimilarityResult
    let relevanceScore: Float
    let contextRank: Int
    let isFiltered: Bool
}

struct RAGContext {
    let contextText: String
    let sourceDocuments: [String]
    let totalChunks: Int
    let averageRelevance: Float
    let language: String?
    let contextLength: Int
}

// MARK: - Similarity Search Result (compatible with CoreDataVectorService)
struct SimilarityResult {
    let id: String
    let documentID: String
    let chunkText: String
    let similarity: Float
    let chunkIndex: Int
    let metadata: [String: Any]
}

// MARK: - RAG Query Errors
enum RAGQueryError: Error, LocalizedError {
    case queryEmbeddingFailed(String)
    case similaritySearchFailed(String)
    case contextBuildingFailed(String)
    case relevanceScoringFailed(String)
    case invalidQuery(String)
    case noResultsFound
    case languageDetectionFailed
    
    var errorDescription: String? {
        switch self {
        case .queryEmbeddingFailed(let message):
            return "Failed to generate query embedding: \(message)"
        case .similaritySearchFailed(let message):
            return "Similarity search failed: \(message)"
        case .contextBuildingFailed(let message):
            return "Failed to build context: \(message)"
        case .relevanceScoringFailed(let message):
            return "Relevance scoring failed: \(message)"
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        case .noResultsFound:
            return "No relevant documents found for the query"
        case .languageDetectionFailed:
            return "Failed to detect query language"
        }
    }
}

// MARK: - Service Protocols (để tránh circular dependencies)

protocol EmbeddingServiceProtocol {
    func generateEmbedding(for text: String, language: String?) async throws -> [Float]
    func detectLanguage(for text: String) -> String?
}

protocol VectorServiceProtocol {
    func similaritySearch(
        queryEmbedding: [Float],
        topK: Int,
        threshold: Float,
        documentIDs: [String]?,
        language: String?
    ) async throws -> [SimilarityResult]
} 