import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @StateObject private var viewModel = DocumentUploadViewModel()
    @State private var showingDocumentPicker = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                uploadAreaView
                
                if viewModel.isProcessing {
                    processingView
                }
                
                if viewModel.uploadedCount > 0 {
                    statusView
                }
                
                if !viewModel.selectedDocuments.isEmpty {
                    selectedDocumentsView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Upload Documents")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf, .jpeg, .png, .plainText],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.addDocuments(urls)
                    Task {
                        await viewModel.processSelectedDocuments()
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Upload Area
    private var uploadAreaView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Upload Documents")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select PDF, images, or text files to upload")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Choose Files") {
                showingDocumentPicker = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isProcessing)
        }
        .padding(32)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("Processing documents...")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(viewModel.processingProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 4) {
                Text("Uploaded: \(viewModel.uploadedCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !viewModel.embeddingProgress.isEmpty {
                    Text(viewModel.embeddingProgress)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Status View
    private var statusView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text("Upload Complete")
                    .font(.headline)
                
                Text("\(viewModel.uploadedCount) documents processed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Reset") {
                viewModel.resetUploadState()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Selected Documents View
    private var selectedDocumentsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Documents (\(viewModel.selectedDocuments.count))")
                .font(.headline)
            
            ForEach(viewModel.selectedDocuments.indices, id: \.self) { index in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    
                    Text(viewModel.selectedDocuments[index].lastPathComponent)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("Remove") {
                        viewModel.removeDocument(at: index)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
            
            if !viewModel.selectedDocuments.isEmpty && !viewModel.isProcessing {
                Button("Process All") {
                    Task {
                        await viewModel.processSelectedDocuments()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
} 