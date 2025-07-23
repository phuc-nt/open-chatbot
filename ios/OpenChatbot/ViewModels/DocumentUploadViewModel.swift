import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Minimal Document Upload View Model
class DocumentUploadViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var selectedDocuments: [URL] = []
    @Published var errorMessage: String?
    @Published var uploadedCount: Int = 0
    
    // MARK: - Document Processing Methods
    
    /// Start processing selected documents
    func processSelectedDocuments() async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            uploadedCount = 0
        }
        
        for (index, url) in selectedDocuments.enumerated() {
            await processDocument(url: url)
            await MainActor.run {
                processingProgress = Double(index + 1) / Double(selectedDocuments.count)
            }
        }
        
        await MainActor.run {
            isProcessing = false
            selectedDocuments.removeAll()
        }
    }
    
    /// Process a single document
    private func processDocument(url: URL) async {
        let fileName = url.lastPathComponent
        
        // Simulate document processing
        do {
            // Simulate processing time
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                uploadedCount += 1
            }
            
            print("✅ Successfully processed document: \(fileName)")
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process \(fileName): \(error.localizedDescription)"
            }
        }
    }
    
    /// Determine MIME type for file
    private func determineMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    /// Generate embeddings for uploaded document (placeholder)
    func generateEmbeddingsForDocument(fileName: String) async {
        print("🧠 Generating embeddings for document: \(fileName)")
        // This would integrate with EmbeddingService when available
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Reset upload state
    func resetUploadState() {
        selectedDocuments.removeAll()
        processingProgress = 0.0
        uploadedCount = 0
        clearError()
    }
    
    /// Add documents to selection
    func addDocuments(_ urls: [URL]) {
        selectedDocuments.append(contentsOf: urls)
    }
    
    /// Remove document from selection
    func removeDocument(at index: Int) {
        guard index < selectedDocuments.count else { return }
        selectedDocuments.remove(at: index)
    }
} 