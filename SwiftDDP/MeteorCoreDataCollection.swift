
import UIKit
import SwiftDDP
import CoreData
import XCGLogger

let log = XCGLogger(identifier: "CoreDataCollection")

public protocol MeteorCoreDataCollectionDelegate {
    func document(willBeCreatedWith fields:NSDictionary?, forObject object:NSManagedObject) -> NSManagedObject
    func document(willBeUpdatedWith fields:NSDictionary?, cleared:[String]?, forObject object:NSManagedObject) -> NSManagedObject
}

//
//
// MeteorCollectionChange
//
//

struct MeteorCollectionChange: Hashable {
    var id:String
    var collection:String
    var fields:NSDictionary?
    var cleared:[String]?
    var hashValue:Int {
        var hash = "\(id.hashValue)\(collection.hashValue)"
        if let _ = fields { hash += "\(fields!.hashValue)" }
        if let _ = cleared {
            for value in cleared! {
                hash += "\(value.hashValue)"
            }
        }
        return hash.hashValue
    }
    
    init(id:String, collection:String, fields:NSDictionary?, cleared:[String]?){
        self.id = id
        self.collection = collection
        self.fields = fields
        self.cleared = cleared
    }
}

func ==(lhs:MeteorCollectionChange, rhs:MeteorCollectionChange) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

//
//
// End Meteor Collection Change
//
//

public class MeteorCoreDataCollection:Collection {
    
    var entityName:String!
    var delegate:MeteorCoreDataCollectionDelegate?
    private let stack = MeteorCoreData.stack
    
    private let backgroundQueue:NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "MeteorCoreData background queue"
        // queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private let mainQueue = NSOperationQueue.mainQueue()
    
    private var changeLog = [Int:MeteorCollectionChange]()
    
    init(collectionName:String, entityName:String) {
        super.init(name: collectionName)
        self.entityName = entityName
        print("Initializing Meteor Core Data Collection \(self.entityName)")
    }
    
    deinit {
    }
    
    var managedObjectContext:NSManagedObjectContext {
        return stack.managedObjectContext
    }
    
    private func newObject() -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
        let object = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
        return object
    }
    
    private func getObjectOnCurrentQueue(objectId:NSManagedObjectID) -> NSManagedObject? {
        do {
            let currentQueueObject = try self.managedObjectContext.existingObjectWithID(objectId)
            return currentQueueObject
        } catch let error {
            log.error("Error fetching object \(objectId) changes on the current queue: \(error)")
            return nil
        }
    }
    
    // Retrieves all results for a given entity name
    func find() -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        do {
            let results = try managedObjectContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            return results!
        } catch let error {
            print("Error fetching results \(error)")
        }
        return []
    }
    
    // Retrieves a single result by name
    func findOne(id:String) -> NSManagedObject? {
        managedObjectContext.refreshAllObjects()
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id == '\(id)'")
        let results = try! managedObjectContext.executeFetchRequest(fetchRequest)
        if results.count > 0 {
            return results[0] as? NSManagedObject
        }
        return nil
    }
    
    func exists(id:String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id == '\(id)'")
        let count = managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        if count > 0 {
            return true
        }
        return false
    }
    
    func exists(collection:String, id:String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id == '\(id)' AND collection == '\(collection)'")
        let count = managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        if count > 0 {
            return true
        }
        return false
    }
    
    //
    //
    //
    // INSERT
    //
    //
    //
    
    func insert(fields:NSDictionary) {
        backgroundQueue.addOperationWithBlock() {
            
            let object = self.newObject()
            if let id = fields.objectForKey("_id") {
                object.setValue(id, forKey: "id")
            } else {
                let id = self.client.getId()
                object.setValue(id, forKey: "id")
            }
            object.setValue(self.name, forKey: "collection")
            self.delegate?.document(willBeCreatedWith: fields, forObject: object)
            try! self.managedObjectContext.save()
            
            let result = self.client.insert(sync: self.name, document: [fields])
            if result.error != nil {
                self.managedObjectContext.deleteObject(object)
                try! self.managedObjectContext.save()
            }
            
        }
    }
    
    //
    //
    //
    // UPDATE
    //
    //
    //
    
    public func update(id:String, fields:NSDictionary, local:Bool) {
        backgroundQueue.addOperationWithBlock() {

            if let object = self.findOne(id) {
                
                self.managedObjectContext.undoManager?.beginUndoGrouping()
                let change = MeteorCollectionChange(id: id, collection: self.name, fields: fields, cleared: nil)
                self.changeLog[change.hashValue] = change
                self.delegate?.document(willBeUpdatedWith: fields, cleared: nil, forObject: object)
                try! self.managedObjectContext.save()
                self.managedObjectContext.undoManager?.endUndoGrouping()
                
                if local == false {
                    let result = self.client.update(sync: self.name, document: [["_id":id], ["$set":fields]])
                    if result.error != nil {
                        log.debug("Update rejected. Attempting to rollback changes")
                        self.managedObjectContext.undoManager?.undoNestedGroup()
                        try! self.managedObjectContext.save()
                    }
                }
            }
        }
    }
    
    public func update(id:String, fields:NSDictionary) {
        update(id, fields:fields, local:false)
    }
    
    //
    //
    //
    // REMOVE
    //
    //
    //
    
    func remove(withId id:String) {
        remove(withId: id, local:false)
    }
    
    // Local delete signals when the delete originates from the server; 
    // In that case, the delete should only be processed locally, and no 
    // message regarding the delete should be sent to the server
    func remove(withId id:String, local:Bool) {
        backgroundQueue.addOperationWithBlock() {
            
            if let document = self.findOne(id) {
                self.managedObjectContext.undoManager?.beginUndoGrouping()
                let id = document.valueForKey("id")
                self.managedObjectContext.deleteObject(document)
                try! self.managedObjectContext.save()
                self.managedObjectContext.undoManager?.endUndoGrouping()
                
                if local == false {
                    if let _ = id {
                        let result = self.client.remove(sync: self.name, document: NSArray(arrayLiteral: ["_id":id!]))
                        if result.error != nil {
                            self.managedObjectContext.undoManager?.undoNestedGroup()
                            try! self.managedObjectContext.save()
                        }
                    }
                }
            }
        }
        
    }
    
    override public func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        if !self.exists(collection, id:id) {
            let object = self.newObject()
            object.setValue(id, forKey: "id")
            object.setValue(collection, forKey: "collection")
            
            if let _ = self.delegate?.document(willBeCreatedWith: fields, forObject: object) {
                try! managedObjectContext.save()
            }
        } else {
            log.info("Object \(collection) \(id) already exists in the database")
        }
        
    }
    
    
    
    override public func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        let currentChange = MeteorCollectionChange(id: id, collection: collection, fields: fields, cleared: cleared)
        
        if let priorChange = self.changeLog[currentChange.hashValue] where (priorChange.hashValue == currentChange.hashValue) {
            self.changeLog[currentChange.hashValue] = nil
            return
        }
    
        if let object = self.findOne(id) {
            if let _ = self.delegate?.document(willBeUpdatedWith: fields, cleared: cleared, forObject: object) {
                try! self.managedObjectContext.save()
            }
        }
        
        self.changeLog[currentChange.hashValue] = nil // Deregister the change
        
    }
    
    override public func documentWasRemoved(collection:String, id:String) {
        if self.exists(collection, id:id) {
            self.remove(withId:id, local: true)
        } else {
            log.debug("document \(id) not found")
        }
    }

    
}