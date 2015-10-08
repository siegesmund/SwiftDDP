//
//  MeteorErrors.swift
//  SwiftDDP
//
//  Created by Peter Siegesmund on 10/8/15.
//  Copyright © 2015 Peter Siegesmund. All rights reserved.
//

import Foundation

extension Meteor {
    enum Error: Int {
        case AccessDenied = 403 // "Access denied. No allow validators set on restricted collection for method."
        case DuplicateKey = 409 // "MongoError: E11000 duplicate key error"
    }
 
}

