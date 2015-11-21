
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
        let timeInterval = NSTimeInterval(ejson.valueForKey("$date") as! Int)
        return NSDate(timeIntervalSince1970: timeInterval)
    }
    
    public static func convertToEJSONDate(date:NSDate) -> [String:Double] {
        let timeInterval = Double(date.timeIntervalSince1970) * 1000
        print("Date -> \(date), \(timeInterval)")
        return ["$date": timeInterval]
    }
    

}

