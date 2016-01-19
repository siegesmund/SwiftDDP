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

// {"$date": MILLISECONDS_SINCE_EPOCH}  // Dates
// {"$binary": BASE_64_STRING}          // Binary data:
// {"$escape": THING}                   // Escaped things that might otherwise look like EJSON types
// {"$type": TYPENAME, "$value": VALUE} // User specified types

public class EJSON: NSObject {
    
    /**
    Determines whether a given key is an eJSON key
    */
    
    public static func isEJSON(key:String) -> Bool {
        switch key {
        case "$date": return true
        case "$binary": return true
        case "$type": return true
        default: return false
        }
    }
    
    /**
    Converts an eJSON date to NSDate
    */
    
    public static func convertToNSDate(ejson:NSDictionary) -> NSDate {
        let timeInterval = NSTimeInterval(ejson.valueForKey("$date") as! Double) / 1000
        return NSDate(timeIntervalSince1970: timeInterval)
    }
    
    public static func convertToEJSONDate(date:NSDate) -> [String:Double] {
        let timeInterval = Double(date.timeIntervalSince1970) * 1000
        print("Date -> \(date), \(timeInterval)")
        return ["$date": timeInterval]
    }
    

}

