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
import CryptoSwift

private let DDP_ID = "DDP_ID"
private let DDP_EMAIL = "DDP_EMAIL"
private let DDP_USERNAME = "DDP_USERNAME"
private let DDP_TOKEN = "DDP_TOKEN"
private let DDP_TOKEN_EXPIRES = "DDP_TOKEN_EXPIRES"
private let DDP_LOGGED_IN = "DDP_LOGGED_IN"

public let DDP_USER_DID_LOGIN = "DDP_USER_DID_LOGIN"
public let DDP_USER_DID_LOGOUT = "DDP_USER_DID_LOGOUT"

let SWIFT_DDP_CALLBACK_DISPATCH_TIME = DispatchTime.distantFuture

private let syncWarning = {(name:String) -> Void in
    if Thread.isMainThread {
        print("\(name) is running synchronously on the main thread. This will block the main thread and should be run on a background thread")
    }
}

extension String {
    func dictionaryValue() -> NSDictionary? {
        if let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! NSDictionary
            return dictionary
        }
        return nil
    }
}

extension NSDictionary {
    func stringValue() -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            return String(data: data, encoding: String.Encoding.utf8)
        }
        return nil
    }
}

/** 
Extensions that provide an api for interacting with basic Meteor server-side services
*/

extension DDPClient {
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription
    */
    
    public func subscribe(_ name:String) -> String { return sub(name, params:nil) }
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription
    - parameter params:     An object containing method arguments, if any
    */
    
