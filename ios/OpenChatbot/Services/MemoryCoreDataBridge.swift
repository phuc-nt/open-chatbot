import Foundation
import CoreData
import Combine

/// Bridge service giữa Memory System và Core Data persistence
/// Implements memory persistence across app sessions
@MainActor
class MemoryCoreDataBridge: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Private Properties
    private let persistenceController: PersistenceController
    private let dataService: DataService
    private var cancellables = Set<AnyCancellable>()
    
    // Memory serialization cache
    private var memoryCache: [UUID: SerializedMemory] = [:]
    
    // MARK: - Initialization
    init(persistenceController: PersistenceController = .shared,
         dataService: DataService = DataService()) {
        self.persistenceController = persistenceController
        self.dataService = dataService
        setupPerformanceMonitoring()
    }
    
    // MARK: - Public Memory Persistence Methods
    
    /// Save memory to Core Data for persistence across sessions
    func saveMemoryToStorage(_ memory: ConversationMemory, conversationId: UUID) async throws {
        isSyncing = true
        syncStatus = .saving
        
        let context = persistenceController.container.newBackgroundContext()
        
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    // Find existing conversation
                    let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)

                    guard let conversation = try context.fetch(request).first else {
                        continuation.resume(throwing: MemoryBridgeError.conversationNotFound)
                        return
                    }

                    // Serialize memory data
                    let serializedMemory = self.serializeMemory(memory)

                    // Store in conversation's memory metadata
                    conversation.setValue(serializedMemory.toData(), forKey: "memoryData")
                    conversation.setValue(Date(), forKey: "memoryLastUpdated")
                    conversation.setValue(memory.messageCount, forKey: "memoryMessageCount")
                    conversation.setValue(memory.estimatedTokens, forKey: "memoryTokenCount")

                    // Save context
                    try context.save()

                    // Update cache
                    self.memoryCache[conversationId] = serializedMemory
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await MainActor.run {
            isSyncing = false
            syncStatus = .saved
            lastSyncTime = Date()
        }
    }
    
    /// Load memory from Core Data storage
    func loadMemoryFromStorage(conversationId: UUID) async throws -> ConversationMemory? {
        isSyncing = true
        syncStatus = .loading
        
        let context = persistenceController.container.viewContext
        
        let memory = try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<ConversationMemory?, Error>) in
            context.perform {
                do {
                    // Find existing conversation
                    let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
                    
                    guard let conversation = try context.fetch(request).first,
                          let self = self else {
                        continuation.resume(throwing: MemoryBridgeError.conversationNotFound)
                        return
                    }
                    
                    // Load memory data
                    guard let memoryData = conversation.value(forKey: "memoryData") as? Data,
                          let serializedMemory = SerializedMemory.fromData(memoryData) else {
                        // No existing memory, create new one
                        let newMemory = self.createNewMemory(for: conversationId, conversation: conversation)
                        continuation.resume(returning: newMemory)
                        return
                    }
                    
                    // Deserialize memory
                    let deserializedMemory = self.deserializeMemory(serializedMemory, conversationId: conversationId)
                    continuation.resume(returning: deserializedMemory)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await MainActor.run {
            isSyncing = false
            syncStatus = .loaded
            lastSyncTime = Date()
        }
        
        return memory
    }
    
    /// Sync memory with messages from Core Data
    func syncMemoryWithMessages(_ memory: ConversationMemory, conversationId: UUID) async throws -> ConversationMemory {
        let context = persistenceController.container.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Fetch latest messages from Core Data
                    let messageRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
                    messageRequest.predicate = NSPredicate(format: "conversationId == %@", conversationId as CVarArg)
                    messageRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
                    
                    let messageEntities = try context.fetch(messageRequest)
                    let messages = messageEntities.compactMap { $0.toMessage() }
                    
                    // Create updated memory with latest messages
                    let updatedMemory = ConversationMemory(
                        conversationId: memory.conversationId,
                        messages: messages,
                        maxTokens: memory.maxTokens
                    )
                    updatedMemory.lastUpdated = Date()
                    // estimatedTokens will be calculated automatically based on messages
                    
                    continuation.resume(returning: updatedMemory)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get memory statistics for monitoring
    func getMemoryStatistics(conversationId: UUID) async -> MemoryStatistics? {
        let context = persistenceController.container.viewContext
        
        return await context.perform {
            let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
            
            guard let conversation = try? context.fetch(request).first else {
                return nil
            }
            
            let messageCount = conversation.value(forKey: "memoryMessageCount") as? Int ?? 0
            let tokenCount = conversation.value(forKey: "memoryTokenCount") as? Int ?? 0
            let lastUpdated = conversation.value(forKey: "memoryLastUpdated") as? Date
            
            return MemoryStatistics(
                messageCount: messageCount,
                estimatedTokens: tokenCount,
                lastUpdated: lastUpdated ?? Date(),
                cacheStatus: self.memoryCache[conversationId] != nil ? "cached" : "disk_only",
                memorySize: self.calculateMemorySize(conversationId: conversationId)
            )
        }
    }
    
    /// Clear memory data for conversation
    func clearMemoryStorage(conversationId: UUID) async throws {
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
            
            guard let conversation = try context.fetch(request).first else { return }
            
            // Clear memory fields
            conversation.setValue(nil, forKey: "memoryData")
            conversation.setValue(nil, forKey: "memoryLastUpdated")
            conversation.setValue(0, forKey: "memoryMessageCount")
            conversation.setValue(0, forKey: "memoryTokenCount")
            
            try context.save()
        }
        
        // Clear cache
        memoryCache.removeValue(forKey: conversationId)
    }
    
    // MARK: - Private Helper Methods
    
    private func createNewMemory(for conversationId: UUID, conversation: ConversationEntity) -> ConversationMemory {
        let messages = conversation.messagesArray
        
        let memory = ConversationMemory(
            conversationId: conversationId,
            messages: messages,
            maxTokens: 4000
        )
        memory.lastUpdated = Date()
        memory.cacheStatus = "new"
        return memory
    }
    
    private func serializeMemory(_ memory: ConversationMemory) -> SerializedMemory {
        return SerializedMemory(
            conversationId: memory.conversationId,
            messageCount: memory.messageCount,
            maxTokens: memory.maxTokens,
            lastUpdated: memory.lastUpdated,
            estimatedTokens: memory.estimatedTokens,
            cacheStatus: memory.cacheStatus,
            version: "1.0"
        )
    }
    
    private func deserializeMemory(_ serialized: SerializedMemory, conversationId: UUID) -> ConversationMemory {
        let memory = ConversationMemory(
            conversationId: conversationId,
            messages: [], // Will be loaded separately
            maxTokens: serialized.maxTokens
        )
        memory.lastUpdated = serialized.lastUpdated
        memory.cacheStatus = "loaded"
        return memory
    }
    
    private func calculateTokens(for messages: [Message]) -> Int {
        // Simple token estimation: ~4 characters per token
        let totalCharacters = messages.reduce(0) { $0 + $1.content.count }
        return totalCharacters / 4
    }
    
    private func calculateMemorySize(conversationId: UUID) -> Int {
        guard let serialized = memoryCache[conversationId] else { return 0 }
        return serialized.estimatedSize
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor memory pressure and optimize accordingly
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.optimizeMemoryCache()
                }
            }
            .store(in: &cancellables)
    }
    
    private func optimizeMemoryCache() async {
        // Remove old cached memories to free up space
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        
        memoryCache = memoryCache.filter { _, serialized in
            serialized.lastUpdated > cutoffTime
        }
    }
}

// MARK: - Supporting Types

enum SyncStatus {
    case idle
    case loading
    case saving
    case loaded
    case saved
    case error(String)
}

enum MemoryBridgeError: Error, LocalizedError {
    case conversationNotFound
    case serializationFailed
    case deserializationFailed
    case coreDataError(Error)
    
    var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found in Core Data"
        case .serializationFailed:
            return "Failed to serialize memory data"
        case .deserializationFailed:
            return "Failed to deserialize memory data"
        case .coreDataError(let error):
            return "Core Data error: \(error.localizedDescription)"
        }
    }
}

struct SerializedMemory: Codable {
    let conversationId: UUID
    let messageCount: Int
    let maxTokens: Int
    let lastUpdated: Date
    let estimatedTokens: Int
    let cacheStatus: String
    let version: String
    
    var estimatedSize: Int {
        return messageCount * 100 + estimatedTokens * 4 // Rough estimate
    }
    
    func toData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    static func fromData(_ data: Data) -> SerializedMemory? {
        return try? JSONDecoder().decode(SerializedMemory.self, from: data)
    }
} 