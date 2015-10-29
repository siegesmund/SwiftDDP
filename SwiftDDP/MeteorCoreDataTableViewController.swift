
import UIKit
import CoreData

public class MeteorCoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Move: print("> Move"); if indexPath!.isEqual(newIndexPath!) == false {
            self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        } else {
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Delete: print("> Delete"); self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Insert: print("> Insert"); self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Update: print("> Update"); self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

}
