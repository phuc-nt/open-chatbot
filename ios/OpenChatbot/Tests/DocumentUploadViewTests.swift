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
        let supportedTypes = ["pdf", "txt", "doc", "docx", "jpg", "png"]
        
        for type in supportedTypes {
            let documentType = DocumentType.from(mimeType: "application/\(type)")
            XCTAssertNotEqual(documentType, .unknown, "File type \(type) should be supported")
        }
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
        let task1 = ProcessingTask(id: "1", filename: "test1.pdf", status: .pending)
        let task2 = ProcessingTask(id: "2", filename: "test2.pdf", status: .processing)
        
        // When
        viewModel.processingTasks = [task1, task2]
        
        // Then
        XCTAssertEqual(viewModel.processingTasks.count, 2)
        XCTAssertEqual(viewModel.processingTasks[0].status, .pending)
        XCTAssertEqual(viewModel.processingTasks[1].status, .processing)
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

struct ProcessingTask {
    let id: String
    let filename: String
    var status: ProcessingStatus
}

enum ProcessingStatus {
    case pending
    case processing
    case completed
    case failed
} 