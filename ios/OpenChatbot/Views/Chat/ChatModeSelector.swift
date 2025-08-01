import SwiftUI

// MARK: - Chat Mode Selector Component
struct ChatModeSelector: View {
    
    // MARK: - Properties
    
    @ObservedObject var documentContextManager: DocumentContextManager
    @Binding var selectedMode: ChatMode
    
    // MARK: - State
    
    @State private var showWarningDialog = false
    @State private var warningMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            modeSelectionSection
            contextInfoSection
            warningSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .alert("Chat Mode Warning", isPresented: $showWarningDialog) {
            Button("OK") { }
        } message: {
            Text(warningMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chat Mode Selector")
        .accessibilityHint("Select between RAG mode and Full Context mode for document chat")
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .medium))
            
            Text("Chat Mode Selection")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            if documentContextManager.hasDocuments {
                contextSizeIndicator
            }
        }
    }
    
    // MARK: - Mode Selection Section
    
    private var modeSelectionSection: some View {
        VStack(spacing: 8) {
            // RAG Mode Option
            ChatModeOptionView(
                mode: .rag,
                isSelected: selectedMode == .rag,
                isRecommended: documentContextManager.recommendedMode == .rag,
                title: "RAG Mode",
                description: "Search relevant information",
                isEnabled: true,
                action: { selectMode(.rag) }
            )
            
            // Full Context Mode Option
            ChatModeOptionView(
                mode: .fullContext,
                isSelected: selectedMode == .fullContext,
                isRecommended: documentContextManager.recommendedMode == .fullContext,
                title: "Full Context",
                description: "Include complete document",
                isEnabled: documentContextManager.canUseFullContext,
                action: { selectMode(.fullContext) }
            )
        }
    }
    
    // MARK: - Context Info Section
    
    private var contextInfoSection: some View {
        Group {
            if documentContextManager.hasDocuments {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Context Summary")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(documentContextManager.getContextSummary())
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    
                    // Processing time estimate
                    if documentContextManager.hasDocuments {
                        HStack {
                            Text("Est. Processing Time")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatProcessingTime(documentContextManager.getProcessingTimeEstimate()))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Warning Section
    
    private var warningSection: some View {
        Group {
            if let warningMessage = documentContextManager.warningMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                        .offset(y: 1)
                    
                    Text(warningMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Context Size Indicator
    
    private var contextSizeIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(contextStatusColor)
                .frame(width: 8, height: 8)
            
            Text(contextStatusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(contextStatusColor)
        }
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
    
    private func selectMode(_ mode: ChatMode) {
        if mode == .fullContext && !documentContextManager.canUseFullContext {
            warningMessage = documentContextManager.warningMessage ?? "Cannot use Full Context mode with current documents"
            showWarningDialog = true
            return
        }
        
        selectedMode = mode
        documentContextManager.updateChatMode(mode)
    }
    
    private func formatProcessingTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 1 {
            return "< 1s"
        } else if timeInterval < 60 {
            return String(format: "~%.0fs", timeInterval)
        } else {
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
}

// MARK: - Chat Mode Option View
struct ChatModeOptionView: View {
    
    let mode: ChatMode
    let isSelected: Bool
    let isRecommended: Bool
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isEnabled ? .blue : .gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(isEnabled ? .blue : .gray)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isEnabled ? .primary : .secondary)
                        
                        if isRecommended {
                            recommendedBadge
                        }
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(isEnabled ? .secondary : Color.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundView)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - UI Components
    
    private var recommendedBadge: some View {
        Text("(Recommended)")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
    
    // MARK: - Accessibility Helpers
    
    private var accessibilityLabel: String {
        var label = title
        if isRecommended {
            label += ", Recommended"
        }
        if !isEnabled {
            label += ", Disabled"
        }
        return label
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "This mode is not available with current document selection"
        }
        return "Double tap to select \(title.lowercased()) for document chat"
    }
}

// MARK: - Preview
struct ChatModeSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with documents
            ChatModeSelector(
                documentContextManager: {
                    let manager = DocumentContextManager()
                    let mockDoc = ProcessedDocument(
                        id: "1",
                        title: "Sample Document",
                        fileName: "sample.pdf",
                        fileURL: URL(string: "file://sample.pdf")!,
                        fileSize: 15000,
                        type: .pdf,
                        pageCount: 10,
                        content: String(repeating: "Sample content. ", count: 1000),
                        detectedLanguage: "en",
                        createdAt: Date()
                    )
                    manager.addDocument(mockDoc)
                    return manager
                }(),
                selectedMode: .constant(.rag)
            )
            
            // Preview without documents
            ChatModeSelector(
                documentContextManager: DocumentContextManager(),
                selectedMode: .constant(.rag)
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}