    public func subscribe(_ name:String, params:[Any]) -> String { return sub(name, params:params) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription
    - parameter params:     An object containing method arguments, if any
    - parameter callback:   The closure to be executed when the server sends a 'ready' message
    */
    
    public func subscribe(_ name:String, params:[Any]?, callback: DDPCallback?) -> String { return sub(name, params:params, callback:callback) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription
    - parameter callback:   The closure to be executed when the server sends a 'ready' message
    */
    
    public func subscribe(_ name:String, callback: DDPCallback?) -> String { return sub(name, params:nil, callback:callback) }
    
    
    /**
    Asynchronously inserts a document into a collection on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to insert
    - parameter callback:   A closure with result and error arguments describing the result of the operation
    */
    
    @discardableResult public func insert(_ collection: String, document: NSArray, callback: DDPMethodCallback?) -> String {
        let arg = "/\(collection)/insert"
        return self.method(arg, params: document, callback: callback)
    }
    
    /**
    Asynchronously inserts a document into a collection on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to insert
    */
    
    public func insert(_ collection: String, document: NSArray) -> String {
        return insert(collection, document: document, callback:nil)
    }
    
    /**
    Synchronously inserts a document into a collection on the server. Cannot be used on the main queue.
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to insert
    */
    
    public func insert(sync collection: String, document: NSArray) -> Result {
        
        syncWarning("Insert")
        
        let semaphore = DispatchSemaphore(value: 0)
        var serverResponse = Result()
        
        insert(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    /**
    Asynchronously updates a document into a collection on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to update
    - parameter callback:   A closure with result and error arguments describing the result of the operation
    */
    
    @discardableResult public func update(_ collection: String, document: NSArray, callback: DDPMethodCallback?) -> String {
        let arg = "/\(collection)/update"
        return method(arg, params: document, callback: callback)
    }
    
    /**
    Asynchronously updates a document on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to update
    */
    
    public func update(_ collection: String, document: NSArray) -> String {
        return update(collection, document: document, callback:nil)
    }
    
    /**
    Synchronously updates a document on the server. Cannot be used on the main queue
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to update
    */
    
    public func update(sync collection: String, document: NSArray) -> Result {
        syncWarning("Update")
        
        let semaphore = DispatchSemaphore(value: 0)
        var serverResponse = Result()
        
        update(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    /**
    Asynchronously removes a document on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to remove
    - parameter callback:   A closure with result and error arguments describing the result of the operation
    */
    
    @discardableResult public func remove(_ collection: String, document: NSArray, callback: DDPMethodCallback?) -> String {
        let arg = "/\(collection)/remove"
        return method(arg, params: document, callback: callback)
    }
    
    /**
    Asynchronously removes a document into a collection on the server
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to remove
    */
    
    public func remove(_ collection: String, document: NSArray) -> String  {
        return remove(collection, document: document, callback:nil)
    }
    
    /**
    Synchronously removes a document into a collection on the server. Cannot be used on the main queue.
    
    - parameter collection: The name of the collection
    - parameter document:   An NSArray of documents to remove
    */
    
    public func remove(sync collection: String, document: NSArray) -> Result {
        syncWarning("Remove")
        
        let semaphore = DispatchSemaphore(value: 0)
        var serverResponse = Result()
        
        remove(collection, document:document) { result, error in
            serverResponse.result = result
            serverResponse.error = error
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: SWIFT_DDP_CALLBACK_DISPATCH_TIME)
        
        return serverResponse
    }
    
    // Callback runs on main thread
    public func login(_ params: NSDictionary, callback: ((_ result: Any?, _ error: DDPError?) -> ())?) {
        
        // method is run on the userBackground queue
        method("login", params: NSArray(arrayLiteral: params)) { result, error in
            guard let e = error, (e.isValid == true) else {
                
                if let user = params["user"] as? NSDictionary {
                    if let email = user["email"] {
                        self.userData.set(email, forKey: DDP_EMAIL)
                    }
                    if let username = user["username"] {
                        self.userData.set(username, forKey: DDP_USERNAME)
                    }
                }
                
                if let data = result as? NSDictionary,
                    let id = data["id"] as? String,
                    let token = data["token"] as? String,
                    let tokenExpires = data["tokenExpires"] as? NSDictionary {
                        let expiration = dateFromTimestamp(tokenExpires)
                        self.userData.set(id, forKey: DDP_ID)
                        self.userData.set(token, forKey: DDP_TOKEN)
                        self.userData.set(expiration, forKey: DDP_TOKEN_EXPIRES)
                }
                
                self.userMainQueue.addOperation() {
                    
                    if let c = callback { c(result, error) }
                    self.userData.set(true, forKey: DDP_LOGGED_IN)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: DDP_USER_DID_LOGIN), object: nil)

                    if let _ = self.delegate {
                        self.delegate!.ddpUserDidLogin(self.user()!)
                    }
                    
                }
                
                return
            }
            
            log.debug("Login error: \(e)")
            if let c = callback { c(result, error) }
        }
    }

    /**
    Logs a user into the server using an email and password
    
    - parameter email:      An email string
    - parameter password:   A password string
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    */
    
    public func loginWithPassword(_ email: String, password: String, callback: DDPMethodCallback?) {
        if !(loginWithToken(callback)) {
            let params = ["user": ["email": email], "password":["digest": password.sha256(), "algorithm":"sha-256"]] as NSDictionary
            login(params, callback: callback)
        }
    }
    
    /**
     Logs a user into the server using a username and password
     
     - parameter username:   A username string
     - parameter password:   A password string
     - parameter callback:   A closure with result and error parameters describing the outcome of the operation
     */
    
    public func loginWithUsername(_ username: String, password: String, callback: DDPMethodCallback?) {
        if !(loginWithToken(callback)) {
            let params = ["user": ["username": username], "password":["digest": password.sha256(), "algorithm":"sha-256"]] as NSDictionary
            login(params, callback: callback)
        }
    }
    
    /**
    Attempts to login a user with a token, if one exists
    
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    */
    
    @discardableResult public func loginWithToken(_ callback: DDPMethodCallback?) -> Bool {
        if let token = userData.string(forKey: DDP_TOKEN),
            let tokenDate = userData.object(forKey: DDP_TOKEN_EXPIRES) as? Date {
                print("Found token & token expires \(token), \(tokenDate)")
                if (tokenDate.compare(Date()) == ComparisonResult.orderedDescending) {
                    let params = ["resume":token] as NSDictionary
                    login(params, callback:callback)
                    return true
                }
        }
        return false
    }
    
    
    public func signup(_ params:NSDictionary, callback:((_ result: Any?, _ error: DDPError?) -> ())?) {
        method("createUser", params: NSArray(arrayLiteral: params)) { result, error in
            guard let e = error, (e.isValid == true) else {
                
                if let email = params["email"] {
                    self.userData.set(email, forKey: DDP_EMAIL)
                }
                
                if let username = params["username"] {
                    self.userData.set(username, forKey: DDP_USERNAME)
                }
                
                if let data = result as? NSDictionary,
                    let id = data["id"] as? String,
                    let token = data["token"] as? String,
                    let tokenExpires = data["tokenExpires"] as? NSDictionary {
                        let expiration = dateFromTimestamp(tokenExpires)
                        self.userData.set(id, forKey: DDP_ID)
                        self.userData.set(token, forKey: DDP_TOKEN)
                        self.userData.set(expiration, forKey: DDP_TOKEN_EXPIRES)
                        self.userData.synchronize()
                }
                if let c = callback { c(result, error) }
                self.userData.set(true, forKey: DDP_LOGGED_IN)
                return
            }
            
            log.debug("login error: \(e)")
            if let c = callback { c(result, error) }
        }
    }
    /**
    Invokes a Meteor method to create a user account with a given email and password on the server
    
    */
    
    public func signupWithEmail(_ email: String, password: String, callback: ((_ result:Any?, _ error:DDPError?) -> ())?) {
        let params = ["email":email, "password":["digest":password.sha256(), "algorithm":"sha-256"]] as [String : Any]
        signup(params as NSDictionary, callback: callback)
    }
    
    /**
    Invokes a Meteor method to create a user account with a given email and password, and a NSDictionary containing a user profile
    */
    
    public func signupWithEmail(_ email: String, password: String, profile: NSDictionary, callback: ((_ result:Any?, _ error:DDPError?) -> ())?) {
        let params = ["email":email, "password":["digest":password.sha256(), "algorithm":"sha-256"], "profile":profile] as [String : Any]
        signup(params as NSDictionary, callback: callback)
    }
    
    /**
     Invokes a Meteor method to create a user account with a given username, email and password, and a NSDictionary containing a user profile
     */
    
    public func signupWithUsername(_ username: String, password: String, email: String?, profile: NSDictionary?, callback: ((_ result:Any?, _ error:DDPError?) -> ())?) {
        let params: NSMutableDictionary = ["username":username, "password":["digest":password.sha256(), "algorithm":"sha-256"]]
        if let email = email {
            params.setValue(email, forKey: "email")
        }
        if let profile = profile {
            params.setValue(profile, forKey: "profile")
        }
        signup(params, callback: callback)
    }
    
    /**
    Returns the client userId, if it exists
    */
    
    public func userId() -> String? {
        return self.userData.object(forKey: DDP_ID) as? String
    }
    
    /**
    Returns the client's username or email, if it exists
    */
    
    public func user() -> String? {
        if let username = self.userData.object(forKey: DDP_USERNAME) as? String {
            return username
        } else if let email = self.userData.object(forKey: DDP_EMAIL) as? String {
            return email
        }
        return nil
    }
    
    
    internal func resetUserData() {
        self.userData.set(false, forKey: DDP_LOGGED_IN)
        self.userData.removeObject(forKey: DDP_ID)
        self.userData.removeObject(forKey: DDP_EMAIL)
        self.userData.removeObject(forKey: DDP_USERNAME)
        self.userData.removeObject(forKey: DDP_TOKEN)
        self.userData.removeObject(forKey: DDP_TOKEN_EXPIRES)
        self.userData.synchronize()
    }
    
    /**
    Logs a user out and removes their account data from NSUserDefaults
    */

    public func logout() {
        logout(nil)
    }
    
    /**
    Logs a user out and removes their account data from NSUserDefaults. 
    When it completes, it posts a notification: DDP_USER_DID_LOGOUT on the main queue
    
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    */
    
    public func logout(_ callback:DDPMethodCallback?) {
        method("logout", params: nil) { result, error in
                if (error == nil) {
                    self.userMainQueue.addOperation() {
                        let user = self.user()!
                        if let _ = self.delegate {
                            self.delegate!.ddpUserDidLogout(user)
                        }
                        self.resetUserData()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: DDP_USER_DID_LOGOUT), object: nil)
                    }
                    
                } else {
                    log.error("\(error)")
                }
                
                if let c = callback { c(result, error) }
            }
        }
    
    /**
    Automatically attempts to resume a prior session, if one exists
    
    - parameter url:        The server url
    */
    
    public func resume(_ url:String, callback:DDPCallback?) {
        connect(url) { session in
            if let _ = self.user() {
                self.loginWithToken() { result, error in
                    if error == nil {
                        log.debug("Resumed previous session at launch")
                        if let completion = callback { completion() }
                    } else {
                        self.logout()
                        log.error("\(error)")
                    }
                }
            } else {
                if let completion = callback { completion() }
            }
        }
    }
    
    /**
    Connects and logs in with an email address and password in one action
    
    - parameter url:        String url, ex. wss://todos.meteor.com/websocket
    - parameter email:      String email address
    - parameter password:   String password
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    */
    
    public convenience init(url: String, email: String, password: String, callback: DDPMethodCallback?) {
        self.init()
        connect(url) { session in
            self.loginWithPassword(email, password: password, callback:callback)
        }
    }
    
    /**
    Returns true if the user is logged in, and false otherwise
    */
    
    public func loggedIn() -> Bool {
        if let userLoggedIn = self.userData.object(forKey: DDP_LOGGED_IN) as? Bool, (userLoggedIn == true) {
            return true
        }
        return false
    }
    
}
