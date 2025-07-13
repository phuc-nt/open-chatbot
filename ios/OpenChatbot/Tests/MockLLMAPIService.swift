import Foundation
import Combine

/// Mock LLM API Service for testing
@MainActor
class MockLLMAPIService: ObservableObject {
    
    // MARK: - Mock Configuration
    var shouldSimulateError: Bool = false
    var mockResponse: String = "This is a mock response from the AI assistant."
    var mockDelay: TimeInterval = 0.1
    
    // MARK: - Mock Response Generation
    func generateMockResponse(for prompt: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if shouldSimulateError {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock API Error"])
        }
        
        return mockResponse
    }
    
    func generateMockStream(for prompt: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                do {
                    let response = try await generateMockResponse(for: prompt)
                    let words = response.split(separator: " ")
                    
                    for word in words {
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
} 