import Foundation
import PDFKit
import Vision
import UniformTypeIdentifiers
import NaturalLanguage
import CoreImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Note: EnhancedOCRService and DocumentTypes are in the same module, no explicit import needed

// MARK: - Document Processing Service
class DocumentProcessingService: ObservableObject {
    
    // MARK: - OCR Configuration
    private let minimumConfidenceThreshold: Float = 0.3
    private let highQualityConfidenceThreshold: Float = 0.8
    private let supportedLanguages = ["vi-VN", "en-US", "zh-Hans", "ja-JP", "ko-KR"]
    
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
            extractedText = try await extractTextFromImageWithEnhancements(url)
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
    
    /// Enhanced OCR processing with quality improvements and error correction
    private func extractTextFromImageWithEnhancements(_ url: URL) async throws -> String {
        print("🔍 Starting enhanced OCR processing for: \(url.lastPathComponent)")
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Load and preprocess image
                    #if os(iOS)
                    guard let originalImage = UIImage(contentsOfFile: url.path),
                          let cgImage = originalImage.cgImage else {
                        continuation.resume(throwing: DocumentProcessingError.invalidImage)
                        return
                    }
                    #elseif os(macOS)
                    guard let originalImage = NSImage(contentsOf: url),
                          let cgImage = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        continuation.resume(throwing: DocumentProcessingError.invalidImage)
                        return
                    }
                    #endif
                    
                    // Apply image enhancements for better OCR
                    let enhancedImage = self.applyImageEnhancements(to: cgImage)
                    
