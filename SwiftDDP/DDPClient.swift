//
//
//  A DDP Client written in Swift
//
// Copyright (c) 2016 Peter Siegesmund <peter.siegesmund@icloud.com>
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

//
// This software uses CryptoSwift: https://github.com/krzyzanowskim/CryptoSwift/
//

import Foundation
import SwiftWebSocket
import XCGLogger

let log = XCGLogger(identifier: "DDP")

public typealias DDPMethodCallback = (_ result:Any?, _ error:DDPError?) -> ()
public typealias DDPConnectedCallback = (_ session:String) -> ()
public typealias DDPCallback = () -> ()


/**
 DDPDelegate provides an interface to react to user events
 */

public protocol SwiftDDPDelegate {
    func ddpUserDidLogin(_ user:String)
    func ddpUserDidLogout(_ user:String)
}

/**
 DDPClient is the base class for communicating with a server using the DDP protocol
 */

open class DDPClient: NSObject {
    
    // included for storing login id and token
    internal let userData = UserDefaults.standard
    
    let background: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "DDP Background Data Queue"
        queue.qualityOfService = .background
        return queue
    }()
    
    // Callbacks execute in the order they're received
    internal let callbackQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "DDP Callback Queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    // Document messages are processed in the order that they are received,
    // separately from callbacks
    internal let documentQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "DDP Background Queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        return queue
    }()
    
    // Hearbeats get a special queue so that they're not blocked by
    // other operations, causing the connection to close
    internal let heartbeat: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "DDP Heartbeat Queue"
        queue.qualityOfService = .utility
        return queue
    }()
    
    let userBackground: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "DDP High Priority Background Queue"
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    let userMainQueue: OperationQueue = {
        let queue = OperationQueue.main
        queue.name = "DDP High Priorty Main Queue"
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    fileprivate var socket:WebSocket!{
        didSet{ socket.allowSelfSignedSSL = self.allowSelfSignedSSL }
    }

    fileprivate var server:(ping:Date?, pong:Date?) = (nil, nil)
    
    internal var resultCallbacks:[String:Completion] = [:]
    internal var subCallbacks:[String:Completion] = [:]
    internal var unsubCallbacks:[String:Completion] = [:]
    
    open var url:String!
    fileprivate var subscriptions = [String:(id:String, name:String, ready:Bool)]()
    
    internal var events = DDPEvents()
    internal var connection:(ddp:Bool, session:String?) = (false, nil)
    
    open var delegate:SwiftDDPDelegate?
    

    // MARK: Settings
    
    /**
    Boolean value that determines whether the
    */
    
    open var allowSelfSignedSSL:Bool = false {
        didSet{
            guard let currentSocket = socket else { return }
            currentSocket.allowSelfSignedSSL = allowSelfSignedSSL
        }
    }
    
    /**
    Sets the log level. The default value is .None.
    Possible values: .Verbose, .Debug, .Info, .Warning, .Error, .Severe, .None
    */
    
    open var logLevel = XCGLogger.Level.none {
        didSet {
            log.setup(level: logLevel, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLevel: true, showFileNames: false, showLineNumbers: true, showDate: false, writeToFile: nil, fileLevel: .none)
        }
    }
    
    internal override init() {
        super.init()
    }
    
    /**
    Creates a random String id
    */
    
    open func getId() -> String {
        let numbers = Set<Character>(["0","1","2","3","4","5","6","7","8","9"])
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        var id = ""
        for character in uuid.characters {
            if (!numbers.contains(character) && (round(Float(arc4random()) / Float(UINT32_MAX)) == 1)) {
                id += String(character).lowercased()
            } else {
                id += String(character)
            }
        }
        return id
    }
    
    /**
     Makes a DDP connection to the server
     
     - parameter url:        The String url to connect to, ex. "wss://todos.meteor.com/websocket"
     - parameter callback:   A closure that takes a String argument with the value of the websocket session token
     */
    
    open func connect(_ url:String, callback:DDPConnectedCallback?) {
        self.url = url
        // capture the thread context in which the function is called
        let executionQueue = OperationQueue.current
        
        socket = WebSocket(url)
        //Create backoff
        let backOff:DDPExponentialBackoff = DDPExponentialBackoff()
        
        socket.event.close = {code, reason, clean in
            //Use backoff to slow reconnection retries
            backOff.createBackoff({
                log.info("Web socket connection closed with code \(code). Clean: \(clean). \(reason)")
                let event = self.socket.event
                self.socket = WebSocket(url)
                self.socket.event = event
                self.ping()
            })
        }
        
        socket.event.error = events.onWebsocketError
        
        socket.event.open = {
            self.heartbeat.addOperation() {
                
                // Add a subscription to loginServices to each connection event
                let callbackWithServiceConfiguration = { (session:String) in
                    
                    
                    // let loginServicesSubscriptionCollection = "meteor_accounts_loginServiceConfiguration"
                    let loginServiceConfiguration = "meteor.loginServiceConfiguration"
                    self.sub(loginServiceConfiguration, params: nil)           // /tools/meteor-services/auth.js line 922
                    
                    
                    // Resubscribe to existing subs on connection to ensure continuity
                    self.subscriptions.forEach({ (subscription: (String, (id: String, name: String, ready: Bool))) -> () in
                        if subscription.1.name != loginServiceConfiguration {
                            self.sub(subscription.1.id, name: subscription.1.name, params: nil, callback: nil)
                        }
                    })
                    callback?(session)
                }
                
                var completion = Completion(callback: callbackWithServiceConfiguration)
                //Reset the backoff to original values
                backOff.reset()
                completion.executionQueue = executionQueue
                self.events.onConnected = completion
                self.sendMessage(["msg":"connect", "version":"1", "support":["1"]])
            }
        }
        
        socket.event.message = { message in
            self.background.addOperation() {
                if let text = message as? String {
                    do { try self.ddpMessageHandler(DDPMessage(message: text)) }
                    catch { log.debug("Message handling error. Raw message: \(text)")}
                }
            }
        }
    }
    
    fileprivate func ping() {
        heartbeat.addOperation() {
            self.sendMessage(["msg":"ping", "id":self.getId()])
        }
    }
    
    // Respond to a server ping
    fileprivate func pong(_ ping: DDPMessage) {
        heartbeat.addOperation() {
            self.server.ping = Date()
            var response = ["msg":"pong"]
            if let id = ping.id { response["id"] = id }
            self.sendMessage(response as NSDictionary)
        }
    }
    
    // Parse DDP messages and dispatch to the appropriate function
    internal func ddpMessageHandler(_ message: DDPMessage) throws {
        
        log.debug("Received message: \(message.json)")
        
        switch message.type {
            
        case .Connected:
            self.connection = (true, message.session!)
            self.events.onConnected.execute(message.session!)
            
        case .Result: callbackQueue.addOperation() {
            if let id = message.id,                              // Message has id
                let completion = self.resultCallbacks[id],          // There is a callback registered for the message
                let result = message.result {
                    completion.execute(result, error: message.error)
                    self.resultCallbacks[id] = nil
            } else if let id = message.id,
                let completion = self.resultCallbacks[id] {
                    completion.execute(nil, error:message.error)
                    self.resultCallbacks[id] = nil
            }
            }
            
            // Principal callbacks for managing data
            // Document was added
        case .Added: documentQueue.addOperation() {
            if let collection = message.collection,
                let id = message.id {
                    self.documentWasAdded(collection, id: id, fields: message.fields)
            }
            }
            
            // Document was changed
        case .Changed: documentQueue.addOperation() {
            if let collection = message.collection,
                let id = message.id {
                    self.documentWasChanged(collection, id: id, fields: message.fields, cleared: message.cleared)
            }
            }
            
            // Document was removed
        case .Removed: documentQueue.addOperation() {
            if let collection = message.collection,
                let id = message.id {
                    self.documentWasRemoved(collection, id: id)
            }
            }
            
            // Notifies you when the result of a method changes
        case .Updated: documentQueue.addOperation() {
            if let methods = message.methods {
                self.methodWasUpdated(methods)
            }
            }
            
            // Callbacks for managing subscriptions
        case .Ready: documentQueue.addOperation() {
            if let subs = message.subs {
                self.ready(subs)
            }
            }
            
            // Callback that fires when subscription has been completely removed
            //
        case .Nosub: documentQueue.addOperation() {
            if let id = message.id {
                self.nosub(id, error: message.error)
            }
            }
            
        case .Ping: heartbeat.addOperation() { self.pong(message) }
            
        case .Pong: heartbeat.addOperation() { self.server.pong = Date() }
            
        case .Error: background.addOperation() {
            self.didReceiveErrorMessage(DDPError(json: message.json))
            }
            
        default: log.error("Unhandled message: \(message.json)")
            
        }
    }
    
    fileprivate func sendMessage(_ message:NSDictionary) {
        if let m = message.stringValue() {
            self.socket.send(m)
        }
    }
    
    /**
     Executes a method on the server. If a callback is passed, the callback is asynchronously
     executed when the method has completed. The callback takes two arguments: result and error. It
     the method call is successful, result contains the return value of the method, if any. If the method fails,
     error contains information about the error.
     
     - parameter name:       The name of the method
     - parameter params:     An object containing method arguments, if any
     - parameter callback:   The closure to be executed when the method has been executed
     */
    
    @discardableResult open func method(_ name: String, params: Any?, callback: DDPMethodCallback?) -> String {
        let id = getId()
        let message = ["msg":"method", "method":name, "id":id] as NSMutableDictionary
        if let p = params { message["params"] = p }
        
        if let completionCallback = callback {
            let completion = Completion(callback: completionCallback)
            self.resultCallbacks[id] = completion
        }
        
        userBackground.addOperation() {
            self.sendMessage(message)
        }
        return id
    }
    
    //
    // Subscribe
    //
    
    @discardableResult internal func sub(_ id: String, name: String, params: [Any]?, callback: DDPCallback?) -> String {
        
        if let completionCallback = callback {
            let completion = Completion(callback: completionCallback)
            self.subCallbacks[id] = completion
        }
        
        self.subscriptions[id] = (id, name, false)
        let message = ["msg":"sub", "name":name, "id":id] as NSMutableDictionary
        if let p = params { message["params"] = p }
        userBackground.addOperation() {
            self.sendMessage(message)
        }
        return id
    }
    
    /**
     Sends a subscription request to the server.
     
     - parameter name:       The name of the subscription
     - parameter params:     An object containing method arguments, if any
     */
    
    @discardableResult open func sub(_ name: String, params: [Any]?) -> String {
        let id = getId()
        return sub(id, name: name, params: params, callback:nil)
    }
    
    /**
     Sends a subscription request to the server. If a callback is passed, the callback asynchronously
     runs when the client receives a 'ready' message indicating that the initial subset of documents contained
     in the subscription has been sent by the server.
     
     - parameter name:       The name of the subscription
     - parameter params:     An object containing method arguments, if any
     - parameter callback:   The closure to be executed when the server sends a 'ready' message
     */
    
    open func sub(_ name:String, params: [Any]?, callback: DDPCallback?) -> String {
        let id = getId()
        print("Subscribing to ID \(id)")
        return sub(id, name: name, params: params, callback: callback)
    }
    
    // Iterates over the Dictionary of subscriptions to find a subscription by name
    internal func findSubscription(_ name:String) -> [String] {
        var subs:[String] = []
        for sub in  subscriptions.values {
            if sub.name == name {
                subs.append(sub.id)
            }
        }
        return subs
    }
    
    // Iterates over the Dictionary of subscriptions to find a subscription by name
    internal func subscriptionReady(_ name:String) -> Bool {
        for sub in  subscriptions.values {
            if sub.name == name {
                return sub.ready
            }
        }
        return false
    }
    
    //
    // Unsubscribe
    //
    
    /**
     Sends an unsubscribe request to the server.
     - parameter name:       The name of the subscription
     - parameter callback:   The closure to be executed when the server sends a 'ready' message
     */
    
    open func unsub(withName name: String) -> [String] {
        return findSubscription(name).map({id in
            background.addOperation() { self.sendMessage(["msg":"unsub", "id": id]) }
            unsub(withId: id, callback: nil)
            return id
        })
    }
    
    /**
     Sends an unsubscribe request to the server. If a callback is passed, the callback asynchronously
     runs when the client receives a 'ready' message indicating that the subset of documents contained
     in the subscription have been removed.
     
     - parameter name:       The name of the subscription
     - parameter callback:   The closure to be executed when the server sends a 'ready' message
     */
    
    open func unsub(withId id: String, callback: DDPCallback?) {
        if let completionCallback = callback {
            let completion = Completion(callback: completionCallback)
            unsubCallbacks[id] = completion
        }
        background.addOperation() { self.sendMessage(["msg":"unsub", "id":id]) }
    }
    
    //
    // Responding to server subscription messages
    //
    
    fileprivate func ready(_ subs: [String]) {
        for id in subs {
            if let completion = subCallbacks[id] {
                completion.execute()                // Run the callback
                subCallbacks[id] = nil              // Delete the callback after running
            } else {                                // If there is no callback, execute the method
                if var sub = subscriptions[id] {
                    sub.ready = true
                    subscriptions[id] = sub
                    subscriptionIsReady(sub.id, subscriptionName: sub.name)
                }
            }
        }
    }
    
    fileprivate func nosub(_ id: String, error: DDPError?) {
        if let e = error, (e.isValid == true) {
            log.error("\(e)")
        } else {
            if let completion = unsubCallbacks[id],
                let _ = subscriptions[id] {
                    completion.execute()
                    unsubCallbacks[id] = nil
                    subscriptions[id] = nil
            } else {
                if let subscription = subscriptions[id] {
                    subscriptions[id] = nil
                    subscriptionWasRemoved(subscription.id, subscriptionName: subscription.name)
                }
            }
        }
    }
    
    //
    // public callbacks: should be overridden
    //
    
    /**
    Executes when a subscription is ready.
    
    - parameter subscriptionId:             A String representation of the hash of the subscription name
    - parameter subscriptionName:           The name of the subscription
    */
    
    open func subscriptionIsReady(_ subscriptionId: String, subscriptionName:String) {}
    
    /**
     Executes when a subscription is removed.
     
     - parameter subscriptionId:             A String representation of the hash of the subscription name
     - parameter subscriptionName:           The name of the subscription
     */
    
    open func subscriptionWasRemoved(_ subscriptionId:String, subscriptionName:String) {}
    
    
    /**
     Executes when the server has sent a new document.
     
     - parameter collection:                 The name of the collection that the document belongs to
     - parameter id:                         The document's unique id
     - parameter fields:                     The documents properties
     */
    
    open func documentWasAdded(_ collection:String, id:String, fields:NSDictionary?) {
        if let added = events.onAdded { added(collection, id, fields) }
    }
    
    /**
     Executes when the server sends a message to remove a document.
     
     - parameter collection:                 The name of the collection that the document belongs to
     - parameter id:                         The document's unique id
     */
    
    open func documentWasRemoved(_ collection:String, id:String) {
        if let removed = events.onRemoved { removed(collection, id) }
    }
    
    /**
     Executes when the server sends a message to update a document.
     
     - parameter collection:                 The name of the collection that the document belongs to
     - parameter id:                         The document's unique id
     - parameter fields:                     Optional object with EJSON values containing the fields to update
     - parameter cleared:                    Optional array of strings (field names to delete)
     */
    
    open func documentWasChanged(_ collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        if let changed = events.onChanged { changed(collection, id, fields, cleared as NSArray?) }
    }
    
    /**
     Executes when the server sends a message indicating that the result of a method has changed.
     
     - parameter methods:                    An array of strings (ids passed to 'method', all of whose writes have been reflected in data messages)
     */
    
    open func methodWasUpdated(_ methods:[String]) {
        if let updated = events.onUpdated { updated(methods) }
    }
    
    /**
     Executes when the client receives an error message from the server. Such a message is used to represent errors raised by the method or subscription, as well as an attempt to subscribe to an unknown subscription or call an unknown method.
     
     - parameter message:                    A DDPError object with information about the error
     */
    
    open func didReceiveErrorMessage(_ message: DDPError) {
        if let error = events.onError { error(message) }
    }
}
