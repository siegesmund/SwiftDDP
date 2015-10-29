
import Foundation

//
// MeteorCollectionChange
//
//

struct MeteorCollectionChange: Hashable {
    var id:String
    var collection:String
    var fields:NSDictionary?
    var cleared:[String]?
    var hashValue:Int {
        var hash = "\(id.hashValue)\(collection.hashValue)"
        if let _ = fields { hash += "\(fields!.hashValue)" }
        if let _ = cleared {
            for value in cleared! {
                hash += "\(value.hashValue)"
            }
        }
        return hash.hashValue
    }
    
    init(id:String, collection:String, fields:NSDictionary?, cleared:[String]?){
        self.id = id
        self.collection = collection
        self.fields = fields
        self.cleared = cleared
    }
}

func ==(lhs:MeteorCollectionChange, rhs:MeteorCollectionChange) -> Bool {
    return lhs.hashValue == rhs.hashValue
}