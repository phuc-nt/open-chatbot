import SwiftUI
import PDFKit
import QuickLook

struct DocumentDetailView: View {
    let document: ProcessedDocument
    @StateObject private var viewModel = DocumentDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingQuickLook = false
    @State private var selectedTab: DetailTab = .preview
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Preview Tab
                previewTab
                    .tabItem {
                        Label("Preview", systemImage: "doc.text")
                    }
                    .tag(DetailTab.preview)
                
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
                    shareButton
                    editButton
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                DocumentEditView(document: document, viewModel: viewModel)
            }
            .sheet(isPresented: $showingQuickLook) {
                QuickLookView(url: document.fileURL)
            }
        }
        .onAppear {
            viewModel.loadDocument(document)
        }
    }
    
    // MARK: - Preview Tab
    @ViewBuilder
    private var previewTab: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    // Document Header
                    documentHeaderSection
                    
                    // Preview Content
                    previewContentSection(geometry: geometry)
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
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
    
    @ViewBuilder
    private func previewContentSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Group {
                switch document.type {
                case .pdf:
                    pdfPreview(geometry: geometry)
                case .image, .imagePNG:
                    imagePreview(geometry: geometry)
                case .text:
                    textPreview()
                case .unknown:
                    unknownFilePreview()
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func pdfPreview(geometry: GeometryProxy) -> some View {
        VStack {
            if let pdfDocument = PDFDocument(url: document.fileURL) {
                PDFKitView(document: pdfDocument)
                    .frame(height: min(geometry.size.height * 0.6, 400))
                    .cornerRadius(8)
                    .onTapGesture {
                        showingQuickLook = true
                    }
            } else {
                fallbackPreview()
            }
        }
    }
    
    @ViewBuilder
    private func imagePreview(geometry: GeometryProxy) -> some View {
        AsyncImage(url: document.fileURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: min(geometry.size.height * 0.6, 400))
                .cornerRadius(8)
                .onTapGesture {
                    showingQuickLook = true
                }
        } placeholder: {
            ProgressView()
                .frame(height: 200)
        }
    }
    
    @ViewBuilder
    private func textPreview() -> some View {
        ScrollView {
            Text(String(document.content.prefix(1000)) + (document.content.count > 1000 ? "..." : ""))
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 300)
        .onTapGesture {
            showingQuickLook = true
        }
    }
    
    @ViewBuilder
    private func unknownFilePreview() -> some View {
        fallbackPreview()
    }
    
    @ViewBuilder
    private func fallbackPreview() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Preview not available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("Open in External App") {
                showingQuickLook = true
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 200)
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(title: "Open", icon: "arrow.up.right.square") {
                    showingQuickLook = true
                }
                
                ActionButton(title: "Share", icon: "square.and.arrow.up") {
                    shareDocument()
                }
                
                ActionButton(title: "Chat", icon: "bubble.left.and.bubble.right") {
                    openChatWithDocument()
                }
                
                ActionButton(title: "Edit Info", icon: "pencil") {
                    showingEditSheet = true
                }
            }
        }
    }
    
    // MARK: - Info Tab
    @ViewBuilder
    private var infoTab: some View {
        List {
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
                
                Button("Edit Tags") {
                    showingEditSheet = true
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
    private var shareButton: some View {
        Button(action: shareDocument) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    @ViewBuilder
    private var editButton: some View {
        Button("Edit") {
            showingEditSheet = true
        }
    }
    
    // MARK: - Actions
    private func shareDocument() {
        let activityVC = UIActivityViewController(activityItems: [document.fileURL], applicationActivities: [])
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func openChatWithDocument() {
        // TODO: Navigate to chat with document context
        dismiss()
    }
}

// MARK: - Supporting Views
struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

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
    case preview = 0
    case info = 1
    case content = 2
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