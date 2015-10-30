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
import CryptoSwift

private let DDP_ID = "DDP_ID"
private let DDP_EMAIL = "DDP_EMAIL"
private let DDP_USERNAME = "DDP_USERNAME"
private let DDP_TOKEN = "DDP_TOKEN"
private let DDP_TOKEN_EXPIRES = "DDP_TOKEN_EXPIRES"
private let DDP_LOGGED_IN = "DDP_LOGGED_IN"

let SWIFT_DDP_CALLBACK_DISPATCH_TIME = DISPATCH_TIME_FOREVER

private let syncWarning = {(name:String) -> Void in
    if NSThread.isMainThread() {
        print("\(name) is running synchronously on the main thread. This will block the main thread and should be run on a background thread")
    }
}



extension String {
    func dictionaryValue() -> NSDictionary? {
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let dictionary = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
            return dictionary
        }
        return nil
    }
}

extension NSDictionary {
    func stringValue() -> String? {
        if let data = try? NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions(rawValue: 0)) {
            return NSString(data: data, encoding: NSASCIIStringEncoding) as? String
        }
        return nil
    }
}

// These are implemented as an extension because they're not a part of the DDP spec
extension DDPClient {
    
    public func subscribe(name:String) -> String { return sub(name, params:nil) }
    
    public func subscribe(name:String, params:[AnyObject]) -> String { return sub(name, params:params) }
    
    public func subscribe(name:String, params:[AnyObject]?, callback: (()->())?) -> String { return sub(name, params:params, callback:callback) }
    
    public func subscribe(name:String, callback: (()->())?) -> String { return sub(name, params:nil, callback:callback) }
    
    // callback is optional. If present, called with an error object as the first argument and,
    // if no error, the _id as the second.
    public func insert(collection: String, document: NSArray, callback: ((result:AnyObject?, error:DDPError?) -> ())?) -> String {
        let arg = "/\(collection)/insert"
        return self.method(arg, params: document, callback: callback)
    }
    
    // Insert without specifying a callback
    public func insert(collection: String, document: NSArray) -> String {
        return insert(collection, document: document, callback:nil)
    }
    
