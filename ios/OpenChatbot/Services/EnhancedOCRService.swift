import Foundation
import Vision
import NaturalLanguage
import CoreImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Enhanced OCR Service

/// Advanced OCR service with quality improvements, confidence scoring, and error correction
class EnhancedOCRService: ObservableObject {
    
    // MARK: - Configuration
    private let minimumConfidenceThreshold: Float = 0.3
    private let highQualityConfidenceThreshold: Float = 0.8
    private let supportedLanguages = ["vi-VN", "en-US", "zh-Hans", "ja-JP", "ko-KR"]
    
    // MARK: - Main OCR Processing
    
    /// Enhanced OCR processing with quality improvements and confidence scoring
    func extractTextWithQualityAnalysis(from url: URL) async throws -> OCRResult {
        print("🔍 Starting enhanced OCR processing for: \(url.lastPathComponent)")
        
        // Load and preprocess image
        let preprocessedImage = try await preprocessImageForOCR(url: url)
        
        // Perform OCR with multiple strategies
        let ocrResults = try await performMultiStrategyOCR(image: preprocessedImage)
        
        // Apply post-processing and quality improvements
        let enhancedResult = try await enhanceOCRResult(ocrResults)
        
        print("✅ Enhanced OCR completed: \(enhancedResult.extractedText.count) characters, confidence: \(String(format: "%.2f", enhancedResult.averageConfidence))")
        
        return enhancedResult
    }
    
    // MARK: - Image Preprocessing
    
