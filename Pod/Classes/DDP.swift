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

public typealias OnComplete = (result:NSDictionary?, error:NSDictionary?) -> ()

public class DDP {
    
    public class Client: NSObject {
        
        // included for storing login id and token
        let userData = NSUserDefaults.standardUserDefaults()

        private var socket:WebSocket!
        private var resultCallbacks:[String:OnComplete] = [:]
        private var subCallbacks:[String:() -> ()] = [:]
        private var unsubCallbacks:[String:() -> ()] = [:]

        private var server:(ping:NSDate?, pong:NSDate?) = (nil, nil)
        
        var url:String!
        var subscriptions = [String:(id:String, name:String, ready:Bool)]()

        public var logLevel = XCGLogger.LogLevel.None
        public var events:Events!
        public var connection:(ddp:Bool, session:String?) = (false, nil)
    
        
        public init(url:String) {
            super.init()
            setLogLevel(logLevel)
            self.url = url
            events = DDP.Events()
            socket = WebSocket(url)
            socket.event.close = events.onWebsocketClose
            socket.event.error = events.onWebsocketError
            socket.event.message = { message in
                if let text = message as? String {
                    do { try self.ddpMessageHandler(DDP.Message(message: text)) }
                    catch { log.debug("Message handling error. Raw message: \(text)")}
                }
            }
        }
        
        // Create the DDP Object and make a basic connection
        public convenience init(url:String, callback:(session:String) -> ()) {
            self.init(url:url)
            events.onConnected = callback
            socket.event.open = {
                self.connect(nil)
            }
        }
        
        func setLogLevel(logLevel:XCGLogger.LogLevel) {
            log.setup(logLevel, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLogLevel: false, showFileNames: false, showLineNumbers: true, showDate: false, writeToFile: nil, fileLogLevel: .None)
        }
        
        private func getId() -> String { return NSUUID().UUIDString }
        
        // Make a websocket connection to a Meteor server
        public func connect(callback:((session:String) -> ())?) {
            if let c = callback { events.onConnected = c }
            sendMessage(["msg":"connect", "version":"1", "support":["1", "pre2"]])
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
            case .Connected: connection = (true, message.session!); events.onConnected(session:message.session!)
                
            case .Result:
                if let id = message.id {
                    if let callback = resultCallbacks[id] {
                        events.onResult(json: message.json, callback: callback) // Message should have id if it's a result message
                        resultCallbacks[id] = nil             // Remove the callback from the dictionary
                    } else { log.debug("no callback availble for the id \(id). resultCallbacks are: \(resultCallbacks)") }
                } else { log.debug("malformed result message: \(message)") }
            
            // Principal callbacks for managing data
                
            case .Added: documentWasAdded(message.collection!, id: message.id!, fields: message.fields)
            case .Changed: documentWasChanged(message.collection!, id: message.id!, fields: message.fields, cleared: message.cleared)
            case .Removed: documentWasRemoved(message.collection!, id: message.id!)
            
            // Notifies you when the result of a method changes
            case .Updated: methodWasUpdated(message.methods!)                         // Updated message should have methods array

            // Callbacks for managing subscriptions
            case .Ready: ready(message.subs!)
            case .Nosub: nosub(message.id!, error: message.error)

            case .Ping: pong(message)
            case .Pong: server.pong = NSDate()
            case .Error: error(message.error!)
                
            default: log.debug("Unhandled message: \(message.json)")
            }
        }
        
        private func sendMessage(message:AnyObject) {
            if let m = Message.toString(message) { socket.send(m) }
        }
        
        // Execute a method on the Meteor server
        public func method(name: String, params: AnyObject?, callback: OnComplete?) -> String {
            let id = getId()
            let message = ["msg":"method", "method":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            resultCallbacks[id] = callback
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
        
        
        // If
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
        
        private func nosub(id: String, error: NSDictionary?) {
            if let e = error {
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
            if let updated = events.onUpdated {
                updated(methods: methods)
            }
        }
        
        public func error(message:NSDictionary) {
            
        }
    }
}

