import Foundation
import Combine

// MARK: - Document Context Manager Service
class DocumentContextManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedDocuments: [ProcessedDocument] = []
    @Published var currentChatMode: ChatMode = .rag
    @Published var contextSizeResult: ContextSizeResult?
    @Published var recommendedMode: ChatMode = .rag
    @Published var canUseFullContext: Bool = true
    @Published var warningMessage: String?
    
    // MARK: - Private Properties
    
    private var currentModelName: String = "gpt-4"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Auto-update context analysis when documents or model changes
        setupAutoAnalysis()
    }
    
    // MARK: - Public Methods
    
    /// Update current LLM model for threshold calculations
    func updateCurrentModel(_ modelName: String) {
        currentModelName = modelName
        analyzeCurrentContext()
    }
    
    /// Add document to context and update analysis
    func addDocument(_ document: ProcessedDocument) {
        if !selectedDocuments.contains(where: { $0.id == document.id }) {
            selectedDocuments.append(document)
            analyzeCurrentContext()
        }
    }
    
    /// Remove document from context and update analysis
    func removeDocument(_ document: ProcessedDocument) {
        selectedDocuments.removeAll { $0.id == document.id }
        analyzeCurrentContext()
    }
    
    /// Remove document by ID
    func removeDocument(withId documentId: String) {
        selectedDocuments.removeAll { $0.id == documentId }
        analyzeCurrentContext()
    }
    
    /// Clear all documents from context
    func clearAllDocuments() {
        selectedDocuments.removeAll()
        analyzeCurrentContext()
    }
    
    /// Set multiple documents at once (for batch selection)
    func setDocuments(_ documents: [ProcessedDocument]) {
        selectedDocuments = documents
        analyzeCurrentContext()
    }
    
    /// Toggle document selection
    func toggleDocument(_ document: ProcessedDocument) {
        if selectedDocuments.contains(where: { $0.id == document.id }) {
            removeDocument(document)
        } else {
            addDocument(document)
        }
    }
    
    /// Update chat mode and validate compatibility
    func updateChatMode(_ mode: ChatMode) {
        currentChatMode = mode
        
        // If Full Context is selected but not available, show warning
        if mode == .fullContext && !canUseFullContext {
            warningMessage = "Selected documents are too large for Full Context mode. Consider removing some documents or using RAG mode."
        } else {
            warningMessage = ContextSizeCalculator.getWarningMessage(
                for: selectedDocuments, 
                modelName: currentModelName
            )
        }
    }
    
    /// Force re-analysis of current context
    func analyzeCurrentContext() {
        guard !selectedDocuments.isEmpty else {
            resetAnalysis()
            return
        }
        
        // Calculate context size
        contextSizeResult = ContextSizeCalculator.calculateSize(
            for: selectedDocuments,
            modelName: currentModelName
        )
        
        // Update recommendations
        recommendedMode = ContextSizeCalculator.getRecommendedChatMode(
            for: selectedDocuments,
            modelName: currentModelName
        )
        
        // Update availability
        canUseFullContext = ContextSizeCalculator.canUseFullContext(
            for: selectedDocuments,
            modelName: currentModelName
        )
        
        // Update warning message
        warningMessage = ContextSizeCalculator.getWarningMessage(
            for: selectedDocuments,
            modelName: currentModelName
        )
        
        // Auto-adjust mode if current mode is not available
        if currentChatMode == .fullContext && !canUseFullContext {
            currentChatMode = .rag
        }
    }
    
    // MARK: - Context Information Methods
    
    /// Get summary string for UI display
    func getContextSummary() -> String {
        guard !selectedDocuments.isEmpty else {
            return "No documents selected"
        }
        
        let documentCount = selectedDocuments.count
        let totalSize = contextSizeResult?.formattedSize ?? "Unknown"
        let status = contextSizeResult?.status.displayName ?? "Calculating..."
        
        if documentCount == 1 {
            return "1 document • \(totalSize) • \(status)"
        } else {
            return "\(documentCount) documents • \(totalSize) • \(status)"
        }
    }
    
    /// Get detailed context information
    func getDetailedContextInfo() -> DocumentContextInfo {
        return DocumentContextInfo(
            documentCount: selectedDocuments.count,
            totalCharacters: contextSizeResult?.totalCharacters ?? 0,
            estimatedTokens: contextSizeResult?.estimatedTokens ?? 0,
            contextStatus: contextSizeResult?.status ?? .optimal,
            recommendedMode: recommendedMode,
            canUseFullContext: canUseFullContext,
            warningMessage: warningMessage,
            modelName: currentModelName,
            threshold: contextSizeResult?.threshold ?? ContextThresholds.defaultLimit
        )
    }
    
    /// Check if specific document would exceed limits if added
    func wouldExceedLimits(withAdditionalDocument document: ProcessedDocument) -> Bool {
        let testDocuments = selectedDocuments + [document]
        let result = ContextSizeCalculator.calculateSize(
            for: testDocuments,
            modelName: currentModelName
        )
        return !result.canUseFullContext
    }
    
    /// Get processing time estimate for current context
    func getProcessingTimeEstimate() -> TimeInterval {
        guard !selectedDocuments.isEmpty else { return 0 }
        
        return ContextSizeCalculator.getProcessingTimeEstimate(
            for: selectedDocuments,
            mode: currentChatMode
        )
    }
    
    /// Get reading time estimate for current context
    func getReadingTimeEstimate() -> TimeInterval {
        guard !selectedDocuments.isEmpty else { return 0 }
        
        return ContextSizeCalculator.estimateReadingTime(for: selectedDocuments)
    }
    
    // MARK: - Batch Operations
    
    /// Add multiple documents with size validation
    func addDocuments(_ documents: [ProcessedDocument], maxSizeLimit: Int? = nil) -> DocumentAdditionResult {
        var successfulDocuments: [ProcessedDocument] = []
        var failedDocuments: [(ProcessedDocument, String)] = []
        
        for document in documents {
            let testDocuments = selectedDocuments + successfulDocuments + [document]
            let result = ContextSizeCalculator.calculateSize(
                for: testDocuments,
                modelName: currentModelName
            )
            
            // Check against custom limit or model limit
            let effectiveLimit = maxSizeLimit ?? result.threshold
            
            if result.totalCharacters <= effectiveLimit {
                successfulDocuments.append(document)
            } else {
                let reason = "Adding this document would exceed the \(ContextThresholds.getModelDisplayName(for: currentModelName)) limit"
                failedDocuments.append((document, reason))
            }
        }
        
        // Add successful documents
        selectedDocuments.append(contentsOf: successfulDocuments)
        analyzeCurrentContext()
        
        return DocumentAdditionResult(
            successfulDocuments: successfulDocuments,
            failedDocuments: failedDocuments
        )
    }
    
    /// Remove documents by type
    func removeDocuments(ofType documentType: DocumentType) {
        selectedDocuments.removeAll { $0.type == documentType }
        analyzeCurrentContext()
    }
    
    /// Keep only documents that fit within a specific size limit
    func optimizeDocumentsForSize(targetLimit: Int) {
        var optimizedDocuments: [ProcessedDocument] = []
        var currentSize = 0
        
        // Sort by document size (smallest first for better fit)
        let sortedDocuments = selectedDocuments.sorted { $0.content.count < $1.content.count }
        
        for document in sortedDocuments {
            let documentSize = document.content.count
            if currentSize + documentSize <= targetLimit {
                optimizedDocuments.append(document)
                currentSize += documentSize
            }
        }
        
        selectedDocuments = optimizedDocuments
        analyzeCurrentContext()
    }
    
    // MARK: - Private Methods
    
    private func setupAutoAnalysis() {
        // Re-analyze when documents change
        $selectedDocuments
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.analyzeCurrentContext()
            }
            .store(in: &cancellables)
    }
    
    private func resetAnalysis() {
        contextSizeResult = nil
        recommendedMode = .rag
        canUseFullContext = true
        warningMessage = nil
    }
}

