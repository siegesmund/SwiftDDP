
import Foundation

extension DDP {
    
    public struct Events {
        
        public struct Callbacks {
            public typealias WebsocketClose =   (code:Int, reason:String, clean:Bool) -> ()
            public typealias WebsocketError =   (error:ErrorType) -> ()
            public typealias Connected      =   (session:String) -> ()
            
            public typealias Added          =   (collection:String, id:String, fields:NSDictionary?) -> ()
            public typealias Changed        =   (collection:String, id:String, fields:NSDictionary?, cleared:NSArray?) -> ()
            public typealias Removed        =   (collection:String, id:String) -> ()
            
            public typealias Result         =   (json: NSDictionary?, callback:OnComplete!) -> ()
            public typealias Error          =   (error:NSDictionary) -> ()
        }
        
        public var onWebsocketClose: Events.Callbacks.WebsocketClose    =   {code, reason, clean in log.debug("websocket closed with reason: \(reason)")}
        public var onWebsocketError: Events.Callbacks.WebsocketError    =   {error in log.debug("websocket error \(error)")}
        public var onConnected:  Events.Callbacks.Connected             =   {session in log.debug("connected with session: \(session)")}
        public var onDisconnected: () -> ()                             =   {log.debug("disconnected")}
        public var onFailed: () -> ()                                   =   {log.debug("failed")}
        
        // Data messages
        public var onAdded: Events.Callbacks.Added                      =   {collection, id, fields in }            // fields is optional
        public var onChanged: Events.Callbacks.Changed                  =   {collection, id, fields, cleared in }   // fields and cleared are optional
        public var onRemoved: Events.Callbacks.Removed                  =   {collection, id in }
        
        // RPC Messages
        public var onResult: Events.Callbacks.Result                    =   {json, callback in callback(result: json, error:nil) }
        public var onUpdated: (methods: NSArray) -> ()                  =   {methods in }
        
        public var onError: Events.Callbacks.Error                      =   {error in }
        
    }
    
}

