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
    var folder: DocumentFolder?
    var tags: [String] = []
    var isArchived: Bool = false
    var archivedAt: Date?
}

// MARK: - Document Folder System
struct DocumentFolder: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let color: FolderColor
    let icon: String
    var parentID: String?
    let createdAt: Date
    
    init(name: String, color: FolderColor = .blue, icon: String = "folder", parentID: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        self.icon = icon
        self.parentID = parentID
        self.createdAt = Date()
    }
    
    static let defaultFolders: [DocumentFolder] = [
        DocumentFolder(name: "Work", color: .blue, icon: "briefcase"),
        DocumentFolder(name: "Personal", color: .green, icon: "house"),
        DocumentFolder(name: "Research", color: .purple, icon: "magnifyingglass"),
        DocumentFolder(name: "Archive", color: .gray, icon: "archivebox")
    ]
}

enum FolderColor: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case red = "red"
    case yellow = "yellow"
    case pink = "pink"
    case gray = "gray"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Document Organization Enums
enum DocumentOrganization: String, CaseIterable {
    case all = "All Documents"
    case folders = "By Folder"
    case tags = "By Tags" 
    case recent = "Recent"
    case archived = "Archived"
    
    var icon: String {
        switch self {
        case .all: return "doc.fill"
        case .folders: return "folder.fill"
        case .tags: return "tag.fill"
        case .recent: return "clock.fill"
        case .archived: return "archivebox.fill"
        }
    }
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

extension FolderColor {
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .yellow: return .yellow
        case .pink: return .pink
        case .gray: return .gray
        }
    }
    
    var backgroundColor: Color {
        return color.opacity(0.1)
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