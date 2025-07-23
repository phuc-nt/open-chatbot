import SwiftUI

// Document Picker for RAG Context Selection
struct DocumentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var chatViewModel: ChatViewModel
    
    // Simulated available documents for RAG
    @State private var availableDocuments: [SimulatedDocument] = [
        SimulatedDocument(id: "doc1", title: "Project Requirements", type: .pdf, size: "2.3 MB"),
        SimulatedDocument(id: "doc2", title: "Technical Specifications", type: .pdf, size: "1.8 MB"),
        SimulatedDocument(id: "doc3", title: "User Guide", type: .text, size: "856 KB"),
        SimulatedDocument(id: "doc4", title: "API Documentation", type: .pdf, size: "3.1 MB"),
        SimulatedDocument(id: "doc5", title: "Meeting Notes", type: .text, size: "245 KB"),
        SimulatedDocument(id: "doc6", title: "Design Mockups", type: .image, size: "5.2 MB")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with context info
                ragContextHeader
                
                // Document list
                documentList
            }
            .navigationTitle("Select Documents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - RAG Context Header
    private var ragContextHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAG Context")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(chatViewModel.getDocumentContextSummary())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if chatViewModel.isRAGEnabled {
                    Button("Clear All") {
                        chatViewModel.clearDocumentContext()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            if chatViewModel.isRAGEnabled {
                ragEnabledIndicator
            }
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
    }
    
    private var ragEnabledIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text("RAG enabled - Selected documents will provide context for AI responses")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
        .padding(.horizontal)
    }
    
    // MARK: - Document List
    private var documentList: some View {
        List {
            Section(header: sectionHeader) {
                ForEach(availableDocuments) { document in
                    DocumentRow(
                        document: document,
                        isSelected: chatViewModel.selectedDocuments.contains(document.id),
                        onToggle: { isSelected in
                            if isSelected {
                                chatViewModel.addDocumentToContext(document.id)
                            } else {
                                chatViewModel.removeDocumentFromContext(document.id)
                            }
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Available Documents")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(availableDocuments.count) documents")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .textCase(nil)
    }
}

// MARK: - Document Row Component
struct DocumentRow: View {
    let document: SimulatedDocument
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Document icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(document.type.backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: document.type.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
            }
            
            // Document info
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
                    
                    Text(document.size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Selection toggle
            Button(action: {
                onToggle(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isSelected)
        }
    }
}

// MARK: - Simulated Document Model
struct SimulatedDocument: Identifiable {
    let id: String
    let title: String
    let type: DocumentFileType
    let size: String
}

// MARK: - Document File Type
enum DocumentFileType {
    case pdf
    case text
    case image
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .text: return "Text"
        case .image: return "Image"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pdf: return .red
        case .text: return .blue
        case .image: return .green
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .pdf: return .red
        case .text: return .blue
        case .image: return .green
        }
    }
}

// MARK: - Preview
struct DocumentPickerView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentPickerView(chatViewModel: ChatViewModel())
    }
} 