import XCTest
@testable import OpenChatbot

final class DocumentTypesTests: XCTestCase {
    
    // MARK: - DocumentType Tests
    
    func testDocumentTypeRawValues() {
        XCTAssertEqual(DocumentType.pdf.rawValue, "application/pdf")
        XCTAssertEqual(DocumentType.image.rawValue, "image/jpeg")
        XCTAssertEqual(DocumentType.imagePNG.rawValue, "image/png")
        XCTAssertEqual(DocumentType.text.rawValue, "text/plain")
        XCTAssertEqual(DocumentType.unknown.rawValue, "unknown")
    }
    
    func testDocumentTypeDisplayNames() {
        XCTAssertEqual(DocumentType.pdf.displayName, "PDF")
        XCTAssertEqual(DocumentType.image.displayName, "Image")
        XCTAssertEqual(DocumentType.imagePNG.displayName, "Image")
        XCTAssertEqual(DocumentType.text.displayName, "Text")
        XCTAssertEqual(DocumentType.unknown.displayName, "Unknown")
    }
    
    func testDocumentTypeSystemImageNames() {
        XCTAssertEqual(DocumentType.pdf.systemImageName, "doc.fill")
        XCTAssertEqual(DocumentType.image.systemImageName, "photo.fill")
        XCTAssertEqual(DocumentType.imagePNG.systemImageName, "photo.fill")
        XCTAssertEqual(DocumentType.text.systemImageName, "doc.text.fill")
        XCTAssertEqual(DocumentType.unknown.systemImageName, "questionmark.circle.fill")
    }
    
    func testDocumentTypeCaseIterable() {
        let allCases = DocumentType.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.pdf))
        XCTAssertTrue(allCases.contains(.image))
        XCTAssertTrue(allCases.contains(.imagePNG))
        XCTAssertTrue(allCases.contains(.text))
        XCTAssertTrue(allCases.contains(.unknown))
    }
    
    // MARK: - ProcessingStatus Tests
    
    func testProcessingStatusRawValues() {
        XCTAssertEqual(ProcessingStatus.pending.rawValue, "pending")
        XCTAssertEqual(ProcessingStatus.processing.rawValue, "processing")
        XCTAssertEqual(ProcessingStatus.completed.rawValue, "completed")
        XCTAssertEqual(ProcessingStatus.failed.rawValue, "failed")
    }
    
    func testProcessingStatusDisplayNames() {
        XCTAssertEqual(ProcessingStatus.pending.displayName, "Pending")
        XCTAssertEqual(ProcessingStatus.processing.displayName, "Processing")
        XCTAssertEqual(ProcessingStatus.completed.displayName, "Completed")
        XCTAssertEqual(ProcessingStatus.failed.displayName, "Failed")
    }
    
    func testProcessingStatusColors() {
        XCTAssertEqual(ProcessingStatus.pending.color, "orange")
        XCTAssertEqual(ProcessingStatus.processing.color, "blue")
        XCTAssertEqual(ProcessingStatus.completed.color, "green")
        XCTAssertEqual(ProcessingStatus.failed.color, "red")
    }
    
    func testProcessingStatusCaseIterable() {
        let allCases = ProcessingStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.processing))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.failed))
    }
    
    // MARK: - ProcessedDocument Tests
    
    func testProcessedDocumentCreation() {
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let testDate = Date()
        
        let processedDoc = ProcessedDocument(
            id: "test-id",
            title: "Test Document",
            fileName: "test.pdf",
            fileURL: testURL,
            fileSize: 1024,
            type: .pdf,
            pageCount: 5,
            content: "This is test content",
            detectedLanguage: "en",
            createdAt: testDate
        )
        
        XCTAssertEqual(processedDoc.id, "test-id")
        XCTAssertEqual(processedDoc.title, "Test Document")
        XCTAssertEqual(processedDoc.fileName, "test.pdf")
        XCTAssertEqual(processedDoc.fileURL, testURL)
        XCTAssertEqual(processedDoc.fileSize, 1024)
        XCTAssertEqual(processedDoc.type, .pdf)
        XCTAssertEqual(processedDoc.pageCount, 5)
        XCTAssertEqual(processedDoc.content, "This is test content")
        XCTAssertEqual(processedDoc.detectedLanguage, "en")
        XCTAssertEqual(processedDoc.createdAt, testDate)
    }
    
    // MARK: - ProcessingTask Tests
    
    func testProcessingTaskCreation() {
        let taskId = "task-123"
        let task = ProcessingTask(
            id: taskId,
            fileName: "document.pdf",
            status: .processing
        )
        
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.fileName, "document.pdf")
        XCTAssertEqual(task.status, .processing)
    }
    
    func testProcessingTaskStatusUpdates() {
        var task = ProcessingTask(
            id: "task-456",
            fileName: "test.txt",
            status: .pending
        )
        
        // Test status progression
        XCTAssertEqual(task.status, .pending)
        
        task.status = .processing
        XCTAssertEqual(task.status, .processing)
        
        task.status = .completed
        XCTAssertEqual(task.status, .completed)
    }
    
    func testProcessingTaskWithFailedStatus() {
        let task = ProcessingTask(
            id: "failed-task",
            fileName: "corrupt.pdf",
            status: .failed
        )
        
        XCTAssertEqual(task.status, .failed)
        XCTAssertEqual(task.status.displayName, "Failed")
        XCTAssertEqual(task.status.color, "red")
    }
} 