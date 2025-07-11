import Foundation
import Combine

/// ConversationSummaryMemory implementation similar to LangChain's ConversationSummaryMemory
/// Provides intelligent conversation compression while preserving key context
@MainActor
class ConversationSummaryMemoryService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCompressing: Bool = false
    @Published var lastCompressionTime: Date?
    @Published var compressionProgress: Float = 0.0
    
    // MARK: - Private Properties
    private let apiService: LLMAPIService
    private weak var memoryService: MemoryService?
    private var compressionCache: [UUID: ConversationSummary] = [:]
    private var compressionThreshold: Int = 4000 // Default threshold
    
    // Compression configuration
    private let config = CompressionConfiguration.default
    
    // MARK: - Initialization
    init(apiService: LLMAPIService) {
        self.apiService = apiService
        self.memoryService = nil
    }
    
    /// Set the memory service reference after initialization to avoid circular dependency
    func setMemoryService(_ memoryService: MemoryService) {
        self.memoryService = memoryService
    }
    
    // MARK: - Public Methods
    
    /// Compress conversation memory using AI summarization
    func compressMemory(for conversationId: UUID, targetTokens: Int) async throws -> Bool {
        isCompressing = true
        compressionProgress = 0.0
        
        defer {
            isCompressing = false
            compressionProgress = 1.0
        }
        
        // Get current memory
        guard let memoryService = memoryService else {
            throw ConversationSummaryError.invalidConfiguration
        }
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        guard memory.estimatedTokens > targetTokens else {
            print("🧠 Memory already within target token limit")
            return false
        }
        
        compressionProgress = 0.2
        
        // Check if we need to create a new summary or update existing
        let existingSummary = compressionCache[conversationId]
        
        // Determine messages to summarize
        let messagesToSummarize = getMessagesToSummarize(memory: memory, existingSummary: existingSummary)
        
        guard !messagesToSummarize.isEmpty else {
            print("🧠 No new messages to summarize")
            return false
        }
        
        compressionProgress = 0.4
        
        // Generate summary using AI
        let newSummaryText = try await generateSummary(messages: messagesToSummarize)
        
        compressionProgress = 0.7
        
        // Create or update conversation summary
        let summary = ConversationSummary(
            conversationId: conversationId,
            summaryText: newSummaryText,
            originalMessageCount: messagesToSummarize.count,
            compressedTokens: estimateTokens(text: newSummaryText),
            createdAt: Date(),
            lastMessageTimestamp: messagesToSummarize.last?.timestamp ?? Date()
        )
        
        // Combine with existing summary if present
        if let existing = existingSummary {
            let combinedSummary = combineSummaries(existing: existing, new: summary)
            compressionCache[conversationId] = combinedSummary
        } else {
            compressionCache[conversationId] = summary
        }
        
        compressionProgress = 0.9
        
        // Update memory with compressed version
        try await applyCompressionToMemory(conversationId: conversationId, summary: summary, targetTokens: targetTokens)
        
        lastCompressionTime = Date()
        
        print("✅ Successfully compressed memory for conversation \(conversationId)")
        return true
    }
    
    /// Get conversation summary
    func getMemorySummary(for conversationId: UUID) async -> String? {
        return compressionCache[conversationId]?.summaryText
    }
    
    /// Set compression threshold
    func setCompressionThreshold(_ threshold: Int) {
        compressionThreshold = threshold
        print("🧠 Compression threshold set to \(threshold) tokens")
    }
    
    /// Check if conversation needs compression
    func needsCompression(for conversationId: UUID) async -> Bool {
        guard let memoryService = memoryService else { return false }
        let memory = await memoryService.getMemoryForConversation(conversationId)
        return memory.estimatedTokens > compressionThreshold
    }
    
    /// Get compression statistics
    func getCompressionStats(for conversationId: UUID) async -> CompressionStats? {
        guard let summary = compressionCache[conversationId],
              let memoryService = memoryService else { return nil }
        
        let memory = await memoryService.getMemoryForConversation(conversationId)
        let originalTokens = memory.estimatedTokens + summary.compressedTokens
        
        return CompressionStats(
            originalTokens: originalTokens,
            compressedTokens: summary.compressedTokens,
            compressionRatio: Float(summary.compressedTokens) / Float(originalTokens),
            messageCount: summary.originalMessageCount,
            lastCompressed: summary.createdAt
        )
    }
    
    // MARK: - Private Methods
    
    private func getMessagesToSummarize(memory: ConversationMemory, existingSummary: ConversationSummary?) -> [Message] {
        if let summary = existingSummary {
            // Only summarize messages newer than last summary
            return memory.messages.filter { $0.timestamp > summary.lastMessageTimestamp }
        } else {
            // Summarize older messages, keep recent ones
            let keepRecentCount = config.keepRecentMessageCount
            let totalCount = memory.messages.count
            
            if totalCount <= keepRecentCount {
                return []
            }
            
            let summarizeCount = totalCount - keepRecentCount
            return Array(memory.messages.prefix(summarizeCount))
        }
    }
    
    private func generateSummary(messages: [Message]) async throws -> String {
        let prompt = buildSummarizationPrompt(messages: messages)
        
        // Use the configured model for summarization
        let model = config.summarizationModel
        
        // Create a simple message for the API
        let summaryRequest = ChatMessage(role: .user, content: prompt)
        
        // Get summarization response
        var summaryText = ""
        let stream = try await apiService.sendMessage(prompt, model: model, conversation: nil)
        
        for try await chunk in stream {
            // Handle error chunks
            if chunk.hasPrefix("__ERROR__") || chunk.hasPrefix("__NETWORK_ERROR__") || chunk.hasPrefix("__HTTP_ERROR__") {
                throw ConversationSummaryError.summarizationFailed("API Error: \(chunk)")
            }
            
            summaryText += chunk
        }
        
        guard !summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConversationSummaryError.summarizationFailed("Empty summary generated")
        }
        
        return summaryText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func buildSummarizationPrompt(messages: [Message]) -> String {
        let conversationText = messages.map { message in
            let role = message.role == .user ? "Human" : "Assistant"
            return "\(role): \(message.content)"
        }.joined(separator: "\n\n")
        
        return """
        Please provide a concise but comprehensive summary of the following conversation. 
        Preserve key information, important decisions, and context that would be valuable for continuing the conversation.
        Focus on the main topics discussed and any specific details or preferences mentioned.
        
        Conversation:
        \(conversationText)
        
        Summary:
        """
    }
    
    private func combineSummaries(existing: ConversationSummary, new: ConversationSummary) -> ConversationSummary {
        let combinedText = """
        Previous conversation summary:
        \(existing.summaryText)
        
        Recent conversation summary:
        \(new.summaryText)
        """
        
        return ConversationSummary(
            conversationId: existing.conversationId,
            summaryText: combinedText,
            originalMessageCount: existing.originalMessageCount + new.originalMessageCount,
            compressedTokens: estimateTokens(text: combinedText),
            createdAt: new.createdAt,
            lastMessageTimestamp: new.lastMessageTimestamp
        )
    }
    
    private func applyCompressionToMemory(conversationId: UUID, summary: ConversationSummary, targetTokens: Int) async throws {
        guard let memoryService = memoryService else {
            throw ConversationSummaryError.invalidConfiguration
        }
        let memory = await memoryService.getMemoryForConversation(conversationId)
        
        // Keep recent messages and replace older ones with summary
        let keepRecentCount = config.keepRecentMessageCount
        let recentMessages = Array(memory.messages.suffix(keepRecentCount))
        
        // Create a system message with the summary
        let summaryMessage = Message(
            content: "Conversation Summary: \(summary.summaryText)",
            role: .system,
            conversationId: conversationId
        )
        
        // Create new message array with summary + recent messages
        let compressedMessages = [summaryMessage] + recentMessages
        
        // Update memory with compressed messages
        memory.messages = compressedMessages
        memory.lastUpdated = Date()
        
        print("🧠 Applied compression: \(memory.messages.count) messages (including summary)")
    }
    
    private func estimateTokens(text: String) -> Int {
        // Simple token estimation: ~4 characters per token
        return text.count / 4
    }
}