    /// Preprocess image for optimal OCR results
    private func preprocessImageForOCR(url: URL) async throws -> CGImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Load original image
                    #if os(iOS)
                    guard let originalImage = UIImage(contentsOfFile: url.path),
                          let cgImage = originalImage.cgImage else {
                        continuation.resume(throwing: OCRProcessingError.invalidImage)
                        return
                    }
                    #elseif os(macOS)
                    guard let originalImage = NSImage(contentsOf: url),
                          let cgImage = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                        continuation.resume(throwing: OCRProcessingError.invalidImage)
                        return
                    }
                    #endif
                    
                    // Apply image enhancements
                    let enhancedImage = self.applyImageEnhancements(to: cgImage)
                    continuation.resume(returning: enhancedImage)
                    
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
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey) // Slightly increase contrast
        contrastFilter.setValue(1.0, forKey: kCIInputBrightnessKey) // Maintain brightness
        contrastFilter.setValue(1.0, forKey: kCIInputSaturationKey) // Maintain saturation
        
        // 3. Sharpening for text clarity
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance"),
              let contrastEnhancedImage = contrastFilter.outputImage else { return cgImage }
        sharpenFilter.setValue(contrastEnhancedImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey) // Moderate sharpening
        
        // 4. Convert back to CGImage
        guard let finalImage = sharpenFilter.outputImage,
              let enhancedCGImage = context.createCGImage(finalImage, from: finalImage.extent) else {
            print("⚠️ Image enhancement failed, using original image")
            return cgImage
        }
        
        print("📈 Applied image enhancements: noise reduction, contrast, sharpening")
        return enhancedCGImage
    }
    
    // MARK: - Multi-Strategy OCR
    
    /// Perform OCR using multiple strategies for best results
    private func performMultiStrategyOCR(image: CGImage) async throws -> [OCRStrategy: OCRStrategyResult] {
        let strategies: [OCRStrategy] = [.accurate, .fast, .languageSpecific]
        var results: [OCRStrategy: OCRStrategyResult] = [:]
        
        // Run strategies in parallel for efficiency
        await withTaskGroup(of: (OCRStrategy, Result<OCRStrategyResult, Error>).self) { group in
            for strategy in strategies {
                group.addTask {
                    do {
                        let result = try await self.performOCRWithStrategy(strategy, image: image)
                        return (strategy, .success(result))
                    } catch {
                        return (strategy, .failure(error))
                    }
                }
            }
            
            for await (strategy, result) in group {
                switch result {
                case .success(let strategyResult):
                    results[strategy] = strategyResult
                    print("✅ OCR strategy \(strategy) completed: \(strategyResult.recognizedText.count) chars, confidence: \(String(format: "%.2f", strategyResult.averageConfidence))")
                case .failure(let error):
                    print("❌ OCR strategy \(strategy) failed: \(error)")
                }
            }
        }
        
        guard !results.isEmpty else {
            throw OCRProcessingError.allStrategiesFailed
        }
        
        return results
    }
    
    /// Perform OCR with specific strategy
    private func performOCRWithStrategy(_ strategy: OCRStrategy, image: CGImage) async throws -> OCRStrategyResult {
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                
                // Extract text with confidence scores
                var textSegments: [OCRTextSegment] = []
                var totalConfidence: Float = 0
                
                for observation in observations {
                    let candidates = observation.topCandidates(3) // Get top 3 candidates
                    
                    if let topCandidate = candidates.first {
                        let segment = OCRTextSegment(
                            text: topCandidate.string,
                            confidence: topCandidate.confidence,
                            boundingBox: observation.boundingBox,
                            alternatives: candidates.dropFirst().map { $0.string }
                        )
                        textSegments.append(segment)
                        totalConfidence += topCandidate.confidence
                    }
                }
                
                let averageConfidence = textSegments.isEmpty ? 0 : totalConfidence / Float(textSegments.count)
                let recognizedText = textSegments.map { $0.text }.joined(separator: "\n")
                
                let result = OCRStrategyResult(
                    strategy: strategy,
                    recognizedText: recognizedText,
                    textSegments: textSegments,
                    averageConfidence: averageConfidence,
                    processingTime: Date().timeIntervalSince(Date())
                )
                
                continuation.resume(returning: result)
            }
            
            // Configure request based on strategy
            self.configureOCRRequest(request, for: strategy)
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Configure OCR request based on strategy
    private func configureOCRRequest(_ request: VNRecognizeTextRequest, for strategy: OCRStrategy) {
        switch strategy {
        case .accurate:
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = supportedLanguages
            request.automaticallyDetectsLanguage = true
            
        case .fast:
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US", "vi-VN"] // Limit for speed
            request.automaticallyDetectsLanguage = false
            
        case .languageSpecific:
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["vi-VN"] // Vietnamese-specific
            request.automaticallyDetectsLanguage = false
        }
    }
    
    // MARK: - Result Enhancement and Post-Processing
    
    /// Enhance OCR result by combining strategies and applying corrections
    private func enhanceOCRResult(_ strategyResults: [OCRStrategy: OCRStrategyResult]) async throws -> OCRResult {
        
        // Select best strategy result as primary
        let primaryResult = selectBestStrategyResult(from: strategyResults)
        
        // Apply text corrections
        let correctedText = try await applyTextCorrections(
            text: primaryResult.recognizedText,
            confidence: primaryResult.averageConfidence,
            segments: primaryResult.textSegments
        )
        
        // Detect language
        let detectedLanguage = detectLanguage(in: correctedText)
        
        // Generate quality metrics
        let qualityMetrics = generateQualityMetrics(
            originalText: primaryResult.recognizedText,
            correctedText: correctedText,
            confidence: primaryResult.averageConfidence,
            segments: primaryResult.textSegments
        )
        
        return OCRResult(
            extractedText: correctedText,
            originalText: primaryResult.recognizedText,
            averageConfidence: primaryResult.averageConfidence,
            detectedLanguage: detectedLanguage,
            qualityMetrics: qualityMetrics,
            textSegments: primaryResult.textSegments,
            strategyUsed: primaryResult.strategy,
            processingTime: Date().timeIntervalSince(Date())
        )
    }
    
    /// Select the best strategy result based on confidence and content quality
    private func selectBestStrategyResult(from results: [OCRStrategy: OCRStrategyResult]) -> OCRStrategyResult {
        var bestResult = results.values.first!
        var bestScore: Float = 0
        
        for result in results.values {
            // Calculate composite score: confidence + text length factor + word count factor
            let lengthFactor = min(Float(result.recognizedText.count) / 1000.0, 1.0) // Normalize to 0-1
            let wordCountFactor = min(Float(result.recognizedText.components(separatedBy: .whitespacesAndNewlines).count) / 100.0, 1.0)
            
            let compositeScore = result.averageConfidence * 0.6 + lengthFactor * 0.2 + wordCountFactor * 0.2
            
            if compositeScore > bestScore {
                bestScore = compositeScore
                bestResult = result
            }
        }
        
        print("🎯 Selected best OCR strategy: \(bestResult.strategy) (score: \(String(format: "%.3f", bestScore)))")
        return bestResult
    }
    
    // MARK: - Text Correction and Enhancement
    
    /// Apply text corrections based on confidence and language patterns
    private func applyTextCorrections(text: String, confidence: Float, segments: [OCRTextSegment]) async throws -> String {
        var correctedText = text
        
        // Apply corrections only if confidence is below high threshold
        if confidence < highQualityConfidenceThreshold {
            
            // 1. Fix common OCR errors
            correctedText = fixCommonOCRErrors(correctedText)
            
            // 2. Apply Vietnamese-specific corrections
            correctedText = applyVietnameseCorrections(correctedText)
            
            // 3. Fix formatting issues
            correctedText = fixFormattingIssues(correctedText)
            
            // 4. Apply contextual corrections using low-confidence segments
            correctedText = try await applyContextualCorrections(
                text: correctedText,
                lowConfidenceSegments: segments.filter { $0.confidence < minimumConfidenceThreshold }
            )
        }
        
        return correctedText
    }
    
    /// Fix common OCR character recognition errors
    private func fixCommonOCRErrors(_ text: String) -> String {
        let commonReplacements: [String: String] = [
            // Common character confusions
            "0": "O", // Only in word contexts
            "1": "l", // Only in word contexts
            "5": "S", // Only in word contexts
            "8": "B", // Only in word contexts
            "rn": "m", // Common OCR confusion
            "vv": "w", // Common OCR confusion
            "|": "l", // Vertical bar to l
            "¢": "c", // Special character to c
            
            // Vietnamese-specific fixes
            "ô": "o", // OCR may miss diacritics
            "ă": "a",
            "â": "a",
            "ê": "e",
            "ư": "u",
            "ơ": "o"
        ]
        
        var correctedText = text
        
        // Apply replacements carefully (only in word contexts)
        for (wrong, correct) in commonReplacements {
            // Use regex to match whole words or specific contexts
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wrong))\\b"
            correctedText = correctedText.replacingOccurrences(
                of: pattern,
                with: correct,
                options: .regularExpression
            )
        }
        
        return correctedText
    }
    
    /// Apply Vietnamese-specific text corrections
    private func applyVietnameseCorrections(_ text: String) -> String {
        var correctedText = text
        
        // Vietnamese tone mark corrections
        let vietnameseToneCorrections: [String: String] = [
            "á": "á", "à": "à", "ả": "ả", "ã": "ã", "ạ": "ạ",
            "é": "é", "è": "è", "ẻ": "ẻ", "ẽ": "ẽ", "ẹ": "ẹ",
            "í": "í", "ì": "ì", "ỉ": "ỉ", "ĩ": "ĩ", "ị": "ị",
            "ó": "ó", "ò": "ò", "ỏ": "ỏ", "õ": "õ", "ọ": "ọ",
            "ú": "ú", "ù": "ù", "ủ": "ủ", "ũ": "ũ", "ụ": "ụ",
            "ý": "ý", "ỳ": "ỳ", "ỷ": "ỷ", "ỹ": "ỹ", "ỵ": "ỵ"
        ]
        
        // Apply Vietnamese corrections
        for (wrong, correct) in vietnameseToneCorrections {
            correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
        }
        
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
    
    /// Apply contextual corrections for low-confidence segments
    private func applyContextualCorrections(text: String, lowConfidenceSegments: [OCRTextSegment]) async throws -> String {
        var correctedText = text
        
        // For low-confidence segments, try to use alternatives or apply aggressive corrections
        for segment in lowConfidenceSegments {
            if let betterAlternative = selectBestAlternative(segment) {
                correctedText = correctedText.replacingOccurrences(
                    of: segment.text,
                    with: betterAlternative
                )
            }
        }
        
        return correctedText
    }
    
    /// Select best alternative for a low-confidence segment
    private func selectBestAlternative(_ segment: OCRTextSegment) -> String? {
        // Simple heuristic: choose longer alternatives or alternatives with common patterns
        let allCandidates = [segment.text] + segment.alternatives
        
        return allCandidates.max { candidate1, candidate2 in
            let score1 = calculateCandidateScore(candidate1)
            let score2 = calculateCandidateScore(candidate2)
            return score1 < score2
        }
    }
    
    /// Calculate score for text candidate
    private func calculateCandidateScore(_ text: String) -> Float {
        var score: Float = 0
        
        // Length factor
        score += Float(text.count) * 0.1
        
        // Word completeness factor
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let completeWords = words.filter { $0.count > 2 }
        score += Float(completeWords.count) * 0.3
        
        // Vietnamese character presence
        let vietnameseChars = text.filter { "áàảãạéèẻẽẹíìỉĩịóòỏõọúùủũụýỳỷỹỵôơưăâêđ".contains($0) }
        score += Float(vietnameseChars.count) * 0.2
        
        return score
    }
    
    // MARK: - Language Detection
    
    /// Detect language in extracted text
    private func detectLanguage(in text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            return dominantLanguage.rawValue
        }
        
        // Fallback: detect Vietnamese manually
        let vietnameseChars = text.filter { "áàảãạéèẻẽẹíìỉĩịóòỏõọúùủũụýỳỷỹỵôơưăâêđ".contains($0) }
        if Float(vietnameseChars.count) / Float(text.count) > 0.1 {
            return "vi"
        }
        
        return "en"
    }
    
    // MARK: - Quality Metrics
    
    /// Generate quality metrics for OCR result
    private func generateQualityMetrics(
        originalText: String,
        correctedText: String,
        confidence: Float,
        segments: [OCRTextSegment]
    ) -> OCRQualityMetrics {
        
        let characterCount = correctedText.count
        let wordCount = correctedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lineCount = correctedText.components(separatedBy: .newlines).count
        
        let lowConfidenceSegmentCount = segments.filter { $0.confidence < minimumConfidenceThreshold }.count
        let highConfidenceSegmentCount = segments.filter { $0.confidence >= highQualityConfidenceThreshold }.count
        
        let correctionsMade = originalText != correctedText
        let estimatedAccuracy = min(1.0, confidence + (correctionsMade ? 0.1 : 0.0))
        
        return OCRQualityMetrics(
            characterCount: characterCount,
            wordCount: wordCount,
            lineCount: lineCount,
            averageConfidence: confidence,
            lowConfidenceSegmentCount: lowConfidenceSegmentCount,
            highConfidenceSegmentCount: highConfidenceSegmentCount,
            totalSegmentCount: segments.count,
            correctionsMade: correctionsMade,
            estimatedAccuracy: estimatedAccuracy
        )
    }
}

