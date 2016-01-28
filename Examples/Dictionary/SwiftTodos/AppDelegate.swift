
import UIKit
import SwiftDDP
import CoreData

let LISTS_SUBSCRIPTION_IS_READY = "LISTS_SUBSCRIPTION_IS_READY"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    let lists = MeteorCollection<List>(name: "lists")
    let todos = MeteorCollection<Todo>(name: "todos")
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        splitViewController.preferredDisplayMode = .AllVisible
        splitViewController.delegate = self
        
        // let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        // let listViewController = masterNavigationController.topViewController as! Lists
        
        Meteor.client.logLevel = .Debug
        // let url = "ws://localhost:3000/websocket"
        let url = "wss://meteor-ios-todos.meteor.com/websocket"
        
        Meteor.connect(url) {
            Meteor.subscribe("publicLists") { self.listsSubscriptionIsReady() }
            Meteor.subscribe("privateLists") { self.listsSubscriptionIsReady() }
        }
        
        print("Application Did Finish Launching")
        return true
    }
    
    func listsSubscriptionIsReady() {
        print("subscription is ready")
        NSNotificationCenter.defaultCenter().postNotificationName(LISTS_SUBSCRIPTION_IS_READY, object: nil)
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if let todosViewController = (secondaryViewController as? UINavigationController)?.topViewController as? Todos {
            if todosViewController.listId == nil {
                return true
            }
        }
        return false
    }


}

