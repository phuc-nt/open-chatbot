import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var keyToDelete: StoredAPIKey?
    
    var body: some View {
        NavigationView {
            Form {
                // API Keys Section
                Section {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        HStack {
                            Image(systemName: iconForProvider(provider))
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.displayName)
                                    .font(.headline)
                                Text(viewModel.providerDisplayText(for: provider))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.storedAPIKeys.contains(where: { $0.provider == provider }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedProvider = provider
                            viewModel.showAddAPIKey = true
                        }
                    }
                } header: {
                    HStack {
                        Text("API Keys")
                        Spacer()
                        Button {
                            viewModel.showAddAPIKey = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                } footer: {
                    Text("Tap a provider to add or manage API keys")
                }
                
                // Stored Keys Section
                if !viewModel.storedAPIKeys.isEmpty {
                    Section("Stored Keys") {
                        ForEach(viewModel.storedAPIKeys) { key in
                            APIKeyRow(
                                apiKey: key,
                                onTest: {
                                    Task {
                                        await viewModel.testConnection(for: key)
                                    }
                                },
                                onDelete: {
                                    keyToDelete = key
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
                
                // App Settings Section
                Section("App Settings") {
                    NavigationLink("Default AI Model") {
                        DefaultModelSettingView()
                    }
                    
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/phuc-nt/open-chatbot")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .sheet(isPresented: $viewModel.showAddAPIKey) {
                AddAPIKeyView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .alert("Delete API Key", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    keyToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let key = keyToDelete {
                        Task {
                            await viewModel.deleteAPIKey(key)
                        }
                    }
                    keyToDelete = nil
                }
            } message: {
                if let key = keyToDelete {
                    Text("Are you sure you want to delete the API key '\(key.displayName)'? This action cannot be undone.")
                }
            }
        }
    }
    
    private func iconForProvider(_ provider: LLMProvider) -> String {
        switch provider {
        case .openrouter: return "globe"
        case .openai: return "brain"
        case .anthropic: return "person.circle"
        case .google: return "magnifyingglass"
        case .groq: return "bolt"
        case .xai: return "sparkle"
        }
    }
}

// MARK: - API Key Row Component
struct APIKeyRow: View {
    let apiKey: StoredAPIKey
    let onTest: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(apiKey.displayName)
                        .font(.headline)
                    Text(apiKey.maskedAPIKey)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(apiKey.isValid ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(apiKey.isValid ? "Valid" : "Invalid")
                        .font(.caption)
                        .foregroundColor(apiKey.isValid ? .green : .red)
                }
            }
            
            HStack {
                Text("Added: \(apiKey.createdAt, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    onTest()
                } label: {
                    Label("Test", systemImage: "network")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add API Key View
struct AddAPIKeyView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isKeyFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(LLMProvider.allCases, id: \.self) { provider in
                            Label(provider.displayName, systemImage: iconForProvider(provider))
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("API Key") {
                    SecureField("Enter your API key", text: $viewModel.apiKeyInput)
                        .focused($isKeyFieldFocused)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Key Name (Optional)", text: $viewModel.apiKeyName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                
                Section {
                    if viewModel.isValidating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating API key...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            Task {
                                await viewModel.addAPIKey()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add API Key")
                            }
                        }
                        .disabled(viewModel.apiKeyInput.isEmpty)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your API key will be stored securely in iOS Keychain", systemImage: "lock.shield")
                            .font(.caption)
                        
                        Label("Face ID/Touch ID protection is available", systemImage: "faceid")
                            .font(.caption)
                        
                        Label("Keys are never sent to external servers", systemImage: "network.slash")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } header: {
                    Text("Security")
                }
            }
            .navigationTitle("Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isKeyFieldFocused = true
            }
        }
    }
    
    private func iconForProvider(_ provider: LLMProvider) -> String {
        switch provider {
        case .openrouter: return "globe"
        case .openai: return "brain"
        case .anthropic: return "person.circle"
        case .google: return "magnifyingglass"
        case .groq: return "bolt"
        case .xai: return "sparkle"
        }
    }
}

// MARK: - Default Model Setting View
struct DefaultModelSettingView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedDefaultModel: LLMModel?
    
    // Computed property for filtered models
    private var filteredModels: [LLMModel] {
        if searchText.isEmpty {
            return chatViewModel.availableModels
        } else {
            return chatViewModel.availableModels.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.provider.displayName.localizedCaseInsensitiveContains(searchText) ||
                (model.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search models...", text: $searchText)
                }
            }
            
            if !filteredModels.isEmpty {
                Section {
                    ForEach(filteredModels, id: \.id) { model in
                        DefaultModelRow(
                            model: model,
                            isSelected: selectedDefaultModel?.id == model.id
                        ) {
                            // Set the selected model and save it
                            selectedDefaultModel = model
                            chatViewModel.setDefaultModel(model)
                            
                            // Small delay for visual feedback, then dismiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dismiss()
                            }
                        }
                    }
                } header: {
                    Text("Available Models (\(filteredModels.count))")
                } footer: {
                    Text("The default model will be used for new conversations. You can always change it later in each conversation.")
                }
            } else if chatViewModel.availableModels.isEmpty {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading models...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else {
                Section {
                    Text("No models found matching '\(searchText)'")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Default AI Model")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load current default model
            selectedDefaultModel = chatViewModel.getDefaultModel()
        }
    }
}

struct DefaultModelRow: View {
    let model: LLMModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(model.provider.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isSelected {
                            Text("• Default")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let description = model.description {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
} 