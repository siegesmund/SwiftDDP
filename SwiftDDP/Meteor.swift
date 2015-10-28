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

protocol MeteorCollectionType {
    func documentWasAdded(collection:String, id:String, fields:NSDictionary?)
    func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?)
    func documentWasRemoved(collection:String, id:String)
}

public class Meteor {
    public static let client = Meteor.Client()          // Client is a singleton object
    private static var collections = [String:Any]()
    
    public static func subscribe(name:String) -> String { return client.sub(name, params:nil) }
    
    public static func subscribe(name:String, params:[AnyObject]) -> String { return client.sub(name, params:params) }
    
    public static func subscribe(name:String, params:[AnyObject]?, callback: (()->())?) -> String { return client.sub(name, params:params, callback:callback) }
    
    public static func subscribe(name:String, callback: (()->())?) -> String { return client.sub(name, params:nil, callback:callback) }
    
    //public static func unsubscribe(
    
    public static func connect(url:String, email:String, password:String) {
        client.connect(url) { session in
            client.loginWithPassword(email, password: password) { result, error in
                guard let _ = error else {
                    if let credentials = result as? NSDictionary {
                        // client.userDidLogin(credentials)
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
        
        // Posts a notification when a document is added
        public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                meteorCollection.documentWasAdded(collection, id: id, fields: fields)
            }
        }
        
        // Posts a notification when a document is removed
        public override func documentWasRemoved(collection:String, id:String) {
            // let message = NSDictionary(dictionary:["collection":collection, "id":id])
            // let userInfo = ["message":message]
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                meteorCollection.documentWasRemoved(collection, id: id)
            }
        }
        
        // Posts a notification when a document is changed
        public override func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                meteorCollection.documentWasChanged(collection, id: id, fields: fields, cleared: cleared)
            }
        }
    }
}

public class Collection: NSObject, MeteorCollectionType {
    
    public let client = Meteor.client
    public var name:String!
    var token: dispatch_once_t = 0
    // Can also set these closures to modify behavior on added, changed, removed
    public var onAdded:((collection:String, id:String, fields:NSDictionary?) -> ())?
    public var onChanged:((collection:String, id:String, fields:NSDictionary?, cleared:[String]?) -> ())?
    public var onRemoved:((collection:String, id:String) -> ())?
    
    // Must use the constructor function to create the collection
    public init(name:String) {
        super.init()
        self.name = name
        Meteor.collections[name] = self
    }
    
    deinit {
        Meteor.collections[name] = nil
    }
    
    // Because this class must inherit from NSObject (an Objective-C class) to use NSNotificationCenter, and Objective-C does not
    // support method overloading, these conflict with collection subclasses and have been commented out.
    
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

    