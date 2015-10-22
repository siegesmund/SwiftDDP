//
//
//  A DDP Client written in Swift
//
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

//
// This software uses CryptoSwift: https://github.com/krzyzanowskim/CryptoSwift/
//

import Foundation
import SwiftWebSocket
import XCGLogger

let log = XCGLogger(identifier: "DDP")

public class DDP {
    
    public class Client: NSObject {
        
        // included for storing login id and token
        let userData = NSUserDefaults.standardUserDefaults()
        let messageQueue = dispatch_queue_create("com.meteor.swiftddp.message", nil)
        
        private var socket:WebSocket!
        private var server:(ping:NSDate?, pong:NSDate?) = (nil, nil)

        var resultCallbacks:[String:(result:AnyObject?, error:DDP.Error?) -> ()] = [:]
        var subCallbacks:[String:() -> ()] = [:]
        var unsubCallbacks:[String:() -> ()] = [:]
        
        var url:String!
        var subscriptions = [String:(id:String, name:String, ready:Bool)]()
        
        public var logLevel = XCGLogger.LogLevel.Debug
        public var events:Events!
        public var connection:(ddp:Bool, session:String?) = (false, nil)
        
        public override init() {
            super.init()
            setLogLevel(logLevel)
            events = DDP.Events()
        }
        
        public func getId() -> String {
            let numbers = Set<Character>(["0","1","2","3","4","5","6","7","8","9"])
            let uuid = NSUUID().UUIDString.stringByReplacingOccurrencesOfString("-", withString: "")
            var id = ""
            for character in uuid.characters {
                if (!numbers.contains(character) && (round(Float(arc4random()) / Float(UINT32_MAX)) == 1)) {
                    id += String(character).lowercaseString
                } else {
                    id += String(character)
                }
            }
            return id
        }
        
        public func connect(url:String, callback:((session:String)->())?) {
            socket = WebSocket(url)
            
            socket.event.close = {code, reason, clean in
                log.info("Web socket connection closed with code \(code). Clean: \(clean). \(reason)")
                if clean == false {
                    self.socket = WebSocket(url)
                }
            }
            
            socket.event.error = events.onWebsocketError
            
            socket.event.open = {
                if let c = callback { self.events.onConnected = c }
                self.sendMessage(["msg":"connect", "version":"1", "support":["1"]])
            }
            
            socket.event.message = { message in
                dispatch_async(self.messageQueue, {
                    if let text = message as? String {
                        do { try self.ddpMessageHandler(DDP.Message(message: text)) }
                        catch { log.debug("Message handling error. Raw message: \(text)")}
                    }
                })
            }
        }
        
        public func setLogLevel(logLevel:XCGLogger.LogLevel) {
            log.setup(logLevel, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLogLevel: true, showFileNames: false, showLineNumbers: true, showDate: false, writeToFile: nil, fileLogLevel: .None)
        }
        
        func ping() {
            sendMessage(["msg":"ping", "id":getId()])
        }
        
        // Respond to a server ping
        private func pong(ping: DDP.Message) {
            server.ping = NSDate()
            log.debug("Ping")
            var response = ["msg":"pong"]
            if let id = ping.id { response["id"] = id }
            sendMessage(response)
        }
        
        // Parse DDP messages and dispatch to the appropriate function
        func ddpMessageHandler(message: DDP.Message) throws {
            log.debug("Received message: \(message.json)")
            switch message.type {
                
            case .Connected:
                self.connection = (true, message.session!)
                self.events.onConnected(session:message.session!)
                
            case .Result:
                if let id = message.id,                              // Message has id
                   let callback = self.resultCallbacks[id],          // There is a callback registered for the message
                   let result = message.result {
                        callback(result:result, error: message.error)
                        self.resultCallbacks[id] = nil
                } else if let id = message.id,
                          let callback = self.resultCallbacks[id] {
                            callback(result:nil, error:message.error)
                            self.resultCallbacks[id] = nil
                }
            
            // Principal callbacks for managing data
            // Document was added
            case .Added: if let collection = message.collection,
                            let id = message.id {
                                documentWasAdded(collection, id: id, fields: message.fields)
                            }
                
            // Document was changed
            case .Changed: if let collection = message.collection,
                              let id = message.id {
                                documentWasChanged(collection, id: id, fields: message.fields, cleared: message.cleared)
                            }
            
            // Document was removed
            case .Removed: if let collection = message.collection,
                              let id = message.id {
                                documentWasRemoved(collection, id: id)
                            }
            
            // Notifies you when the result of a method changes
            case .Updated: dispatch_async(dispatch_get_main_queue(), {
                    if let methods = message.methods {
                        self.methodWasUpdated(methods)
                }
            })
            
            // Callbacks for managing subscriptions
            case .Ready: dispatch_async(dispatch_get_main_queue(), {
                if let subs = message.subs {
                    self.ready(subs)
                }
            })
            
            // Callback that fires when subscription has been completely removed
            //
            case .Nosub: dispatch_async(dispatch_get_main_queue(), {
                if let id = message.id {
                    self.nosub(id, error: message.error)
                }
            })

            case .Ping: pong(message)
                
            case .Pong: server.pong = NSDate()
            
            case .Error: dispatch_async(dispatch_get_main_queue(), {
                self.didReceiveErrorMessage(DDP.Error(json: message.json))
            })
                
            default: log.error("Unhandled message: \(message.json)")
                
            }
        }
        
