import Foundation
import NaturalLanguage
import CoreData

// MARK: - Enhanced Embedding Service Protocol for Testing
protocol EmbeddingServiceProtocol {
    func generateEmbedding(for text: String, language: String?) async throws -> [Float]
    func generateEmbeddings(for texts: [String], language: String?) async throws -> [[Float]]
    func detectLanguage(for text: String) -> String?
    func cacheEmbedding(text: String, embedding: [Float], language: String?)
    func getCachedEmbedding(for text: String) -> [Float]?
    func benchmarkEmbeddingPerformance(text: String, iterations: Int) async -> (averageTime: Double, embeddings: [[Float]])
}

// MARK: - NLContextualEmbedding Wrapper Protocol for Testing
protocol NLContextualEmbeddingProtocol {
    var hasAvailableAssets: Bool { get }
    func requestAssets() async throws -> NLContextualEmbedding.AssetsResult
    func embeddingResult(for text: String, language: NLLanguage) throws -> NLContextualEmbeddingResult
}

// MARK: - API Embedding Service Protocol
protocol APIEmbeddingServiceProtocol {
    func generateEmbedding(for text: String, language: String) async throws -> [Float]
}

// MARK: - Real NLContextualEmbedding Wrapper
class NLContextualEmbeddingWrapper: NLContextualEmbeddingProtocol {
    private let embedding: NLContextualEmbedding
    
    init(language: NLLanguage) {
        self.embedding = NLContextualEmbedding(language: language)!
    }
    
    var hasAvailableAssets: Bool {
        return embedding.hasAvailableAssets
    }
    
    func requestAssets() async throws -> NLContextualEmbedding.AssetsResult {
        return try await embedding.requestAssets()
    }
    
    func embeddingResult(for text: String, language: NLLanguage) throws -> NLContextualEmbeddingResult {
        return try embedding.embeddingResult(for: text, language: language)
    }
}

// MARK: - Embedding Errors
enum EmbeddingError: Error, LocalizedError {
    case generationFailed(String)
    case unsupportedLanguage(String)
    case apiError(String)
    case invalidDimensions
    case cacheError(String)
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let message):
            return "Embedding generation failed: \(message)"
        case .unsupportedLanguage(let language):
            return "Unsupported language: \(language)"
        case .apiError(let message):
            return "API embedding error: \(message)"
        case .invalidDimensions:
            return "Invalid embedding dimensions"
        case .cacheError(let message):
            return "Embedding cache error: \(message)"
        }
    }
}

// MARK: - Embedding Strategy Enum
enum EmbeddingStrategy {
    case onDevice
    case api
    case hybrid
}

// MARK: - Main Embedding Service
@MainActor
class EmbeddingService: EmbeddingServiceProtocol {
    
    // MARK: - Properties
    private let strategy: EmbeddingStrategy
    private let context: NSManagedObjectContext
    private let apiService: APIEmbeddingServiceProtocol?
    private var embeddingCache: [String: [Float]] = [:]
    
    // Dependency injection for testing
    private let vietnameseEmbedding: NLContextualEmbeddingProtocol
    private let englishEmbedding: NLContextualEmbeddingProtocol
    
    // MARK: - Initialization with Dependency Injection
    init(strategy: EmbeddingStrategy = .hybrid, 
         context: NSManagedObjectContext,
         apiKey: String? = nil,
         vietnameseEmbedding: NLContextualEmbeddingProtocol? = nil,
         englishEmbedding: NLContextualEmbeddingProtocol? = nil,
         apiService: APIEmbeddingServiceProtocol? = nil) {
        self.strategy = strategy
        self.context = context
        
        // Use injected dependencies or create real ones
        self.vietnameseEmbedding = vietnameseEmbedding ?? NLContextualEmbeddingWrapper(language: .vietnamese)
        self.englishEmbedding = englishEmbedding ?? NLContextualEmbeddingWrapper(language: .english)
        
        if let injectedAPIService = apiService {
            self.apiService = injectedAPIService
        } else if strategy != .onDevice, let apiKey = apiKey {
            self.apiService = APIEmbeddingService(apiKey: apiKey)
        } else {
            self.apiService = nil
        }
    }
    
    // MARK: - Main Embedding Generation
    func generateEmbedding(for text: String, language: String? = nil) async throws -> [Float] {
        // Check cache first
        if let cachedEmbedding = getCachedEmbedding(for: text) {
            return cachedEmbedding
        }
        
        let detectedLanguage = language ?? detectLanguage(for: text) ?? "en"
        
        switch strategy {
        case .onDevice:
            return try await generateOnDeviceEmbedding(text: text, language: detectedLanguage)
            
        case .api:
            guard let apiService = apiService else {
                throw EmbeddingError.apiError("API service not available")
            }
            return try await apiService.generateEmbedding(for: text, language: detectedLanguage)
            
        case .hybrid:
            // Try on-device first, fallback to API
            do {
                let embedding = try await generateOnDeviceEmbedding(text: text, language: detectedLanguage)
                cacheEmbedding(text: text, embedding: embedding, language: detectedLanguage)
                return embedding
            } catch {
                // Fallback to API
                guard let apiService = apiService else {
                    throw EmbeddingError.generationFailed("Both on-device and API failed: \(error.localizedDescription)")
                }
                let embedding = try await apiService.generateEmbedding(for: text, language: detectedLanguage)
                cacheEmbedding(text: text, embedding: embedding, language: detectedLanguage)
                return embedding
            }
        }
    }
    
