import CoreData
import CloudKit

/// Core Data persistence controller với CloudKit sync support
class PersistenceController {
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    
    lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "OpenChatbot")
        
        // CloudKit configuration
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // CloudKit container identifier will be configured in project settings
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    // MARK: - Context Management
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    /// Background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    // MARK: - Save Operations
    
    /// Save changes to the view context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    /// Save changes to a specific context
    func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - Preview Support
    
    /// In-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        // NOTE: Sample data creation will be implemented after Core Data entities are generated
        
        do {
            try viewContext.save()
        } catch {
            print("Preview data creation error: \(error)")
        }
        
        return result
    }()
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "OpenChatbot")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
} 