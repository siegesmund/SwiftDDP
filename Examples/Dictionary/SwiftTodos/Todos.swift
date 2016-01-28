
import UIKit
import CoreData
import SwiftDDP

// Allows us to attach the list _id to the cell
public class TodoCell:UITableViewCell {
    var _id:String?
}


class Todos: UITableViewController {
    
    let collection:MeteorCollection<Todo> = (UIApplication.sharedApplication().delegate as! AppDelegate).todos
    let listsCollection = (UIApplication.sharedApplication().delegate as! AppDelegate).lists
    
    var listId:String? {
        didSet {
            Meteor.subscribe("todos", params: [listId!]) {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var privateButton: UIBarButtonItem!
    
    @IBAction func makeListPrivate(sender: UIBarButtonItem) {
        
        if let userId = Meteor.client.userId() {
            if let object = listsCollection.findOne(listId!) {
                if let objectUserId = object.valueForKey("userId") as? String where (objectUserId == userId) {
                    object.setValue("", forKey: "userId")
                    let fields = ["userId":"true"]
                    let operation = ["$unset":fields]
                    listsCollection.update(object, withMongoOperation: operation)
                    privateButton.image = UIImage(named: "unlocked_icon")

                } else {
                    object.setValue(userId, forKey: "userId")
                    listsCollection.update(object)
                    privateButton.image = UIImage(named: "locked_icon")
                }
            } else {
                print("Can't find object")
            }
            
        } else {
            print("You must be logged in to make a list private")
        }
    }
    
    @IBOutlet weak var addTaskTextField: UITextField!
    
    // Insert the list
    @IBAction func add(sender: UIButton) {
        if let task = addTaskTextField.text where task != "" {
            let _id = Meteor.client.getId()
            let todo = Todo(id:_id, fields: ["listId":listId!, "text":task])
            collection.insert(todo)
            addTaskTextField.text = ""
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableView", name: METEOR_COLLECTION_SET_DID_CHANGE, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        Meteor.unsubscribe("todos")
    }
    
    func reloadTableView() {
        self.tableView.reloadData()
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("todoCell", forIndexPath: indexPath) as! TodoCell
        
        let todo = collection.sorted[indexPath.row]
        if let checked = todo.valueForKey("checked") where checked as! Bool == true {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        cell.textLabel?.text = todo.valueForKey("text") as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = collection.sorted[indexPath.row]
        object.checked = !object.checked
        collection.update(object)
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let object = collection.sorted[indexPath.row]
            self.collection.remove(object)
            self.tableView.reloadData()
        }
    }
 }
