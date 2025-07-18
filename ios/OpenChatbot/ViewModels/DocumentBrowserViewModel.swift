import Foundation
import SwiftUI
import CoreData

// MARK: - Document Browser ViewModel
@MainActor
class DocumentBrowserViewModel: ObservableObject {
    @Published var documents: [ProcessedDocument] = []
    @Published var filteredDocuments: [ProcessedDocument] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var selectedFilter: DocumentFilter = .all
    @Published var sortOption: DocumentSortOption = .dateModified
    @Published var sortAscending = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let dataService = DataService()
    
    // MARK: - Computed Properties
    
    /// Statistics for the document collection
    var documentStats: DocumentStats {
        DocumentStats(
            total: documents.count,
            pdf: documents.filter { $0.type == .pdf }.count,
            images: documents.filter { $0.type == .image || $0.type == .imagePNG }.count,
            text: documents.filter { $0.type == .text }.count,
            recent: documents.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        )
    }
    
    /// Total file size of all documents
    var totalFileSize: Int64 {
        return documents.reduce(0) { total, document in
            total + document.fileSize
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize and load documents
    func initialize() async {
        await loadDocuments()
    }
    
    /// Refresh documents from Core Data
    func refreshDocuments() async {
        await loadDocuments()
    }
    
    /// Update current filter and refresh documents
    func updateFilter(_ filter: DocumentFilter) {
        selectedFilter = filter
        filterDocuments()
    }
    
    /// Update search text and filter documents
    func updateSearchFilter(_ text: String) {
        searchText = text
        filterDocuments()
    }
    
    /// Search documents with given text
    func searchDocuments(_ searchText: String) async {
        self.searchText = searchText
        await filterAndSortDocuments()
    }
    
    /// Update type filter
    func updateTypeFilter(_ filter: DocumentFilter) {
        selectedFilter = filter
        Task {
            await filterAndSortDocuments()
        }
    }
    
    /// Update sort option
    func updateSortOption(_ option: DocumentSortOption, ascending: Bool) {
        sortOption = option
        sortAscending = ascending
        Task {
            await filterAndSortDocuments()
        }
    }
    
    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedFilter = .all
        Task {
            await filterAndSortDocuments()
        }
    }
    
    /// Get document count for specific filter
    func getDocumentCount(for filter: DocumentFilter) -> Int {
        switch filter {
        case .all:
            return documents.count
        case .pdf:
            return documents.filter { $0.type == .pdf }.count
        case .images:
            return documents.filter { $0.type == .image || $0.type == .imagePNG }.count
        case .text:
            return documents.filter { $0.type == .text }.count
        case .recent:
            return documents.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        case .archived:
            return 0 // TODO: Implement archived documents
        }
    }
    
    // MARK: - Document Actions
    
    /// Delete a document
    func deleteDocument(_ document: ProcessedDocument) async {
        do {
            try await performDocumentDeletion(documentID: document.id)
            await loadDocuments()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete document: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// Archive a document
    func archiveDocument(_ document: ProcessedDocument) async {
        do {
            try await performDocumentArchiving(documentID: document.id)
            await loadDocuments()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to archive document: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// Duplicate a document
    func duplicateDocument(_ document: ProcessedDocument) async {
        // TODO: Implement duplicate functionality
        print("Duplicate document: \(document.title)")
    }
    
    /// Share a document
    func shareDocument(_ document: ProcessedDocument) {
        // TODO: Implement share functionality
        print("Share document: \(document.title)")
    }
    
    // MARK: - Private Methods
    
    /// Load documents from Core Data
    private func loadDocuments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedDocuments = try await fetchDocumentsFromCoreData()
            await MainActor.run {
                self.documents = fetchedDocuments
            }
            await filterAndSortDocuments()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load documents: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// Filter and sort documents based on current criteria
    private func filterAndSortDocuments() async {
        let filtered = await filterDocuments(documents, searchText: searchText, filter: selectedFilter)
        let sorted = await sortDocuments(filtered, by: sortOption, ascending: sortAscending)
        
        await MainActor.run {
            self.filteredDocuments = sorted
        }
    }
    
    /// Filter documents
    private func filterDocuments(_ documents: [ProcessedDocument], searchText: String, filter: DocumentFilter) async -> [ProcessedDocument] {
        var filtered = documents
        
        // Apply type filter
        switch filter {
        case .all:
            break
        case .pdf:
            filtered = filtered.filter { $0.type == .pdf }
        case .images:
            filtered = filtered.filter { $0.type == .image || $0.type == .imagePNG }
        case .text:
            filtered = filtered.filter { $0.type == .text }
        case .recent:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .archived:
            // TODO: Implement archived filter
            filtered = []
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.fileName.localizedCaseInsensitiveContains(searchText) ||
                document.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    /// Sort documents
    private func sortDocuments(_ documents: [ProcessedDocument], by option: DocumentSortOption, ascending: Bool) async -> [ProcessedDocument] {
        let sorted = documents.sorted { first, second in
            let result: Bool
            
            switch option {
            case .name:
                result = first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            case .dateCreated, .dateModified:
                result = first.createdAt < second.createdAt
            case .size:
                result = first.fileSize < second.fileSize
            case .type:
                result = first.type.displayName.localizedCaseInsensitiveCompare(second.type.displayName) == .orderedAscending
            }
            
            return ascending ? result : !result
        }
        
        return sorted
    }
    
    /// Fetch documents from Core Data
    private func fetchDocumentsFromCoreData() async throws -> [ProcessedDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            let context = dataService.persistenceContainer.container.viewContext
            
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<DocumentModel> = DocumentModel.fetchRequest()
                    let documents = try context.fetch(fetchRequest)
                    
                    let processedDocuments = documents.compactMap { document in
                        ProcessedDocument(
                            id: document.id.uuidString,
                            title: document.title,
                            fileName: document.fileName,
                            fileURL: document.fileURL,
                            fileSize: document.fileSize,
                            type: DocumentType(rawValue: document.mimeType) ?? .unknown,
                            pageCount: document.pageCount,
                            content: document.extractedText ?? "",
                            detectedLanguage: document.detectedLanguage,
                            createdAt: document.createdAt
                        )
                    }
                    
                    continuation.resume(returning: processedDocuments)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete document from Core Data
    private func performDocumentDeletion(documentID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = dataService.persistenceContainer.container.newBackgroundContext()
            
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<DocumentModel> = DocumentModel.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: documentID)! as CVarArg)
                    
                    let documents = try context.fetch(fetchRequest)
                    guard let document = documents.first else {
                        continuation.resume(throwing: DocumentError.documentNotFound)
                        return
                    }
                    
                    context.delete(document)
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Archive document in Core Data
    private func performDocumentArchiving(documentID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = dataService.persistenceContainer.container.newBackgroundContext()
            
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<DocumentModel> = DocumentModel.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: documentID)! as CVarArg)
                    
                    let documents = try context.fetch(fetchRequest)
                    guard let document = documents.first else {
                        continuation.resume(throwing: DocumentError.documentNotFound)
                        return
                    }
                    
                    // TODO: Add archived flag to DocumentModel when schema is updated
                    // document.isArchived = true
                    // document.archivedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Manual trigger for filtering documents
    private func filterDocuments() {
        Task { @MainActor in
            await refreshDocuments()
        }
    }
}

// MARK: - Supporting Types

/// Document filter options
enum DocumentFilter: String, CaseIterable {
    case all = "All"
    case pdf = "PDFs"
    case images = "Images"
    case text = "Text"
    case recent = "Recent"
    case archived = "Archived"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .all:
            return "doc.fill"
        case .pdf:
            return "doc.richtext.fill"
        case .images:
            return "photo.fill"
        case .text:
            return "doc.text.fill"
        case .recent:
            return "clock.fill"
        case .archived:
            return "archivebox.fill"
        }
    }
}

/// Document sort options
enum DocumentSortOption: String, CaseIterable {
    case name = "Name"
    case dateCreated = "Date Created"
    case dateModified = "Date Modified"
    case size = "Size"
    case type = "Type"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .name:
            return "textformat.abc"
        case .dateCreated, .dateModified:
            return "calendar"
        case .size:
            return "arrow.up.arrow.down"
        case .type:
            return "doc.fill"
        }
    }
}

/// Document statistics
struct DocumentStats {
    let total: Int
    let pdf: Int
    let images: Int
    let text: Int
    let recent: Int
}

/// Document errors
enum DocumentError: LocalizedError {
    case documentNotFound
    case deleteError(Error)
    case archiveError(Error)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .deleteError(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .archiveError(let error):
            return "Failed to archive: \(error.localizedDescription)"
        }
    }
} 