//
//  ListStruct.swift
//  SwiftTodos
//
//  Created by Sadman samee on 1/28/16.
//  Copyright © 2016 Peter Siegesmund. All rights reserved.
//
import Foundation

var listStructs = [ListStruct]()

struct ListStruct {
    
    var _id:String?
    var incompleteCount:Int = 0
    var name:String?
    var userId:String?
    
    init(id:String, fields:NSDictionary?) {
        self._id = id
        update(fields)
    }
    
    mutating func update(fields:NSDictionary?) {
        
        if let name = fields?.valueForKey("name") as? String {
            self.name = name
        }
        
        if let incompleteCount = fields?.valueForKey("incompleteCount") as? Int {
            self.incompleteCount = incompleteCount
        }
        
        if let userId = fields?.valueForKey("userId") as? String {
            self.userId = userId
        }
    }
}