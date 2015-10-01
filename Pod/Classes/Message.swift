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
    
    public struct Message {
        
        // SwiftyJSON JSON Object
        public var json:NSDictionary!
        
        public init(message:String) {
            if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
                } catch {
                    let errorMessage = "SwiftDDP JSON serialization error. JSON string was: \(message). Message will handled as a DDP error."
                    log.error(errorMessage)
                    let msg = ["msg":"error"] as NSMutableDictionary
                    msg["error"] = ["error": "SwiftDDP JSON serialization error.", "reason": "SwiftDDP JSON serialization error", "details": errorMessage]
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
            get { return json["msg"] as! String? }
        }
        
        public var session:String? {
            get { return json["session"] as! String? }
        }
        
        public var version:String? {
            get { return json["version"] as! String? }
        }
        
        public var support:String? {
            get { return json["support"] as! String? }
        }
        
        public var id:String? {
            get { return json["id"] as! String? }
        }
        
        public var name:String? {
            get { return json["name"] as! String? }
        }
        
        public var params:String? {
            get { return json["params"] as! String? }
        }
        
        public var error:NSDictionary? {
            get { return json["error"] as! NSDictionary? }
        }
        
        public var collection:String? {
            get { return json["collection"] as! String? }
        }
        
        public var fields:NSDictionary? {
            get { return json["fields"] as! NSDictionary? }
        }
        
        public var cleared:[String]? {
            get { return json["cleared"] as! [String]? }
        }
        
        public var method:String? {
            get { return json["method"] as! String? }
        }
        
        public var randomSeed:String? {
            get { return json["randomSeed"] as! String? }
        }
        
        public var result:String? {
            get { return json["result"] as! String? }
        }
        
        public var methods:[String]? {
            get { return json["methods"] as! [String]? }
        }
        
        public var subs:[String]? {
            get { return json["subs"] as! [String]? }
        }
    }
}
