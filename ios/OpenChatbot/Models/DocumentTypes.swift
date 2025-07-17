import Foundation

// MARK: - Processed Document Struct
struct ProcessedDocument: Identifiable {
    let id: String
    let title: String
    let fileName: String
    let fileURL: URL
    let fileSize: Int64
    let type: DocumentType
    let pageCount: Int32
    let content: String
    let detectedLanguage: String?
    let createdAt: Date
}

// MARK: - Document Type Enum
enum DocumentType: String, CaseIterable {
    case pdf = "application/pdf"
    case image = "image/jpeg"
    case imagePNG = "image/png"
    case text = "text/plain"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .image, .imagePNG: return "Image"
        case .text: return "Text"
        case .unknown: return "Unknown"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image, .imagePNG: return "photo.fill"
        case .text: return "doc.text.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

import SwiftUI

extension DocumentType {
    var icon: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .text:
            return "doc.text.fill"
        case .image, .imagePNG:
            return "photo.fill"
        case .unknown:
            return "doc.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pdf:
            return Color.red.opacity(0.1)
        case .text:
            return Color.blue.opacity(0.1)
        case .image, .imagePNG:
            return Color.green.opacity(0.1)
        case .unknown:
            return Color.gray.opacity(0.1)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .pdf:
            return Color.red
        case .text:
            return Color.blue
        case .image, .imagePNG:
            return Color.green
        case .unknown:
            return Color.gray
        }
    }
}

// MARK: - Processing Task
struct ProcessingTask: Identifiable {
    let id: String
    let fileName: String
    var status: ProcessingStatus
}

enum ProcessingStatus: String, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .processing: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
} 