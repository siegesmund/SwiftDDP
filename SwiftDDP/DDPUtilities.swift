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

// Base64

func randomBase64String(n: Int = 20) -> String {
    
    var string = ""
    let BASE64_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    
    for _ in 1...n {
        let r = arc4random() % UInt32(BASE64_CHARS.characters.count)
        let index = BASE64_CHARS.startIndex.advancedBy(Int(r))
        let c = BASE64_CHARS[index]
        string += String(c)
    }
    
    return string
}

func toBase64(string: String) -> String {
    let encodedData = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding)
    let base64String = encodedData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    return base64String as String
}

func fromBase64(string: String) -> String {
    let decodedData = NSData(base64EncodedString: string, options: NSDataBase64DecodingOptions(rawValue: 0))
    let decodedString = NSString(data: decodedData!, encoding: NSUTF8StringEncoding)
    return decodedString as! String
}


// URL Parsing

// Returns a dictionary of arguments
func getArguments(fromUrl url: String) -> [String:String] {
    var componentsDictionary:[String:String] = [:]
    let components = NSURLComponents(string: url)
    components?.queryItems?.forEach { item in componentsDictionary[item.name] = item.value }
    return componentsDictionary
}

func getValue(fromUrl url: String, forArgument argument:String) -> String? {
    let arguments = getArguments(fromUrl: url)
    print("Arguments \(arguments) for url: \(url)")
    return arguments[argument]
}

// Misc

func dateFromTimestamp(containedIn: NSDictionary) -> NSDate {
    let date = containedIn["$date"] as? Double
    let timestamp = NSTimeInterval(date! / 1000)
    return NSDate(timeIntervalSince1970: timestamp)
}