    public func insert(sync collection: String, document: NSArray) -> Result {
        
        syncWarning("Insert")
        
        let semaphore = dispatch_semaphore_create(0)
        var serverResponse = Result()
        
        insert(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            dispatch_semaphore_signal(semaphore)
        }
        
        dispatch_semaphore_wait(semaphore, SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    public func update(collection: String, document: NSArray, callback: ((result:AnyObject?, error:DDPError?) -> ())?) -> String {
        let arg = "/\(collection)/update"
        return method(arg, params: document, callback: callback)
    }
    
    // Update without specifying a callback
    public func update(collection: String, document: NSArray) -> String {
        return update(collection, document: document, callback:nil)
    }
    
    public func update(sync collection: String, document: NSArray) -> Result {
        syncWarning("Update")
        
        let semaphore = dispatch_semaphore_create(0)
        var serverResponse = Result()
        
        update(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            dispatch_semaphore_signal(semaphore)
        }
        
        dispatch_semaphore_wait(semaphore, SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    public func remove(collection: String, document: NSArray, callback: ((result:AnyObject?, error:DDPError?) -> ())?) -> String {
        let arg = "/\(collection)/remove"
        return method(arg, params: document, callback: callback)
    }
    
    // Remove without specifying a callback
    public func remove(collection: String, document: NSArray) -> String  {
        return remove(collection, document: document, callback:nil)
    }
    
    public func remove(sync collection: String, document: NSArray) -> Result {
        syncWarning("Remove")
        
        let semaphore = dispatch_semaphore_create(0)
        var serverResponse = Result()
        
        remove(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            dispatch_semaphore_signal(semaphore)
        }
        
        dispatch_semaphore_wait(semaphore, SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    internal func login(params: NSDictionary, callback: ((result: AnyObject?, error: DDPError?) -> ())?) {
        method("login", params: NSArray(arrayLiteral: params)) { result, error in
            guard let e = error where (e.isValid == true) else {
                
                if let user = params["user"],
                    let email = user["email"] {
                        self.userData.setObject(email, forKey: DDP_EMAIL)
                }
                
                if let data = result as? NSDictionary,
                    let id = data["id"] as? String,
                    let token = data["token"] as? String,
                    let tokenExpires = data["tokenExpires"] as? NSDictionary,
                    let date = tokenExpires["$date"] as? Int {
                        let timestamp = NSTimeInterval(Double(date)) / 1000.0
                        let expiration = NSDate(timeIntervalSince1970: timestamp)
                        self.userData.setObject(id, forKey: DDP_ID)
                        self.userData.setObject(token, forKey: DDP_TOKEN)
                        self.userData.setObject(expiration, forKey: DDP_TOKEN_EXPIRES)
                }
                if let c = callback { c(result:result, error:error) }
                self.userData.setObject(true, forKey: DDP_LOGGED_IN)
                return
            }
            
            log.debug("Login error: \(e)")
            if let c = callback { c(result: result, error: error) }
        }
    }
    
    // Login with email and password
    public func loginWithPassword(email: String, password: String, callback: ((result:AnyObject?, error:DDPError?) -> ())?) {
        if !(loginWithToken(callback)) {
            let params = ["user": ["email": email], "password":["digest": password.sha256()!, "algorithm":"sha-256"]] as NSDictionary
            login(params, callback: callback)
        }
    }
    
    // Does the date comparison account for TimeZone?
    public func loginWithToken(callback:((result: AnyObject?, error: DDPError?) -> ())?) -> Bool {
        if let token = userData.stringForKey(DDP_TOKEN),
            let tokenDate = userData.objectForKey(DDP_TOKEN_EXPIRES) {
                if (tokenDate.compare(NSDate()) == NSComparisonResult.OrderedDescending) {
                    let params = ["resume":token] as NSDictionary
                    login(params, callback:callback)
                    return true
                }
        }
        return false
    }
    
    public func signup(params:NSDictionary, callback:((result: AnyObject?, error: DDPError?) -> ())?) {
        method("createUser", params: NSArray(arrayLiteral: params)) { result, error in
            guard let e = error where (e.isValid == true) else {
                
                if let email = params["email"] {
                    self.userData.setObject(email, forKey: DDP_EMAIL)
                }
                
                if let data = result as? NSDictionary,
                    let id = data["id"] as? String,
                    let token = data["token"] as? String,
                    let tokenExpires = data["tokenExpires"] as? NSDictionary,
                    let date = tokenExpires["$date"] as? Int {
                        let timestamp = NSTimeInterval(Double(date)) / 1000.0
                        let expiration = NSDate(timeIntervalSince1970: timestamp)
                        self.userData.setObject(id, forKey: DDP_ID)
                        self.userData.setObject(token, forKey: DDP_TOKEN)
                        self.userData.setObject(expiration, forKey: DDP_TOKEN_EXPIRES)
                }
                if let c = callback { c(result:result, error:error) }
                self.userData.setObject(true, forKey: DDP_LOGGED_IN)
                return
            }
            
            log.debug("login error: \(e)")
            if let c = callback { c(result: result, error: error) }
        }
    }
    
    public func signupWithEmail(email: String, password: String, callback: ((result:AnyObject?, error:DDPError?) -> ())?) {
        let params = ["email":email, "password":["digest":password.sha256()!, "algorithm":"sha-256"]]
        signup(params, callback: callback)
    }
    
    public func signupWithEmail(email: String, password: String, profile: NSDictionary, callback: ((result:AnyObject?, error:DDPError?) -> ())?) {
        let params = ["email":email, "password":["digest":password.sha256()!, "algorithm":"sha-256"], "profile":profile]
        signup(params, callback: callback)
    }
    
    public func logout() {
        method("logout", params: nil) { result, error in
            if (error == nil) {
                self.userData.setObject(false, forKey: DDP_LOGGED_IN)
                self.userData.removeObjectForKey(DDP_ID)
                self.userData.removeObjectForKey(DDP_EMAIL)
                self.userData.removeObjectForKey(DDP_USERNAME)
                self.userData.removeObjectForKey(DDP_TOKEN)
                self.userData.removeObjectForKey(DDP_TOKEN_EXPIRES)
            }
        }
    }
    
    public func logout(callback: ((result: AnyObject?, error: DDPError?) -> ())?) {
        method("logout", params: nil, callback: callback)
    }
    
    public convenience init(url: String, email: String, password: String, callback: (result:AnyObject?, error:DDPError?) -> ()) {
        self.init()
        connect(url) { session in
            self.loginWithPassword(email, password: password, callback:callback)
        }
    }
    
    public func loggedIn() -> Bool {
        if let userLoggedIn = self.userData.objectForKey(DDP_LOGGED_IN) as? Bool where (userLoggedIn == true) {
            return true
        }
        return false
    }
    
}
