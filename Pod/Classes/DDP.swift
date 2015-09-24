//
//
//  A DDP Client written in Swift
//
//

import Foundation
import SwiftWebSocket
import XCGLogger

let log = XCGLogger.defaultInstance()

public typealias OnResult = (result:NSDictionary?, error:NSDictionary?) -> ()

public class DDP {
    
    public class Client: NSObject {
        
        public var url:String!
        public var socket:WebSocket!
        public var events:Events!
        public var session:String!
        public var test = false
        public var connected = false
        var subscriptions = [String:String]()
        private var callbacks:[String:OnResult!] = [:]
        
        public init(url:String) {
            super.init()
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
        public convenience init(url:String, onConnected:OnResult) {
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
        public func ddpMessageHandler(message: DDP.Message) {
            print("Received message: \(message.json)")
            switch message.type {
            case .Connected:
                session = message.session!
                connected = true
                events.onConnected(result: nil,error: nil)
                
            case .Result: events.onResult(json: message.json, callback:callbacks[message.id!])
            case .Updated: events.onUpdated(methods: message.methods!)
            case .Nosub: events.onNosub(id: message.id!)
            case .Added: events.onAdded(collection: message.collection!, id: message.id!, fields: message.fields)
            case .Changed: events.onChanged(collection: message.collection!, id: message.id!, fields: message.fields, cleared: message.cleared)
            case .Removed: events.onRemoved(collection: message.collection!, id: message.id!)
            case .Ready: events.onReady(subs: message.subs!)
            case .AddedBefore: events.onAddedBefore(collection: message.collection!, id: message.id!, fields: message.fields, before: message.before!)
            case .MovedBefore: events.onMovedBefore(collection: message.collection!, id: message.id!, before: message.before!)
            case .Ping: events.onPong(message: message)
            case .Pong: log.debug("Pong received")
            default: log.debug("Unhandled message: \(message.json)")
            }
        }
        
        private func sendMessage(message:AnyObject) {
            if let m = Message.toString(message) { socket.send(m) }
        }
        
        
        public func connect(onConnected:OnResult!) {
            if (onConnected != nil) { events.onConnected = onConnected }
            sendMessage(["msg":"connect", "version":"1", "support":["1", "pre2"]])
        }
    
        public func method(methodName: String, params: AnyObject?, callback: OnResult?) -> String {
            let id = getId()
            let message = ["msg":"method", "method":methodName, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            callbacks[id] = callback
            sendMessage(message)
            return id
        }
        
        public func sub(name: String, params: NSDictionary?) -> String {
            let id = getId()
            subscriptions[name] = id
            let message = ["msg":"sub", "name":name, "id":id] as NSMutableDictionary
            if let p = params { message["params"] = p }
            sendMessage(message)
            return id
        }
        
        public func unsub(name: String) -> String? {
            if let id = subscriptions[name] {
                sendMessage(["msg":"unsub", "id":id])
                return name
            }
            return nil
        }
    }
}

