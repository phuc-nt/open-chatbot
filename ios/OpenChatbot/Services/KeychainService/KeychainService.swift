import Foundation
import Security
import CryptoKit

// MARK: - Keychain Service for Secure API Key Storage
@MainActor
class KeychainService: ObservableObject {
    private let service = "com.phucnt.openchatbot.apikeys"
    
    // MARK: - API Key Management
    
    /// Store API key securely in keychain
    /// - Parameters:
    ///   - apiKey: The API key to store
    ///   - provider: The LLM provider
    ///   - name: Optional name for the key
    func storeAPIKey(_ apiKey: String, for provider: LLMProvider, name: String? = nil) async throws {
        let account = createAccount(for: provider, name: name)
        let data = apiKey.data(using: .utf8)!
        
        // Delete existing key first
        try await deleteAPIKey(for: provider, name: name)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageError(status)
        }
    }
    
    /// Retrieve API key from keychain
    /// - Parameters:
    ///   - provider: The LLM provider
    ///   - name: Optional name for the key
    /// - Returns: The API key if found
    func getAPIKey(for provider: LLMProvider, name: String? = nil) async -> String? {
        let account = createAccount(for: provider, name: name)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    /// Delete API key from keychain
    /// - Parameters:
    ///   - provider: The LLM provider
    ///   - name: Optional name for the key
    func deleteAPIKey(for provider: LLMProvider, name: String? = nil) async throws {
        let account = createAccount(for: provider, name: name)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Don't throw error if item doesn't exist
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionError(status)
        }
    }
    
    /// Get all stored API keys
    /// - Returns: Array of stored API key info
    func getAllAPIKeys() async -> [StoredAPIKey] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        var storedKeys: [StoredAPIKey] = []
        
        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String,
                  let data = item[kSecValueData as String] as? Data,
                  let apiKey = String(data: data, encoding: .utf8) else {
                continue
            }
            
            let components = account.components(separatedBy: ":")
            guard let providerString = components.first,
                  let provider = LLMProvider(rawValue: providerString) else {
                continue
            }
            
            let name = components.count > 1 ? components[1] : nil
            let createdAt = item[kSecAttrCreationDate as String] as? Date ?? Date()
            
            storedKeys.append(StoredAPIKey(
                provider: provider,
                name: name,
                apiKey: apiKey,
                createdAt: createdAt,
                isValid: false // Will be validated separately
            ))
        }
        
        return storedKeys
    }
    
    /// Validate all stored API keys
    /// - Returns: Dictionary mapping provider to validation status
    func validateAllAPIKeys() async -> [LLMProvider: Bool] {
        let storedKeys = await getAllAPIKeys()
        var validationResults: [LLMProvider: Bool] = [:]
        
        for storedKey in storedKeys {
            // This would use the appropriate API service to validate
            // For now, we'll assume they're valid if they exist
            validationResults[storedKey.provider] = !storedKey.apiKey.isEmpty
        }
        
        return validationResults
    }
    
    // MARK: - Biometric Authentication
    
    /// Enable biometric authentication for API key access
    func enableBiometricAuthentication() async throws {
        // This would configure Touch ID/Face ID protection
        // Implementation depends on specific requirements
    }
    
    /// Check if biometric authentication is available
    var isBiometricAuthenticationAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Private Helpers
    
    private func createAccount(for provider: LLMProvider, name: String?) -> String {
        if let name = name {
            return "\(provider.rawValue):\(name)"
        } else {
            return provider.rawValue
        }
    }
}

// MARK: - Supporting Types

struct StoredAPIKey: Identifiable {
    let id = UUID()
    let provider: LLMProvider
    let name: String?
    let apiKey: String
    let createdAt: Date
    var isValid: Bool
    
    var displayName: String {
        if let name = name {
            return "\(provider.displayName) - \(name)"
        } else {
            return provider.displayName
        }
    }
    
    var maskedAPIKey: String {
        guard apiKey.count > 8 else { return "••••••••" }
        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}

enum KeychainError: LocalizedError {
    case storageError(OSStatus)
    case deletionError(OSStatus)
    case biometricError(Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .storageError(let status):
            return "Failed to store API key: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
        case .deletionError(let status):
            return "Failed to delete API key: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
        case .biometricError(let error):
            return "Biometric authentication error: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data provided"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .storageError:
            return "Please try again or restart the app."
        case .deletionError:
            return "The API key might already be deleted."
        case .biometricError:
            return "Please check your Face ID/Touch ID settings."
        case .invalidData:
            return "Please check the API key format."
        }
    }
}

// MARK: - Import Required Frameworks
import LocalAuthentication

extension KeychainService {
    /// Request biometric authentication before accessing sensitive data
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        
        do {
            let result = try await context.evaluatePolicy(
                policy,
                localizedReason: "Authenticate to access your API keys"
            )
            return result
        } catch {
            throw KeychainError.biometricError(error)
        }
    }
} 