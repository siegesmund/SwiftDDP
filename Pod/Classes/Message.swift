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

//
// Wrapper around NSDictionary for dealing with DDP Messages
//

extension DDP {
    
    // Handled Message Types
    public enum MessageType:String {
        
        // case Connect = "connect"     // (client -> server)
        case Connected  = "connected"
        case Failed     = "failed"
        case Ping       = "ping"
        case Pong       = "pong"
        // case Sub     = "sub"         // (client -> server)
        // case Unsub   = "unsub"       // (client -> server)
        case Nosub      = "nosub"
        case Added      = "added"
        case Changed    = "changed"
        case Removed    = "removed"
        case Ready      = "ready"
        case AddedBefore = "addedBefore"
        case MovedBefore = "movedBefore"
        // case Method  = "method"       // (client -> server)
        case Result     = "result"
        case Updated    = "updated"
        case Error      = "error"
        case Unhandled  = "unhandled"
        
    }
    
    // Method or Nosub error
    // Such an Error is used to represent errors raised by the method or subscription, 
    // as well as an attempt to subscribe to an unknown subscription or call an unknown method.
    
    // Other erroneous messages sent from the client to the server can result in receiving a top-level msg: 'error' message in response. These conditions include:
    
    // - sending messages which are not valid JSON objects
    // - unknown msg type
    // - other malformed client requests (not including required fields)
    // - sending anything other than connect as the first message, or sending connect as a non-initial message
    //   The error message contains the following fields:
    
    // - reason: string describing the error
    // - offendingMessage: if the original message parsed properly, it is included here
    
    public struct Error {
        
        private var json:NSDictionary?
        
        var error:String? { return json?["error"] as? String }
        var reason:String? { return json?["reason"] as? String }
        var details:String? { return json?["details"] as? String }
        var offendingMessage:String? { return json?["offendingMessage"] as? String }
        
        var isValid:Bool {
            if let _ = error { return true }
            if let _ = reason { return true }
            return false
        }
        
        init(json:AnyObject?) {
            self.json = json as? NSDictionary
        }
    }
    
    
    
   
    
    public struct MessageError {
        
        private var json:NSDictionary?
        
        var reason:String? { return json?["reason"] as? String }
        var offendingMessage:String? { return json?["offendingMessage"] as? String }
        
    }
    
    public struct Message {
        
        // SwiftyJSON JSON Object
        public var json:NSDictionary!
        
        public init(message:String) {
            if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
                } catch {
                    let errorMessage = "SwiftDDP JSON serialization error. JSON string was: \(message). Message will be handled as a DDP message error."
                    log.error(errorMessage)
                    let msg = ["msg":"error", "reason":"SwiftDDP JSON serialization error.", "details": errorMessage] 
                    json = msg
                }
            }
        }
        
        public init(message:[String:String]) {
            json = message as NSDictionary
        }
        
        // Converts an NSDictionary to a JSON String
        public static func toString(json:AnyObject) -> String? {
            if let data = try? NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0)) {
                let message = NSString(data: data, encoding: NSASCIIStringEncoding) as String?
                return message
            }
            return nil
        }
        
        //
        // Computed variables
        //
        
        // Returns the type of DDP message, or unhandled if it is not a DDP message
        public var type:DDP.MessageType {
            if let msg = json["msg"] as! String? {
                if let type = DDP.MessageType(rawValue: msg) {
                    return type
                }
            }
            return DDP.MessageType(rawValue: "unhandled")!
        }
        
        public var isError:Bool {
            if (self.type == .Error) { return true }
            if let _ = self.error { return true }
            return false
        }
        
        // Returns the root-level keys of the JSON object
        public var keys:[String] {
            return json.allKeys as! [String]
        }
        
        public func hasProperty(name:String) -> Bool {
            if let _ = json[name] {
                return true
            }
            return false
        }
        
        public var message:String? {
            get { return json["msg"] as? String }
        }
        
        public var session:String? {
            get { return json["session"] as? String }
        }
        
        public var version:String? {
            get { return json["version"] as? String }
        }
        
        public var support:String? {
            get { return json["support"] as? String }
        }
        
        public var id:String? {
            get { return json["id"] as? String }
        }
        
        public var name:String? {
            get { return json["name"] as? String }
        }
        
        public var params:String? {
            get { return json["params"] as? String }
        }
        
        public var error:DDP.Error? {
            get { if let e = json["error"] as? NSDictionary { return DDP.Error(json:e) } else { return nil }}
        }
        
        public var collection:String? {
            get { return json["collection"] as? String }
        }
        
        public var fields:NSDictionary? {
            get { return json["fields"] as? NSDictionary }
        }
        
        public var cleared:[String]? {
            get { return json["cleared"] as? [String] }
        }
        
        public var method:String? {
            get { return json["method"] as? String }
        }
        
        public var randomSeed:String? {
            get { return json["randomSeed"] as? String }
        }
        
        public var result:String? {
            get { return json["result"] as? String }
        }
        
        public var methods:[String]? {
            get { return json["methods"] as? [String] }
        }
        
        public var subs:[String]? {
            get { return json["subs"] as? [String] }
        }
        
        
        // Communication error properties
        public var reason:String? {
            get { return json["reason"] as? String }
        }
        
        public var offendingMessage:String? {
            get { return json["offendingMessage"] as? String }
        }
    }
}