        private func sendMessage(message:NSDictionary) {
            if let m = message.stringValue() {
                socket.send(m)
            }
        }
        
        // Execute a method on the Meteor server
        public func method(name: String, params: AnyObject?, callback: ((result:AnyObject?, error: DDP.Error?) -> ())?) -> String {
            let id = getId()
            let message = ["msg":"method", "method":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            if let c = callback { resultCallbacks[id] = c }
            sendMessage(message)
            return id
        }
        
        //
        // Subscribe
        //
        
        public func sub(id: String, name: String, params: [AnyObject]?, callback: (() -> ())?) -> String {
            if let c = callback { subCallbacks[id] = c }
            subscriptions[id] = (id, name, false)
            let message = ["msg":"sub", "name":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            sendMessage(message)
            return id
        }
        
        // Subscribe to a Meteor collection
        public func sub(name: String, params: [AnyObject]?) -> String {
            let id = getId()
            return sub(id, name: name, params: params, callback:nil)
        }
        
        public func sub(name:String, params: [AnyObject]?, callback: (() -> ())?) -> String {
            let id = getId()
            return  sub(id, name: name, params: params, callback: callback)
        }
        
        // Iterates over the Dictionary of subscriptions to find a subscription by name
        func findSubscription(name:String) -> (id:String, name:String, ready:Bool)? {
            for subscription in subscriptions.values {
                if (name == subscription.name) {
                    return subscription
                }
            }
            return nil
        }
        
        //
        // Unsubscribe
        //
        
        public func unsub(withName name: String) -> String? {
            return unsub(withName: name, callback: nil)
        }
        
        public func unsub(withName name: String, callback:(()->())?) -> String? {
            if let sub = findSubscription(name) {
                unsub(withId: sub.id, callback: callback)
                sendMessage(["msg":"unsub", "id":sub.id])
                return sub.id
            }
            return nil
        }
        
        public func unsub(withId id: String, callback: (() -> ())?) {
            if let c = callback { unsubCallbacks[id] = c }
            sendMessage(["msg":"unsub", "id":id])
        }
        
        //
        // Responding to server subscription messages
        //
        
        private func ready(subs: [String]) {
            for id in subs {
                if let callback = subCallbacks[id] {
                    callback()                          // Run the callback
                    subCallbacks[id] = nil           // Delete the callback after running
                } else {                                // If there is no callback, execute the method
                    if var sub = subscriptions[id] {
                        sub.ready = true
                        subscriptions[id] = sub
                        subscriptionIsReady(sub.id, subscriptionName: sub.name)
                    }
                }
            }
        }
        
        private func nosub(id: String, error: DDP.Error?) {
            if let e = error where (e.isValid == true) {
                print(e)
            } else {
                if let callback = unsubCallbacks[id],
                   let _ = subscriptions[id] {
                        callback()
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
        
        public func subscriptionIsReady(subscriptionId:String, subscriptionName:String) {}
        
        public func subscriptionWasRemoved(subscriptionId:String, subscriptionName:String) {}
        
        public func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
            if let added = events.onAdded { added(collection: collection, id: id, fields: fields) }
        }
        
        public func documentWasRemoved(collection:String, id:String) {
            if let removed = events.onRemoved { removed(collection: collection, id: id) }
        }
        
        public func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
            if let changed = events.onChanged { changed(collection:collection, id:id, fields:fields, cleared:cleared) }
        }
        
        public func methodWasUpdated(methods:[String]) {
            if let updated = events.onUpdated { updated(methods: methods) }
        }
        
        public func didReceiveErrorMessage(message: DDP.Error) {
            if let error = events.onError { error(message: message) }
        }
    }
}

