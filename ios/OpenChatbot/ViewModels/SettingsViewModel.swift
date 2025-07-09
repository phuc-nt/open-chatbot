import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var storedAPIKeys: [StoredAPIKey] = []
    @Published var isDarkMode = false
    @Published var notificationsEnabled = true
    @Published var showAddAPIKey = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedProvider: LLMProvider = .openrouter
    @Published var apiKeyInput = ""
    @Published var apiKeyName = ""
    @Published var isValidating = false
    @Published var validationResult: Bool?
    @Published var showBiometricPrompt = false
    
    // MARK: - Services
    private let keychain = KeychainService()
    private let apiServices: [LLMProvider: LLMAPIService] = [
        .openrouter: OpenRouterAPIService(keychain: KeychainService())
    ]
    
    // MARK: - Initialization
    init() {
        Task {
            await loadAPIKeys()
        }
    }
    
    // MARK: - API Key Management
    
    /// Load all stored API keys from keychain
    func loadAPIKeys() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            storedAPIKeys = await keychain.getAllAPIKeys()
            
            // Validate all keys in background
            await validateAllKeys()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    /// Add new API key
    func addAPIKey() async {
        guard !apiKeyInput.isEmpty else {
            showError("Please enter an API key")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First validate the key
            isValidating = true
            let isValid = try await validateAPIKey(apiKeyInput, for: selectedProvider)
            isValidating = false
            
            if !isValid {
                showError("Invalid API key. Please check and try again.")
                return
            }
            
            // Store in keychain
            let keyName = apiKeyName.isEmpty ? nil : apiKeyName
            try await keychain.storeAPIKey(apiKeyInput, for: selectedProvider, name: keyName)
            
            // Reload keys
            await loadAPIKeys()
            
            // Clear input
            apiKeyInput = ""
            apiKeyName = ""
            showAddAPIKey = false
            
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    /// Delete API key
    func deleteAPIKey(_ key: StoredAPIKey) async {
        do {
            // For now, skip biometric authentication to fix crash
            // TODO: Re-enable biometric auth after fixing KeychainService imports
            
            try await keychain.deleteAPIKey(for: key.provider, name: key.name)
            await loadAPIKeys()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    /// Validate API key
    func validateAPIKey(_ apiKey: String, for provider: LLMProvider) async throws -> Bool {
        guard let apiService = apiServices[provider] else {
            // For providers we don't have service for yet, assume valid if not empty
            return !apiKey.isEmpty
        }
        
        return try await apiService.validateAPIKey(apiKey)
    }
    
    /// Validate all stored keys
    private func validateAllKeys() async {
        for index in storedAPIKeys.indices {
            if let apiService = apiServices[storedAPIKeys[index].provider] {
                do {
                    let isValid = try await apiService.validateAPIKey(storedAPIKeys[index].apiKey)
                    storedAPIKeys[index].isValid = isValid
                } catch {
                    storedAPIKeys[index].isValid = false
                }
            } else {
                // Assume valid for unsupported providers
                storedAPIKeys[index].isValid = true
            }
        }
    }
    
    /// Test connection with selected API key
    func testConnection(for key: StoredAPIKey) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let isValid = try await validateAPIKey(key.apiKey, for: key.provider)
            
            if isValid {
                showError("✅ Connection successful!", isError: false)
            } else {
                showError("❌ Connection failed. Please check your API key.")
            }
        } catch {
            showError("❌ Connection error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func showError(_ message: String, isError: Bool = true) {
        errorMessage = message
        showError = true
        
        // Auto-dismiss success messages
        if !isError {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showError = false
            }
        }
    }
    
    /// Get primary API key for a provider
    func getPrimaryAPIKey(for provider: LLMProvider) -> StoredAPIKey? {
        return storedAPIKeys
            .filter { $0.provider == provider && $0.isValid }
            .first
    }
    
    /// Check if any valid API key exists
    var hasValidAPIKey: Bool {
        return storedAPIKeys.contains { $0.isValid }
    }
    
    /// Get display text for provider
    func providerDisplayText(for provider: LLMProvider) -> String {
        let keys = storedAPIKeys.filter { $0.provider == provider }
        if keys.isEmpty {
            return "Not configured"
        } else if keys.count == 1 {
            return keys[0].maskedAPIKey
        } else {
            return "\(keys.count) keys configured"
        }
    }
} 