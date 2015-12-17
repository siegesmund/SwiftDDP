
import UIKit
import SwiftDDP
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    let todos = MeteorCoreDataCollection(collectionName: "todos", entityName: "Todo")
    let lists = MeteorCoreDataCollection(collectionName: "lists", entityName: "List")
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.preferredDisplayMode = .AllVisible
        splitViewController.delegate = self
        
        // let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        // let listViewController = masterNavigationController.topViewController as! Lists
        
        
        Meteor.client.logLevel = .Debug
        // let url = "wss://todos.meteor.com/websocket"
        let url = "wss://meteor-ios-todos.meteor.com/websocket"
        
        Meteor.connect(url) {
            Meteor.subscribe("publicLists")
            Meteor.subscribe("privateLists")
        }
        
        print("Application Did Finish Launching")
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if let todosViewController = (secondaryViewController as? UINavigationController)?.topViewController as? Todos {
            if todosViewController.listId == nil {
                return true
            }
        }
        return false
    }
    
    // MARK: - Core Data Saving support
    /*
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }*/


}

