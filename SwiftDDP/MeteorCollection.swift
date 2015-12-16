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

public class MeteorDocument: NSObject {
    
    var _id:String
    
    required public init(id: String, fields: NSDictionary?) {
        self._id = id
        super.init()
        print(fields)
        if let properties = fields {
            for (key,value) in properties  {
                self.setValue(value, forKey: key as! String)
            }
        }
    }
    
    public func update(fields: NSDictionary?, cleared: [String]?) {
        if let properties = fields {
            for (key,value) in properties  {
                self.setValue(value, forKey: key as! String)
            }
        }
        
        if let deletions = cleared {
            for property in deletions {
                self.setNilValueForKey(property)
            }
        }
    }
    
    /*
    Limitations to propertyNames:
    - Returns an empty array for Objective-C objects
    - Will not return computed properties, i.e.:
    - If self is an instance of a class (vs., say, a struct), this doesn't report its superclass's properties, i.e.:
    see http://stackoverflow.com/questions/24844681/list-of-classs-properties-in-swift
    */
    
    func propertyNames() -> [String] {
        return Mirror(reflecting: self).children.filter { $0.label != nil }.map { $0.label! }
    }
    
    func fields() -> NSDictionary {
        let fieldsDict = NSMutableDictionary()
        let properties = propertyNames()
        
        for name in properties {
            if let value = self.valueForKey(name) {
                fieldsDict.setValue(value, forKey: name)
            }
        }
        
        fieldsDict.setValue(self._id, forKey: "_id")
        print("fields \(fieldsDict)")
        return fieldsDict as NSDictionary
    }
    
}




/**
MeteorCollection provides basic persistence as well as an api for integrating SwiftDDP with persistence stores. MeteorCollection
should generally be subclassed, with the methods documentWasAdded, documentWasChanged and documentWasRemoved facilitating communicating
with the datastore.
*/

// MeteorCollectionType protocol declaration is necessary
public class MeteorCollection<T:MeteorDocument>: AbstractCollection {
    
    
    var documents = [String:T]()
    
    public var sorted:[T] {
        return Array(documents.values).sort({ $0._id > $1._id })
    }
    
    /**
    Returns the number of documents in the collection
    */
    
    public var count:Int {
        return documents.count
    }
    
    /**
    Initializes a MeteorCollection object
    
    - parameter name:   The string name of the collection (must match the name of the collection on the server)
    */
    
    public override init(name: String) {
        super.init(name: name)
    }
    
    private func sorted(property:String) -> [T] {
        let values = Array(documents.values)
        return values.sort({ $0._id > $1._id })
    }
    
    /**
    Find a single document by id
    
    - parameter id: the id of the document
    */
    
    public func findOne(id: String) -> T? {
        return documents[id]
    }
    
    /**
    Invoked when a document has been sent from the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    */
    
    public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        let document = T(id: id, fields: fields)
        self.documents[id] = document
    }
    
    /**
    Invoked when a document has been changed on the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    - parameter cleared:                    Optional array of strings (field names to delete)
    */
    
    public override func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        if let document = documents[id] {
            document.update(fields, cleared: cleared)
            self.documents[id] = document
        }
    }
    
    /**
    Invoked when a document has been removed on the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    */
    
    public override func documentWasRemoved(collection:String, id:String) {
        print("removed: \(collection) \(id)")
        if let _ = documents[id] {
            self.documents[id] = nil
            print("document \(id) removed?")
        }
    }
    
    /**
    Client-side method to insert a document
    
    - parameter document:       a document that inherits from MeteorDocument
    */
    public func insert(document: T) {
        
        documents[document._id] = document
        
        let fields = document.fields()
        
        client.insert(self.name, document: [fields]) { result, error in
            if error != nil {
                self.documents[document._id] = nil
                log.error("\(error)")
            }
        }
        
    }
    
    /**
    Client-side method to update a document
    
    - parameter document:       a document that inherits from MeteorDocument
    */
    public func update(document: T) {
        
        let oldDocument = documents[document._id]
        
        documents[document._id] = document
        
        let fields = document.fields()
        
        client.update(self.name, document: [fields]) { result, error in
            if error != nil {
                self.documents[document._id] = oldDocument
                log.error("\(error)")
            }
        }
        
    }
    
    /**
    Client-side method to remove a document
    
    - parameter document:       a document that inherits from MeteorDocument
    */
    public func remove(document: T) {
        documents[document._id] = nil
        
        client.remove(self.name, document: [document._id]) { result, error in
            if error != nil {
                self.documents[document._id] = nil
                log.error("\(error)")
            }
        }
        
    }
}

    