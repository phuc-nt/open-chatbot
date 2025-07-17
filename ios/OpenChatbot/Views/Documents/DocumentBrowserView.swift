import SwiftUI
import CoreData

struct DocumentBrowserView: View {
    @StateObject private var viewModel = DocumentBrowserViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: DocumentFilter = .all
    @State private var selectedSortOption: DocumentSortOption = .dateModified
    @State private var isAscending = false
    @State private var showingDocumentDetail = false
    @State private var selectedDocument: ProcessedDocument?
    @State private var showingDeleteConfirmation = false
    @State private var documentToDelete: ProcessedDocument?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterSection
                
                // Documents List
                documentsListSection
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    sortMenuButton
                    uploadButton
                }
            }
            .searchable(text: $searchText, prompt: "Search documents...")
            .onChange(of: searchText) { _ in
                viewModel.updateSearchFilter(searchText)
            }
            .refreshable {
                await viewModel.refreshDocuments()
            }
            .sheet(isPresented: $showingDocumentDetail) {
                if let selectedDocument = selectedDocument {
                    DocumentDetailView(document: selectedDocument)
                }
            }
            .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    documentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let document = documentToDelete {
                        viewModel.deleteDocument(document)
                        documentToDelete = nil
                    }
                }
            } message: {
                if let document = documentToDelete {
                    Text("Are you sure you want to delete '\(document.title)'? This action cannot be undone.")
                }
            }
        }
        .onAppear {
            viewModel.loadDocuments()
        }
    }
    
    // MARK: - Search and Filter Section
    @ViewBuilder
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DocumentFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            count: viewModel.getDocumentCount(for: filter)
                        ) {
                            selectedFilter = filter
                            viewModel.updateTypeFilter(filter)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Statistics Summary
            if !viewModel.documents.isEmpty {
                HStack {
                    Text("\(viewModel.filteredDocuments.count) of \(viewModel.documents.count) documents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Total: \(ByteCountFormatter.string(fromByteCount: viewModel.totalFileSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Documents List Section
    @ViewBuilder
    private var documentsListSection: some View {
        if viewModel.isLoading {
            ProgressView("Loading documents...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredDocuments.isEmpty {
            emptyStateView
        } else {
            List {
                ForEach(viewModel.filteredDocuments, id: \.id) { document in
                    DocumentBrowserRow(document: document) {
                        selectedDocument = document
                        showingDocumentDetail = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            documentToDelete = document
                            showingDeleteConfirmation = true
                        }
                        
                        Button("Archive") {
                            viewModel.archiveDocument(document)
                        }
                        .tint(.orange)
                    }
                    .contextMenu {
                        Button {
                            selectedDocument = document
                            showingDocumentDetail = true
                        } label: {
                            Label("View Details", systemImage: "doc.text.magnifyingglass")
                        }
                        
                        Button {
                            viewModel.duplicateDocument(document)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            documentToDelete = document
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            if searchText.isEmpty && selectedFilter == .all {
                // No documents at all
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No documents yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Upload your first document to get started with AI-powered document analysis")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                // No search results
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No results found")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Text("No documents match '\(searchText)'")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No \(selectedFilter.displayName.lowercased()) documents")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if searchText.isEmpty && selectedFilter == .all {
                    NavigationLink(destination: DocumentUploadView()) {
                        Label("Upload Documents", systemImage: "doc.badge.plus")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Clear Filters") {
                        searchText = ""
                        selectedFilter = .all
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Toolbar Buttons
    @ViewBuilder
    private var sortMenuButton: some View {
        Menu {
            Picker("Sort by", selection: $selectedSortOption) {
                ForEach(DocumentSortOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option)
                }
            }
            .onChange(of: selectedSortOption) { newValue in
                viewModel.updateSortOption(newValue, ascending: isAscending)
            }
            
            Divider()
            
            Button {
                isAscending.toggle()
                viewModel.updateSortOption(selectedSortOption, ascending: isAscending)
            } label: {
                Label(
                    isAscending ? "Descending" : "Ascending",
                    systemImage: isAscending ? "arrow.down" : "arrow.up"
                )
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    @ViewBuilder
    private var uploadButton: some View {
        NavigationLink(destination: DocumentUploadView()) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.white.opacity(0.3) : Color.primary.opacity(0.2)
                        )
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.blue : Color(.systemGray5)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Browser Row
struct DocumentBrowserRow: View {
    let document: ProcessedDocument
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Document Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(document.type.backgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: document.type.systemImageName)
                        .font(.title2)
                        .foregroundColor(document.type.foregroundColor)
                }
                
                // Document Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(document.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if document.pageCount > 1 {
                            Text("• \(document.pageCount) pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let language = document.detectedLanguage {
                            Text("• \(language.uppercased())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: document.createdAt, relativeTo: Date()))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Enums
enum DocumentFilter: String, CaseIterable {
    case all = "all"
    case pdf = "pdf"
    case image = "image"
    case text = "text"
    case recent = "recent"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .pdf: return "PDFs"
        case .image: return "Images"
        case .text: return "Text"
        case .recent: return "Recent"
        case .archived: return "Archived"
        }
    }
}

enum DocumentSortOption: String, CaseIterable {
    case name = "name"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"
    case size = "size"
    case type = "type"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .dateCreated: return "Date Created"
        case .dateModified: return "Date Modified"
        case .size: return "Size"
        case .type: return "Type"
        }
    }
}

// MARK: - DocumentType Extensions
extension DocumentType {
    var backgroundColor: Color {
        switch self {
        case .pdf: return .red
        case .image, .imagePNG: return .green
        case .text: return .blue
        case .unknown: return .gray
        }
    }
    
    var foregroundColor: Color {
        return .white
    }
}

// MARK: - Preview
struct DocumentBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentBrowserView()
    }
} 