import Foundation
import CoreData


public protocol MeteorCoreDataStack {
    var mainContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    var managedObjectContext:NSManagedObjectContext { get }
}

class MeteorCoreDataStackPersisted:NSObject, MeteorCoreDataStack {
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeCoreDataChanges:", name: NSManagedObjectContextDidSaveNotification, object: backgroundContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("MeteorCoreData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        try! coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        return coordinator
    }
    
    var managedObjectContext:NSManagedObjectContext {
        if (NSOperationQueue.currentQueue() == NSOperationQueue.mainQueue()) {
            return self.mainContext
        }
        return backgroundContext
    }
    
    
    lazy var mainContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.stalenessInterval = 0
        return context
        }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.stalenessInterval = 0
        return context
        }()
    
    func mergeCoreDataChanges(notification: NSNotification) {
        let context = notification.object as! NSManagedObjectContext
        if context === mainContext {
            log.debug("Merging changes mainQueue > privateQueue")
            backgroundContext.performBlock() {
                self.backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        } else if context === backgroundContext {
            log.debug("Merging changes privateQueue > mainQueue")
            mainContext.performBlock() {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        } else {
            log.debug("Merging changes mainQueue <> privateQueue")
            backgroundContext.performBlock() {
                self.backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            
            mainContext.performBlock() {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            
        }
    }
}
