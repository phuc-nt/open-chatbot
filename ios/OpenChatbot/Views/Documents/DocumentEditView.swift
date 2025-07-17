import SwiftUI

struct DocumentEditView: View {
    let document: ProcessedDocument
    @ObservedObject var viewModel: DocumentDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedTitle: String
    @State private var newTag: String = ""
    @State private var editedTags: [String]
    
    init(document: ProcessedDocument, viewModel: DocumentDetailViewModel) {
        self.document = document
        self.viewModel = viewModel
        _editedTitle = State(initialValue: document.title)
        _editedTags = State(initialValue: viewModel.tags)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Document Information") {
                    TextField("Title", text: $editedTitle)
                        .textContentType(.name)
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(document.type.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                    
                    if document.pageCount > 1 {
                        HStack {
                            Text("Pages")
                            Spacer()
                            Text("\(document.pageCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Tags") {
                    // Add new tag
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textContentType(.none)
                            .autocapitalization(.none)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("Add", action: addTag)
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Existing tags
                    if !editedTags.isEmpty {
                        ForEach(editedTags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                
                                Spacer()
                                
                                Button("Remove") {
                                    removeTag(tag)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    } else {
                        Text("No tags")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("File Details") {
                    HStack {
                        Text("Original Name")
                        Spacer()
                        Text(document.fileName)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if let language = document.detectedLanguage {
                        HStack {
                            Text("Language")
                            Spacer()
                            Text(language.uppercased())
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(DateFormatter.shortStyle.string(from: document.createdAt))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var hasChanges: Bool {
        editedTitle != document.title || editedTags != viewModel.tags
    }
    
    // MARK: - Actions
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !editedTags.contains(trimmedTag) else { return }
        
        editedTags.append(trimmedTag)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        editedTags.removeAll { $0 == tag }
    }
    
    private func saveChanges() {
        // Update title if changed
        if editedTitle != document.title {
            viewModel.updateTitle(editedTitle)
        }
        
        // Update tags if changed
        if editedTags != viewModel.tags {
            viewModel.updateTags(editedTags)
        }
        
        dismiss()
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let shortStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct DocumentEditView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentEditView(
            document: ProcessedDocument(
                id: "1",
                title: "Sample Document",
                fileName: "sample.pdf",
                fileURL: URL(string: "file://sample.pdf")!,
                fileSize: 1024000,
                type: .pdf,
                pageCount: 10,
                content: "This is sample content...",
                detectedLanguage: "en",
                createdAt: Date()
            ),
            viewModel: DocumentDetailViewModel()
        )
    }
} 