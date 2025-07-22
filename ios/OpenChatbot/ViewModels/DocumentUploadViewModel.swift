import Foundation
import SwiftUI

// Import required types and services
import CoreData

// MARK: - Document Upload ViewModel
@MainActor
class DocumentUploadViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var uploadedDocuments: [ProcessedDocument] = []
    @Published var backgroundTasks: [String: ProcessingTask] = [:]
    @Published var selectedDocuments: [URL] = []
    @Published var errorMessage: String?
    
    private let documentService = DocumentProcessingService()
    private let dataService = DataService()
    
    /// Computed property để backward compatibility với tests
    var processingTasks: [ProcessingTask] {
        return Array(backgroundTasks.values)
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>, completion: @escaping (Error) -> Void) {
        switch result {
        case .success(let urls):
            processDocuments(urls, completion: completion)
        case .failure(let error):
            completion(error)
        }
    }
    
    private func processDocuments(_ urls: [URL], completion: @escaping (Error) -> Void) {
        isProcessing = true
        processingProgress = 0.0
        
        Task {
            for (index, url) in urls.enumerated() {
                let taskID = UUID().uuidString
                
                // Add to background tasks tracking
                self.backgroundTasks[taskID] = ProcessingTask(
                    id: taskID,
                    fileName: url.lastPathComponent,
                    status: .processing
                )
                
                // Process in background with high priority
                Task.detached(priority: .high) {
                    do {
                        // 🔒 SECURITY SCOPED ACCESS - This is the key fix!
                        let accessGranted = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessGranted {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        
                        // Verify we can actually access the file
                        guard FileManager.default.fileExists(atPath: url.path) else {
                            throw DocumentUploadError.fileNotAccessible(fileName: url.lastPathComponent)
                        }
                        
                        let processedDocument = try await self.documentService.processDocument(url)
                        
                        // 💾 SAVE TO CORE DATA - This was missing!
                        await self.saveDocumentToCoreData(processedDocument)
                        
                        await MainActor.run {
                            self.uploadedDocuments.append(processedDocument)
                            self.backgroundTasks[taskID]?.status = .completed
                        }
                    } catch {
                        await MainActor.run {
                            self.backgroundTasks[taskID]?.status = .failed
                            completion(error)
                        }
                    }
                }
                
                // Update immediate progress
                self.processingProgress = Double(index + 1) / Double(urls.count)
            }
            
            // Wait a moment for background tasks to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            self.isProcessing = false
        }
    }
    
    func removeDocument(_ document: ProcessedDocument) {
        uploadedDocuments.removeAll { $0.id == document.id }
    }
    
    func clearCompletedTasks() {
        backgroundTasks = backgroundTasks.filter { task in
            switch task.value.status {
            case .completed:
                return false
            default:
                return true
            }
        }
    }
    
    // MARK: - Core Data Persistence
    
    /// Save processed document to Core Data
    private func saveDocumentToCoreData(_ processedDocument: ProcessedDocument) async {
        return await withCheckedContinuation { continuation in
            let context = dataService.persistenceContainer.container.newBackgroundContext()
            
            context.perform {
                do {
                    // Create DocumentEntity (correct Core Data entity)
                    let documentEntity = DocumentEntity(context: context)
                    documentEntity.id = UUID(uuidString: processedDocument.id) ?? UUID()
                    documentEntity.title = processedDocument.title
                    // Map fileName - need to check actual property name
                    documentEntity.fileURL = processedDocument.fileURL
                    documentEntity.fileSize = processedDocument.fileSize
                    documentEntity.type = processedDocument.type.rawValue
                    documentEntity.pageCount = processedDocument.pageCount
                    documentEntity.textContent = processedDocument.content
                    documentEntity.detectedLanguage = processedDocument.detectedLanguage
                    documentEntity.createdAt = processedDocument.createdAt
                    documentEntity.updatedAt = Date()
                    documentEntity.isProcessed = true
                    documentEntity.processingStatus = "completed"
                    
                    // Save context
                    try context.save()
                    
                    print("✅ Saved document '\(processedDocument.title)' to Core Data")
                    continuation.resume()
                } catch {
                    print("❌ Failed to save document to Core Data: \(error)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Error Types
enum DocumentUploadError: LocalizedError {
    case fileNotAccessible(fileName: String)
    case processingFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotAccessible(let fileName):
            return "Cannot access file '\(fileName)'. Please try selecting the file again."
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        }
    }
} 