// Copyright (c) 2015 Peter Siegesmund <peter.siegesmund@icloud.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public class Meteor {
    public static let client = Meteor.Client()          // Client is a singleton object
    private static var collections = [String:Any]()
    
    public static func collection<T>(name: String) -> Collection<T> {
        if let c = Meteor.collections[name] {
            return c as! Collection<T>
        }
        return Collection<T>(name: name)
    }
    
    public static func subscribe(name:String) { client.sub(name, params:nil) }
    
    public static func subscribe(name:String, params:[AnyObject]) { client.sub(name, params:params) }
    
    public static func subscribe(name:String, params:[AnyObject]?, callback: (()->())?) { client.sub(name, params:params, callback:callback) }
    
    public static func connect(url:String, email:String, password:String) {
        client.connect(url) { session in
            client.loginWithPassword(email, password: password) { result, error in
                guard let _ = error else {
                    if let credentials = result as? NSDictionary {
                        client.userDidLogin(credentials)
                    }
                    return
                }
            }
        }
    }
    
    public class Client: DDP.Client {
        
        typealias SubscriptionCallback = () -> ()
        let notifications = NSNotificationCenter.defaultCenter()
        
        public convenience init(url:String, email:String, password:String) {
            self.init()
            
        }
        
       
        
        public func userDidLogin(result:NSDictionary) {
            notifications.postNotificationName("userWasLoggedIn", object: self, userInfo: ["message":result])
        }
        
        // Posts a notification when a subscription is ready
        public override func subscriptionIsReady(subscriptionId:String, subscriptionName:String) {
            let message = NSDictionary(dictionary: ["id":subscriptionId, "name":subscriptionName])
            let userInfo = ["message":message]
            notifications.postNotificationName("\(subscriptionId)_isReady", object: self, userInfo: userInfo)
            notifications.postNotificationName("\(subscriptionName)_isReady", object: self, userInfo: userInfo)
        }
        
        // Posts a notificaiton when a subscription is removed
        public override func subscriptionWasRemoved(subscriptionId:String, subscriptionName:String) {
            let message = NSDictionary(dictionary: ["id":subscriptionId, "name":subscriptionName])
            let userInfo = ["message":message]
            notifications.postNotificationName("\(subscriptionId)_wasRemoved", object: self, userInfo: userInfo)
            notifications.postNotificationName("\(subscriptionName)_wasRemoved", object: self, userInfo: userInfo)
        }
        
        // Posts a notification when a document is added
        public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
            let message = NSMutableDictionary(dictionary: ["collection":collection, "id":id])
            if let f = fields { message["fields"] = f }
            let userInfo = ["message":message]
            notifications.postNotificationName("\(collection)_wasAdded", object: self, userInfo: userInfo)
        }
        
        // Posts a notification when a document is removed
        public override func documentWasRemoved(collection:String, id:String) {
            let message = NSDictionary(dictionary:["collection":collection, "id":id])
            let userInfo = ["message":message]
            notifications.postNotificationName("\(collection)_wasRemoved", object: self, userInfo: userInfo)
        }
        
        // Posts a notification when a document is changed
        public override func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
            let message = NSMutableDictionary(dictionary: ["collection":collection, "id":id])
            if let f = fields { message["fields"] = f }
            if let c = cleared { message["cleared"] = c }
            let userInfo = ["message":message]
            notifications.postNotificationName("\(collection)_wasChanged", object: self, userInfo: userInfo)
        }
        
        public override func methodWasUpdated(methods:[String]) {
            for method in methods {
                notifications.postNotificationName("\(method)_wasUpdated", object: self)
            }
        }
    }
}

public class Collection<T>: NSObject {
    
    public let client = Meteor.client
    public var name:String!
    
    // Can also set these closures to modify behavior on added, changed, removed
    public var onAdded:((collection:String, id:String, fields:NSDictionary?) -> ())?
    public var onChanged:((collection:String, id:String, fields:NSDictionary?, cleared:[String]?) -> ())?
    public var onRemoved:((collection:String, id:String) -> ())?
    
    // Must use the constructor function to create the collection
    public init(name:String) {
        super.init()
        self.name = name
        addObservers()
        Meteor.collections[name] = self
    }
    
    deinit {
        removeObservers()
    }
    
    // adds NSNotification observers
    private func addObservers() {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.addObserver(self, selector: "addedNotification:", name: "\(name)_wasAdded", object: client)
        notifications.addObserver(self, selector: "changedNotification:", name: "\(name)_wasChanged", object: client)
        notifications.addObserver(self, selector: "removedNotification:", name: "\(name)_wasRemoved", object: client)
    }
    
    // removes NSNotification observers
    private func removeObservers() {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.removeObserver("\(name)_wasAdded")
        notifications.removeObserver("\(name)_wasChanged")
        notifications.removeObserver("\(name)_wasRemoved")
    }
    
    // These conflict with collection subclasses
    
    /*
    public func insert(doc:[NSDictionary]) -> String {
        return client.insert(name, doc: doc)
    }
    
    public func insert(doc:NSArray, callback:((result:AnyObject?, error:DDP.Error?) -> ())?) -> String {
        return client.insert(name, doc:doc, callback:callback)
    }
    
    public func update(doc:[NSDictionary]) -> String {
        return client.update(name, doc: doc)
    }
    
    public func update(doc:[NSDictionary], callback:((result:AnyObject?, error:DDP.Error?) -> ())?) -> String {
        return client.update(name, doc:doc, callback:callback)
    }
    
    public func remove(doc:[NSDictionary]) -> String {
        return client.remove(name, doc: doc)
    }
    
    public func remove(doc:[NSDictionary], callback:((result:AnyObject?, error:DDP.Error?) -> ())?) -> String {
        return client.remove(name, doc:doc, callback:callback)
    }
    */
    
    // These methods translate pull the message out of the NSNotification userInfo for a more intuitive api
    final func addedNotification(notification: NSNotification) {
        let message = (notification.userInfo as! [String:NSDictionary])["message"]!,
        collection = message["collection"] as! String,
        id = message["id"] as! String,
        fields = message["fields"] as? NSDictionary
        documentWasAdded(collection, id:id, fields:fields)
    }
    
    final func changedNotification(notification: NSNotification) {
        let message = (notification.userInfo as! [String:NSDictionary])["message"]!,
        collection = message["collection"] as! String,
        id = message["id"] as! String,
        fields = message["fields"] as? NSDictionary,
        cleared = message["cleared"] as? [String]
        documentWasChanged(collection, id:id, fields:fields, cleared:cleared)
    }
    
    final func removedNotification(notification: NSNotification) {
        let message = (notification.userInfo as! [String:NSDictionary])["message"]!,
        id = message["id"] as! String,
        collection = message["collection"] as! String
        documentWasRemoved(collection, id: id)
    }
    
    // Override these methods to subclass Collection
    public func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        if let added = onAdded { added(collection: collection, id: id, fields:fields) }
    }
    
    public func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        if let changed = onChanged { changed(collection:collection, id:id, fields:fields, cleared:cleared) }
    }
    
    public func documentWasRemoved(collection:String, id:String) {
        if let removed = onRemoved { removed(collection:collection, id:id) }
    }
}

    