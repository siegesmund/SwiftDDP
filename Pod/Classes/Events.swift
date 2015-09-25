
import Foundation

extension DDP {
    
    public struct Events {
        
        public struct Callbacks {
            public typealias WebsocketClose =   (code:Int, reason:String, clean:Bool) -> ()
            public typealias WebsocketError =   (error:ErrorType) -> ()
            public typealias Connected      =   (result:NSDictionary?, error:NSDictionary?) -> ()
            
            public typealias Added          =   (collection:String, id:String, fields:NSDictionary?) -> ()
            public typealias Changed        =   (collection:String, id:String, fields:NSDictionary?, cleared:NSArray?) -> ()
            public typealias Removed        =   (collection:String, id:String) -> ()
            
            public typealias Result         =   (json: NSDictionary?, callback:OnComplete!) -> ()
            public typealias Error          =   (error:String?) -> ()
        }
        
        public var onWebsocketClose: Events.Callbacks.WebsocketClose    =   {code, reason, clean in log.debug("[DDP] websocket closed with reason: \(reason)")}
        public var onWebsocketError: Events.Callbacks.WebsocketError    =   {error in log.debug("[DDP] websocket error \(error)")}
        public var onConnected:  Events.Callbacks.Connected             =   {result, error in log.debug("[DDP] connected")}
        public var onDisconnected: () -> ()                             =   {log.debug("[DDP] disconnected")}
        public var onFailed: () -> ()                                   =   {log.debug("[DDP] failed")}
        public var onPing: (message:DDP.Message) -> ()                  =   {message in}
        public var onPong: (message:DDP.Message) -> ()                  =   {message in}
        
        public var onNosub: (id:String, error:String?) -> ()            =   {id in }                                // error is optional
        public var onAdded: Events.Callbacks.Added                      =   {collection, id, fields in }            // fields is optional
        public var onChanged: Events.Callbacks.Changed                  =   {collection, id, fields, cleared in }   // fields and cleared are optional
        public var onRemoved: Events.Callbacks.Removed                  =   {collection, id in }
        public var onReady: (subs: NSArray) -> ()                  =   {subs in }
        
        // The ordered messages are not currently used by Meteor
        // public var onAddedBefore: (collection: String, id: String, fields: NSDictionary?, before: String?) -> () = {collection, id, fields, before in }    //
        // public var onMovedBefore: (collection: String, id: String, before: String?) -> () = {collection, id, before in }
        
        // RPC Messages
        public var onResult: Events.Callbacks.Result                    =   {json, callback in callback(result: json, error:nil) }
        public var onUpdated: (methods: NSArray) -> ()                  =   {methods in }
        
        public var onError: Events.Callbacks.Error                      =   {error in }
        
    }
    
}

