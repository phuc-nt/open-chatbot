import XCTest
import SwiftUI
@testable import OpenChatbot

@MainActor
final class DocumentUploadViewTests: XCTestCase {
    
    // MARK: - View State Tests
    
    func testDocumentUploadViewInitialState() {
        // Given & When
        let view = DocumentUploadView()
        
        // Then - View should initialize without crashing
        XCTAssertNotNil(view)
    }
    
    // MARK: - File Type Support Tests
    
    func testSupportedFileTypes() {
        // Test known supported document types
        XCTAssertNotEqual(DocumentType.pdf, .unknown, "PDF should be supported")
        XCTAssertNotEqual(DocumentType.text, .unknown, "Text should be supported")
        XCTAssertNotEqual(DocumentType.image, .unknown, "Image should be supported")
        XCTAssertNotEqual(DocumentType.imagePNG, .unknown, "PNG should be supported")
        
        // Test DocumentType enum cases
        XCTAssertEqual(DocumentType.pdf.displayName, "PDF")
        XCTAssertEqual(DocumentType.text.displayName, "Text")
        XCTAssertEqual(DocumentType.image.displayName, "Image")
    }
    
    // MARK: - DocumentUploadViewModel Tests
    
    func testDocumentUploadViewModelInitialState() {
        // Given
        let viewModel = DocumentUploadViewModel()
        
        // When & Then
        XCTAssertEqual(viewModel.selectedDocuments.count, 0)
        XCTAssertEqual(viewModel.processingTasks.count, 0)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testAddDocumentToSelection() {
        // Given
        let viewModel = DocumentUploadViewModel()
        let testURL = createTestDocumentURL()
        
        // When
        viewModel.selectedDocuments.append(testURL)
        
        // Then
        XCTAssertEqual(viewModel.selectedDocuments.count, 1)
        XCTAssertEqual(viewModel.selectedDocuments.first, testURL)
    }
    
    func testRemoveDocumentFromSelection() {
        // Given
        let viewModel = DocumentUploadViewModel()
        let testURL1 = createTestDocumentURL(name: "test1.pdf")
        let testURL2 = createTestDocumentURL(name: "test2.pdf")
        viewModel.selectedDocuments = [testURL1, testURL2]
        
        // When
        viewModel.selectedDocuments.removeAll { $0 == testURL1 }
        
        // Then
        XCTAssertEqual(viewModel.selectedDocuments.count, 1)
        XCTAssertEqual(viewModel.selectedDocuments.first, testURL2)
    }
    
    // MARK: - Processing State Tests
    
    func testProcessingStateManagement() {
        // Given
        let viewModel = DocumentUploadViewModel()
        
        // When - Start processing
        viewModel.isProcessing = true
        
        // Then
        XCTAssertTrue(viewModel.isProcessing)
        
        // When - Stop processing
        viewModel.isProcessing = false
        
        // Then
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testProcessingTasksManagement() {
        // Given
        let viewModel = DocumentUploadViewModel()
        let task1 = ProcessingTask(id: "1", fileName: "test1.pdf", status: .pending)
        let task2 = ProcessingTask(id: "2", fileName: "test2.pdf", status: .processing)
        
        // When
        viewModel.backgroundTasks["1"] = task1
        viewModel.backgroundTasks["2"] = task2
        
        // Then
        XCTAssertEqual(viewModel.processingTasks.count, 2)
        XCTAssertTrue(viewModel.processingTasks.contains { $0.status == .pending })
        XCTAssertTrue(viewModel.processingTasks.contains { $0.status == .processing })
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageHandling() {
        // Given
        let viewModel = DocumentUploadViewModel()
        let errorMessage = "Test error message"
        
        // When
        viewModel.errorMessage = errorMessage
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
    }
    
    // MARK: - File Validation Tests
    
    func testFileValidation() {
        let validExtensions = ["pdf", "txt", "doc", "docx", "jpg", "png", "jpeg"]
        
        for ext in validExtensions {
            let filename = "test.\(ext)"
            let isValid = isValidFileType(filename)
            XCTAssertTrue(isValid, "File with extension .\(ext) should be valid")
        }
        
        // Test invalid extensions
        let invalidExtensions = ["exe", "bat", "sh"]
        for ext in invalidExtensions {
            let filename = "test.\(ext)"
            let isValid = isValidFileType(filename)
            XCTAssertFalse(isValid, "File with extension .\(ext) should be invalid")
        }
    }
    
    // MARK: - Test Helpers
    
    private func createTestDocumentURL(name: String = "test.pdf") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent(name)
    }
    
    private func isValidFileType(_ filename: String) -> Bool {
        let validExtensions = ["pdf", "txt", "doc", "docx", "jpg", "png", "jpeg"]
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.lowercased()
        return validExtensions.contains(fileExtension)
    }
}

// MARK: - Mock Processing Task
// Note: ProcessingTask and ProcessingStatus are defined in DocumentTypes.swift 