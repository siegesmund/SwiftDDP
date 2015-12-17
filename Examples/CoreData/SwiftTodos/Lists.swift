
import UIKit
import CoreData
import SwiftDDP

//
// This class defines the table of lists
//

// Allows us to attach the list _id to the cell
public class ListCell:UITableViewCell {
    var _id:String?
}


class Lists: MeteorCoreDataTableViewController, MeteorCoreDataCollectionDelegate {
    
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    @IBAction func loginButtonWasClicked(sender: UIBarButtonItem) {
        if let _ = Meteor.client.userId() {
            logoutDialog()
        } else {
            self.performSegueWithIdentifier("loginDialog", sender: self)
        }
    }
    
    var collection:MeteorCoreDataCollection = (UIApplication.sharedApplication().delegate as! AppDelegate).lists
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "List")
        let primarySortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [secondarySortDescriptor, primarySortDescriptor]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.collection.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collection.delegate = self
        try! fetchedResultsController.performFetch()
        if let _ = Meteor.client.userId() {
            loginButton.image = UIImage(named: "user_icon_selected")
        } else {
            loginButton.image = UIImage(named:"user_icon")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        try! fetchedResultsController.performFetch()
        if let _ = Meteor.client.userId() {
            loginButton.image = UIImage(named: "user_icon_selected")
        } else {
            loginButton.image = UIImage(named:"user_icon")
        }

    }
    
    @IBOutlet weak var newListField: UITextField!
    
    @IBAction func addList(sender: AnyObject) {
        let list = (UIApplication.sharedApplication().delegate as! AppDelegate).lists

        if let newList = newListField.text {
            list.insert(["_id":Meteor.client.getId(), "name":newList])
            newListField.text = ""
        }
    }
    
    
    func logoutDialog() {
        
        let emailAddress = Meteor.client.user()
        let message = emailAddress != nil ? "Signed in as \(emailAddress!)." : "Signed in."
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
        }
        alertController.addAction(cancelAction)
        
        let signOutAction = UIAlertAction(title: "Sign Out", style: .Destructive) { (action) in
            Meteor.logout()
            self.loginButton.image = UIImage(named:"user_icon")
        }
        alertController.addAction(signOutAction)
        
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.barButtonItem = loginButton
        }
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    
    func subscriptionReady() {
        self.tableView.reloadData()
    }
    
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
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! ListCell
        
        let listItem = fetchedResultsController.objectAtIndexPath(indexPath)
        print("Cell -> \(listItem)")
        cell.textLabel?.text = listItem.valueForKey("name") as? String
        cell._id = listItem.valueForKey("id") as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let object = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            let id = object.valueForKey("id") as! String
            self.collection.remove(withId: id)
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "listsSegue") {
            let todosVC = (segue.destinationViewController as! UINavigationController).topViewController as! Todos
            let cell = (sender as! UITableViewCell)
            
            let indexPath = self.tableView.indexPathForCell(cell)
            let todo = fetchedResultsController.objectAtIndexPath(indexPath!)
            
            let id = todo.valueForKey("id") as? String
            let userId = todo.valueForKey("userId") as? String
            
            todosVC.listId = id!
            todosVC.title = cell.textLabel?.text
            
            if let _ = userId {
                todosVC.privateButton.image = UIImage(named: "locked_icon")
            } else {
                todosVC.privateButton.image = UIImage(named: "unlocked_icon")
            }
            
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
