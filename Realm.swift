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
import RealmSwift

public class Datastore {
    public static let realm = try? Realm()
}

public class RealmCollection<T:RealmDocument>: Collection<T> {
    
    let realm = Datastore.realm
    
    public override init(name:String) {
        super.init(name: name)
    }
    
    public func count() -> Int {
        return self.find()!.count
    }
    
    public func flush() {
        // let realm = Datastore.realm
         realm?.write {
            realm?.deleteAll()
        }
    }

    /*
    public func insert(json:NSDictionary) throws {
        let doc = T()
        if let id = json["id"] as? String { doc._id = id }
        doc.apply(json)
        try doc.insert()
        
        // Try adding the document on the server, but remove it if 
        // the insert is unsuccessful
        self.insert(NSArray(arrayLiteral: json)) { result, error in
            if (error != nil) {
                try doc.remove()
            }
        }
    }
    */
    
    public func insert(document:T) throws {
        try document.insert()
        
        // add code to insert on server
    }
    
    public func remove(document:T) throws {
        try document.remove()
        // add code to remove on server
    }
    
    public func remove(_id:String) throws {
        let results = find(_id)
        if results?.count > 0 {
            try results?[0].remove()
        }
    }
    
    public func find() -> Results<T>? {
        return self.realm?.objects(T.self)
    }
    
    public func find(_id:String) -> Results<T>? {
        return self.realm?.objects(T.self).filter(NSPredicate(format:"_id = '\(_id)'"))
    }
    
    public func find(query:NSPredicate) -> Results<T>? {
        return realm?.objects(T.self).filter(query)
    }
    
    public func findOne(_id:String) -> T? {
        let result = find(_id)
        if (result?.count > 0) {
            return result?[0]
        }
        return nil
    }
    
    public func findOne(query:NSPredicate) -> T? {
        let result = find(query)
        if (result?.count > 0) {
            return result?[0]
        }
        return nil
    }
    
    public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        print("REALM: Document was added \(collection), \(id), \(fields)")
        let doc = T()
        doc._id = id
        if let f = fields { print("REALM: Correctly parsed fields \(f)"); doc.apply(f) }
        print("REALM: Inserting doc \(doc)")
        try! doc.insert()
    }
    
    public override func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        if let doc = findOne(id) {
            realm?.write {
                if let f = fields { doc.apply(f) }
                if let c = cleared {
                    for field in c {
                        doc[field] = ""
                    }
                }
            }
        }
    }
    
    public override func documentWasRemoved(collection:String, id:String) {
        if let doc = findOne(id) {
            try! doc.remove()
        }
    }
}

// The field _id functions as the primary key and guarantees uniqueness
// _id property is immutable
public class RealmDocument: Object {
    
    public dynamic var _id = ""
    
    public var exists:Bool {
        return self.invalidated
    }
    
    public var r:Realm? {
        if (self.realm != nil) {
            return self.realm!
        }
        return Datastore.realm
    }
    
    public var persisted:Bool {
        if (self.realm != nil) {
            return true
        }
        return false
    }
    
    override public static func primaryKey() -> String {
        return "_id"
    }
    
    public func insert() throws {
        r?.write {
            self.r?.add(self)
        }
    }
    
    public func remove() throws {
        r?.write {
            self.r?.delete(self)
        }
    }
    
    public func apply(json:NSDictionary) {}
}

