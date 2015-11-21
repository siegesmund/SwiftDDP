//
//  ArrayCollection.swift
//  SwiftDDP
//
//  Created by Peter Siegesmund on 11/21/15.
//  Copyright © 2015 Peter Siegesmund. All rights reserved.
//

import Foundation


public class MeteorDocument: NSObject {
    
    var id:String
    
    required public init(id: String, fields: NSDictionary?) {
        self.id = id
        super.init()
        
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
    
}




/**
MeteorCollection provides basic persistence as well as an api for integrating SwiftDDP with persistence stores. MeteorCollection
should generally be subclassed, with the methods documentWasAdded, documentWasChanged and documentWasRemoved facilitating communicating
with the datastore.
*/

// MeteorCollectionType protocol declaration is necessary
public class MeteorCollection<T:MeteorDocument>: AbstractCollection {
    
    
    var documents = [String:T]()
    
    var sorted:[T] {
        return Array(documents.values).sort({ $0.id > $1.id })
    }
    
    /**
    Returns the number of documents in the collection
    */
    
    var count:Int {
        return documents.count
    }
    
    /**
    Initializes a MeteorCollection object
    
    - parameter name:   The string name of the collection (must match the name of the collection on the server)
    */
    
    private func sorted(property:String) -> [T] {
        let values = Array(documents.values)
        return values.sort({ $0.id > $1.id })
    }
    
    /**
    Invoked when a document has been sent from the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    */
    
    public override func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        let document = T(id: id, fields: fields)
        documents[id] = document
        
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
            documents[id] = document
        }
        
    }
    
    /**
    Invoked when a document has been removed on the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    */
    
    public override func documentWasRemoved(collection:String, id:String) {
        if let _ = documents[id] {
            documents[id] = nil
        }
    }
}

    