// MARK: - Supporting Types

struct DocumentContextInfo {
    let documentCount: Int
    let totalCharacters: Int
    let estimatedTokens: Int
    let contextStatus: ContextSizeStatus
    let recommendedMode: ChatMode
    let canUseFullContext: Bool
    let warningMessage: String?
    let modelName: String
    let threshold: Int
    
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
    
    var percentageUsed: Double {
        return Double(totalCharacters) / Double(threshold)
    }
    
    var percentageString: String {
        return String(format: "%.0f%%", percentageUsed * 100)
    }
}

struct DocumentAdditionResult {
    let successfulDocuments: [ProcessedDocument]
    let failedDocuments: [(ProcessedDocument, String)]
    
    var hasFailures: Bool {
        return !failedDocuments.isEmpty
    }
    
    var successCount: Int {
        return successfulDocuments.count
    }
    
    var failureCount: Int {
        return failedDocuments.count
    }
}

// MARK: - Extensions

extension DocumentContextManager {
    
    /// Check if context manager has any documents
    var hasDocuments: Bool {
        return !selectedDocuments.isEmpty
    }
    
    /// Get document count
    var documentCount: Int {
        return selectedDocuments.count
    }
    
    /// Check if context is optimal for full context mode
    var isOptimalForFullContext: Bool {
        return contextSizeResult?.status == .optimal
    }
    
    /// Check if context is in warning state
    var hasWarning: Bool {
        return warningMessage != nil
    }
    
    /// Get current context utilization percentage
    var contextUtilization: Double {
        return contextSizeResult?.percentage ?? 0.0
    }
}