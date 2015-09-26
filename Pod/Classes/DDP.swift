//
//
//  A DDP Client written in Swift
//
// Copyright (c) 2015 Peter Siegesmund <peter.siegesmund@gmail.com>
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

let log = XCGLogger(identifier: "DDPLog")

public typealias OnComplete = (result:NSDictionary?, error:NSDictionary?) -> ()

public class DDP {
    
    public class Client: NSObject {
        
        let userData = NSUserDefaults.standardUserDefaults()

        var url:String!
        var socket:WebSocket!
        var session:String!
        var test = false
        var subscriptions = [String:String]()
        var callbacks:[String:OnComplete?] = [:]
        
        public var logLevel = XCGLogger.LogLevel.None
        public var events:Events!
        public var connected = false
        
        public init(url:String) {
            super.init()
            log.setup(logLevel, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLogLevel: false, showFileNames: false, showLineNumbers: true, showDate: false, writeToFile: nil, fileLogLevel: .None)
            self.url = url
            events = DDP.Events()
            events.onPing = pong
            socket = WebSocket(url)
            socket.event.close = events.onWebsocketClose
            socket.event.error = events.onWebsocketError
            socket.event.message = { message in
                if let text = message as? String {
                    self.ddpMessageHandler(DDP.Message(message: text))
                }
            }
        }
        
        // Create the DDP Object and make a basic connection
        public convenience init(url:String, onConnected:OnComplete) {
            self.init(url:url)
            events.onConnected = onConnected
            socket.event.open = {
                self.connect(nil)
            }
        }
        
        private func getId() -> String { return NSUUID().UUIDString }
        
        // Respond to a server ping
        private func pong(ping: DDP.Message) {
            var response = ["msg":"pong"]
            if let id = ping.id { response["id"] = id }
            sendMessage(response)
        }
        
        // Parse DDP messages and dispatch to the appropriate function
        internal func ddpMessageHandler(message: DDP.Message) {
            log.debug("Received message: \(message.json)")
            switch message.type {
            case .Connected:
                session = message.session!
                connected = true
                events.onConnected(result: nil,error: nil)
                
            case .Result:
                if let id = message.id {
                    if let callback = callbacks[id] {
                        events.onResult(json: message.json, callback: callback) // Message should have id if it's a result message
                    } else { log.debug("no callback availble for the id \(id). callbacks are: \(callbacks)") }
                } else { log.debug("malformed result message: \(message)") }
            
            case .Updated: events.onUpdated(methods: message.methods!)                         // Updated message should have methods array
            case .Nosub: events.onNosub(id: message.id!, error: message.error)
            case .Added: events.onAdded(collection: message.collection!, id: message.id!, fields: message.fields)
            case .Changed: events.onChanged(collection: message.collection!, id: message.id!, fields: message.fields, cleared: message.cleared)
            case .Removed: events.onRemoved(collection: message.collection!, id: message.id!)
            case .Ready: events.onReady(subs: message.subs!)
            case .Ping: events.onPong(message: message)
            case .Pong: log.debug("[DDP] Pong received")
            
            // The ordered messages are not currently used by Meteor
            // case .AddedBefore: events.onAddedBefore(collection: message.collection!, id: message.id!, fields: message.fields!, before: message.before!)
            // case .MovedBefore: events.onMovedBefore(collection: message.collection!, id: message.id!, before: message.before!)
                
            default: log.debug("[DDP] Unhandled message: \(message.json)")
            }
        }
        
        private func sendMessage(message:AnyObject) {
            if let m = Message.toString(message) { socket.send(m) }
        }
        
        // Make a websocket connection to a Meteor server
        public func connect(onConnected:OnComplete?) {
            if let callback = onConnected { events.onConnected = callback }
            sendMessage(["msg":"connect", "version":"1", "support":["1", "pre2"]])
        }
        
        // Execute a method on the Meteor server
        public func method(name: String, params: AnyObject?, callback: OnComplete?) -> String {
            let id = getId()
            let message = ["msg":"method", "method":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            callbacks[id] = callback
            sendMessage(message)
            return id
        }
        
        // Subscribe to a Meteor collection
        public func sub(name: String, params: NSDictionary?) -> String {
            let id = getId()
            subscriptions[name] = id
            let message = ["msg":"sub", "name":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            sendMessage(message)
            return id
        }
        
        // Unsubscribe to a Meteor collection
        public func unsub(name: String) -> String? {
            if let id = subscriptions[name] {
                sendMessage(["msg":"unsub", "id":id])
                return name
            }
            return nil
        }
    }
}

