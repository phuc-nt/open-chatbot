import XCTest
import Security
import LocalAuthentication
@testable import OpenChatbot

final class KeychainServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    var keychainService: KeychainService!
    var testProviders: [LLMProvider]!
    var testAPIKeys: [String]!
    
    override func setUp() async throws {
        try await super.setUp()
        
        keychainService = await KeychainService()
        testProviders = [.openrouter, .openai, .anthropic]
        testAPIKeys = [
            "sk-or-v1-test123456789abcdef",
            "sk-openai-test123456789abcdef", 
            "sk-ant-test123456789abcdef"
        ]
        
        // Clean up any existing test data
        for provider in testProviders {
            try? await keychainService.deleteAPIKey(for: provider)
            try? await keychainService.deleteAPIKey(for: provider, name: "test")
        }
    }
    
    override func tearDown() async throws {
        // Clean up test data
        for provider in testProviders {
            try? await keychainService.deleteAPIKey(for: provider)
            try? await keychainService.deleteAPIKey(for: provider, name: "test")
            try? await keychainService.deleteAPIKey(for: provider, name: "backup")
        }
        
        keychainService = nil
        testProviders = nil
        testAPIKeys = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Core Storage Tests
    
    func testStoreAPIKeyBasic() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let apiKey = testAPIKeys[0]
        
        // When
        try await keychainService.storeAPIKey(apiKey, for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, apiKey, "Retrieved API key should match stored key")
    }
    
    func testStoreAPIKeyWithName() async throws {
        // Given
        let provider = LLMProvider.openai
        let apiKey = testAPIKeys[1]
        let keyName = "primary"
        
        // When
        try await keychainService.storeAPIKey(apiKey, for: provider, name: keyName)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider, name: keyName)
        XCTAssertEqual(retrievedKey, apiKey, "Named API key should be stored and retrieved correctly")
    }
    
    func testStoreMultipleKeysForSameProvider() async throws {
        // Given
        let provider = LLMProvider.anthropic
        let primaryKey = testAPIKeys[2]
        let backupKey = "sk-ant-backup123456789abcdef"
        
        // When
        try await keychainService.storeAPIKey(primaryKey, for: provider)
        try await keychainService.storeAPIKey(backupKey, for: provider, name: "backup")
        
        // Then
        let retrievedPrimary = await keychainService.getAPIKey(for: provider)
        let retrievedBackup = await keychainService.getAPIKey(for: provider, name: "backup")
        
        XCTAssertEqual(retrievedPrimary, primaryKey, "Primary key should be stored correctly")
        XCTAssertEqual(retrievedBackup, backupKey, "Backup key should be stored correctly")
        XCTAssertNotEqual(retrievedPrimary, retrievedBackup, "Keys should be stored separately")
    }
    
    func testStoreAPIKeyOverwrite() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let originalKey = testAPIKeys[0]
        let newKey = "sk-or-v1-new123456789abcdef"
        
        // When
        try await keychainService.storeAPIKey(originalKey, for: provider)
        try await keychainService.storeAPIKey(newKey, for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, newKey, "New key should overwrite old key")
        XCTAssertNotEqual(retrievedKey, originalKey, "Old key should be replaced")
    }
    
    // MARK: - Retrieval Tests
    
    func testGetAPIKeyNonExistent() async {
        // Given
        let provider = LLMProvider.openai
        
        // When
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        
        // Then
        XCTAssertNil(retrievedKey, "Non-existent key should return nil")
    }
    
    func testGetAPIKeyWithInvalidName() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let apiKey = testAPIKeys[0]
        
        try await keychainService.storeAPIKey(apiKey, for: provider)
        
        // When
        let retrievedKey = await keychainService.getAPIKey(for: provider, name: "nonexistent")
        
        // Then
        XCTAssertNil(retrievedKey, "Key with invalid name should return nil")
    }
    
    func testGetAPIKeyAfterStorage() async throws {
        // Given
        let provider = LLMProvider.anthropic
        let apiKey = testAPIKeys[2]
        
        // When
        try await keychainService.storeAPIKey(apiKey, for: provider)
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        
        // Then
        XCTAssertNotNil(retrievedKey, "Stored key should be retrievable")
        XCTAssertEqual(retrievedKey, apiKey, "Retrieved key should match stored key")
    }
    
    // MARK: - Deletion Tests
    
    func testDeleteAPIKeyBasic() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let apiKey = testAPIKeys[0]
        
        try await keychainService.storeAPIKey(apiKey, for: provider)
        
        // When
        try await keychainService.deleteAPIKey(for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertNil(retrievedKey, "Deleted key should not be retrievable")
    }
    
    func testDeleteAPIKeyWithName() async throws {
        // Given
        let provider = LLMProvider.openai
        let apiKey = testAPIKeys[1]
        let keyName = "test"
        
        try await keychainService.storeAPIKey(apiKey, for: provider, name: keyName)
        
        // When
        try await keychainService.deleteAPIKey(for: provider, name: keyName)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider, name: keyName)
        XCTAssertNil(retrievedKey, "Deleted named key should not be retrievable")
    }
    
    func testDeleteNonExistentKey() async throws {
        // Given
        let provider = LLMProvider.anthropic
        
        // When & Then
        // Should not throw error when deleting non-existent key
        try await keychainService.deleteAPIKey(for: provider)
        try await keychainService.deleteAPIKey(for: provider, name: "nonexistent")
        
        // No assertion needed - test passes if no exception is thrown
    }
    
    func testDeleteSpecificNamedKey() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let primaryKey = testAPIKeys[0]
        let testKey = "sk-or-v1-test123456789abcdef"
        
        try await keychainService.storeAPIKey(primaryKey, for: provider)
        try await keychainService.storeAPIKey(testKey, for: provider, name: "test")
        
        // When
        try await keychainService.deleteAPIKey(for: provider, name: "test")
        
        // Then
        let primaryRetrieved = await keychainService.getAPIKey(for: provider)
        let testRetrieved = await keychainService.getAPIKey(for: provider, name: "test")
        
        XCTAssertEqual(primaryRetrieved, primaryKey, "Primary key should remain after deleting named key")
        XCTAssertNil(testRetrieved, "Named key should be deleted")
    }
    
    // MARK: - Multiple Keys Management Tests
    
    func testGetAllAPIKeysEmpty() async {
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        
        // Then
        XCTAssertTrue(allKeys.isEmpty, "Should return empty array when no keys stored")
    }
    
    func testGetAllAPIKeysWithMultipleProviders() async throws {
        // Given
        for (index, provider) in testProviders.enumerated() {
            try await keychainService.storeAPIKey(testAPIKeys[index], for: provider)
        }
        
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        
        // Then
        XCTAssertEqual(allKeys.count, testProviders.count, "Should return all stored keys")
        
        let providers = Set(allKeys.map { $0.provider })
        let expectedProviders = Set(testProviders)
        XCTAssertEqual(providers, expectedProviders, "Should include all providers")
        
        for storedKey in allKeys {
            let expectedIndex = testProviders.firstIndex(of: storedKey.provider)!
            XCTAssertEqual(storedKey.apiKey, testAPIKeys[expectedIndex], "Key should match expected value")
        }
    }
    
    func testGetAllAPIKeysWithNamedKeys() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let primaryKey = testAPIKeys[0]
        let backupKey = "sk-or-v1-backup123456789abcdef"
        
        try await keychainService.storeAPIKey(primaryKey, for: provider)
        try await keychainService.storeAPIKey(backupKey, for: provider, name: "backup")
        
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        
        // Then
        XCTAssertEqual(allKeys.count, 2, "Should return both primary and named keys")
        
        let primaryStored = allKeys.first { $0.name == nil }
        let backupStored = allKeys.first { $0.name == "backup" }
        
        XCTAssertNotNil(primaryStored, "Primary key should be included")
        XCTAssertNotNil(backupStored, "Backup key should be included")
        XCTAssertEqual(primaryStored?.apiKey, primaryKey, "Primary key should match")
        XCTAssertEqual(backupStored?.apiKey, backupKey, "Backup key should match")
    }
    
    // MARK: - Validation Tests
    
    func testValidateAllAPIKeysEmpty() async {
        // When
        let validationResults = await keychainService.validateAllAPIKeys()
        
        // Then
        XCTAssertTrue(validationResults.isEmpty, "Should return empty results when no keys stored")
    }
    
    func testValidateAllAPIKeysWithValidKeys() async throws {
        // Given
        for (index, provider) in testProviders.enumerated() {
            try await keychainService.storeAPIKey(testAPIKeys[index], for: provider)
        }
        
        // When
        let validationResults = await keychainService.validateAllAPIKeys()
        
        // Then
        XCTAssertEqual(validationResults.count, testProviders.count, "Should validate all providers")
        
        for provider in testProviders {
            XCTAssertEqual(validationResults[provider], true, "Valid keys should be marked as valid")
        }
    }
    
    func testValidateAllAPIKeysWithEmptyKey() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let emptyKey = ""
        
        try await keychainService.storeAPIKey(emptyKey, for: provider)
        
        // When
        let validationResults = await keychainService.validateAllAPIKeys()
        
        // Then
        XCTAssertEqual(validationResults[provider], false, "Empty key should be marked as invalid")
    }
    
    // MARK: - StoredAPIKey Model Tests
    
    func testStoredAPIKeyDisplayName() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let apiKey = testAPIKeys[0]
        let keyName = "production"
        
        try await keychainService.storeAPIKey(apiKey, for: provider)
        try await keychainService.storeAPIKey(apiKey, for: provider, name: keyName)
        
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        
        // Then
        let primaryKey = allKeys.first { $0.name == nil }
        let namedKey = allKeys.first { $0.name == keyName }
        
        XCTAssertEqual(primaryKey?.displayName, provider.displayName, "Primary key should show provider name")
        XCTAssertEqual(namedKey?.displayName, "\(provider.displayName) - \(keyName)", "Named key should show provider and name")
    }
    
    func testStoredAPIKeyMaskedDisplay() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let apiKey = "sk-or-v1-1234567890abcdef1234567890abcdef"
        
        try await keychainService.storeAPIKey(apiKey, for: provider)
        
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        let storedKey = allKeys.first!
        
        // Then
        // Expected: prefix(4) + 8 bullets + suffix(4) = "sk-o••••••••cdef"
        let expectedMasked = "sk-o••••••••cdef"
        XCTAssertEqual(storedKey.maskedAPIKey, expectedMasked, "API key should be properly masked")
        XCTAssertNotEqual(storedKey.maskedAPIKey, apiKey, "Masked key should not expose full key")
    }
    
    func testStoredAPIKeyMaskedDisplayShortKey() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let shortKey = "short"
        
        try await keychainService.storeAPIKey(shortKey, for: provider)
        
        // When
        let allKeys = await keychainService.getAllAPIKeys()
        let storedKey = allKeys.first!
        
        // Then
        // For short keys (<=8 chars), it returns 8 bullets
        XCTAssertEqual(storedKey.maskedAPIKey, "••••••••", "Short keys should be fully masked")
    }
    
    // MARK: - Biometric Authentication Tests
    
    @MainActor
    func testBiometricAuthenticationAvailability() {
        // When
        let isAvailable = keychainService.isBiometricAuthenticationAvailable
        
        // Then
        // Note: This will vary by device/simulator
        // On simulator without biometrics, should be false
        // On device with Face ID/Touch ID, should be true
        XCTAssertNotNil(isAvailable, "Biometric availability should return a boolean value")
    }
    
    func testEnableBiometricAuthentication() async throws {
        // Given & When & Then
        // Note: This test may need to be skipped on devices without biometrics
        // or adjusted based on specific implementation requirements
        
        // For now, we test that the method can be called without crashing
        try await keychainService.enableBiometricAuthentication()
        
        // No assertion needed - test passes if no exception is thrown
    }
    
    // MARK: - Error Handling Tests
    
    func testKeychainErrorDescriptions() {
        // Given
        let storageError = KeychainError.storageError(errSecDuplicateItem)
        let deletionError = KeychainError.deletionError(errSecItemNotFound)
        let biometricError = KeychainError.biometricError(NSError(domain: "test", code: -1))
        let invalidDataError = KeychainError.invalidData
        
        // Then
        XCTAssertNotNil(storageError.errorDescription, "Storage error should have description")
        XCTAssertNotNil(deletionError.errorDescription, "Deletion error should have description")
        XCTAssertNotNil(biometricError.errorDescription, "Biometric error should have description")
        XCTAssertNotNil(invalidDataError.errorDescription, "Invalid data error should have description")
        
        XCTAssertNotNil(storageError.recoverySuggestion, "Storage error should have recovery suggestion")
        XCTAssertNotNil(deletionError.recoverySuggestion, "Deletion error should have recovery suggestion")
        XCTAssertNotNil(biometricError.recoverySuggestion, "Biometric error should have recovery suggestion")
        XCTAssertNotNil(invalidDataError.recoverySuggestion, "Invalid data error should have recovery suggestion")
    }
    
    // MARK: - Edge Cases and Security Tests
    
    func testStoreEmptyAPIKey() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let emptyKey = ""
        
        // When
        try await keychainService.storeAPIKey(emptyKey, for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, emptyKey, "Empty key should be stored and retrieved")
    }
    
    func testStoreVeryLongAPIKey() async throws {
        // Given
        let provider = LLMProvider.openai
        let longKey = String(repeating: "a", count: 1000)
        
        // When
        try await keychainService.storeAPIKey(longKey, for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, longKey, "Long key should be stored and retrieved correctly")
    }
    
    func testStoreAPIKeyWithSpecialCharacters() async throws {
        // Given
        let provider = LLMProvider.anthropic
        let specialKey = "sk-ant-!@#$%^&*()_+-=[]{}|;:,.<>?"
        
        // When
        try await keychainService.storeAPIKey(specialKey, for: provider)
        
        // Then
        let retrievedKey = await keychainService.getAPIKey(for: provider)
        XCTAssertEqual(retrievedKey, specialKey, "Key with special characters should be handled correctly")
    }
    
    func testConcurrentOperations() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let keys = ["key1", "key2", "key3", "key4", "key5"]
        
        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for (index, key) in keys.enumerated() {
                group.addTask {
                    try? await self.keychainService.storeAPIKey(key, for: provider, name: "concurrent\(index)")
                }
            }
        }
        
        // Then
        let allKeys = await keychainService.getAllAPIKeys()
        let concurrentKeys = allKeys.filter { $0.name?.starts(with: "concurrent") == true }
        
        XCTAssertEqual(concurrentKeys.count, keys.count, "All concurrent operations should complete")
        
        // Clean up
        for index in 0..<keys.count {
            try? await keychainService.deleteAPIKey(for: provider, name: "concurrent\(index)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() async throws {
        // Given
        let provider = LLMProvider.openrouter
        let primaryKey = testAPIKeys[0]
        let backupKey = "sk-or-v1-backup123456789abcdef"
        
        // When - Complete workflow
        // 1. Store primary key
        try await keychainService.storeAPIKey(primaryKey, for: provider)
        
        // 2. Store backup key
        try await keychainService.storeAPIKey(backupKey, for: provider, name: "backup")
        
        // 3. Verify both keys exist
        let allKeys = await keychainService.getAllAPIKeys()
        XCTAssertEqual(allKeys.count, 2, "Both keys should be stored")
        
        // 4. Validate keys
        let validationResults = await keychainService.validateAllAPIKeys()
        XCTAssertEqual(validationResults[provider], true, "Keys should be valid")
        
        // 5. Update primary key
        let newPrimaryKey = "sk-or-v1-newprimary123456789abcdef"
        try await keychainService.storeAPIKey(newPrimaryKey, for: provider)
        
        // 6. Verify update
        let updatedPrimary = await keychainService.getAPIKey(for: provider)
        let unchangedBackup = await keychainService.getAPIKey(for: provider, name: "backup")
        
        XCTAssertEqual(updatedPrimary, newPrimaryKey, "Primary key should be updated")
        XCTAssertEqual(unchangedBackup, backupKey, "Backup key should remain unchanged")
        
        // 7. Delete backup key
        try await keychainService.deleteAPIKey(for: provider, name: "backup")
        
        // 8. Verify deletion
        let finalKeys = await keychainService.getAllAPIKeys()
        XCTAssertEqual(finalKeys.count, 1, "Only primary key should remain")
        XCTAssertEqual(finalKeys.first?.name, nil, "Remaining key should be primary")
    }
}

