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
    @State private var showingOrganization = false
    
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
                    organizationButton
                    sortMenuButton
                    uploadButton
                }
            }
            .searchable(text: $searchText, prompt: "Search documents...")
            .onChange(of: searchText) {
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
                Button("Delete", role: .destructive) {
                    if let document = documentToDelete {
                        Task {
                            await viewModel.deleteDocument(document)
                        }
                        documentToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    documentToDelete = nil
                }
            } message: {
                if let document = documentToDelete {
                    Text("Are you sure you want to delete '\(document.title)'? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .task {
            await viewModel.initialize()
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
                            Task {
                                await viewModel.archiveDocument(document)
                            }
                        }
                        .tint(.orange)
                    }
                    .contextMenu {
                        Button {
                            selectedDocument = document
                            showingDocumentDetail = true
                        } label: {
                            Label("View", systemImage: "eye")
                        }
                        
                        Button {
                            Task {
                                await viewModel.archiveDocument(document)
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
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
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty && selectedFilter == .all ? "doc" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty && selectedFilter == .all ? 
                 "No Documents" : 
                 "No Results Found"
            )
            .font(.title2)
            .fontWeight(.semibold)
            
            Text(searchText.isEmpty && selectedFilter == .all ? 
                 "Upload your first document to get started" : 
                 "Try adjusting your search or filters"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            
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
    private var organizationButton: some View {
        Button {
            showingOrganization = true
        } label: {
            Image(systemName: "folder.badge.gearshape")
        }
        .sheet(isPresented: $showingOrganization) {
            DocumentOrganizationView()
        }
    }
    
    @ViewBuilder
    private var sortMenuButton: some View {
        Menu {
            Picker("Sort by", selection: $selectedSortOption) {
                ForEach(DocumentSortOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option)
                }
            }
            .onChange(of: selectedSortOption) { _, newValue in
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
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// Note: DocumentFilter and DocumentSortOption are defined in DocumentBrowserViewModel.swift to avoid duplication
// Note: DocumentType extensions are defined in DocumentTypes.swift to avoid duplication

// MARK: - Preview
struct DocumentBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentBrowserView()
    }
} 