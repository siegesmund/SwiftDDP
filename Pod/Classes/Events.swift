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

public typealias Connected      =   (session:String) -> ()

public typealias Added          =   (collection:String, id:String, fields:NSDictionary?) -> ()
public typealias Changed        =   (collection:String, id:String, fields:NSDictionary?, cleared:NSArray?) -> ()
public typealias Removed        =   (collection:String, id:String) -> ()

public typealias Result         =   (json: NSDictionary?, callback:OnComplete!) -> ()
public typealias Error          =   (error:NSDictionary) -> ()


extension DDP {
    
    public struct Events {
        
        public var onWebsocketClose: (code:Int, reason:String, clean:Bool) -> () =   {code, reason, clean in log.debug("websocket closed with reason: \(reason)")}
        public var onWebsocketError: (error:ErrorType) -> () = {error in log.debug("websocket error \(error)")}
        
        public var onConnected: Connected = {session in log.debug("connected with session: \(session)")}
        public var onDisconnected: () -> () = {log.debug("disconnected")}
        public var onFailed: () -> () = {log.debug("failed")}
        
        // Data messages
        public var onAdded: Added?
        public var onChanged: Changed?
        public var onRemoved: Removed?
        
        // RPC Messages
        public var onResult: Result = {json, callback in callback(result: json, error:nil) }
        public var onUpdated: (methods: [String]) -> () = {methods in }
        
        public var onError: Error = {error in }
        
    }
    
}

