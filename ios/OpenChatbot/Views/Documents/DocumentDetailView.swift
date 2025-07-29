import SwiftUI
import PDFKit
import QuickLook
import Foundation

struct DocumentDetailView: View {
    let document: ProcessedDocument
    @StateObject private var viewModel = DocumentDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showingEditSheet = false
    @State private var selectedTab: DetailTab = .info
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Info Tab
                infoTab
                    .tabItem {
                        Label("Info", systemImage: "info.circle")
                    }
                    .tag(DetailTab.info)
                
                // Content Tab
                contentTab
                    .tabItem {
                        Label("Content", systemImage: "text.alignleft")
                    }
                    .tag(DetailTab.content)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                DocumentEditView(document: document, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadDocument(document)
        }
    }
    
    
    @ViewBuilder
    private var documentHeaderSection: some View {
        VStack(spacing: 12) {
            // Document Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(document.type.backgroundColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: document.type.systemImageName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Document Title
            Text(document.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Document Metadata
            HStack {
                Label(document.type.displayName, systemImage: "doc")
                
                if document.pageCount > 1 {
                    Label("\(document.pageCount) pages", systemImage: "doc.plaintext")
                }
                
                if let language = document.detectedLanguage {
                    Label(language.uppercased(), systemImage: "globe")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    
    
    // MARK: - Info Tab
    @ViewBuilder
    private var infoTab: some View {
        List {
            Section("Actions") {
                Button(action: openChatWithDocument) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text("Chat with Document")
                            .foregroundColor(.primary)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Button("Edit Info") {
                    showingEditSheet = true
                }
            }
            
            Section("File Information") {
                InfoRow(label: "Name", value: document.fileName)
                InfoRow(label: "Title", value: document.title)
                InfoRow(label: "Type", value: document.type.displayName)
                InfoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                if document.pageCount > 1 {
                    InfoRow(label: "Pages", value: "\(document.pageCount)")
                }
                if let language = document.detectedLanguage {
                    InfoRow(label: "Language", value: language.uppercased())
                }
            }
            
            Section("Dates") {
                InfoRow(label: "Created", value: DateFormatter.longStyle.string(from: document.createdAt))
                InfoRow(label: "Modified", value: DateFormatter.longStyle.string(from: document.createdAt))
            }
            
            Section("Tags") {
                if viewModel.tags.isEmpty {
                    Text("No tags")
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
            
            Section("Storage") {
                InfoRow(label: "Location", value: document.fileURL.path)
                InfoRow(label: "ID", value: document.id)
            }
        }
    }
    
    // MARK: - Content Tab
    @ViewBuilder
    private var contentTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Extracted Content")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(document.content.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(document.content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding()
        }
    }
    
    // MARK: - Toolbar Buttons
    @ViewBuilder
    private var editButton: some View {
        Button("Edit") {
            showingEditSheet = true
        }
    }
    
    // MARK: - Actions
    
    private func openChatWithDocument() {
        // Navigate to chat with document context
        dismiss()
        
        // Switch to Chat tab
        appState.switchToChatTab()
        
        // Post notification để ChatView add document to context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChatWithDocument"),
                object: document
            )
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

// MARK: - PDFKit Integration
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

// MARK: - Supporting Types
enum DetailTab: Int, CaseIterable {
    case info = 0
    case content = 1
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let longStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct DocumentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentDetailView(document: ProcessedDocument(
            id: "1",
            title: "Sample Document",
            fileName: "sample.pdf",
            fileURL: URL(string: "file://sample.pdf")!,
            fileSize: 1024000,
            type: .pdf,
            pageCount: 10,
            content: "This is sample content...",
            detectedLanguage: "en",
            createdAt: Date()
        ))
    }
} 