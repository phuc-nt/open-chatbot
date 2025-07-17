import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @StateObject private var viewModel = DocumentUploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingBrowserView = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragActive = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Enhanced Upload Area with Drag & Drop
                        enhancedUploadArea(geometry: geometry)
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Processing Status with Animations
                        if viewModel.isProcessing {
                            EnhancedProcessingStatusView(
                                progress: viewModel.processingProgress,
                                backgroundTasks: viewModel.backgroundTasks
                            )
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        // Recent Documents Preview
                        if !viewModel.uploadedDocuments.isEmpty {
                            recentDocumentsSection
                        } else if !viewModel.isProcessing {
                            enhancedEmptyStateView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Upload Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !viewModel.uploadedDocuments.isEmpty {
                        Button {
                            showingBrowserView = true
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                    
                    Menu {
                        Button {
                            showingDocumentPicker = true
                        } label: {
                            Label("Upload Files", systemImage: "doc.badge.plus")
                        }
                        
                        Button {
                            // TODO: Camera integration for document scanning
                        } label: {
                            Label("Scan Document", systemImage: "camera")
                        }
                        
                        Button {
                            // TODO: Import from cloud storage
                        } label: {
                            Label("Import from Cloud", systemImage: "icloud.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: DocumentProcessingService.supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                viewModel.handleFileSelection(result) { error in
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            .alert("Upload Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingBrowserView) {
                // DocumentBrowserView() // Temporarily commented out for build
                Text("Document Browser - Under Development")
                    .padding()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isProcessing)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.blue.gradient)
            
            Text("Upload & Analyze Documents")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add PDFs, images, or text files to chat with your documents using AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    // MARK: - Enhanced Upload Area
    @ViewBuilder
    private func enhancedUploadArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            // Main Drop Zone
            Button(action: {
                showingDocumentPicker = true
            }) {
                VStack(spacing: 20) {
                    // Animated Icon
                    ZStack {
                        Circle()
                            .fill(isDragActive ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .scaleEffect(isDragActive ? 1.1 : 1.0)
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(isDragActive ? .blue : .blue.opacity(0.8))
                            .scaleEffect(isDragActive ? 1.2 : 1.0)
                    }
                    
                    VStack(spacing: 8) {
                        Text(isDragActive ? "Release to Upload" : "Drag & Drop Documents")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("or tap to browse files")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Supported file types
                    HStack(spacing: 16) {
                        FileTypeChip(icon: "doc.fill", label: "PDF", color: .red)
                        FileTypeChip(icon: "photo.fill", label: "Images", color: .green)
                        FileTypeChip(icon: "doc.text.fill", label: "Text", color: .blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDragActive ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isDragActive ? Color.blue : Color.gray.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: isDragActive ? [] : [8])
                                )
                        )
                )
                .scaleEffect(isDragActive ? 1.02 : 1.0)
            }
            .disabled(viewModel.isProcessing)
            .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
                handleDrop(providers: providers)
            }
            
            // Upload Stats
            if !viewModel.uploadedDocuments.isEmpty {
                HStack {
                    Label("\(viewModel.uploadedDocuments.count) documents", systemImage: "doc.stack")
                    
                    Spacer()
                    
                    let totalSize = viewModel.uploadedDocuments.reduce(0) { $0 + $1.fileSize }
                    Label(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file), systemImage: "internaldrive")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    icon: "camera.viewfinder",
                    title: "Scan Document",
                    description: "Use camera to scan papers",
                    color: .purple
                ) {
                    // TODO: Camera scanning
                }
                
                QuickActionCard(
                    icon: "icloud.and.arrow.down",
                    title: "Import from Cloud",
                    description: "Import from iCloud, Dropbox",
                    color: .cyan
                ) {
                    // TODO: Cloud import
                }
                
                QuickActionCard(
                    icon: "folder.badge.plus",
                    title: "Bulk Upload",
                    description: "Upload multiple files at once",
                    color: .orange
                ) {
                    showingDocumentPicker = true
                }
                
                QuickActionCard(
                    icon: "text.viewfinder",
                    title: "Extract Text",
                    description: "OCR from images",
                    color: .green
                ) {
                    // TODO: Text extraction focus
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Documents Section
    @ViewBuilder
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Documents")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    showingBrowserView = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.uploadedDocuments.prefix(5)), id: \.id) { document in
                        DocumentPreviewCard(document: document) {
                            // TODO: Open document detail
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Enhanced Empty State
    @ViewBuilder
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No documents yet")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Upload your first document to get started with AI-powered analysis")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Get Started") {
                showingDocumentPicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        viewModel.handleFileSelection(.success([url])) { error in
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Supporting Components

struct FileTypeChip: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct DocumentPreviewCard: View {
    let document: ProcessedDocument
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(document.type.backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: document.type.systemImageName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 2) {
                    Text(document.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Processing Status View
struct EnhancedProcessingStatusView: View {
    let progress: Double
    let backgroundTasks: [String: ProcessingTask]
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Progress with Animation
            VStack(spacing: 12) {
                HStack {
                    Text("Processing Documents")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
            
            // Individual Task Status with Better Animations
            if !backgroundTasks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(backgroundTasks.values), id: \.id) { task in
                        EnhancedTaskStatusRow(task: task)
                            .transition(.slide.combined(with: .opacity))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct EnhancedTaskStatusRow: View {
    let task: ProcessingTask
    
    var body: some View {
        HStack(spacing: 12) {
            // File Icon with Status
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                statusIcon
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(task.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Animation
            if task.status == .processing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .pending:
            Image(systemName: "clock.fill")
        case .processing:
            Image(systemName: "gear")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
        }
    }
}

// MARK: - Preview
struct DocumentUploadView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentUploadView()
    }
} 