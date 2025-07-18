import Foundation
import SwiftUI
import CoreData

// MARK: - Document Detail ViewModel
@MainActor
class DocumentDetailViewModel: ObservableObject {
    @Published var tags: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let dataService = DataService()
    private var currentDocument: ProcessedDocument?
    
    // MARK: - Public Methods
    
    /// Load document details and metadata
    func loadDocument(_ document: ProcessedDocument) {
        currentDocument = document
        // Initialize with empty tags for now
        tags = []
    }
    
    /// Save document metadata changes
    func saveChanges(title: String, tags: [String]) async {
        guard currentDocument != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Update local state
        self.tags = tags
        
        // TODO: Implement actual Core Data saving when DocumentEntity structure is confirmed
    }
    
    /// Update document title
    func updateTitle(_ newTitle: String) {
        // TODO: Implement title update logic
        print("Updating title to: \(newTitle)")
    }
    
    /// Update document tags
    func updateTags(_ newTags: [String]) {
        tags = newTags
        // TODO: Implement tags update persistence
        print("Updating tags to: \(newTags)")
    }
    
    // MARK: - Tag Management
    
    /// Add a new tag
    func addTag(_ tagName: String) {
        let trimmedTag = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
        }
    }
    
    /// Remove a tag
    func removeTag(_ tagName: String) {
        tags.removeAll { $0 == tagName }
    }
    
    /// Toggle tag presence
    func toggleTag(_ tagName: String) {
        if tags.contains(tagName) {
            removeTag(tagName)
        } else {
            addTag(tagName)
        }
    }
} 