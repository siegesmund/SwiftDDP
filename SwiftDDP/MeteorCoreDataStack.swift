import Foundation
import CoreData


public class MeteorCoreDataStack:NSObject {
    
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
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
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
        context.undoManager = NSUndoManager()
        return context
        }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.undoManager = NSUndoManager()
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
