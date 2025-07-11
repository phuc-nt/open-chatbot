import SwiftUI

@main
struct OpenChatbotApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared
    
    // Memory persistence service for cross-session memory continuity
    @StateObject private var memoryPersistenceService = MemoryPersistenceService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(memoryPersistenceService)
                .task {
                    // Load memories on app startup
                    await memoryPersistenceService.loadMemoriesOnStartup()
                }
        }
    }
} 