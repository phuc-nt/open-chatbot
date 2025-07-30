import Foundation
import NaturalLanguage

// MARK: - Context Size Status
enum ContextSizeStatus {
    case optimal    // < 50% threshold - Green indicator
    case large      // 50-80% threshold - Yellow indicator  
    case excessive  // > 80% threshold - Red indicator
    
    var displayName: String {
        switch self {
        case .optimal:
            return "Perfect for Full Context"
        case .large:
            return "Consider RAG for speed"
        case .excessive:
            return "RAG Mode recommended"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .optimal:
            return "checkmark.circle.fill"
        case .large:
            return "exclamationmark.triangle.fill"
        case .excessive:
            return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .optimal:
            return "green"
        case .large:
            return "orange"
        case .excessive:
            return "red"
        }
    }
}

// MARK: - Context Thresholds Configuration
struct ContextThresholds {
    // Model-specific character limits (conservative estimates)
    static let gpt4: Int = 120_000        // ~30k tokens
    static let gpt4Turbo: Int = 120_000   // ~30k tokens
    static let claude3: Int = 180_000     // ~45k tokens
    static let claude3Haiku: Int = 180_000 // ~45k tokens
    static let llama: Int = 60_000        // ~15k tokens
    static let gemini: Int = 80_000       // ~20k tokens
    static let defaultLimit: Int = 80_000 // Conservative default
    
    // Status calculation thresholds
    static let optimalThreshold: Double = 0.5   // 50%
    static let largeThreshold: Double = 0.8     // 80%
    
    // Token-to-character ratio estimates
    static let averageTokenRatio: Double = 4.0  // ~4 characters per token
    
    // Get threshold for specific model
    static func getThreshold(for modelName: String) -> Int {
        let lowercaseModel = modelName.lowercased()
        
        if lowercaseModel.contains("gpt-4") {
            return gpt4
        } else if lowercaseModel.contains("claude-3") {
            return claude3
        } else if lowercaseModel.contains("llama") {
            return llama
        } else if lowercaseModel.contains("gemini") {
            return gemini
        } else {
            return defaultLimit
        }
    }
    
    // Get model display name for threshold
    static func getModelDisplayName(for modelName: String) -> String {
        let lowercaseModel = modelName.lowercased()
        
        if lowercaseModel.contains("gpt-4") {
            return "GPT-4 (120k chars)"
        } else if lowercaseModel.contains("claude-3") {
            return "Claude 3 (180k chars)"
        } else if lowercaseModel.contains("llama") {
            return "Llama (60k chars)"
        } else if lowercaseModel.contains("gemini") {
            return "Gemini (80k chars)"
        } else {
            return "Default (80k chars)"
        }
    }
}

// MARK: - Context Size Result
struct ContextSizeResult {
    let totalCharacters: Int
    let estimatedTokens: Int
    let threshold: Int
    let status: ContextSizeStatus
    let percentage: Double
    let canUseFullContext: Bool
    let modelName: String
    
    var formattedSize: String {
        if totalCharacters < 1000 {
            return "\(totalCharacters) chars"
        } else if totalCharacters < 1_000_000 {
            return String(format: "%.1fk chars", Double(totalCharacters) / 1000.0)
        } else {
            return String(format: "%.1fM chars", Double(totalCharacters) / 1_000_000.0)
        }
    }
    
    var formattedTokens: String {
        if estimatedTokens < 1000 {
            return "\(estimatedTokens) tokens"
        } else {
            return String(format: "%.1fk tokens", Double(estimatedTokens) / 1000.0)
        }
    }
    
    var percentageString: String {
        return String(format: "%.0f%%", percentage * 100)
    }
}

// MARK: - Context Size Calculator Service
class ContextSizeCalculator {
    
    // MARK: - Public Methods
    
    /// Calculate context size for a single document
    static func calculateSize(for document: ProcessedDocument, modelName: String) -> ContextSizeResult {
        let content = document.content
        return calculateSize(for: content, modelName: modelName)
    }
    
    /// Calculate context size for multiple documents
    static func calculateSize(for documents: [ProcessedDocument], modelName: String) -> ContextSizeResult {
        let combinedContent = documents.map { $0.content }.joined(separator: "\n\n")
        return calculateSize(for: combinedContent, modelName: modelName)
    }
    
