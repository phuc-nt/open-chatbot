import Foundation
import CoreData
import NaturalLanguage

/// Complete implementation of document embedding processing service
/// Transforms documents into searchable vector embeddings with semantic chunking
class DocumentEmbeddingProcessingService {
    
    // MARK: - Dependencies
    private let embeddingService: EmbeddingServiceProtocol
    private let vectorService: CoreDataVectorService
    private let context: NSManagedObjectContext
    
    // MARK: - Configuration
    private let defaultChunkSize: Int = 1000
    private let defaultOverlap: Int = 100
    private let minChunkSize: Int = 200
    private let maxChunkSize: Int = 2000
    
    // MARK: - Initialization
    init(
        embeddingService: EmbeddingServiceProtocol,
        vectorService: CoreDataVectorService,
        context: NSManagedObjectContext
    ) {
        self.embeddingService = embeddingService
        self.vectorService = vectorService
        self.context = context
    }
    
    /// Process document to generate embeddings with semantic chunking
    func processDocumentEmbeddings(for documentID: UUID) async throws {
        print("🧠 Processing embeddings for document: \(documentID)")
        
        // 1. Fetch document content
        guard let document = try await fetchDocument(documentID: documentID) else {
            throw EmbeddingProcessingError.documentNotFound(documentID)
        }
        
        // 2. Clean and prepare text
        let cleanedText = cleanText(document.content)
        guard !cleanedText.isEmpty else {
            throw EmbeddingProcessingError.emptyContent(documentID)
        }
        
        // 3. Detect language for optimal processing
        let detectedLanguage = embeddingService.detectLanguage(for: cleanedText) ?? "en"
        print("📝 Detected language: \(detectedLanguage)")
        
        // 4. Create semantic chunks
        let chunks = createSemanticChunks(
            text: cleanedText,
            language: detectedLanguage,
            documentType: document.type?.rawValue ?? "unknown"
        )
        print("📊 Created \(chunks.count) semantic chunks")
        
        // 5. Generate embeddings for each chunk
        let embeddings = try await generateEmbeddings(for: chunks, language: detectedLanguage)
        print("🎯 Generated \(embeddings.count) embeddings")
        
        // 6. Store embeddings in vector database
        try await storeEmbeddings(
            embeddings: embeddings,
            chunks: chunks,
            documentID: documentID,
            language: detectedLanguage
        )
        
        // 7. Update document processing status
        try await markDocumentAsProcessed(documentID: documentID)
        
        print("✅ Embedding processing completed for document: \(documentID)")
    }
    
    // MARK: - Text Chunking
    
    /// Create semantic chunks from text with language awareness
    private func createSemanticChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        // Use Vietnamese-specific chunking for Vietnamese text
        if language == "vi" {
            return createVietnameseAwareChunks(text: text, language: language, documentType: documentType)
        }
        
