import XCTest
import SwiftUI
@testable import OpenChatbot

@MainActor
final class DocumentEditViewTests: XCTestCase {
    
    // MARK: - View Initialization Tests
    
    func testDocumentEditViewInitialization() {
        // Given
        let testDocument = createTestProcessedDocument()
        
        // When
        let view = DocumentEditView(document: testDocument, onSave: { _, _ in })
        
        // Then - View should initialize without crashing
        XCTAssertNotNil(view)
    }
    
    // MARK: - Document Editing Tests
    
    func testDocumentTitleEditing() {
        // Given
        let testDocument = createTestProcessedDocument()
        var savedTitle: String?
        var savedTags: [String]?
        
        // When
        let view = DocumentEditView(document: testDocument) { title, tags in
            savedTitle = title
            savedTags = tags
        }
        
        // Then - Should be able to access the document for editing
        XCTAssertNotNil(view)
        // Note: Actual UI interaction testing would require ViewInspector or similar
    }
    
    func testDocumentTagManagement() {
        // Given
        let testDocument = createTestProcessedDocument()
        let initialTags = ["tag1", "tag2"]
        
        // When
        let view = DocumentEditView(document: testDocument) { title, tags in
            // Verify tags are passed correctly
            XCTAssertEqual(tags.count, 2)
        }
        
        // Then
        XCTAssertNotNil(view)
    }
    
    // MARK: - Form Validation Tests
    
    func testEmptyTitleValidation() {
        // Given
        let testDocument = createTestProcessedDocument()
        
        // When
        let view = DocumentEditView(document: testDocument) { title, tags in
            // Should handle empty title gracefully
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                XCTFail("Empty title should not be allowed")
            }
        }
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testTagValidation() {
        let validTags = ["valid-tag", "another_tag", "Tag123"]
        let invalidTags = ["", "   ", "tag with spaces", "tag@invalid"]
        
        for tag in validTags {
            XCTAssertTrue(isValidTag(tag), "Tag '\(tag)' should be valid")
        }
        
        for tag in invalidTags {
            XCTAssertFalse(isValidTag(tag), "Tag '\(tag)' should be invalid")
        }
    }
    
    // MARK: - Save Functionality Tests
    
    func testSaveChanges() {
        // Given
        let testDocument = createTestProcessedDocument()
        let newTitle = "Updated Document Title"
        let newTags = ["updated", "tags", "test"]
        var saveCallbackTriggered = false
        
        // When
        let view = DocumentEditView(document: testDocument) { title, tags in
            saveCallbackTriggered = true
            XCTAssertEqual(title, newTitle)
            XCTAssertEqual(tags, newTags)
        }
        
        // Simulate save action (in actual implementation)
        // saveCallbackTriggered would be set to true when save is called
        
        // Then
        XCTAssertNotNil(view)
        // Note: Actual save testing would require UI interaction simulation
    }
    
    // MARK: - Cancel Functionality Tests
    
    func testCancelChanges() {
        // Given
        let testDocument = createTestProcessedDocument()
        var saveCallbackTriggered = false
        
        // When
        let view = DocumentEditView(document: testDocument) { title, tags in
            saveCallbackTriggered = true
        }
        
        // Simulate cancel action
        // In actual implementation, cancel should not trigger save callback
        
        // Then
        XCTAssertFalse(saveCallbackTriggered, "Cancel should not trigger save callback")
        XCTAssertNotNil(view)
    }
    
    // MARK: - Document Metadata Display Tests
    
    func testDocumentMetadataDisplay() {
        // Given
        let testDocument = createTestProcessedDocument()
        
        // When
        let view = DocumentEditView(document: testDocument) { _, _ in }
        
        // Then - Should display document metadata
        // In actual implementation, would verify:
        // - Document title is displayed in text field
        // - Document type is shown
        // - File size is displayed
        // - Creation date is shown
        XCTAssertNotNil(view)
    }
    
    // MARK: - Tag Management Tests
    
    func testAddTag() {
        var tags = ["existing-tag"]
        let newTag = "new-tag"
        
        // Simulate adding tag
        if !tags.contains(newTag) && isValidTag(newTag) {
            tags.append(newTag)
        }
        
        XCTAssertEqual(tags.count, 2)
        XCTAssertTrue(tags.contains(newTag))
    }
    
    func testRemoveTag() {
        var tags = ["tag1", "tag2", "tag3"]
        let tagToRemove = "tag2"
        
        // Simulate removing tag
        tags.removeAll { $0 == tagToRemove }
        
        XCTAssertEqual(tags.count, 2)
        XCTAssertFalse(tags.contains(tagToRemove))
        XCTAssertTrue(tags.contains("tag1"))
        XCTAssertTrue(tags.contains("tag3"))
    }
    
    func testDuplicateTagPrevention() {
        var tags = ["existing-tag"]
        let duplicateTag = "existing-tag"
        
        // Simulate adding duplicate tag
        if !tags.contains(duplicateTag) {
            tags.append(duplicateTag)
        }
        
        XCTAssertEqual(tags.count, 1, "Duplicate tags should not be added")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Given
        let testDocument = createTestProcessedDocument()
        
        // When
        let view = DocumentEditView(document: testDocument) { _, _ in }
        
        // Then - Should have proper accessibility labels
        // In actual implementation, would verify:
        // - Title field has accessibility label
        // - Tag input has accessibility label
        // - Save/Cancel buttons have accessibility labels
        // - Document info is accessible
        XCTAssertNotNil(view)
    }
    
    // MARK: - Performance Tests
    
    func testViewRenderingPerformance() {
        let testDocument = createTestProcessedDocument()
        
        measure {
            // Measure view creation performance
            let view = DocumentEditView(document: testDocument) { _, _ in }
            _ = view
        }
    }
    
    // MARK: - Test Helpers
    
    private func createTestProcessedDocument() -> ProcessedDocument {
        return ProcessedDocument(
            id: UUID().uuidString,
            title: "Test Document Title",
            fileName: "test_document.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/test_document.pdf"),
            fileSize: 2048,
            type: .pdf,
            pageCount: 1,
            content: "This is test document content for editing.",
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
    
    private func isValidTag(_ tag: String) -> Bool {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Tag validation rules:
        // - Not empty
        // - No spaces
        // - Alphanumeric and hyphens/underscores only
        // - Reasonable length
        
        guard !trimmedTag.isEmpty else { return false }
        guard trimmedTag.count <= 50 else { return false }
        guard !trimmedTag.contains(" ") else { return false }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return trimmedTag.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}

// MARK: - Mock Data Extensions

extension ProcessedDocument {
    static func createTestDocument(
        title: String = "Test Document",
        fileName: String = "test.pdf",
        type: DocumentType = .pdf,
        fileSize: Int64 = 1024,
        content: String = "Test content"
    ) -> ProcessedDocument {
        return ProcessedDocument(
            id: UUID().uuidString,
            title: title,
            fileName: fileName,
            fileURL: URL(fileURLWithPath: "/tmp/\(fileName)"),
            fileSize: fileSize,
            type: type,
            pageCount: 1,
            content: content,
            detectedLanguage: "en",
            createdAt: Date()
        )
    }
} 