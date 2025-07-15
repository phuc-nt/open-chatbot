import Foundation
import PDFKit
import Vision
import UniformTypeIdentifiers
import NaturalLanguage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Document Processing Service
class DocumentProcessingService: ObservableObject {
    
    // MARK: - Public Methods
    
    /// Process a document from URL and return processed data
    func processDocument(_ url: URL) async throws -> ProcessedDocument {
        
        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Determine document type
        let documentType = determineDocumentType(from: url)
        
        // Extract text based on document type
        let extractedText: String
        var pageCount: Int32 = 0
        
        switch documentType {
        case .pdf:
            let result = try await extractTextFromPDF(url)
            extractedText = result.text
            pageCount = result.pageCount
            
        case .image, .imagePNG:
            extractedText = try await extractTextFromImage(url)
            pageCount = 1
            
        case .text:
            extractedText = try String(contentsOf: url, encoding: .utf8)
            pageCount = 1
            
        case .unknown:
            throw DocumentProcessingError.unsupportedFormat
        }
        
        // Create processed document
        let processedDocument = ProcessedDocument(
            id: UUID().uuidString,
            title: url.deletingPathExtension().lastPathComponent,
            fileName: url.lastPathComponent,
            fileURL: url,
            fileSize: fileSize,
            type: documentType,
            pageCount: pageCount,
            content: extractedText,
            detectedLanguage: detectLanguage(text: extractedText),
            createdAt: Date()
        )
        
        return processedDocument
    }
    
    // MARK: - Private Methods
    
    private func determineDocumentType(from url: URL) -> DocumentType {
        guard let typeIdentifier = UTType(filenameExtension: url.pathExtension) else {
            return .unknown
        }
        
        if typeIdentifier.conforms(to: .pdf) {
            return .pdf
        } else if typeIdentifier.conforms(to: .image) {
            return url.pathExtension.lowercased() == "png" ? .imagePNG : .image
        } else if typeIdentifier.conforms(to: .plainText) {
            return .text
        } else {
            return .unknown
        }
    }
    
    private func extractTextFromPDF(_ url: URL) async throws -> (text: String, pageCount: Int32) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pdfDocument = PDFDocument(url: url) else {
                    continuation.resume(throwing: DocumentProcessingError.invalidPDF)
                    return
                }
                
                var extractedText = ""
                let pageCount = pdfDocument.pageCount
                
                for pageIndex in 0..<pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    if let pageText = page.string {
                        extractedText += pageText + "\n"
                    }
                }
                
                continuation.resume(returning: (extractedText, Int32(pageCount)))
            }
        }
    }
    
    private func extractTextFromImage(_ url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            
            #if os(iOS)
            guard let image = UIImage(contentsOfFile: url.path),
                  let cgImage = image.cgImage else {
                continuation.resume(throwing: DocumentProcessingError.invalidImage)
                return
            }
            #elseif os(macOS)
            guard let image = NSImage(contentsOf: url),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continuation.resume(throwing: DocumentProcessingError.invalidImage)
                return
            }
            #endif
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            // Configure for Vietnamese text
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectLanguage(text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }
        
        return nil
    }
}

// Document types moved to DocumentTypes.swift

// MARK: - Document Processing Errors
enum DocumentProcessingError: LocalizedError {
    case unsupportedFormat
    case invalidPDF
    case invalidImage
    case textExtractionFailed
    case fileNotFound
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported document format"
        case .invalidPDF:
            return "Invalid PDF file"
        case .invalidImage:
            return "Invalid image file"
        case .textExtractionFailed:
            return "Failed to extract text from document"
        case .fileNotFound:
            return "File not found"
        case .permissionDenied:
            return "Permission denied to access file"
        }
    }
}

// MARK: - Helper Extensions
extension DocumentProcessingService {
    
    /// Get supported file types for document picker
    static var supportedTypes: [UTType] {
        return [.pdf, .png, .jpeg, .plainText]
    }
    
    /// Check if file type is supported
    static func isSupported(_ url: URL) -> Bool {
        guard let typeIdentifier = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        
        return supportedTypes.contains { typeIdentifier.conforms(to: $0) }
    }
} 