    // MARK: - On-Device Embedding Generation
    private func generateOnDeviceEmbedding(text: String, language: String) async throws -> [Float] {
        let nlLanguage: NLLanguage
        let embedding: NLContextualEmbeddingProtocol
        
        switch language.lowercased() {
        case "vi", "vi-vn", "vietnamese":
            nlLanguage = .vietnamese
            embedding = vietnameseEmbedding
        case "en", "en-us", "english":
            nlLanguage = .english
            embedding = englishEmbedding
        default:
            // Default to English for unknown languages
            nlLanguage = .english
            embedding = englishEmbedding
        }
        
        let contextualEmbedding = embedding
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // Check if assets are available, request if needed
                    if !contextualEmbedding.hasAvailableAssets {
                        let assetsResult = try await contextualEmbedding.requestAssets()
                        guard assetsResult == .available else {
                            continuation.resume(throwing: EmbeddingError.generationFailed("Assets not available"))
                            return
                        }
                    }
                    
                    let embeddingResult = try contextualEmbedding.embeddingResult(for: text, language: nlLanguage)
                    let aggregatedEmbedding = meanPooling(embeddingResult: embeddingResult, text: text)
                    continuation.resume(returning: aggregatedEmbedding)
                } catch {
                    continuation.resume(throwing: EmbeddingError.generationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Mean Pooling for Token Aggregation
    private func meanPooling(embeddingResult: NLContextualEmbeddingResult, text: String) -> [Float] {
        // NLContextualEmbeddingResult provides token vectors via enumerateTokenVectors
        var allVectors: [[Double]] = []
        
        // Use enumerateTokenVectors to get all token vectors
        embeddingResult.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { tokenVector, _ in
            allVectors.append(tokenVector)
            return true
        }
        
        guard !allVectors.isEmpty else { return [] }
        
        // Get embedding dimension from first vector
        let embeddingDimension = allVectors.first?.count ?? 512
        var aggregated = Array(repeating: Double(0.0), count: embeddingDimension)
        
        // Sum all vectors
        for tokenVector in allVectors {
            for (index, value) in tokenVector.enumerated() {
                if index < embeddingDimension {
                    aggregated[index] += value
                }
            }
        }
        
        // Average the vectors and convert to Float
        let tokenCount = allVectors.count
        return aggregated.map { Float($0 / Double(tokenCount)) }
    }
    
    // MARK: - Language Detection
    nonisolated func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            switch dominantLanguage {
            case .vietnamese:
                return "vi"
            case .english:
                return "en"
            default:
                return dominantLanguage.rawValue
            }
        }
        
        return nil
    }
    
    // MARK: - Caching Methods
    nonisolated func cacheEmbedding(text: String, embedding: [Float], language: String?) {
        let cacheKey = generateCacheKey(text: text, language: language)
        Task { @MainActor in
            embeddingCache[cacheKey] = embedding
        }
    }
    
    nonisolated func getCachedEmbedding(for text: String) -> [Float]? {
        let cacheKey = generateCacheKey(text: text, language: nil)
        // Since we can't access @MainActor property from nonisolated context synchronously,
        // we'll return nil and handle caching differently
        return nil
    }
    
    nonisolated private func generateCacheKey(text: String, language: String?) -> String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let language = language {
            return "\(language):\(cleanText.hashValue)"
        }
        return "\(cleanText.hashValue)"
    }
    
    // MARK: - Batch Processing
    func generateEmbeddings(for texts: [String], language: String? = nil) async throws -> [[Float]] {
        var embeddings: [[Float]] = []
        
        for text in texts {
            let embedding = try await generateEmbedding(for: text, language: language)
            embeddings.append(embedding)
        }
        
        return embeddings
    }
    
    // MARK: - Performance Benchmarking
    func benchmarkEmbeddingPerformance(text: String, iterations: Int = 5) async -> (averageTime: Double, embeddings: [[Float]]) {
        var times: [Double] = []
        var embeddings: [[Float]] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let embedding = try await generateEmbedding(for: text)
                embeddings.append(embedding)
            } catch {
                print("Benchmark iteration failed: \(error)")
                continue
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(timeElapsed)
        }
        
        let averageTime = times.isEmpty ? 0.0 : times.reduce(0, +) / Double(times.count)
        return (averageTime, embeddings)
    }
}

// MARK: - API Embedding Service
class APIEmbeddingService: APIEmbeddingServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/embeddings" // Default to OpenAI, can be configured
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateEmbedding(for text: String, language: String) async throws -> [Float] {
        let request = EmbeddingRequest(
            input: text,
            model: selectModel(for: language)
        )
        
        let requestData = try JSONEncoder().encode(request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.apiError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw EmbeddingError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let embeddingResponse = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        return embeddingResponse.data.first?.embedding ?? []
    }
    
    private func selectModel(for language: String) -> String {
        switch language.lowercased() {
        case "vi", "vietnamese":
            return "text-embedding-3-small" // Good multilingual support
        default:
            return "text-embedding-3-small"
        }
    }
}

// MARK: - API Request/Response Models
struct EmbeddingRequest: Codable {
    let input: String
    let model: String
}

struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
}

struct EmbeddingData: Codable {
    let embedding: [Float]
} 