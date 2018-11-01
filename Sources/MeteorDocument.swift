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

open class MeteorDocument: NSObject {
    
    public var _id:String
    
    required public init(id: String, fields: NSDictionary?) {
        self._id = id
        super.init()
        if let properties = fields {
            for (key,value) in properties  {
                if !(value is NSNull) {
                    self.setValue(value, forKey: key as! String)
                }
            }
        }
    }
    
    open func update(_ fields: NSDictionary?, cleared: [String]?) {
        if let properties = fields {
            for (key,value) in properties  {
                print("Key: \(key), Value: \(value)")
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
    
    public func propertyNames() -> [String] {
        return Mirror(reflecting: self).children.filter { $0.label != nil }.map { $0.label! }
    }


    /*
    This method should be public so users of this library can override it for parsing their variables in their MeteorDocument object when having structs and such in their Document.
    */
    open func fields() -> NSDictionary {
        let fieldsDict = NSMutableDictionary()
        let properties = propertyNames()
        
        for name in properties {
            if var value = self.value(forKey: name) {
                
                if value as? Date != nil {
                    value = EJSON.convertToEJSONDate(value as! Date)
                }
                
                fieldsDict.setValue(value, forKey: name)
            }
        }
        
        fieldsDict.setValue(self._id, forKey: "_id")
        print("fields \(fieldsDict)")
        return fieldsDict as NSDictionary
    }
    
}