// MARK: - Supporting Types

struct ConversationSummary {
    let conversationId: UUID
    let summaryText: String
    let originalMessageCount: Int
    let compressedTokens: Int
    let createdAt: Date
    let lastMessageTimestamp: Date
}

struct CompressionStats {
    let originalTokens: Int
    let compressedTokens: Int
    let compressionRatio: Float
    let messageCount: Int
    let lastCompressed: Date
    
    var compressionPercentage: Float {
        return (1.0 - compressionRatio) * 100
    }
}

struct CompressionConfiguration {
    let keepRecentMessageCount: Int
    let summarizationModel: LLMModel
    let maxSummaryTokens: Int
    let compressionThreshold: Int
    
    static let `default` = CompressionConfiguration(
        keepRecentMessageCount: 6, // Keep last 6 messages uncompressed
        summarizationModel: LLMModel(
            id: "gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            provider: .openai,
            contextLength: 16385,
            pricing: ModelPricing(inputTokens: 0.0015, outputTokens: 0.002, imageInputs: nil),
            description: "Fast model for summarization",
            capabilities: .basic
        ),
        maxSummaryTokens: 500,
        compressionThreshold: 4000
    )
}

enum ConversationSummaryError: Error, LocalizedError {
    case summarizationFailed(String)
    case invalidConfiguration
    case compressionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .summarizationFailed(let message):
            return "Summarization failed: \(message)"
        case .invalidConfiguration:
            return "Invalid compression configuration"
        case .compressionFailed(let message):
            return "Compression failed: \(message)"
        }
    }
}