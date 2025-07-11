import Foundation
import Combine
import UIKit

/// Service responsible for memory persistence across app sessions
/// Handles memory loading on startup and continuity management
@MainActor
class MemoryPersistenceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoadingMemories: Bool = false
    @Published var memoriesLoaded: Bool = false
    @Published var loadedConversationCount: Int = 0
    @Published var totalMemorySize: Int = 0
    
    // MARK: - Private Properties
    private let memoryCoreDataBridge: MemoryCoreDataBridge
    private let memoryService: MemoryService
    private var cancellables = Set<AnyCancellable>()
    
    // Memory loading statistics
    private var loadingStats = MemoryLoadingStats()
    
    // MARK: - Initialization
    init(memoryCoreDataBridge: MemoryCoreDataBridge? = nil,
         memoryService: MemoryService? = nil) {
        self.memoryCoreDataBridge = memoryCoreDataBridge ?? MemoryCoreDataBridge()
        self.memoryService = memoryService ?? MemoryService()
        setupAppLifecycleObservers()
    }
    
    // MARK: - App Startup Memory Loading
    
    /// Load all conversation memories on app startup
    func loadMemoriesOnStartup() async {
        guard !isLoadingMemories else { return }
        
        isLoadingMemories = true
        loadingStats.startTime = Date()
        
        do {
            // Get all conversations that have memory data
            let conversationsWithMemory = try await getConversationsWithMemory()
            loadedConversationCount = conversationsWithMemory.count
            
            // Load memory for each conversation
            for conversationId in conversationsWithMemory {
                do {
                    if let memory = try await memoryCoreDataBridge.loadMemoryFromStorage(conversationId: conversationId) {
                        // Cache memory in MemoryService
                        await cacheMemoryInService(memory, conversationId: conversationId)
                        
                        // Update stats
                        loadingStats.successfulLoads += 1
                        updateTotalMemorySize(memory)
                    }
                } catch {
                    print("⚠️ Failed to load memory for conversation \(conversationId): \(error)")
                    loadingStats.failedLoads += 1
                }
            }
            
            // Complete loading
            await completeMemoryLoading()
            
        } catch {
            print("❌ Failed to load memories on startup: \(error)")
            isLoadingMemories = false
        }
    }
    
    /// Preload memory for specific conversation
    func preloadMemoryForConversation(_ conversationId: UUID) async {
        do {
            if let memory = try await memoryCoreDataBridge.loadMemoryFromStorage(conversationId: conversationId) {
                let syncedMemory = try await memoryCoreDataBridge.syncMemoryWithMessages(memory, conversationId: conversationId)
                await cacheMemoryInService(syncedMemory, conversationId: conversationId)
            }
        } catch {
            print("⚠️ Failed to preload memory for conversation \(conversationId): \(error)")
        }
    }
    
    /// Ensure memory continuity when switching conversations
    func ensureMemoryContinuity(for conversationId: UUID) async -> Bool {
        do {
            // Check if memory is already cached
            if await isMemoryCached(conversationId) {
                return true
            }
            
            // Load from storage if available
            if let memory = try await memoryCoreDataBridge.loadMemoryFromStorage(conversationId: conversationId) {
                let syncedMemory = try await memoryCoreDataBridge.syncMemoryWithMessages(memory, conversationId: conversationId)
                await cacheMemoryInService(syncedMemory, conversationId: conversationId)
                return true
            }
            
            return false
        } catch {
            print("⚠️ Failed to ensure memory continuity for \(conversationId): \(error)")
            return false
        }
    }
    
    // MARK: - Memory Persistence Management
    
    /// Save all cached memories to persistent storage
    func persistAllCachedMemories() async {
        do {
            let cachedConversations = await getCachedConversationIds()
            
            for conversationId in cachedConversations {
                if let memory = await getCachedMemory(conversationId) {
                    try await memoryCoreDataBridge.saveMemoryToStorage(memory, conversationId: conversationId)
                }
            }
            
            print("✅ Persisted \(cachedConversations.count) memories to storage")
        } catch {
            print("❌ Failed to persist cached memories: \(error)")
        }
    }
    
    /// Clean up stale memories (older than 24 hours)
    func cleanupStaleMemories() async {
        do {
            let staleConversations = try await getStaleConversations()
            
            for conversationId in staleConversations {
                try await memoryCoreDataBridge.clearMemoryStorage(conversationId: conversationId)
            }
            
            print("🧹 Cleaned up \(staleConversations.count) stale memories")
        } catch {
            print("⚠️ Failed to cleanup stale memories: \(error)")
        }
    }
    
    /// Get memory persistence statistics
    func getMemoryPersistenceStats() async -> MemoryPersistenceStats {
        let cachedCount = await getCachedConversationIds().count
        let totalStats = try? await getTotalMemoryStats()
        
        return MemoryPersistenceStats(
            cachedConversations: cachedCount,
            persistedConversations: totalStats?.conversations ?? 0,
            totalMessages: totalStats?.totalMessages ?? 0,
            totalTokens: totalStats?.totalTokens ?? 0,
            memorySize: totalMemorySize,
            lastLoaded: loadingStats.startTime,
            loadingSuccess: loadingStats.successfulLoads,
            loadingFailures: loadingStats.failedLoads
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func setupAppLifecycleObservers() {
        // Save memories when app enters background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.persistAllCachedMemories()
                }
            }
            .store(in: &cancellables)
        
        // Load memories when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    if await self?.memoriesLoaded == false {
                        await self?.loadMemoriesOnStartup()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func getConversationsWithMemory() async throws -> [UUID] {
        // Mock implementation - in real app this would query Core Data
        return []
    }
    
    private func cacheMemoryInService(_ memory: ConversationMemory, conversationId: UUID) async {
        // This would call MemoryService to cache the memory
        // await memoryService.cacheMemory(memory, for: conversationId)
    }
    
    private func isMemoryCached(_ conversationId: UUID) async -> Bool {
        // Check if memory is cached in MemoryService
        return false
    }
    
    private func getCachedMemory(_ conversationId: UUID) async -> ConversationMemory? {
        // Get cached memory from MemoryService
        return nil
    }
    
    private func getCachedConversationIds() async -> [UUID] {
        // Get all cached conversation IDs from MemoryService
        return []
    }
    
    private func getStaleConversations() async throws -> [UUID] {
        // Get conversations with stale memory (older than 24 hours)
        return []
    }
    
    private func getTotalMemoryStats() async throws -> (conversations: Int, totalMessages: Int, totalTokens: Int)? {
        // Get total memory statistics from Core Data
        return nil
    }
    
    private func updateTotalMemorySize(_ memory: ConversationMemory) {
        totalMemorySize += memory.estimatedTokens * 4 // Rough estimation
    }
    
    private func completeMemoryLoading() async {
        loadingStats.endTime = Date()
        loadingStats.duration = loadingStats.endTime?.timeIntervalSince(loadingStats.startTime ?? Date()) ?? 0
        
        isLoadingMemories = false
        memoriesLoaded = true
        
        print("✅ Memory loading completed:")
        print("   - Loaded: \(loadingStats.successfulLoads) conversations")
        print("   - Failed: \(loadingStats.failedLoads) conversations")
        print("   - Duration: \(String(format: "%.2f", loadingStats.duration))s")
        print("   - Total size: \(totalMemorySize) tokens")
    }
}

// MARK: - Supporting Types

struct MemoryLoadingStats {
    var startTime: Date?
    var endTime: Date?
    var duration: TimeInterval = 0
    var successfulLoads: Int = 0
    var failedLoads: Int = 0
}

struct MemoryPersistenceStats {
    let cachedConversations: Int
    let persistedConversations: Int
    let totalMessages: Int
    let totalTokens: Int
    let memorySize: Int
    let lastLoaded: Date?
    let loadingSuccess: Int
    let loadingFailures: Int
    
    var successRate: Double {
        let total = loadingSuccess + loadingFailures
        guard total > 0 else { return 0 }
        return Double(loadingSuccess) / Double(total)
    }
    
    var averageTokensPerConversation: Double {
        guard persistedConversations > 0 else { return 0 }
        return Double(totalTokens) / Double(persistedConversations)
    }
} 