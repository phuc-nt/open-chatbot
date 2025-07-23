import Foundation
import SwiftUI
import PDFKit
import Vision
import VisionKit
import UniformTypeIdentifiers
import CoreData
import NaturalLanguage

// MARK: - Document Upload View Model with RAG Pipeline Foundation
class DocumentUploadViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var selectedDocuments: [URL] = []
    @Published var errorMessage: String?
    @Published var uploadedCount: Int = 0
    @Published var embeddingProgress: String = ""
    @Published var processedDocuments: [ProcessedDocumentInfo] = []
    
    // MARK: - Document Processing Methods
    
    /// Start processing selected documents with embedding pipeline
    func processSelectedDocuments() async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            uploadedCount = 0
            embeddingProgress = "Starting document processing..."
        }
        
        for (index, url) in selectedDocuments.enumerated() {
            await processDocumentWithEmbeddings(url: url)
            await MainActor.run {
                processingProgress = Double(index + 1) / Double(selectedDocuments.count)
            }
        }
        
        await MainActor.run {
            isProcessing = false
            selectedDocuments.removeAll()
            embeddingProgress = "Processing complete! \(uploadedCount) documents processed with embeddings."
        }
    }
    
    /// Process a single document with embedding simulation
    private func processDocumentWithEmbeddings(url: URL) async {
        let fileName = url.lastPathComponent
        
        await MainActor.run {
            embeddingProgress = "Processing \(fileName)..."
        }
        
        do {
            // Step 1: Grant security scoped access
            let accessGranted = url.startAccessingSecurityScopedResource()
            defer {
                if accessGranted {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Step 2: Extract document content
            await MainActor.run {
                embeddingProgress = "Extracting text from \(fileName)..."
            }
            
            let documentInfo = try await extractDocumentContent(from: url)
            
            // Step 3: Generate text chunks for embedding
            await MainActor.run {
                embeddingProgress = "Creating text chunks for \(fileName)..."
            }
            
            let textChunks = chunkText(documentInfo.content, maxChunkSize: 1000, overlap: 100)
            
            // Step 4: Simulate embedding generation
            await MainActor.run {
                embeddingProgress = "Generating embeddings for \(fileName)..."
            }
            
            try await simulateEmbeddingGeneration(for: documentInfo, chunks: textChunks)
            
            // Step 5: Save to Core Data
            await MainActor.run {
                embeddingProgress = "Saving \(fileName) to database..."
            }
            
            await saveDocumentToCoreData(documentInfo)
            
            // Step 6: Store processed document info
            await MainActor.run {
                processedDocuments.append(documentInfo)
                uploadedCount += 1
                embeddingProgress = "✅ Completed processing \(fileName) with \(textChunks.count) embeddings"
            }
            
            print("✅ Successfully processed document: \(fileName)")
            print("📊 Generated \(textChunks.count) text chunks for embedding")
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process \(fileName): \(error.localizedDescription)"
                embeddingProgress = "❌ Failed to process \(fileName)"
            }
            print("❌ Document processing failed: \(error)")
        }
    }
    
    /// Extract content from document
    private func extractDocumentContent(from url: URL) async throws -> ProcessedDocumentInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        let fileType = determineFileType(from: url)
        
        // Extract text content based on file type
        let content: String
        switch fileType {
        case .text:
            content = try String(contentsOf: url, encoding: .utf8)
        case .pdf:
            // Simulate PDF text extraction
            content = "PDF document content extracted from \(url.lastPathComponent)\n\nThis is simulated text content that would be extracted from a PDF document using PDFKit. In a real implementation, this would contain the actual text content of the PDF file."
        case .image:
            // Simulate OCR text extraction
            content = "Image text content extracted from \(url.lastPathComponent)\n\nThis is simulated text content that would be extracted from an image using Vision framework OCR. In a real implementation, this would contain the actual text recognized from the image."
        case .unknown:
            content = "Document content from \(url.lastPathComponent)"
        }
        
        // Simulate language detection
        let detectedLanguage = detectLanguage(text: content)
        
        return ProcessedDocumentInfo(
            id: UUID().uuidString,
            title: url.deletingPathExtension().lastPathComponent,
            fileName: url.lastPathComponent,
            fileURL: url,
            fileSize: fileSize,
            fileType: fileType,
            content: content,
            detectedLanguage: detectedLanguage,
            embeddingCount: 0,
            createdAt: Date()
        )
    }
    
    /// Simulate embedding generation process
    private func simulateEmbeddingGeneration(for document: ProcessedDocumentInfo, chunks: [String]) async throws {
        for (index, chunk) in chunks.enumerated() {
            // Simulate embedding generation time
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds per chunk
            
            await MainActor.run {
                embeddingProgress = "Generated embedding \(index + 1)/\(chunks.count) for \(document.fileName)"
            }
            
            // In real implementation, this would:
            // 1. Generate actual embeddings using EmbeddingService
            // 2. Save embeddings to CoreDataVectorService
            // 3. Update document with embedding metadata
            
            print("🧠 Generated embedding for chunk \(index + 1): \(chunk.prefix(50))...")
        }
        
        // Update document with embedding count
        if let docIndex = processedDocuments.firstIndex(where: { $0.id == document.id }) {
            await MainActor.run {
                processedDocuments[docIndex].embeddingCount = chunks.count
                
                // TODO: Save document to Core Data after processing
                // Need to fix DataService and DocumentEntity imports
                // Task {
                //     await saveDocumentToCoreData(processedDocuments[docIndex])
                // }
                
                print("🏆 Document processed successfully: \(document.title)")
                print("📊 Embedding count: \(chunks.count)")
            }
        }
    }
    
    /// Chunk text into smaller pieces for embedding
    private func chunkText(_ text: String, maxChunkSize: Int, overlap: Int) -> [String] {
        let sentences = text.components(separatedBy: .newlines)
        var chunks: [String] = []
        var currentChunk = ""
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSentence.isEmpty { continue }
            
            if currentChunk.count + trimmedSentence.count <= maxChunkSize {
                if !currentChunk.isEmpty {
                    currentChunk += "\n"
                }
                currentChunk += trimmedSentence
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    
                    // Create overlap for context continuity
                    let words = currentChunk.components(separatedBy: .whitespaces)
                    let overlapWords = words.suffix(overlap / 10) // Rough word count estimation
                    currentChunk = overlapWords.joined(separator: " ")
                }
                
                currentChunk += "\n" + trimmedSentence
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks.isEmpty ? [text] : chunks
    }
    
    /// Determine document type from URL
    private func determineFileType(from url: URL) -> SimpleFileType {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf": return .pdf
        case "jpg", "jpeg", "png": return .image
        case "txt": return .text
        default: return .unknown
        }
    }
    
    /// Detect language of text content
    private func detectLanguage(text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            switch dominantLanguage {
            case .vietnamese:
                return "vi"
            case .english:
                return "en"
            default:
                return dominantLanguage.rawValue
            }
        }
        
        return nil
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Reset upload state
    func resetUploadState() {
        selectedDocuments.removeAll()
        processedDocuments.removeAll()
        processingProgress = 0.0
        uploadedCount = 0
        embeddingProgress = ""
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
    
    /// Get embedding statistics for UI display
    func getEmbeddingStats() -> String {
        let totalEmbeddings = processedDocuments.reduce(0) { $0 + $1.embeddingCount }
        return "\(totalEmbeddings) embeddings from \(processedDocuments.count) documents"
    }
    
    /// Save processed document to Core Data
    private func saveDocumentToCoreData(_ document: ProcessedDocumentInfo) async {
        return await withCheckedContinuation { continuation in
            let context = PersistenceController.shared.newBackgroundContext()
            
            context.perform {
                do {
                    // Create DocumentEntity using NSEntityDescription
                    guard let entityDescription = NSEntityDescription.entity(forEntityName: "DocumentEntity", in: context) else {
                        print("❌ Failed to get DocumentEntity description")
                        continuation.resume()
                        return
                    }
                    
                    let documentEntity = NSManagedObject(entity: entityDescription, insertInto: context)
                    documentEntity.setValue(UUID(uuidString: document.id) ?? UUID(), forKey: "id")
                    documentEntity.setValue(document.title, forKey: "title")
                    documentEntity.setValue(document.fileURL, forKey: "fileURL")
                    documentEntity.setValue(document.fileSize, forKey: "fileSize")
                    documentEntity.setValue(document.fileType.rawValue, forKey: "type")
                    documentEntity.setValue(Int32(0), forKey: "pageCount")
                    documentEntity.setValue(document.content, forKey: "textContent")
                    documentEntity.setValue(document.detectedLanguage, forKey: "detectedLanguage")
                    documentEntity.setValue(document.createdAt, forKey: "createdAt")
                    documentEntity.setValue(Date(), forKey: "updatedAt")
                    
                    // Save context
                    try context.save()
                    print("✅ Saved document to Core Data: \(document.title)")
                    continuation.resume()
                    
                } catch {
                    print("❌ Failed to save document to Core Data: \(error)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Processed Document Info Model
struct ProcessedDocumentInfo: Identifiable {
    let id: String
    let title: String
    let fileName: String
    let fileURL: URL
    let fileSize: Int64
    let fileType: SimpleFileType
    let content: String
    let detectedLanguage: String?
    var embeddingCount: Int
    let createdAt: Date
}

// MARK: - Simple File Type Enum
enum SimpleFileType: String, CaseIterable {
    case pdf = "pdf"
    case image = "image"
    case text = "text"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "Image"
        case .text: return "Text"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

 