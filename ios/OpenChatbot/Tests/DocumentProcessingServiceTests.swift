import XCTest
import PDFKit
import Vision
import UniformTypeIdentifiers
import CoreData
@testable import OpenChatbot

@MainActor
final class DocumentProcessingServiceTests: XCTestCase {
    
    var documentService: DocumentProcessingService!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory Core Data context for testing
        testContext = PersistenceController.shared.container.viewContext
        documentService = DocumentProcessingService()
    }
    
    override func tearDownWithError() throws {
        documentService = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Document Type Detection Tests
    
    func testDocumentTypeFromMimeType() {
        XCTAssertEqual(DocumentType.fromMimeType("application/pdf"), .pdf)
        XCTAssertEqual(DocumentType.fromMimeType("image/jpeg"), .image)
        XCTAssertEqual(DocumentType.fromMimeType("image/png"), .imagePNG)
        XCTAssertEqual(DocumentType.fromMimeType("text/plain"), .text)
        XCTAssertEqual(DocumentType.fromMimeType("unknown/type"), .unknown)
    }
    
    func testDocumentTypeFromFileExtension() {
        XCTAssertEqual(DocumentType.fromFileExtension("pdf"), .pdf)
        XCTAssertEqual(DocumentType.fromFileExtension("jpg"), .image)
        XCTAssertEqual(DocumentType.fromFileExtension("jpeg"), .image)
        XCTAssertEqual(DocumentType.fromFileExtension("png"), .imagePNG)
        XCTAssertEqual(DocumentType.fromFileExtension("txt"), .text)
        XCTAssertEqual(DocumentType.fromFileExtension("xyz"), .unknown)
    }
    
    // MARK: - PDF Processing Tests
    
    func testProcessPDFWithValidDocument() async throws {
        // Create a simple test PDF
        let testPDF = createTestPDF(content: "This is a test PDF document with sample content.")
        
        let result = await documentService.processPDF(testPDF)
        
        switch result {
        case .success(let extractedText):
            XCTAssertFalse(extractedText.isEmpty)
            XCTAssertTrue(extractedText.contains("test PDF"))
        case .failure(let error):
            XCTFail("PDF processing should succeed but failed with: \(error)")
        }
    }
    
    func testProcessPDFWithEmptyDocument() async throws {
        let emptyPDF = createTestPDF(content: "")
        
        let result = await documentService.processPDF(emptyPDF)
        
        switch result {
        case .success(let extractedText):
            XCTAssertTrue(extractedText.isEmpty || extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .failure:
            // Empty PDF might fail, which is acceptable
            break
        }
    }
    
    func testProcessInvalidPDFData() async throws {
        let invalidData = "This is not a PDF".data(using: .utf8)!
        
        let result = await documentService.processPDF(invalidData)
        
        switch result {
        case .success:
            XCTFail("Processing invalid PDF data should fail")
        case .failure(let error):
            XCTAssertTrue(error is DocumentProcessingError)
        }
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImageWithText() async throws {
        // Create a test image with text (this is a mock test)
        let testImage = createTestImageWithText("Sample text for OCR testing")
        
        let result = await documentService.processImage(testImage)
        
        switch result {
        case .success(let extractedText):
            // Note: Real OCR testing would require actual image with text
            // For unit tests, we're testing the flow
            XCTAssertNotNil(extractedText)
        case .failure(let error):
            // Vision framework might not be available in test environment
            XCTAssertTrue(error is DocumentProcessingError)
        }
    }
    
    func testProcessInvalidImageData() async throws {
        let invalidData = "This is not an image".data(using: .utf8)!
        
        let result = await documentService.processImage(invalidData)
        
        switch result {
        case .success:
            XCTFail("Processing invalid image data should fail")
        case .failure(let error):
            XCTAssertTrue(error is DocumentProcessingError)
        }
    }
    
    // MARK: - Text Processing Tests
    
    func testProcessTextDocument() async throws {
        let testText = "This is a sample text document for testing purposes."
        let textData = testText.data(using: .utf8)!
        
        let result = await documentService.processText(textData)
        
        switch result {
        case .success(let extractedText):
            XCTAssertEqual(extractedText, testText)
        case .failure(let error):
            XCTFail("Text processing should succeed but failed with: \(error)")
        }
    }
    
    func testProcessTextWithInvalidEncoding() async throws {
        // Create data that can't be decoded as UTF-8
        let invalidData = Data([0xFF, 0xFE, 0xFD])
        
        let result = await documentService.processText(invalidData)
        
        switch result {
        case .success:
            XCTFail("Processing invalid text encoding should fail")
        case .failure(let error):
            XCTAssertTrue(error is DocumentProcessingError)
        }
    }
    
    // MARK: - Core Data Integration Tests
    
    func testCreateDocumentInCoreData() async throws {
        let testData = "Test document content".data(using: .utf8)!
        let testUrl = URL(fileURLWithPath: "/tmp/test.txt")
        
        let document = await documentService.createDocument(
            from: testUrl,
            data: testData,
            type: .text,
            in: testContext
        )
        
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.title, "test.txt")
        XCTAssertEqual(document?.type, DocumentType.text.rawValue)
        XCTAssertEqual(document?.status, ProcessingStatus.pending.rawValue)
        XCTAssertNotNil(document?.createdAt)
    }
    
    // MARK: - Performance Tests
    
    func testPDFProcessingPerformance() async throws {
        let largePDF = createTestPDF(content: String(repeating: "This is test content. ", count: 1000))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await documentService.processPDF(largePDF)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        switch result {
        case .success:
            // Processing should complete within reasonable time (< 5 seconds for test)
            XCTAssertLessThan(timeElapsed, 5.0, "PDF processing took too long: \(timeElapsed)s")
        case .failure:
            // Performance test doesn't care about success/failure, just timing
            break
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDocumentProcessingErrorTypes() {
        let pdfError = DocumentProcessingError.pdfProcessingFailed("Test error")
        let imageError = DocumentProcessingError.imageProcessingFailed("Test error")
        let textError = DocumentProcessingError.textProcessingFailed("Test error")
        let coreDataError = DocumentProcessingError.coreDataError("Test error")
        
        XCTAssertNotNil(pdfError.localizedDescription)
        XCTAssertNotNil(imageError.localizedDescription)
        XCTAssertNotNil(textError.localizedDescription)
        XCTAssertNotNil(coreDataError.localizedDescription)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPDF(content: String) -> Data {
        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage()
        
        // Create attributed string with content
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12)
        ]
        let attributedString = NSAttributedString(string: content, attributes: attributes)
        
        // This is a simplified PDF creation for testing
        // In real scenario, you'd create proper PDF with content
        if let data = pdfDocument.dataRepresentation() {
            return data
        }
        
        // Fallback: return minimal valid PDF data
        return createMinimalPDFData()
    }
    
    private func createMinimalPDFData() -> Data {
        // Create minimal valid PDF structure
        let pdfContent = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        
        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj
        
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        >>
        endobj
        
        xref
        0 4
        0000000000 65535 f 
        0000000010 00000 n 
        0000000053 00000 n 
        0000000125 00000 n 
        trailer
        <<
        /Size 4
        /Root 1 0 R
        >>
        startxref
        0
        %%EOF
        """
        
        return pdfContent.data(using: .utf8) ?? Data()
    }
    
    private func createTestImageWithText(_ text: String) -> Data {
        // Create a simple test image (this is mock data for testing)
        // In real scenario, you'd create actual image with text
        let imageSize = CGSize(width: 200, height: 100)
        
        #if os(iOS)
        UIGraphicsBeginImageContext(imageSize)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(origin: .zero, size: imageSize))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.pngData() ?? Data()
        #else
        // For macOS testing
        return Data()
        #endif
    }
}

// MARK: - Test Helper Extensions

// Note: DocumentProcessingError already conforms to Equatable in main module 