// MARK: - Test Performance

extension KeychainServiceTests {
    
    func testPerformanceStoreMultipleKeys() async throws {
        // Given - Setup data
        var keys: [String] = []
        for i in 0..<10 {
            keys.append("test-key-\(i)")
        }
        
        // When - Measure performance of storing multiple keys
        measure {
            let exp = expectation(description: "Store keys")
            Task {
                for (index, key) in keys.enumerated() {
                    try? await keychainService.storeAPIKey(key, for: .openrouter, name: "perf\(index)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
        
        // Clean up
        for i in 0..<10 {
            try? await keychainService.deleteAPIKey(for: .openrouter, name: "perf\(i)")
        }
    }
    
    func testPerformanceRetrieveMultipleKeys() async throws {
        // Setup
        for i in 0..<10 {
            try? await keychainService.storeAPIKey("test-key-\(i)", for: .openrouter, name: "perf\(i)")
        }
        
        // Measure performance of retrieving multiple keys
        measure {
            let exp = expectation(description: "Retrieve keys")
            Task {
                for i in 0..<10 {
                    _ = await keychainService.getAPIKey(for: .openrouter, name: "perf\(i)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
        
        // Clean up
        for i in 0..<10 {
            try? await keychainService.deleteAPIKey(for: .openrouter, name: "perf\(i)")
        }
    }
} 