                    // Perform OCR with multiple strategies
                    self.performEnhancedOCR(image: enhancedImage) { result in
                        switch result {
                        case .success(let text):
                            print("✅ Enhanced OCR completed: \(text.count) characters")
                            continuation.resume(returning: text)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Apply image enhancement filters for better OCR accuracy
    private func applyImageEnhancements(to cgImage: CGImage) -> CGImage {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // 1. Noise reduction
        guard let noiseReduction = CIFilter(name: "CINoiseReduction") else { return cgImage }
        noiseReduction.setValue(ciImage, forKey: kCIInputImageKey)
        noiseReduction.setValue(0.02, forKey: "inputNoiseLevel")
        noiseReduction.setValue(0.40, forKey: "inputSharpness")
        
        // 2. Contrast enhancement
        guard let contrastFilter = CIFilter(name: "CIColorControls"),
              let noiseReducedImage = noiseReduction.outputImage else { return cgImage }
        contrastFilter.setValue(noiseReducedImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
        contrastFilter.setValue(1.0, forKey: kCIInputBrightnessKey)
        contrastFilter.setValue(1.0, forKey: kCIInputSaturationKey)
        
        // 3. Sharpening for text clarity
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance"),
              let contrastEnhancedImage = contrastFilter.outputImage else { return cgImage }
        sharpenFilter.setValue(contrastEnhancedImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
        
        // 4. Convert back to CGImage
        guard let finalImage = sharpenFilter.outputImage,
              let enhancedCGImage = context.createCGImage(finalImage, from: finalImage.extent) else {
            print("⚠️ Image enhancement failed, using original image")
            return cgImage
        }
        
        print("📈 Applied image enhancements: noise reduction, contrast, sharpening")
        return enhancedCGImage
    }
    
    /// Perform enhanced OCR with multiple strategies and text corrections
    private func performEnhancedOCR(image: CGImage, completion: @escaping (Result<String, Error>) -> Void) {
        
        var allResults: [String] = []
        var bestResult = ""
        var highestConfidence: Float = 0
        let group = DispatchGroup()
        
        // Strategy 1: Accurate recognition
        group.enter()
        let accurateRequest = VNRecognizeTextRequest { request, error in
            defer { group.leave() }
            
            if let error = error {
                print("⚠️ Accurate OCR failed: \(error)")
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            var totalConfidence: Float = 0
            var textSegments: [String] = []
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    textSegments.append(candidate.string)
                    totalConfidence += candidate.confidence
                }
            }
            
            let averageConfidence = observations.isEmpty ? 0 : totalConfidence / Float(observations.count)
            let text = textSegments.joined(separator: "\n")
            
            allResults.append(text)
            if averageConfidence > highestConfidence {
                highestConfidence = averageConfidence
                bestResult = text
            }
            
            print("📊 Accurate OCR: \(text.count) chars, confidence: \(String(format: "%.2f", averageConfidence))")
        }
        
        accurateRequest.recognitionLevel = .accurate
        accurateRequest.usesLanguageCorrection = true
        accurateRequest.recognitionLanguages = supportedLanguages
        accurateRequest.automaticallyDetectsLanguage = true
        
        // Strategy 2: Fast recognition for comparison
        group.enter()
        let fastRequest = VNRecognizeTextRequest { request, error in
            defer { group.leave() }
            
            if let error = error {
                print("⚠️ Fast OCR failed: \(error)")
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            allResults.append(text)
            print("⚡ Fast OCR: \(text.count) chars")
        }
        
        fastRequest.recognitionLevel = .fast
        fastRequest.usesLanguageCorrection = false
        fastRequest.recognitionLanguages = ["vi-VN", "en-US"]
        
        // Perform both requests
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([accurateRequest])
            try handler.perform([fastRequest])
        } catch {
            completion(.failure(error))
            return
        }
        
        // Wait for all requests to complete
        group.notify(queue: .global()) {
            // Apply text corrections and enhancements
            let correctedText = self.applyTextCorrections(bestResult, confidence: highestConfidence)
            completion(.success(correctedText))
        }
    }
    
    /// Apply text corrections and Vietnamese-specific enhancements
    private func applyTextCorrections(_ text: String, confidence: Float) -> String {
        var correctedText = text
        
        // Apply corrections only if confidence is below high threshold
        if confidence < highQualityConfidenceThreshold {
            
            // Fix common OCR errors
            correctedText = fixCommonOCRErrors(correctedText)
            
            // Apply Vietnamese-specific corrections
            correctedText = applyVietnameseCorrections(correctedText)
            
            // Fix formatting issues
            correctedText = fixFormattingIssues(correctedText)
        }
        
        return correctedText
    }
    
    /// Fix common OCR character recognition errors
    private func fixCommonOCRErrors(_ text: String) -> String {
        let commonReplacements: [String: String] = [
            "rn": "m",  // Common OCR confusion
            "vv": "w",  // Common OCR confusion
            "|": "l",   // Vertical bar to l
            "¢": "c"    // Special character to c
        ]
        
        var correctedText = text
        
        for (wrong, correct) in commonReplacements {
            correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
        }
        
        return correctedText
    }
    
    /// Apply Vietnamese-specific text corrections
    private func applyVietnameseCorrections(_ text: String) -> String {
        var correctedText = text
        
        // Fix common Vietnamese word patterns
        let vietnameseWordFixes: [String: String] = [
            "đuợc": "được",
            "nhưrig": "nhưng", 
            "chúrig": "chúng",
            "tliì": "thì",
            "clia": "của",
            "vôi": "với"
        ]
        
        for (wrong, correct) in vietnameseWordFixes {
            correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
        }
        
        return correctedText
    }
    
    /// Fix formatting issues in extracted text
    private func fixFormattingIssues(_ text: String) -> String {
        var correctedText = text
        
        // Fix multiple spaces
        correctedText = correctedText.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Fix line breaks
        correctedText = correctedText.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Fix punctuation spacing
        correctedText = correctedText.replacingOccurrences(
            of: "\\s+([.,:;!?])",
            with: "$1",
            options: .regularExpression
        )
        
        // Add space after punctuation if missing
        correctedText = correctedText.replacingOccurrences(
            of: "([.,:;!?])([A-Za-z])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        return correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
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