        // Standard chunking for other languages
        return createStandardChunks(text: text, language: language, documentType: documentType)
    }
    
    /// Create Vietnamese-aware semantic chunks using inline processing
    private func createVietnameseAwareChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        print("🇻🇳 Using Vietnamese-aware chunking")
        
        let adaptiveChunkSize = determineOptimalChunkSize(for: documentType, language: language)
        let adaptiveOverlap = Int(Double(defaultOverlap) * 1.1) // Slightly more overlap for Vietnamese
        
        // Vietnamese-specific sentence detection
        let sentences = detectVietnameseSentences(in: text)
        print("📝 Detected \(sentences.count) Vietnamese sentences")
        
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentSentences: [String] = []
        var chunkIndex = 0
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if adding this sentence would exceed chunk size
            if !currentChunk.isEmpty && (currentChunk.count + trimmedSentence.count) > adaptiveChunkSize {
                // Finalize current chunk
                let chunk = createVietnameseChunkWithMetadata(
                    text: currentChunk,
                    sentences: currentSentences,
                    index: chunkIndex,
                    language: language
                )
                chunks.append(chunk)
                
                // Start new chunk with overlap from previous
                let overlapText = createVietnameseOverlap(from: currentSentences, maxSize: adaptiveOverlap)
                currentChunk = overlapText + (overlapText.isEmpty ? "" : " ") + trimmedSentence
                currentSentences = extractOverlapSentences(from: currentSentences, maxSize: adaptiveOverlap)
                currentSentences.append(trimmedSentence)
                chunkIndex += 1
            } else {
                // Add sentence to current chunk
                if currentChunk.isEmpty {
                    currentChunk = trimmedSentence
                } else {
                    currentChunk += " " + trimmedSentence
                }
                currentSentences.append(trimmedSentence)
            }
        }
        
        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            let chunk = createVietnameseChunkWithMetadata(
                text: currentChunk,
                sentences: currentSentences,
                index: chunkIndex,
                language: language
            )
            chunks.append(chunk)
        }
        
        // Handle edge case: if no chunks created, create single chunk
        if chunks.isEmpty && !text.isEmpty {
            let chunk = createVietnameseChunkWithMetadata(
                text: text,
                sentences: [text],
                index: 0,
                language: language
            )
            chunks.append(chunk)
        }
        
        print("✅ Created \(chunks.count) Vietnamese-aware chunks")
        return chunks
    }
    
    /// Create standard semantic chunks for non-Vietnamese languages with structure awareness
    private func createStandardChunks(text: String, language: String, documentType: String) -> [TextChunk] {
        let adaptiveChunkSize = determineOptimalChunkSize(for: documentType, language: language)
        
        // Analyze document structure first
        let documentStructure = analyzeDocumentStructure(text: text)
        print("📋 Detected document structure: \(documentStructure.sections.count) sections, \(documentStructure.tables.count) tables, \(documentStructure.lists.count) lists")
        
        // Use structure-aware chunking
        return createStructureAwareChunks(
            text: text,
            structure: documentStructure,
            chunkSize: adaptiveChunkSize,
            language: language
        )
    }
    
    /// Create structure-aware chunks that preserve document hierarchy
    private func createStructureAwareChunks(
        text: String,
        structure: DocumentStructure,
        chunkSize: Int,
        language: String
    ) -> [TextChunk] {
        var chunks: [TextChunk] = []
        var chunkIndex = 0
        
        // Process each section separately to maintain structural boundaries
        for section in structure.sections {
            let sectionChunks = createSectionChunks(
                section: section,
                chunkSize: chunkSize,
                startIndex: chunkIndex,
                language: language
            )
            chunks.append(contentsOf: sectionChunks)
            chunkIndex += sectionChunks.count
        }
        
        // If no sections detected, fall back to paragraph-based chunking
        if chunks.isEmpty {
            chunks = createParagraphBasedChunks(
                text: text,
                chunkSize: chunkSize,
                language: language
            )
        }
        
        return chunks
    }
    
    /// Create chunks for a specific document section
    private func createSectionChunks(
        section: DocumentSection,
        chunkSize: Int,
        startIndex: Int,
        language: String
    ) -> [TextChunk] {
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var chunkIndex = startIndex
        
        // Add section header if exists
        if let header = section.header, !header.isEmpty {
            currentChunk = header
        }
        
        // Process section content in smaller segments
        let segments = section.content.components(separatedBy: "\n\n").filter { 
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        }
        
        for segment in segments {
            let cleanSegment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if adding this segment would exceed chunk size
            if !currentChunk.isEmpty && (currentChunk.count + cleanSegment.count + 2) > chunkSize {
                // Finalize current chunk with structure metadata
                let chunk = createStructureAwareChunkWithMetadata(
                    text: currentChunk,
                    index: chunkIndex,
                    language: language,
                    sectionHeader: section.header,
                    sectionLevel: section.level,
                    structuralElements: identifyStructuralElements(in: currentChunk)
                )
                chunks.append(chunk)
                
                // Start new chunk with structural context
                currentChunk = preserveStructuralContext(
                    previousChunk: currentChunk,
                    newSegment: cleanSegment,
                    sectionHeader: section.header
                )
                chunkIndex += 1
            } else {
                // Add segment to current chunk
                if currentChunk.isEmpty {
                    currentChunk = cleanSegment
                } else {
                    currentChunk += "\n\n" + cleanSegment
                }
            }
        }
        
        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            let chunk = createStructureAwareChunkWithMetadata(
                text: currentChunk,
                index: chunkIndex,
                language: language,
                sectionHeader: section.header,
                sectionLevel: section.level,
                structuralElements: identifyStructuralElements(in: currentChunk)
            )
            chunks.append(chunk)
        }
        
        return chunks
    }
    
    /// Fallback paragraph-based chunking when no structure detected
    private func createParagraphBasedChunks(
        text: String,
        chunkSize: Int,
        language: String
    ) -> [TextChunk] {
        let paragraphs = text.components(separatedBy: "\n\n").filter { 
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        }
        
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var chunkIndex = 0
        
        for paragraph in paragraphs {
            let cleanParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !currentChunk.isEmpty && (currentChunk.count + cleanParagraph.count) > chunkSize {
                chunks.append(createChunkWithMetadata(
                    text: currentChunk,
                    index: chunkIndex,
                    language: language
                ))
                
                currentChunk = createOverlapText(from: currentChunk) + "\n\n" + cleanParagraph
                chunkIndex += 1
            } else {
                if currentChunk.isEmpty {
                    currentChunk = cleanParagraph
                } else {
                    currentChunk += "\n\n" + cleanParagraph
                }
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(createChunkWithMetadata(
                text: currentChunk,
                index: chunkIndex,
                language: language
            ))
        }
        
        if chunks.isEmpty && !text.isEmpty {
            chunks.append(createChunkWithMetadata(
                text: text,
                index: 0,
                language: language
            ))
        }
        
        return chunks
    }
    
    /// Determine optimal chunk size based on document type and language
    private func determineOptimalChunkSize(for documentType: String, language: String) -> Int {
        var baseSize = defaultChunkSize
        
        // Adjust for document type
        switch documentType.lowercased() {
        case "pdf", "technical", "manual":
            baseSize = Int(Double(defaultChunkSize) * 1.2) // Larger chunks for technical content
        case "text", "note":
            baseSize = Int(Double(defaultChunkSize) * 0.8) // Smaller chunks for notes
        default:
            baseSize = defaultChunkSize
        }
        
        // Adjust for Vietnamese (longer words, different sentence structure)
        if language == "vi" {
            baseSize = Int(Double(baseSize) * 1.1)
        }
        
        return min(max(baseSize, minChunkSize), maxChunkSize)
    }
    
    /// Create overlap text from the end of previous chunk
    private func createOverlapText(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let overlapWords = min(defaultOverlap / 10, words.count) // Approximate word count
        
        if overlapWords > 0 {
            return words.suffix(overlapWords).joined(separator: " ")
        }
        return ""
    }
    
    /// Create chunk with metadata
    private func createChunkWithMetadata(text: String, index: Int, language: String) -> TextChunk {
        return TextChunk(
            text: text,
            index: index,
            characterCount: text.count,
            wordCount: text.components(separatedBy: .whitespacesAndNewlines).count,
            language: language,
            metadata: [
                "chunk_type": "semantic",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "word_density": calculateWordDensity(text)
            ]
        )
    }
    
    /// Calculate word density for chunk quality metrics
    private func calculateWordDensity(_ text: String) -> Double {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return Double(words.count) / Double(text.count) * 1000 // words per 1000 characters
    }
    
    // MARK: - Document Structure Analysis
    
    /// Analyze document structure to detect sections, headers, tables, and lists
    private func analyzeDocumentStructure(text: String) -> DocumentStructure {
        print("📋 Analyzing document structure...")
        
        let lines = text.components(separatedBy: .newlines)
        var sections: [DocumentSection] = []
        var tables: [DocumentTable] = []
        var lists: [DocumentList] = []
        
        var currentSection: DocumentSection?
        var currentSectionLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmedLine.isEmpty {
                currentSectionLines.append(line)
                continue
            }
            
            // Detect headers (lines that look like section headers)
            if let headerLevel = detectHeaderLevel(line: trimmedLine) {
                // Finalize previous section if exists
                if let section = currentSection, !currentSectionLines.isEmpty {
                    let updatedSection = DocumentSection(
                        header: section.header,
                        content: currentSectionLines.joined(separator: "\n"),
                        level: section.level,
                        startIndex: section.startIndex,
                        endIndex: index - 1
                    )
                    sections.append(updatedSection)
                }
                
                // Start new section
                currentSection = DocumentSection(
                    header: trimmedLine,
                    content: "",
                    level: headerLevel,
                    startIndex: index,
                    endIndex: index
                )
                currentSectionLines = []
                continue
            }
            
            // Detect tables (lines with multiple columns separated by |, tabs, or multiple spaces)
            if detectTableRow(line: trimmedLine) {
                let table = analyzeTable(startingAt: index, lines: lines)
                if table.rows.count > 1 { // At least header + 1 data row
                    tables.append(table)
                }
            }
            
            // Detect lists (lines starting with -, *, •, numbers, etc.)
            if detectListItem(line: trimmedLine) {
                let list = analyzeList(startingAt: index, lines: lines)
                if list.items.count > 1 {
                    lists.append(list)
                }
            }
            
            // Add line to current section content
            currentSectionLines.append(line)
        }
        
        // Finalize last section
        if let section = currentSection, !currentSectionLines.isEmpty {
            let updatedSection = DocumentSection(
                header: section.header,
                content: currentSectionLines.joined(separator: "\n"),
                level: section.level,
                startIndex: section.startIndex,
                endIndex: lines.count - 1
            )
            sections.append(updatedSection)
        }
        
        // If no sections detected, create a single section from entire text
        if sections.isEmpty {
            sections.append(DocumentSection(
                header: nil,
                content: text,
                level: 0,
                startIndex: 0,
                endIndex: lines.count - 1
            ))
        }
        
        return DocumentStructure(
            sections: sections,
            tables: tables,
            lists: lists,
            metadata: [
                "total_lines": lines.count,
                "analysis_date": ISO8601DateFormatter().string(from: Date()),
                "structure_detected": !sections.isEmpty || !tables.isEmpty || !lists.isEmpty
            ]
        )
    }
    
    /// Detect header level based on formatting patterns
    private func detectHeaderLevel(line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Markdown-style headers (#, ##, ###, etc.)
        if trimmed.hasPrefix("#") {
            let headerMarks = trimmed.prefix(while: { $0 == "#" })
            return min(headerMarks.count, 6) // Max 6 levels like HTML
        }
        
        // All caps headers (likely section headers)
        if trimmed.count > 5 && trimmed.count < 100 && trimmed == trimmed.uppercased() {
            // Check if it contains mostly letters (not just punctuation)
            let letterCount = trimmed.filter { $0.isLetter }.count
            if letterCount > trimmed.count * 2 / 3 {
                return 1
            }
        }
        
        // Headers followed by underlines (next line with === or ---)
        // This would require looking ahead, implement if needed
        
        // Headers with specific formatting patterns
        if trimmed.hasPrefix("CHAPTER ") || trimmed.hasPrefix("SECTION ") || 
           trimmed.hasPrefix("Part ") || trimmed.hasPrefix("Chapter ") {
            return 1
        }
        
        // Numbered headers (1., 1.1, 1.1.1, etc.)
        if let _ = trimmed.range(of: "^\\d+(\\.\\d+)*\\.?\\s+[A-Za-z]", options: .regularExpression) {
            let dotCount = trimmed.filter { $0 == "." }.count
            return min(dotCount + 1, 6)
        }
        
        return nil
    }
    
    /// Detect if a line is part of a table
    private func detectTableRow(line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Pipe-separated tables (|col1|col2|col3|)
        if trimmed.contains("|") && trimmed.components(separatedBy: "|").count >= 3 {
            return true
        }
        
        // Tab-separated tables
        if trimmed.contains("\t") && trimmed.components(separatedBy: "\t").count >= 2 {
            return true
        }
        
        // Multiple spaces as separators (at least 2 columns with 2+ spaces between)
        let components = trimmed.components(separatedBy: "  ").filter { !$0.isEmpty }
        if components.count >= 2 {
            return true
        }
        
        return false
    }
    
    /// Detect if a line is a list item
    private func detectListItem(line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Bullet points (-, *, •, etc.)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || 
           trimmed.hasPrefix("• ") || trimmed.hasPrefix("◦ ") {
            return true
        }
        
        // Numbered lists (1., 2., etc.)
        if let _ = trimmed.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
            return true
        }
        
        // Lettered lists (a., b., etc.)
        if let _ = trimmed.range(of: "^[a-zA-Z]\\.\\s+", options: .regularExpression) {
            return true
        }
        
        return false
    }
    
    /// Analyze table structure starting from a specific line
    private func analyzeTable(startingAt startIndex: Int, lines: [String]) -> DocumentTable {
        var rows: [DocumentTableRow] = []
        var currentIndex = startIndex
        
        // Analyze consecutive table rows
        while currentIndex < lines.count {
            let line = lines[currentIndex]
            if detectTableRow(line: line) {
                let cells = parseTableCells(from: line)
                rows.append(DocumentTableRow(cells: cells, originalLine: line))
                currentIndex += 1
            } else {
                break
            }
        }
        
        return DocumentTable(
            rows: rows,
            startIndex: startIndex,
            endIndex: currentIndex - 1,
            columnCount: rows.first?.cells.count ?? 0
        )
    }
    
    /// Parse table cells from a line
    private func parseTableCells(from line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle pipe-separated tables
        if trimmed.contains("|") {
            return trimmed.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        // Handle tab-separated tables
        if trimmed.contains("\t") {
            return trimmed.components(separatedBy: "\t")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        // Handle space-separated tables (2+ spaces as delimiter)
        return trimmed.components(separatedBy: "  ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Analyze list structure starting from a specific line
    private func analyzeList(startingAt startIndex: Int, lines: [String]) -> DocumentList {
        var items: [DocumentListItem] = []
        var currentIndex = startIndex
        
        // Analyze consecutive list items
        while currentIndex < lines.count {
            let line = lines[currentIndex]
            if detectListItem(line: line) {
                let content = parseListItemContent(from: line)
                let level = detectListIndentLevel(line: line)
                items.append(DocumentListItem(
                    content: content,
                    level: level,
                    originalLine: line
                ))
                currentIndex += 1
            } else {
                break
            }
        }
        
        let listType: DocumentListType = items.first?.originalLine.contains(where: { "123456789".contains($0) }) == true ? .numbered : .bulleted
        
        return DocumentList(
            items: items,
            type: listType,
            startIndex: startIndex,
            endIndex: currentIndex - 1
        )
    }
    
    /// Parse content from a list item line
    private func parseListItemContent(from line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove bullet markers
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || 
           trimmed.hasPrefix("• ") || trimmed.hasPrefix("◦ ") {
            return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Remove numbered markers
        if let range = trimmed.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Remove lettered markers
        if let range = trimmed.range(of: "^[a-zA-Z]\\.\\s+", options: .regularExpression) {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return trimmed
    }
    
    /// Detect list indentation level
    private func detectListIndentLevel(line: String) -> Int {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        return leadingSpaces / 2 // Assuming 2 spaces per indent level
    }
    
    /// Create structure-aware chunk with enhanced metadata
    private func createStructureAwareChunkWithMetadata(
        text: String,
        index: Int,
        language: String,
        sectionHeader: String?,
        sectionLevel: Int,
        structuralElements: [String]
    ) -> TextChunk {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordDensity = calculateWordDensity(text)
        
        return TextChunk(
            text: text,
            index: index,
            characterCount: text.count,
            wordCount: words.count,
            language: language,
            metadata: [
                "chunk_type": "structure_aware",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "word_density": wordDensity,
                "section_header": sectionHeader ?? "",
                "section_level": sectionLevel,
                "structural_elements": structuralElements,
                "structure_enhanced": true,
                "has_section_context": sectionHeader != nil
            ]
        )
    }
    
    /// Identify structural elements within a chunk
    private func identifyStructuralElements(in text: String) -> [String] {
        var elements: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if detectHeaderLevel(line: trimmed) != nil {
                elements.append("header")
            }
            
            if detectTableRow(line: trimmed) {
                elements.append("table")
            }
            
            if detectListItem(line: trimmed) {
                elements.append("list")
            }
            
            // Detect code blocks (lines with indentation or code patterns)
            if line.hasPrefix("    ") || line.hasPrefix("\t") {
                elements.append("code")
            }
        }
        
        return Array(Set(elements)) // Remove duplicates
    }
    
    /// Preserve structural context when creating overlaps
    private func preserveStructuralContext(
        previousChunk: String,
        newSegment: String,
        sectionHeader: String?
    ) -> String {
        var contextualStart = ""
        
        // Add section header for context if available
        if let header = sectionHeader, !header.isEmpty {
            contextualStart = header + "\n\n"
        }
        
        // Add relevant context from previous chunk (last sentence or paragraph)
        let overlapText = createOverlapText(from: previousChunk)
        if !overlapText.isEmpty {
            contextualStart += overlapText + "\n\n"
        }
        
        return contextualStart + newSegment
    }

    // MARK: - Vietnamese Text Processing
    
    /// Detect Vietnamese sentences using language-aware tokenization
    private func detectVietnameseSentences(in text: String) -> [String] {
        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.setLanguage(.vietnamese)
        sentenceTokenizer.string = text
        
        var sentences: [String] = []
        sentenceTokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let sentence = String(text[tokenRange])
            sentences.append(sentence)
            return true
        }
        
        // Apply Vietnamese-specific refinement
        return refineVietnameseSentenceBoundaries(sentences)
    }
    
    /// Refine sentence boundaries using Vietnamese grammar rules
    private func refineVietnameseSentenceBoundaries(_ sentences: [String]) -> [String] {
        var refinedSentences: [String] = []
        var currentSentence = ""
        
        let vietnameseConjunctions: Set<String> = [
            "và", "hoặc", "nhưng", "mà", "hay", "thì", "nên", "để", "vì", "do", "bởi vì", "tuy nhiên", "tuy", "dù", "dẫu"
        ]
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this should be merged with previous sentence
            let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            let shouldMerge = !currentSentence.isEmpty && (
                (words.first.map { vietnameseConjunctions.contains($0.lowercased()) } ?? false) ||
                (trimmed.count < 20 && words.count < 4) ||
                !currentSentence.hasSuffix(".") && !currentSentence.hasSuffix("!") && !currentSentence.hasSuffix("?")
            )
            
            if shouldMerge {
                if !currentSentence.isEmpty {
                    currentSentence += " " + trimmed
                } else {
                    currentSentence = trimmed
                }
            } else {
                // Finalize previous sentence if exists
                if !currentSentence.isEmpty {
                    refinedSentences.append(currentSentence)
                }
                currentSentence = trimmed
            }
        }
        
        // Add final sentence
        if !currentSentence.isEmpty {
            refinedSentences.append(currentSentence)
        }
        
        return refinedSentences.filter { !$0.isEmpty }
    }
    
    /// Create Vietnamese chunk with enhanced metadata
    private func createVietnameseChunkWithMetadata(
        text: String,
        sentences: [String],
        index: Int,
        language: String
    ) -> TextChunk {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordDensity = calculateVietnameseWordDensity(text: text, words: words)
        
        return TextChunk(
            text: text,
            index: index,
            characterCount: text.count,
            wordCount: words.count,
            language: language,
            metadata: [
                "chunk_type": "vietnamese_semantic",
                "processing_date": ISO8601DateFormatter().string(from: Date()),
                "word_density": wordDensity,
                "sentence_count": sentences.count,
                "vietnamese_enhanced": true,
                "sentence_boundary_detection": "vietnamese_grammar_aware",
                "tokenization_method": "nl_tokenizer_vietnamese"
            ]
        )
    }
    
    /// Calculate Vietnamese-specific word density
    private func calculateVietnameseWordDensity(text: String, words: [String]) -> Double {
        guard !text.isEmpty else { return 0.0 }
        
        // Vietnamese has different word density characteristics than English
        let adjustedWordCount = Double(words.count)
        let characterCount = Double(text.count)
        
        // Vietnamese words are typically longer, so adjust the density calculation
        return (adjustedWordCount / characterCount) * 1000 * 1.15 // 1.15 adjustment for Vietnamese
    }
    
    /// Create overlap text from previous Vietnamese sentences
    private func createVietnameseOverlap(from sentences: [String], maxSize: Int) -> String {
        guard !sentences.isEmpty else { return "" }
        
        // Try to include complete sentences within size limit
        var overlapText = ""
        var currentSize = 0
        
        for sentence in sentences.reversed() {
            let sentenceSize = sentence.count + 1 // +1 for space
            if currentSize + sentenceSize <= maxSize {
                if overlapText.isEmpty {
                    overlapText = sentence
                } else {
                    overlapText = sentence + " " + overlapText
                }
                currentSize += sentenceSize
            } else {
                break
            }
        }
        
        return overlapText
    }
    
    /// Extract sentences for Vietnamese overlap
    private func extractOverlapSentences(from sentences: [String], maxSize: Int) -> [String] {
        var overlapSentences: [String] = []
        var currentSize = 0
        
        for sentence in sentences.reversed() {
            let sentenceSize = sentence.count
            if currentSize + sentenceSize <= maxSize {
                overlapSentences.insert(sentence, at: 0)
                currentSize += sentenceSize
            } else {
                break
            }
        }
        
        return overlapSentences
    }
    
    // MARK: - Text Cleaning
    
    /// Clean and normalize text for optimal processing
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // Normalize whitespace
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression) // Normalize line breaks
    }
    
    // MARK: - Embedding Generation
    
    /// Generate embeddings for all chunks with batch processing
    private func generateEmbeddings(for chunks: [TextChunk], language: String) async throws -> [ChunkEmbedding] {
        var embeddings: [ChunkEmbedding] = []
        
        // Process chunks in batches for better performance
        let batchSize = 10
        for i in stride(from: 0, to: chunks.count, by: batchSize) {
            let endIndex = min(i + batchSize, chunks.count)
            let batch = Array(chunks[i..<endIndex])
            
            let batchTexts = batch.map { $0.text }
            let batchEmbeddings = try await embeddingService.generateEmbeddings(for: batchTexts, language: language)
            
            for (index, embedding) in batchEmbeddings.enumerated() {
                let chunkIndex = i + index
                embeddings.append(ChunkEmbedding(
                    chunk: batch[index],
                    embedding: embedding,
                    chunkIndex: chunkIndex
                ))
            }
            
            // Small delay to prevent overwhelming the system
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        return embeddings
    }
    
    // MARK: - Storage
    
    /// Store embeddings in vector database with metadata
    private func storeEmbeddings(
        embeddings: [ChunkEmbedding],
        chunks: [TextChunk],
        documentID: UUID,
        language: String
    ) async throws {
        for embedding in embeddings {
            let metadata: [String: Any] = [
                "language": language,
                "chunk_index": embedding.chunkIndex,
                "character_count": embedding.chunk.characterCount,
                "word_count": embedding.chunk.wordCount,
                "word_density": embedding.chunk.metadata["word_density"] ?? 0.0,
                "processing_date": embedding.chunk.metadata["processing_date"] ?? "",
                "chunk_type": embedding.chunk.metadata["chunk_type"] ?? "semantic"
            ]
            
            try await vectorService.saveEmbedding(
                documentID: documentID,
                chunkText: embedding.chunk.text,
                embedding: embedding.embedding,
                chunkIndex: embedding.chunkIndex,
                metadata: metadata,
                language: language
            )
        }
    }
    
    // MARK: - Database Operations
    
    /// Fetch document from Core Data
    private func fetchDocument(documentID: UUID) async throws -> DocumentContent? {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Document")
                request.predicate = NSPredicate(format: "id == %@", documentID as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.context.fetch(request)
                    if let document = results.first {
                        let content = DocumentContent(
                            id: documentID,
                            content: document.value(forKey: "content") as? String ?? "",
                            title: document.value(forKey: "title") as? String ?? "",
                            type: ProcessingDocumentType(rawValue: document.value(forKey: "type") as? String ?? "unknown")
                        )
                        continuation.resume(returning: content)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Mark document as processed
    private func markDocumentAsProcessed(documentID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Document")
                request.predicate = NSPredicate(format: "id == %@", documentID as CVarArg)
                request.fetchLimit = 1
                
                do {
                    let results = try self.context.fetch(request)
                    if let document = results.first {
                        document.setValue(true, forKey: "isEmbeddingProcessed")
                        document.setValue(Date(), forKey: "embeddingProcessedAt")
                        try self.context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Supporting Data Structures

/// Document structure containing all detected structural elements
struct DocumentStructure {
    let sections: [DocumentSection]
    let tables: [DocumentTable]
    let lists: [DocumentList]
    let metadata: [String: Any]
}

/// Document section with header and content
struct DocumentSection {
    let header: String?
    let content: String
    let level: Int
    let startIndex: Int
    let endIndex: Int
}

/// Document table with rows and structure information
struct DocumentTable {
    let rows: [DocumentTableRow]
    let startIndex: Int
    let endIndex: Int
    let columnCount: Int
}

/// Table row containing cells
struct DocumentTableRow {
    let cells: [String]
    let originalLine: String
}

/// Document list with items and type
struct DocumentList {
    let items: [DocumentListItem]
    let type: DocumentListType
    let startIndex: Int
    let endIndex: Int
}

/// List item with content and indentation
struct DocumentListItem {
    let content: String
    let level: Int
    let originalLine: String
}

/// Type of document list
enum DocumentListType {
    case bulleted
    case numbered
    case lettered
}

struct TextChunk {
    let text: String
    let index: Int
    let characterCount: Int
    let wordCount: Int
    let language: String
    let metadata: [String: Any]
}

struct ChunkEmbedding {
    let chunk: TextChunk
    let embedding: [Float]
    let chunkIndex: Int
}

struct DocumentContent {
    let id: UUID
    let content: String
    let title: String
    let type: ProcessingDocumentType?
}

enum ProcessingDocumentType: String {
    case pdf = "pdf"
    case text = "text"
    case image = "image"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Document"
        case .text: return "Text Document"
        case .image: return "Image Document"
        case .unknown: return "Unknown Document"
        }
    }
}

// MARK: - Errors

enum EmbeddingProcessingError: Error, LocalizedError {
    case documentNotFound(UUID)
    case emptyContent(UUID)
    case chunkingFailed(String)
    case embeddingGenerationFailed(String)
    case storageFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .emptyContent(let id):
            return "Document has no content: \(id)"
        case .chunkingFailed(let message):
            return "Text chunking failed: \(message)"
        case .embeddingGenerationFailed(let message):
            return "Embedding generation failed: \(message)"
        case .storageFailed(let message):
            return "Storage operation failed: \(message)"
        }
    }
} 