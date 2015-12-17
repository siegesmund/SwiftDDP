
import UIKit
import CoreData
import SwiftDDP

// Allows us to attach the list _id to the cell
public class TodoCell:UITableViewCell {
    var _id:String?
}


class Todos: MeteorCoreDataTableViewController, MeteorCoreDataCollectionDelegate {
    
    @IBOutlet weak var privateButton: UIBarButtonItem!
    
    @IBAction func makeListPrivate(sender: UIBarButtonItem) {
        if let userId = Meteor.client.userId() {
            
            if let objectUserId = lists.findOne(listId!)?.valueForKey("userId") as? String where (objectUserId == userId)  {
                lists.update(listId!, fields: ["userId": "true"], action:"$unset")
                privateButton.image = UIImage(named: "unlocked_icon")
            } else {
                lists.update(listId!, fields: ["userId": userId])
                privateButton.image = UIImage(named: "locked_icon")
            }
            
        } else {
            print("You must be logged in to make a list private")
        }
    }
    
    let todos:MeteorCoreDataCollection = (UIApplication.sharedApplication().delegate as! AppDelegate).todos
    let lists:MeteorCoreDataCollection = (UIApplication.sharedApplication().delegate as! AppDelegate).lists
    
    var listId:String? {
        didSet {
            Meteor.subscribe("todos", params: [listId!])
            try! fetchedResultsController.performFetch()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //meteor.unsub("todos")
    }
    
    private lazy var predicate:NSPredicate? = {
        if let _ = self.listId {
            return NSPredicate(format: "listId == '\(self.listId!)'")
        }
        return nil
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Todo")
        let primarySortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let secondarySortDescriptor = NSSortDescriptor(key: "listId", ascending: false)
        fetchRequest.sortDescriptors = [secondarySortDescriptor, primarySortDescriptor]
        if let _ = self.predicate { fetchRequest.predicate = self.predicate! }
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.todos.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        todos.delegate = self
    }
    
    @IBOutlet weak var addTaskTextField: UITextField!
   
    // Insert the list
    @IBAction func add(sender: UIButton) {
        if let task = addTaskTextField.text where task != "" {
            let _id = Meteor.client.getId()
            todos.insert(["_id":_id, "listId":listId!, "text":task] as NSDictionary)
            addTaskTextField.text = ""
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("todoCell", forIndexPath: indexPath) as! TodoCell
        let todo = fetchedResultsController.objectAtIndexPath(indexPath)
        if let checked = todo.valueForKey("checked") where checked as! Bool == true {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        cell.textLabel?.text = todo.valueForKey("text") as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = fetchedResultsController.objectAtIndexPath(indexPath)
        let id = object.valueForKey("id") as! String
        let checked = object.valueForKey("checked") as! Bool
        let update = ["checked":!checked]
        todos.update(id, fields: update)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let object = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            let id = object.valueForKey("id") as! String
            self.todos.remove(withId: id)
        }
    }
    
    func document(willBeCreatedWith fields: NSDictionary?, forObject object: NSManagedObject) -> NSManagedObject {
        if let data = fields {
            for (key,value) in data {
                if !key.isEqual("createdAt") && !key.isEqual("_id") {
                    object.setValue(value, forKey: key as! String)
                }
            }
        }
        
        if !(object.valueForKey("checked") is Bool) {
            object.setValue(false, forKey: "checked")
        }
        
        return object
    }
    
    func document(willBeUpdatedWith fields: NSDictionary?, cleared: [String]?, forObject object: NSManagedObject) -> NSManagedObject {
        if let _ = fields {
            for (key,value) in fields! {
                object.setValue(value, forKey: key as! String)
            }
        }
        
        if let _ = cleared {
            for field in cleared! {
                object.setNilValueForKey(field)
            }
        }
        return object
    }

 }
