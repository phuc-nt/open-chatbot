import Foundation
import Combine

// MARK: - OpenRouter API Service Implementation
@MainActor
class OpenRouterAPIService: LLMAPIService {
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    private var currentTask: URLSessionDataTask?
    private let keychain: KeychainService
    private var dataBuffer: String = ""
    private var isCancelled: Bool = false
    private var currentStreamContinuation: AsyncStream<String>.Continuation?
    
    init(keychain: KeychainService) {
        // Configure session for streaming
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        self.keychain = keychain
    }
    
    // MARK: - Send Message with Streaming
    func sendMessage(
        _ message: String,
        model: LLMModel,
        conversation: [ChatMessage]?
    ) async throws -> AsyncStream<String> {
        let apiKey = try await getAPIKey()
        let request = try createChatRequest(
            message: message,
            model: model,
            conversation: conversation,
            streaming: true,
            apiKey: apiKey
        )
        
        return AsyncStream<String> { continuation in
            // Reset buffer and cancellation flag for new request
            self.dataBuffer = ""
            self.isCancelled = false
            self.currentStreamContinuation = continuation
            
            let task = self.session.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Check if request was cancelled
                    if self.isCancelled {
                        print("🛑 Request was cancelled by user")
                        continuation.finish()
                        return
                    }
                    
                    if let error = error {
                        print("❌ Network error: \(error.localizedDescription)")
                        // Set error flag for ChatViewModel to handle
                        continuation.yield("__NETWORK_ERROR__: \(error.localizedDescription)")
                        continuation.finish()
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid response type")
                        continuation.yield("__ERROR__: Invalid response type")
                        continuation.finish()
                        return
                    }
                    
                    if httpResponse.statusCode != 200 {
                        let errorData = data ?? Data()
                        let errorMessage = self.parseErrorResponse(data: errorData)
                        print("❌ HTTP error \(httpResponse.statusCode): \(errorMessage)")
                        continuation.yield("__HTTP_ERROR__\(httpResponse.statusCode): \(errorMessage)")
                        continuation.finish()
                        return
                    }
                    
                    guard let data = data,
                          let chunk = String(data: data, encoding: .utf8) else {
                        print("❌ No data received or invalid encoding")
                        continuation.finish()
                        return
                    }
                    
                                            // Process streaming chunk with proper SSE parsing
                        self.processStreamingChunk(chunk) { content in
                            continuation.yield(content)
                        } completion: {
                            continuation.finish()
                        }
                }
            }
            
            self.currentTask = task
            task.resume()
            
