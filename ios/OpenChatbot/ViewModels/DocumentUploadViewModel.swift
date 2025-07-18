import Foundation
import SwiftUI

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
                        let processedDocument = try await self.documentService.processDocument(url)
                        
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
} 