    /// Calculate context size for raw text content
    static func calculateSize(for content: String, modelName: String) -> ContextSizeResult {
        let characterCount = countCharacters(in: content)
        let estimatedTokens = estimateTokenCount(from: characterCount)
        let threshold = ContextThresholds.getThreshold(for: modelName)
        let percentage = Double(characterCount) / Double(threshold)
        let status = determineStatus(percentage: percentage)
        let canUseFullContext = percentage <= ContextThresholds.largeThreshold
        
        return ContextSizeResult(
            totalCharacters: characterCount,
            estimatedTokens: estimatedTokens,
            threshold: threshold,
            status: status,
            percentage: percentage,
            canUseFullContext: canUseFullContext,
            modelName: modelName
        )
    }
    
    /// Get recommended chat mode based on context size
    static func getRecommendedChatMode(for documents: [ProcessedDocument], modelName: String) -> ChatMode {
        let result = calculateSize(for: documents, modelName: modelName)
        
        switch result.status {
        case .optimal:
            return .fullContext
        case .large:
            return .rag  // Recommend RAG for better performance
        case .excessive:
            return .rag  // Force RAG for very large documents
        }
    }
    
    /// Check if full context mode is available for documents
    static func canUseFullContext(for documents: [ProcessedDocument], modelName: String) -> Bool {
        let result = calculateSize(for: documents, modelName: modelName)
        return result.canUseFullContext
    }
    
    /// Get context size warning message
    static func getWarningMessage(for documents: [ProcessedDocument], modelName: String) -> String? {
        let result = calculateSize(for: documents, modelName: modelName)
        
        switch result.status {
        case .optimal:
            return nil
        case .large:
            return "Large document detected. Full Context mode may be slower. Consider RAG mode for better performance."
        case .excessive:
            return "Document too large for Full Context mode. RAG mode will be used automatically."
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Count meaningful characters (excluding excessive whitespace)
    private static func countCharacters(in text: String) -> Int {
        // Remove excessive whitespace while preserving document structure
        let normalizedText = text
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalizedText.count
    }
    
    /// Estimate token count from character count
    private static func estimateTokenCount(from characterCount: Int) -> Int {
        return Int(Double(characterCount) / ContextThresholds.averageTokenRatio)
    }
    
    /// Determine status based on percentage of threshold
    private static func determineStatus(percentage: Double) -> ContextSizeStatus {
        if percentage <= ContextThresholds.optimalThreshold {
            return .optimal
        } else if percentage <= ContextThresholds.largeThreshold {
            return .large
        } else {
            return .excessive
        }
    }
    
    /// Calculate reading time estimate
    static func estimateReadingTime(for documents: [ProcessedDocument]) -> TimeInterval {
        let totalCharacters = documents.reduce(0) { $0 + $1.content.count }
        let wordsPerMinute = 200.0  // Average reading speed
        let charactersPerWord = 5.0
        let minutes = Double(totalCharacters) / charactersPerWord / wordsPerMinute
        return minutes * 60  // Return in seconds
    }
    
    /// Get processing time estimate for different modes
    static func getProcessingTimeEstimate(for documents: [ProcessedDocument], mode: ChatMode) -> TimeInterval {
        let baseTime: TimeInterval = 2.0  // Base processing time in seconds
        
        switch mode {
        case .rag:
            return baseTime + 0.5  // RAG mode is slightly faster
        case .fullContext:
            let result = calculateSize(for: documents, modelName: "default")
            let complexityMultiplier = min(result.percentage * 2, 3.0)  // Up to 3x slower for large docs
            return baseTime * complexityMultiplier
        }
    }
}

// MARK: - Chat Mode Enum
enum ChatMode: String, CaseIterable, Identifiable {
    case rag = "rag"
    case fullContext = "full_context"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rag:
            return "RAG Mode"
        case .fullContext:
            return "Full Context"
        }
    }
    
    var description: String {
        switch self {
        case .rag:
            return "Search relevant information"
        case .fullContext:
            return "Include complete document"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .rag:
            return "magnifyingglass.circle"
        case .fullContext:
            return "doc.text.fill"
        }
    }
    
    var isDefault: Bool {
        return self == .rag
    }
}

// MARK: - Extensions for Utility

extension Array where Element == ProcessedDocument {
    /// Get total character count for document array
    var totalCharacterCount: Int {
        return self.reduce(0) { $0 + $1.content.count }
    }
    
    /// Get formatted total size
    var formattedTotalSize: String {
        let total = totalCharacterCount
        if total < 1000 {
            return "\(total) chars"
        } else if total < 1_000_000 {
            return String(format: "%.1fk chars", Double(total) / 1000.0)
        } else {
            return String(format: "%.1fM chars", Double(total) / 1_000_000.0)
        }
    }
}