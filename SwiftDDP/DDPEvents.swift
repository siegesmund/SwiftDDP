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

public struct DDPEvents {
    
    public var onWebsocketClose:    ((code:Int, reason:String, clean:Bool) -> ())?
    public var onWebsocketError:    (error:ErrorType) -> () = {error in log.error("websocket error \(error)")}
    
    public var onConnected:         (session:String) -> () = {session in log.info("connected with session: \(session)")}
    public var onDisconnected:      () -> () = {log.debug("disconnected")}
    public var onFailed:            () -> () = {log.error("failed")}
    
    // Data messages
    public var onAdded:             ((collection:String, id:String, fields:NSDictionary?) -> ())?
    public var onChanged:           ((collection:String, id:String, fields:NSDictionary?, cleared:NSArray?) -> ())?
    public var onRemoved:           ((collection:String, id:String) -> ())?
    
    // RPC Messages
    // public var onResult:            (json: NSDictionary?, callback:(result:AnyObject?, error:AnyObject?) -> ()) -> () = {json, callback in callback(result: json, error:nil) }
    public var onUpdated:           ((methods: [String]) -> ())?
    public var onError:             ((message:DDPError) -> ())?
    
}

