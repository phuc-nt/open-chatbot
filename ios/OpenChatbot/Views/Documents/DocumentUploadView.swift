import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @StateObject private var viewModel = DocumentUploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Upload Area
                uploadArea
                
                // Processing Status
                if viewModel.isProcessing {
                    ProcessingStatusView(
                        progress: viewModel.processingProgress,
                        backgroundTasks: viewModel.backgroundTasks
                    )
                }
                
                // Uploaded Documents List
                if !viewModel.uploadedDocuments.isEmpty {
                    DocumentListView(documents: viewModel.uploadedDocuments)
                } else if !viewModel.isProcessing {
                    emptyStateView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        showingDocumentPicker = true
                    }
                    .disabled(viewModel.isProcessing)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Upload Area
    private var uploadArea: some View {
        Button(action: {
            showingDocumentPicker = true
        }) {
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Upload Documents")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("PDF, Images, Text files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.isProcessing ? Color.gray : Color.blue,
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
            )
        }
        .disabled(viewModel.isProcessing)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No documents uploaded yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Upload your first document to get started with AI-powered document analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Processing Status View
struct ProcessingStatusView: View {
    let progress: Double
    let backgroundTasks: [String: ProcessingTask]
    
    var body: some View {
        VStack(spacing: 12) {
            // Overall Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Processing documents...")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            // Individual Task Status
            if !backgroundTasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(backgroundTasks.values), id: \.id) { task in
                        TaskStatusRow(task: task)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Task Status Row
struct TaskStatusRow: View {
    let task: ProcessingTask
    
    var body: some View {
        HStack {
            // File Icon
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
            
            // File Name
            Text(task.fileName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // Status Icon
            statusIcon
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .pending:
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
        case .processing:
            ProgressView()
                .scaleEffect(0.7)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Document List View
struct DocumentListView: View {
    let documents: [ProcessedDocument]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uploaded Documents")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(documents, id: \.id) { document in
                    DocumentRowView(document: document)
                }
            }
        }
    }
}

// MARK: - Document Row View
struct DocumentRowView: View {
    let document: ProcessedDocument
    
    var body: some View {
        HStack(spacing: 12) {
            // Document Icon
            Image(systemName: document.type.systemImageName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            // Document Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(document.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if document.pageCount > 1 {
                        Text("• \(document.pageCount) pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let language = document.detectedLanguage {
                        Text("• \(language.uppercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                // TODO: Show document detail
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
struct DocumentUploadView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentUploadView()
    }
} 