// MARK: - Data Structures

/// OCR processing strategy
enum OCRStrategy: String, CaseIterable {
    case accurate = "accurate"
    case fast = "fast"
    case languageSpecific = "language_specific"
}

/// Individual text segment with confidence and position
struct OCRTextSegment {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    let alternatives: [String]
}

/// Result from a specific OCR strategy
struct OCRStrategyResult {
    let strategy: OCRStrategy
    let recognizedText: String
    let textSegments: [OCRTextSegment]
    let averageConfidence: Float
    let processingTime: TimeInterval
}

/// Final enhanced OCR result
struct OCRResult {
    let extractedText: String
    let originalText: String
    let averageConfidence: Float
    let detectedLanguage: String?
    let qualityMetrics: OCRQualityMetrics
    let textSegments: [OCRTextSegment]
    let strategyUsed: OCRStrategy
    let processingTime: TimeInterval
}

/// Quality metrics for OCR result
struct OCRQualityMetrics {
    let characterCount: Int
    let wordCount: Int
    let lineCount: Int
    let averageConfidence: Float
    let lowConfidenceSegmentCount: Int
    let highConfidenceSegmentCount: Int
    let totalSegmentCount: Int
    let correctionsMade: Bool
    let estimatedAccuracy: Float
}

// MARK: - Errors

enum OCRProcessingError: LocalizedError {
    case invalidImage
    case allStrategiesFailed
    case preprocessingFailed
    case postProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format for OCR processing"
        case .allStrategiesFailed:
            return "All OCR strategies failed to extract text"
        case .preprocessingFailed:
            return "Image preprocessing failed"
        case .postProcessingFailed:
            return "Text post-processing failed"
        }
    }
}