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

public class AbstractCollection: NSObject, MeteorCollectionType {
    
    public var name:String
    public let client = Meteor.client
    
    public init(name:String) {
        self.name = name
        super.init()
        Meteor.collections[name] = self
    }
    
    deinit {
        Meteor.collections[name] = nil
    }
    
    /**
    Invoked when a document has been sent from the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    */
    
    public func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {}
    
    /**
    Invoked when a document has been changed on the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    - parameter fields:         an optional NSDictionary with the documents properties
    - parameter cleared:                    Optional array of strings (field names to delete)
    */
    
    public func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {}
    
    /**
    Invoked when a document has been removed on the server.
    
    - parameter collection:     the string name of the collection to which the document belongs
    - parameter id:             the string unique id that identifies the document on the server
    */
    
    public func documentWasRemoved(collection:String, id:String) {}
    
}