            continuation.onTermination = { @Sendable termination in
                task.cancel()
            }
        }
    }
    
    // MARK: - Send Message Synchronously
    func sendMessageSync(
        _ message: String,
        model: LLMModel,
        conversation: [ChatMessage]?
    ) async throws -> String {
        let apiKey = try await getAPIKey()
        let request = try createChatRequest(
            message: message,
            model: model,
            conversation: conversation,
            streaming: false,
            apiKey: apiKey
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMAPIError.unknownError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = parseErrorResponse(data: data)
            throw LLMAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message?.content else {
            throw LLMAPIError.unknownError("No content in response")
        }
        
        return content
    }
    
    // MARK: - Get Available Models
    func getAvailableModels() async throws -> [LLMModel] {
        let apiKey = try await getAPIKey()
        let url = URL(string: "\(baseURL)/models")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMAPIError.unknownError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = parseErrorResponse(data: data)
            throw LLMAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let modelsResponse = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
        return modelsResponse.data.map { $0.toLLMModel() }
    }
    
    // MARK: - Validate API Key
    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/auth/key")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - Get API Key Status
    func getAPIKeyStatus() async throws -> APIKeyStatus {
        let apiKey = try await getAPIKey()
        let url = URL(string: "\(baseURL)/auth/key")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMAPIError.unknownError("Invalid response")
        }
        
        if httpResponse.statusCode != 200 {
            throw LLMAPIError.invalidAPIKey
        }
        
        // Parse credits information if available
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let credits = json["credits"] as? Double {
            return APIKeyStatus(
                isValid: true,
                remainingCredits: credits,
                usageToday: nil,
                rateLimitRemaining: nil,
                rateLimitReset: nil
            )
        }
        
        return APIKeyStatus(
            isValid: true,
            remainingCredits: nil,
            usageToday: nil,
            rateLimitRemaining: nil,
            rateLimitReset: nil
        )
    }
    
    // MARK: - Cancel Current Request
    nonisolated func cancelCurrentRequest() {
        print("🛑 Setting cancellation flag and canceling current task")
        Task { @MainActor in
            isCancelled = true
            currentTask?.cancel()
            currentTask = nil
            
            // Force finish the AsyncStream immediately
            if let continuation = currentStreamContinuation {
                print("🛑 Force finishing AsyncStream")
                continuation.finish()
                currentStreamContinuation = nil
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getAPIKey() async throws -> String {
        guard let apiKey = await keychain.getAPIKey(for: .openrouter),
              !apiKey.isEmpty else {
            throw LLMAPIError.invalidAPIKey
        }
        return apiKey
    }
    
    private func createChatRequest(
        message: String,
        model: LLMModel,
        conversation: [ChatMessage]?,
        streaming: Bool,
        apiKey: String
    ) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/phuc-nt/open-chatbot", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("OpenChatbot iOS", forHTTPHeaderField: "X-Title")
        
        // Build messages array
        var messages: [[String: String]] = []
        
        // Add conversation history if provided
        if let conversation = conversation {
            for chatMessage in conversation {
                messages.append([
                    "role": chatMessage.role.rawValue,
                    "content": chatMessage.content
                ])
            }
        }
        
        // Add current message
        messages.append([
            "role": "user",
            "content": message
        ])
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": model.id,
            "messages": messages,
            "stream": streaming,
            "temperature": 0.7,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return request
    }
    
    private func processStreamingChunk(
        _ chunk: String,
        onContent: @escaping (String) -> Void,
        completion: @escaping () -> Void
    ) {
        // Check cancellation first before processing
        if isCancelled {
            print("🛑 Streaming cancelled during chunk processing")
            completion()
            return
        }
        
        // Add new chunk to buffer
        dataBuffer += chunk
        
        // Process complete lines from buffer
        while let lineEnd = dataBuffer.firstIndex(of: "\n") {
            // Check cancellation for each line processed
            if isCancelled {
                print("🛑 Streaming cancelled during line processing")
                completion()
                return
            }
            
            let line = String(dataBuffer[..<lineEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            dataBuffer.removeSubrange(...lineEnd)
            
            // Skip empty lines and comments (OpenRouter sends ": OPENROUTER PROCESSING" comments)
            if line.isEmpty || line.hasPrefix(":") {
                continue
            }
            
            // Process SSE data lines
            if line.hasPrefix("data: ") {
                let dataString = String(line.dropFirst(6)) // Remove "data: " prefix
                
                // Check for end of stream
                if dataString == "[DONE]" {
                    completion()
                    return
                }
                
                // Parse JSON chunk according to OpenRouter format
                guard let data = dataString.data(using: .utf8) else {
                    print("⚠️ Failed to convert data string to UTF8")
                    continue
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // OpenRouter format: {"choices":[{"delta":{"content":"text"}}]}
                        if let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String,
                           !content.isEmpty {
                            
                            // Final check before yielding content
                            if isCancelled {
                                print("🛑 Streaming cancelled before yielding content")
                                completion()
                                return
                            }
                            
                            onContent(content)
                        }
                    }
                } catch {
                    print("⚠️ JSON parsing error: \(error.localizedDescription)")
                    // Continue processing other lines even if one fails
                }
            }
        }
    }
    
    private func parseErrorResponse(data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Unknown error"
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        
        if let message = json["message"] as? String {
            return message
        }
        
        return "Unknown error"
    }
}

// Note: KeychainService methods are already implemented in KeychainService.swift 