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

import Foundation

/**
Enum value representing the types of DDP messages that the server can send
*/

// Handled Message Types
public enum DDPMessageType:String {
    
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

/**
A struct to parse, encapsulate and facilitate handling of DDP message strings
*/

public struct DDPMessage {
    
    /**
    The message's properties, stored as an NSDictionary
    */
    
    public var json:NSDictionary!
    
    /**
    Initialize a message struct, with a Json string
    */
    
    public init(message:String) {
        
        if let JSON = message.dictionaryValue() { json = JSON }
        else {
            json = ["msg":"error", "reason":"SwiftDDP JSON serialization error.",
                "details": "SwiftDDP JSON serialization error. JSON string was: \(message). Message will be handled as a DDP message error."]
        }
    }
    
    /**
    Initialize a message struct, with a dictionary of strings
    */
    
    public init(message:[String:String]) {
        json = message as NSDictionary
    }
    
    /**
    Converts an NSDictionary to a JSON string
    */
    
    public static func toString(_ json:Any) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let message = NSString(data: data, encoding: String.Encoding.ascii.rawValue) as String?
            return message
        }
        return nil
    }
    
    //
    // Computed variables
    //
    
    /**
    Returns the DDP message type, of type DDPMessageType enum
    */
    
    public var type:DDPMessageType {
        if let msg = message,
            let type = DDPMessageType(rawValue: msg) {
                return type
        }
        return DDPMessageType(rawValue: "unhandled")!
    }
    
    /**
    Returns a boolean value indicating if the message is an error message or not
    */
    
    public var isError:Bool {
        if (self.type == .Error) { return true }    // if message is a top level error ("msg"="error")
        if let _ = self.error { return true }       // if message contains an error object, as in method or nosub
        return false
    }
    
    // Returns the root-level keys of the JSON object
    internal var keys:[String] {
        return json.allKeys as! [String]
    }
    
    public func hasProperty(_ name:String) -> Bool {
        if let property = json[name], ((property as! NSObject) != NSNull()) {
            return true
        }
        return false
    }
    
    /**
    The optional DDP message
    */
    
    public var message:String? {
        get { return json["msg"] as? String }
    }
    
    /**
    The optional DDP session string
    */
    
    public var session:String? {
        get { return json["session"] as? String }
    }
    
    /**
    The optional DDP version string
    */
    
    public var version:String? {
        get { return json["version"] as? String }
    }
    
    /**
    The optional DDP support string
    */
    
    public var support:String? {
        get { return json["support"] as? String }
    }
    
    /**
    The optional DDP message id string
    */
    
    public var id:String? {
        get { return json["id"] as? String }
    }
    
    /**
    The optional DDP name string
    */
    
    public var name:String? {
        get { return json["name"] as? String }
    }
    
    /**
    The optional DDP param string
    */
    
    public var params:String? {
        get { return json["params"] as? String }
    }
    
    /**
    The optional DDP error object
    */
    
    public var error:DDPError? {
        get { if let e = json["error"] as? NSDictionary { return DDPError(json:e) } else { return nil }}
    }
    
    /**
    The optional DDP collection name string
    */
    
    public var collection:String? {
        get { return json["collection"] as? String }
    }
    
    /**
    The optional DDP fields dictionary
    */
    
    public var fields:NSDictionary? {
        get { return json["fields"] as? NSDictionary }
    }
    
    /**
    The optional DDP cleared array. Contains an array of fields that should be removed
    */
    
    public var cleared:[String]? {
        get { return json["cleared"] as? [String] }
    }
    
    /**
    The optional method name
    */
    
    public var method:String? {
        get { return json["method"] as? String }
    }
    
    /**
    The optional random seed JSON value (an arbitrary client-determined seed for pseudo-random generators)
    */
    
    public var randomSeed:String? {
        get { return json["randomSeed"] as? String }
    }
    
    /**
    The optional result object, containing the result of a method call
    */
    
    public var result:Any? {
        get { return json.object(forKey: "result") as Any? }
    }
    
    /**
    The optional array of ids passed to 'method', all of whose writes have been reflected in data messages)
    */
    
    public var methods:[String]? {
        get { return json["methods"] as? [String] }
    }
    
    /**
    The optional array of id strings passed to 'sub' which have sent their initial batch of data
    */
    
    public var subs:[String]? {
        get { return json["subs"] as? [String] }
    }
    
    /**
    The optional reason given for an error returned from the server
    */
    
    public var reason:String? {
        get { return json["reason"] as? String }
    }
    
    /**
    The optional original error message
    */
    
    public var offendingMessage:String? {
        get { return json["offendingMessage"] as? String }
    }
}


/**
A struct encapsulating a DDP error message
*/

public struct DDPError: Error {
    
    fileprivate var json:NSDictionary?
    
    /**
    The string error code
    */
    
    public var error:String? { return json?["error"] as? String }                      // Error code
    
    /**
    The detailed message given for an error returned from the server
    */
    
    public var reason:String? { return json?["reason"] as? String }
    
    /**
    The string providing error details
    */
    
    public var details:String? { return json?["details"] as? String }
    
    /**
    If the original message parsed properly, it is included here
    */
    
    public var offendingMessage:String? { return json?["offendingMessage"] as? String }
    
    /**
    Helper variable that returns true if the struct has both an error code and a reason
    */
    
    var isValid:Bool {
        if let _ = error { return true }
        if let _ = reason { return true }
        return false
    }
    
    init(json:Any?) {
        self.json = json as? NSDictionary
    }
}
