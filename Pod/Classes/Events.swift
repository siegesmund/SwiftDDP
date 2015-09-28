
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
        public var onAdded: Added = {collection, id, fields in }            // fields is optional
        public var onChanged: Changed = {collection, id, fields, cleared in }   // fields and cleared are optional
        public var onRemoved: Removed = {collection, id in }
        
        // RPC Messages
        public var onResult: Result = {json, callback in callback(result: json, error:nil) }
        public var onUpdated: (methods: [String]) -> () = {methods in }
        
        public var onError: Error = {error in }
        
    }
    
}

