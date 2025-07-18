import SwiftUI

// MARK: - Document Organization View
struct DocumentOrganizationView: View {
    @StateObject private var organizationViewModel = DocumentOrganizationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateFolder = false
    @State private var showingEditFolder = false
    @State private var selectedFolder: DocumentFolder?
    
    var body: some View {
        NavigationView {
            List {
                // Organization Options Section
                Section("Organization") {
                    ForEach(DocumentOrganization.allCases, id: \.self) { organization in
                        NavigationLink(destination: organizedDocumentsView(for: organization)) {
                            HStack {
                                Image(systemName: organization.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text(organization.rawValue)
                                
                                Spacer()
                                
                                Text("\(organizationViewModel.getDocumentCount(for: organization))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Folders Section
                Section {
                    HStack {
                        Text("Folders")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingCreateFolder = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    EmptyView()
                }
                
                if organizationViewModel.folders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("No folders yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Create your first folder") {
                            showingCreateFolder = true
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(organizationViewModel.folders) { folder in
                        FolderRowView(folder: folder) {
                            selectedFolder = folder
                            showingEditFolder = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                organizationViewModel.deleteFolder(folder)
                            }
                            
                            Button("Edit") {
                                selectedFolder = folder
                                showingEditFolder = true
                            }
                            .tint(.blue)
                        }
                    }
                }
                
                // Quick Actions Section
                Section("Quick Actions") {
                    Button {
                        organizationViewModel.createDefaultFolders()
                    } label: {
                        Label("Create Default Folders", systemImage: "folder.badge.plus")
                    }
                    
                    Button {
                        organizationViewModel.organizeDocumentsByType()
                    } label: {
                        Label("Auto-organize by Type", systemImage: "square.grid.3x3")
                    }
                }
            }
            .navigationTitle("Organization")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateFolder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateFolder) {
                CreateFolderView(organizationViewModel: organizationViewModel)
            }
            .sheet(isPresented: $showingEditFolder) {
                if let folder = selectedFolder {
                    EditFolderView(folder: folder, organizationViewModel: organizationViewModel)
                }
            }
        }
        .task {
            await organizationViewModel.loadFolders()
        }
    }
    
    @ViewBuilder
    private func organizedDocumentsView(for organization: DocumentOrganization) -> some View {
        DocumentBrowserView()
            .navigationTitle(organization.rawValue)
    }
}

// MARK: - Folder Row View
struct FolderRowView: View {
    let folder: DocumentFolder
    let onEdit: () -> Void
    @StateObject private var organizationViewModel = DocumentOrganizationViewModel()
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Folder Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(folder.color.backgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: folder.icon)
                        .font(.title2)
                        .foregroundColor(folder.color.color)
                }
                
                // Folder Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(organizationViewModel.getDocumentCount(for: folder)) documents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Folder View
struct CreateFolderView: View {
    @ObservedObject var organizationViewModel: DocumentOrganizationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName = ""
    @State private var selectedColor: FolderColor = .blue
    @State private var selectedIcon = "folder"
    
    private let folderIcons = ["folder", "briefcase", "house", "magnifyingglass", "book", "heart", "star", "tag", "archivebox"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                        .textContentType(.name)
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(FolderColor.allCases, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                        
                        Text("Icon")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(folderIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? selectedColor.backgroundColor : Color(.systemGray6))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? selectedColor.color : .secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor.backgroundColor)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(selectedColor.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folderName.isEmpty ? "New Folder" : folderName)
                                .font(.headline)
                            
                            Text("0 documents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let folder = DocumentFolder(
                            name: folderName.isEmpty ? "New Folder" : folderName,
                            color: selectedColor,
                            icon: selectedIcon
                        )
                        organizationViewModel.createFolder(folder)
                        dismiss()
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Folder View
struct EditFolderView: View {
    let folder: DocumentFolder
    @ObservedObject var organizationViewModel: DocumentOrganizationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName: String
    @State private var selectedColor: FolderColor
    @State private var selectedIcon: String
    
    private let folderIcons = ["folder", "briefcase", "house", "magnifyingglass", "book", "heart", "star", "tag", "archivebox"]
    
    init(folder: DocumentFolder, organizationViewModel: DocumentOrganizationViewModel) {
        self.folder = folder
        self.organizationViewModel = organizationViewModel
        self._folderName = State(initialValue: folder.name)
        self._selectedColor = State(initialValue: folder.color)
        self._selectedIcon = State(initialValue: folder.icon)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                        .textContentType(.name)
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(FolderColor.allCases, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                        
                        Text("Icon")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(folderIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? selectedColor.backgroundColor : Color(.systemGray6))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? selectedColor.color : .secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Delete Folder", role: .destructive) {
                        organizationViewModel.deleteFolder(folder)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedFolder = folder
                        organizationViewModel.updateFolder(updatedFolder, name: folderName, color: selectedColor, icon: selectedIcon)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Document Organization ViewModel
@MainActor
class DocumentOrganizationViewModel: ObservableObject {
    @Published var folders: [DocumentFolder] = []
    @Published var documents: [ProcessedDocument] = []
    
    func loadFolders() async {
        // Load folders from Core Data or UserDefaults
        // For now, we'll use default folders
        folders = DocumentFolder.defaultFolders
    }
    
    func createFolder(_ folder: DocumentFolder) {
        folders.append(folder)
        // TODO: Save to Core Data
    }
    
    func updateFolder(_ folder: DocumentFolder, name: String, color: FolderColor, icon: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            let updatedFolder = DocumentFolder(name: name, color: color, icon: icon)
            folders[index] = updatedFolder
            // TODO: Save to Core Data
        }
    }
    
    func deleteFolder(_ folder: DocumentFolder) {
        folders.removeAll { $0.id == folder.id }
        // TODO: Remove from Core Data and reassign documents
    }
    
    func createDefaultFolders() {
        let defaultFolders = DocumentFolder.defaultFolders
        for folder in defaultFolders {
            if !folders.contains(where: { $0.name == folder.name }) {
                folders.append(folder)
            }
        }
    }
    
    func organizeDocumentsByType() {
        // Auto-organize documents by their type into folders
        // This would move PDFs to a "PDFs" folder, images to "Images", etc.
        // TODO: Implement auto-organization logic
    }
    
    func getDocumentCount(for organization: DocumentOrganization) -> Int {
        switch organization {
        case .all:
            return documents.count
        case .folders:
            return documents.filter { $0.folder != nil }.count
        case .tags:
            return documents.filter { !$0.tags.isEmpty }.count
        case .recent:
            return documents.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        case .archived:
            return documents.filter { $0.isArchived }.count
        }
    }
    
    func getDocumentCount(for folder: DocumentFolder) -> Int {
        return documents.filter { $0.folder?.id == folder.id }.count
    }
} 