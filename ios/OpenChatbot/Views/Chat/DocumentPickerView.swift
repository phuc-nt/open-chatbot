import SwiftUI
import CoreData

// Document Picker for RAG Context Selection with Enhanced Context Management
struct DocumentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var chatViewModel: ChatViewModel
    
    // Document Context Manager for size calculation and mode selection
    @StateObject private var documentContextManager = DocumentContextManager()
    
    // Real uploaded documents from Core Data instead of simulated
    @State private var availableDocuments: [ProcessedDocument] = []
    @State private var isLoading = true
    
    // Chat mode selection state
    @State private var selectedChatMode: ChatMode = .rag
    
    // Batch selection state
    @State private var isSelectingMultiple = false
    @State private var showModeSelector = false
    
    // Data service to fetch real documents
    private let dataService = DataService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced header with context info and mode selection
                enhancedContextHeader
                
                // Chat Mode Selector (if documents are selected)
                if documentContextManager.hasDocuments {
                    ChatModeSelector(
                        documentContextManager: documentContextManager,
                        selectedMode: $selectedChatMode
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Document list or loading/empty state
                if isLoading {
                    loadingState
                } else if availableDocuments.isEmpty {
                    emptyState
                } else {
                    enhancedDocumentList
                }
            }
            .navigationTitle("Document Selection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if !availableDocuments.isEmpty {
                            Button(isSelectingMultiple ? "Done" : "Select All") {
                                if isSelectingMultiple {
                                    isSelectingMultiple = false
                                } else {
                                    selectAllOptimalDocuments()
                                }
                            }
                            .font(.system(size: 14))
                        }
                        
                        Button("Done") {
                            applySelectionToChatViewModel()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .task {
                await loadRealDocuments()
            }
            .onChange(of: selectedChatMode) { oldValue, newValue in
                updateChatViewModelMode()
            }
        }
    }
    
    // MARK: - Enhanced Context Header
    private var enhancedContextHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Document Context")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(getContextSummaryText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Context size indicator
                if documentContextManager.hasDocuments {
                    contextSizeIndicator
                }
            }
            .padding(.horizontal)
            
            // Context status bar
            if documentContextManager.hasDocuments {
                contextStatusBar
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    private var contextSizeIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(contextStatusColor)
                    .frame(width: 8, height: 8)
                
                Text(contextStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(contextStatusColor)
            }
            
            if let result = documentContextManager.contextSizeResult {
                Text(result.formattedSize)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var contextStatusBar: some View {
        VStack(spacing: 6) {
            // Progress bar showing context utilization
            HStack {
                Text("Context Usage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.0f%%", documentContextManager.contextUtilization * 100))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(contextStatusColor)
                        .frame(width: geometry.size.width * documentContextManager.contextUtilization, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: documentContextManager.contextUtilization)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Enhanced Document List
    private var enhancedDocumentList: some View {
        List {
            Section(header: enhancedSectionHeader) {
                ForEach(availableDocuments, id: \.id) { document in
                    EnhancedDocumentRow(
                        document: document,
                        isSelected: documentContextManager.selectedDocuments.contains(where: { $0.id == document.id }),
                        contextSizeResult: getDocumentContextSize(document),
                        wouldExceedLimits: documentContextManager.wouldExceedLimits(withAdditionalDocument: document),
                        onToggle: { isSelected in
                            toggleDocumentSelection(document, isSelected: isSelected)
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var enhancedSectionHeader: some View {
        HStack {
            Text("Available Documents")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(availableDocuments.count) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if documentContextManager.hasDocuments {
                    Text("\(documentContextManager.documentCount) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .textCase(nil)
    }
    
    // MARK: - Loading and Empty States
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading documents...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No Documents Available")
                .font(.headline)
            
            Text("Upload documents in the Documents tab to use them for context")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties
    private var contextStatusColor: Color {
        guard let result = documentContextManager.contextSizeResult else { return .gray }
        switch result.status {
        case .optimal:
            return .green
        case .large:
            return .orange
        case .excessive:
            return .red
        }
    }
    
    private var contextStatusText: String {
        guard let result = documentContextManager.contextSizeResult else { return "No data" }
        return result.status.displayName
    }
    
    // MARK: - Helper Methods
    
    private func getContextSummaryText() -> String {
        if documentContextManager.hasDocuments {
            return documentContextManager.getContextSummary()
        } else {
            return "No documents selected for context"
        }
    }
    
    private func getDocumentContextSize(_ document: ProcessedDocument) -> ContextSizeResult? {
        let singleDocumentResult = ContextSizeCalculator.calculateSize(
            for: [document],
            modelName: documentContextManager.currentModel
        )
        return singleDocumentResult
    }
    
    private func toggleDocumentSelection(_ document: ProcessedDocument, isSelected: Bool) {
        if isSelected {
            // Check if adding this document would exceed limits
            if documentContextManager.wouldExceedLimits(withAdditionalDocument: document) {
                // Show warning but allow selection (user can switch to RAG mode)
                showExceedsLimitWarning(for: document)
            }
            documentContextManager.addDocument(document)
        } else {
            documentContextManager.removeDocument(document)
        }
    }
    
    private func selectAllOptimalDocuments() {
        var documentsToAdd: [ProcessedDocument] = []
        
        for document in availableDocuments {
            let testDocuments = documentsToAdd + [document]
            let result = ContextSizeCalculator.calculateSize(
                for: testDocuments,
                modelName: documentContextManager.currentModel
            )
            
            // Only add if it keeps context in optimal or large range
            if result.status != .excessive {
                documentsToAdd.append(document)
            }
        }
        
        documentContextManager.setDocuments(documentsToAdd)
        isSelectingMultiple = true
    }
    
    private func showExceedsLimitWarning(for document: ProcessedDocument) {
        // This could be enhanced with an alert, for now we rely on UI indicators
        print("Warning: Adding '\(document.title)' may exceed context limits")
    }
    
    private func applySelectionToChatViewModel() {
        // Clear existing context
        chatViewModel.clearDocumentContext()
        
        // Add selected documents to ChatViewModel
        for document in documentContextManager.selectedDocuments {
            chatViewModel.addDocumentToContext(document.id)
        }
        
        // Update chat mode if needed
        updateChatViewModelMode()
    }
    
    private func updateChatViewModelMode() {
        // This would need to be implemented in ChatViewModel
        // For now, we'll just update the DocumentContextManager
        documentContextManager.updateChatMode(selectedChatMode)
    }
    
    // MARK: - Load Real Documents
    private func loadRealDocuments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let documents = try await fetchDocumentsFromCoreData()
            await MainActor.run {
                self.availableDocuments = documents
                
                // Initialize DocumentContextManager with current model
                let currentModel = chatViewModel.selectedModel.id
                if !currentModel.isEmpty {
                    documentContextManager.updateCurrentModel(currentModel)
                }
                
                // Pre-select documents that are already in ChatViewModel context
                let preSelectedDocuments = documents.filter { document in
                    chatViewModel.selectedDocuments.contains(document.id)
                }
                documentContextManager.setDocuments(preSelectedDocuments)
            }
        } catch {
            print("Failed to load documents: \(error)")
            await MainActor.run {
                self.availableDocuments = []
            }
        }
    }
    
    private func fetchDocumentsFromCoreData() async throws -> [ProcessedDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            let context = dataService.persistenceContainer.container.viewContext
            
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
                    let documents = try context.fetch(fetchRequest)
                    
                    let processedDocuments = documents.compactMap { document in
                        ProcessedDocument(
                            id: document.id?.uuidString ?? UUID().uuidString,
                            title: document.title ?? "Untitled",
                            fileName: document.fileURL?.lastPathComponent ?? "Unknown",
                            fileURL: document.fileURL ?? URL(fileURLWithPath: ""),
                            fileSize: document.fileSize,
                            type: DocumentType(rawValue: document.type ?? "") ?? .unknown,
                            pageCount: document.pageCount,
                            content: document.textContent ?? "",
                            detectedLanguage: document.detectedLanguage,
                            createdAt: document.createdAt ?? Date()
                        )
                    }
                    
                    continuation.resume(returning: processedDocuments)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Enhanced Document Row Component
struct EnhancedDocumentRow: View {
    let document: ProcessedDocument
    let isSelected: Bool
    let contextSizeResult: ContextSizeResult?
    let wouldExceedLimits: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Document icon with size indicator
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(document.type.backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: document.type.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                
                // Size indicator badge
                if let result = contextSizeResult {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(sizeIndicatorColor(for: result.status))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Document info with enhanced metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(document.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(document.type.backgroundColor.opacity(0.2))
                        .foregroundColor(document.type.foregroundColor)
                        .cornerRadius(4)
                    
                    Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Context size info
                    if let result = contextSizeResult {
                        Text(formatSize(result.totalCharacters))
                            .font(.caption)
                            .foregroundColor(sizeIndicatorColor(for: result.status))
                            .fontWeight(.medium)
                    }
                }
                
                // Warning message if would exceed limits
                if wouldExceedLimits && !isSelected {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        
                        Text("May exceed context limits")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Selection toggle with visual feedback
            Button(action: {
                onToggle(!isSelected)
            }) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isSelected)
        }
        .opacity(wouldExceedLimits && !isSelected ? 0.7 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func sizeIndicatorColor(for status: ContextSizeStatus) -> Color {
        switch status {
        case .optimal:
            return .green
        case .large:
            return .orange
        case .excessive:
            return .red
        }
    }
    
    private func formatSize(_ characters: Int) -> String {
        if characters < 1000 {
            return "\(characters)c"
        } else if characters < 1_000_000 {
            return String(format: "%.1fk", Double(characters) / 1000.0)
        } else {
            return String(format: "%.1fM", Double(characters) / 1_000_000.0)
        }
    }
}

// MARK: - Preview
struct DocumentPickerView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPickerView(chatViewModel: ChatViewModel())
    }
}