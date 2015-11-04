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

/**
Meteor is a class to simplify communicating with and consuming MeteorJS server services
*/

public class Meteor {
    
    /**
    client is a singleton instance of DDPClient
    */
        
    public static let client = Meteor.Client()          // Client is a singleton object
    
    private static var collections = [String:Any]()
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription.
    */
    
    public static func subscribe(name:String) -> String { return client.sub(name, params:nil) }
    
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription.
    - parameter params:     An object containing method arguments, if any.
    */
    
    public static func subscribe(name:String, params:[AnyObject]) -> String { return client.sub(name, params:params) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription.
    - parameter params:     An object containing method arguments, if any.
    - parameter callback:   The closure to be executed when the server sends a 'ready' message.
    */
    
    public static func subscribe(name:String, params:[AnyObject]?, callback: DDPCallback?) -> String { return client.sub(name, params:params, callback:callback) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription.
    - parameter callback:   The closure to be executed when the server sends a 'ready' message.
    */
    
    public static func subscribe(name:String, callback: DDPCallback?) -> String { return client.sub(name, params:nil, callback:callback) }
    
    //public static func unsubscribe(
    
    /**
    Call a single function to establish a DDP connection, and login with email and password
    
    - parameter url:        The url to connect to
    - parameter email:      A string email address associated with a Meteor account
    - parameter password:   A string password 
    */
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
    
    /**
    Meteor.Client is a subclass of DDPClient that facilitates interaction with the MeteorCollection class
    */
    public class Client: DDPClient {
        
        typealias SubscriptionCallback = () -> ()
        let notifications = NSNotificationCenter.defaultCenter()
        
        public convenience init(url:String, email:String, password:String) {
            self.init()
        }
        
        /**
        Calls the documentWasAdded method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        - parameter fields:         an optional NSDictionary with the documents properties
        */
        
        public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    meteorCollection.documentWasAdded(collection, id: id, fields: fields)
                }
            }
        }
        
        /**
        Calls the documentWasChanged method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        - parameter fields:         an optional NSDictionary with the documents properties
        - parameter cleared:        an optional array of string property names to delete
        */
        
        public override func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    meteorCollection.documentWasChanged(collection, id: id, fields: fields, cleared: cleared)
                }
            }
        }
        
        /**
        Calls the documentWasRemoved method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        */
        
        public override func documentWasRemoved(collection:String, id:String) {
            if let meteorCollection = Meteor.collections[collection] as? MeteorCollectionType {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    meteorCollection.documentWasRemoved(collection, id: id)
                }
            }
        }
    }
}

/**
MeteorCollection is a class created to provide a base class and api for integrating SwiftDDP with persistence stores. MeteorCollection
should generally be subclassed, with the methods documentWasAdded, documentWasChanged and documentWasRemoved facilitating communicating 
with the datastore.
*/
public class MeteorCollection: NSObject, MeteorCollectionType {
    
    internal var name:String
    internal let client = Meteor.client
    
    // Alternative API to subclassing
    // Can also set these closures to modify behavior on added, changed, removed
    internal var onAdded:((collection:String, id:String, fields:NSDictionary?) -> ())?
    internal var onChanged:((collection:String, id:String, fields:NSDictionary?, cleared:[String]?) -> ())?
    internal var onRemoved:((collection:String, id:String) -> ())?
    
    /**
    Initializes a MeteorCollection object
    
    - parameter name:   The string name of the collection (must match the name of the collection on the server) 
    */
    public init(name:String) {
        self.name = name
        super.init()
        Meteor.collections[name] = self
    }
    
    deinit {
        Meteor.collections[name] = nil
    }
    
    /**
    Called when a document has been sent from the server. Always executes on the main queue
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    */
    
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

    