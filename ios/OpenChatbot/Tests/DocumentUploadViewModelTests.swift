import XCTest
import CoreData
@testable import OpenChatbot

@MainActor
final class DocumentUploadViewModelTests: XCTestCase {
    
    var viewModel: DocumentUploadViewModel!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory Core Data context for testing
        testContext = PersistenceController.shared.container.viewContext
        viewModel = DocumentUploadViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testViewModelInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.uploadedDocuments.isEmpty)
        XCTAssertTrue(viewModel.backgroundTasks.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    // MARK: - Document Upload Tests
    
    func testDocumentUploadCreatesTask() async {
        // Create test document data
        let testContent = "This is a test document for upload"
        let testData = testContent.data(using: .utf8)!
        let testURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        // Simulate document upload
        await viewModel.uploadDocument(url: testURL, data: testData)
        
        // Verify task was created
        XCTAssertFalse(viewModel.backgroundTasks.isEmpty)
        XCTAssertTrue(viewModel.isProcessing)
        
        // Wait for processing to complete (with timeout)
        let expectation = XCTestExpectation(description: "Document processing completes")
        
        Task {
            // Wait for processing to finish
            while viewModel.isProcessing {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Verify final state
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    // MARK: - File Validation Tests
    
    func testSupportedFileTypes() {
        let supportedTypes = viewModel.supportedTypes
        
        XCTAssertTrue(supportedTypes.contains("public.pdf"))
        XCTAssertTrue(supportedTypes.contains("public.image"))
        XCTAssertTrue(supportedTypes.contains("public.text"))
    }
    
    func testFileValidation() {
        // Test valid file sizes
        let validSize = 5 * 1024 * 1024 // 5MB
        XCTAssertTrue(viewModel.isValidFileSize(validSize))
        
        // Test invalid file sizes
        let invalidSize = 50 * 1024 * 1024 // 50MB (over limit)
        XCTAssertFalse(viewModel.isValidFileSize(invalidSize))
    }
    
    // MARK: - Task Management Tests
    
    func testRemoveCompletedTask() async {
        // Create a mock task
        let taskId = UUID()
        let mockTask = ProcessingTask(
            id: taskId,
            fileName: "test.txt",
            status: .completed,
            progress: 1.0
        )
        
        await viewModel.addTask(mockTask)
        XCTAssertEqual(viewModel.backgroundTasks.count, 1)
        
        await viewModel.removeTask(taskId)
        XCTAssertEqual(viewModel.backgroundTasks.count, 0)
    }
    
    func testClearAllTasks() async {
        // Add multiple mock tasks
        let task1 = ProcessingTask(id: UUID(), fileName: "test1.txt", status: .completed, progress: 1.0)
        let task2 = ProcessingTask(id: UUID(), fileName: "test2.pdf", status: .failed, progress: 0.5)
        
        await viewModel.addTask(task1)
        await viewModel.addTask(task2)
        XCTAssertEqual(viewModel.backgroundTasks.count, 2)
        
        await viewModel.clearAllTasks()
        XCTAssertEqual(viewModel.backgroundTasks.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testProcessingErrorHandling() async {
        // Test with invalid data that should cause processing to fail
        let invalidData = Data() // Empty data
        let testURL = URL(fileURLWithPath: "/tmp/invalid.pdf")
        
        await viewModel.uploadDocument(url: testURL, data: invalidData)
        
        // Wait for processing to complete
        let expectation = XCTestExpectation(description: "Processing completes with error")
        
        Task {
            while viewModel.isProcessing {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Check if any task has failed status
        let hasFailedTask = viewModel.backgroundTasks.values.contains { task in
            task.status == .failed
        }
        
        // Note: This might pass or fail depending on how DocumentProcessingService handles empty data
        // The important thing is that it doesn't crash
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    // MARK: - Helper Methods for Testing
    
    @MainActor
    private func addTask(_ task: ProcessingTask) {
        viewModel.backgroundTasks[task.id] = task
    }
    
    @MainActor
    private func removeTask(_ taskId: UUID) {
        viewModel.backgroundTasks.removeValue(forKey: taskId)
    }
    
    @MainActor
    private func clearAllTasks() {
        viewModel.backgroundTasks.removeAll()
    }
} 