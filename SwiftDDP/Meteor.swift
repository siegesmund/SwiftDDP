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
import UIKit

/*
enum Error: String {
    case BadRequest = "400"             // The server cannot or will not process the request due to something that is perceived to be a client error
    case Unauthorized = "401"           // Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided.
    case NotFound = "404"               // ex. Method not found, Subscription not found
    case Forbidden = "403"              // Not authorized to access resource, also issued when you've been logged out by the server
    case RequestConflict = "409"        // ex. MongoError: E11000 duplicate key error
    case PayloadTooLarge = "413"        // The request is larger than the server is willing or able to process.
    case InternalServerError = "500"
}
*/

public protocol MeteorCollectionType {
    func documentWasAdded(_ collection:String, id:String, fields:NSDictionary?)
    func documentWasChanged(_ collection:String, id:String, fields:NSDictionary?, cleared:[String]?)
    func documentWasRemoved(_ collection:String, id:String)
}

/**
Meteor is a class to simplify communicating with and consuming MeteorJS server services
*/

open class Meteor {
    
    /**
    client is a singleton instance of DDPClient
    */
        
    open static let client = Meteor.Client()          // Client is a singleton object
    
    internal static var collections = [String:MeteorCollectionType]()
    
    /**
    returns a Meteor collection, if it exists
    */
    
    open static func collection(_ name:String) -> MeteorCollectionType? {
        return collections[name]
    }
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription.
    */
    
    @discardableResult open static func subscribe(_ name:String) -> String { return client.sub(name, params:nil) }
    
    
    /**
    Sends a subscription request to the server.
    
    - parameter name:       The name of the subscription.
    - parameter params:     An object containing method arguments, if any.
    */
    
    @discardableResult open static func subscribe(_ name:String, params:[Any]) -> String { return client.sub(name, params:params) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription.
    - parameter params:     An object containing method arguments, if any.
    - parameter callback:   The closure to be executed when the server sends a 'ready' message.
    */
    
    @discardableResult open static func subscribe(_ name:String, params:[Any]?, callback: DDPCallback?) -> String { return client.sub(name, params:params, callback:callback) }
    
    /**
    Sends a subscription request to the server. If a callback is passed, the callback asynchronously
    runs when the client receives a 'ready' message indicating that the initial subset of documents contained
    in the subscription has been sent by the server.
    
    - parameter name:       The name of the subscription.
    - parameter callback:   The closure to be executed when the server sends a 'ready' message.
    */
    
    @discardableResult open static func subscribe(_ name:String, callback: DDPCallback?) -> String { return client.sub(name, params: nil, callback: callback) }
    
    /**
    Sends an unsubscribe request to the server. Unsubscibes to all subscriptions with the provided name.
     - parameter name:       The name of the subscription.
     
    */
    
    @discardableResult open static func unsubscribe(_ name:String, callback:DDPCallback?) -> [String] { return client.unsub(withName: name, callback: callback) }
    
    /**
     Sends an unsubscribe request to the server using a subscription id. This allows fine-grained control of subscriptions. For example, you can unsubscribe to specific combinations of subscriptions and subscription parameters. 
     - parameter id: An id string returned from a subscription request
     */
    
    @discardableResult open static func unsubscribe(withId id:String) { return client.unsub(withId: id, callback: nil) }
    
    /**
     Sends an unsubscribe request to the server using a subscription id. This allows fine-grained control of subscriptions. For example, you can unsubscribe to specific combinations of subscriptions and subscription parameters. If a callback is passed, the callback asynchronously
     runs when the unsubscribe transaction is complete.
     - parameter id: An id string returned from a subscription request
     - parameter callback:   The closure to be executed when the method has been executed
     */
    
    @discardableResult open static func unsubscribe(withId id:String, callback:DDPCallback?) { return client.unsub(withId: id, callback: callback) }
    
    /**
    Calls a method on the server. If a callback is passed, the callback is asynchronously
    executed when the method has completed. The callback takes two arguments: result and error. It
    the method call is successful, result contains the return value of the method, if any. If the method fails,
    error contains information about the error.
    
    - parameter name:       The name of the method
    - parameter params:     An array containing method arguments, if any
    - parameter callback:   The closure to be executed when the method has been executed
    */
    
    @discardableResult open static func call(_ name:String, params:[Any]?, callback:DDPMethodCallback?) -> String? {
        return client.method(name, params: params, callback: callback)
    }
    
    /**
    Call a single function to establish a DDP connection, and login with email and password
    
    - parameter url:        The url of a Meteor server
    - parameter email:      A string email address associated with a Meteor account
    - parameter password:   A string password 
    */
    
    open static func connect(_ url:String, email:String, password:String) {
        client.connect(url) { session in
            client.loginWithPassword(email, password: password) { result, error in
                guard let _ = error else {
                    if let _ = result as? NSDictionary {
                        // client.userDidLogin(credentials)
                    }
                    return
                }
            }
        }
    }
    
    /**
    Connect to a Meteor server and resume a prior session, if the user was logged in
    
    - parameter url:        The url of a Meteor server
    */
    
    open static func connect(_ url:String) {
        client.resume(url, callback: nil)
    }
    
    /**
    Connect to a Meteor server and resume a prior session, if the user was logged in
    
    - parameter url:        The url of a Meteor server
    - parameter callback:   An optional closure to be executed after the connection is established
    */
    
    open static func connect(_ url:String, callback:DDPCallback?) {
        client.resume(url, callback: callback)
    }

    
    /**
    Creates a user account on the server with an email and password
    
    - parameter email:      An email string
    - parameter password:   A password string
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    
    */
    
    open static func signupWithEmail(_ email: String, password: String, callback: DDPMethodCallback?) {
        client.signupWithEmail(email, password: password, callback: callback)
    }
    
    /**
     Creates a user account on the server with an email and password
     
     - parameter email:      An email string
     - parameter password:   A password string
     - parameter profile:    A dictionary containing the user profile
     - parameter callback:   A closure with result and error parameters describing the outcome of the operation
     
     */
    
    open static func signupWithEmail(_ email: String, password: String, profile: NSDictionary, callback: DDPMethodCallback?) {
        client.signupWithEmail(email, password: password, profile: profile, callback: callback)
    }
    
    /**
     Creates a user account on the server with a username and password
     
     - parameter username:   A username string
     - parameter password:   A password string
     - parameter email:      An email to be associated with the account
     - parameter profile:    A dictionary containing the user profile
     - parameter callback:   A closure with result and error parameters describing the outcome of the operation
     
     */
    
    open static func signupWithUsername(_ username: String, password: String, email: String? = nil, profile: NSDictionary? = nil, callback: DDPMethodCallback? = nil) {
        client.signupWithUsername(username, password: password, email: email, profile: profile, callback: callback)
    }
    
    /**
    Logs a user into the server using an email and password
    
    - parameter email:      An email string
    - parameter password:   A password string
    - parameter callback:   A closure with result and error parameters describing the outcome of the operation
    */
    
    open static func loginWithPassword(_ email:String, password:String, callback:DDPMethodCallback?) {
        client.loginWithPassword(email, password: password, callback: callback)
    }
    
    /**
    Logs a user into the server using an email and password
    
    - parameter email:      An email string
    - parameter password:   A password string
    */
    
    open static func loginWithPassword(_ email:String, password:String) {
        client.loginWithPassword(email, password: password, callback: nil)
    }
    
    /**
     Logs a user into the server using a username and password
     
     - parameter username:   A username string
     - parameter password:   A password string
     - parameter callback:   A closure with result and error parameters describing the outcome of the operation
     */
    
    open static func loginWithUsername(_ username:String, password:String, callback:DDPMethodCallback? = nil) {
        client.loginWithUsername(username, password: password, callback: callback)
    }

    /**
     Logs a user into the server using a third party auth provider
     
     - parameter params:   sign in parameters
     - parameter callback:   A closure with result and error parameters describing the outcome of the operation
     */
    
    open static func login(_ params: NSDictionary, callback:DDPMethodCallback?) {
        client.login(params, callback: callback)
    }
    
    internal static func loginWithService<T: UIViewController>(_ service: String, clientId: String, viewController: T) {
        
        // Resume rather than
//        if Meteor.client.loginWithToken(nil) == false {
//            var url:String!
//            
//            switch service {
//            case "twitter":
//                url = MeteorOAuthServices.twitter()
//                
//            case "facebook":
//                url =  MeteorOAuthServices.facebook(clientId)
//                
//            case "github":
//                url = MeteorOAuthServices.github(clientId)
//                
//            case "google":
//                url = MeteorOAuthServices.google(clientId)
//                
//            default:
//                url = nil
//            }
//            
//            let oauthDialog = MeteorOAuthDialogViewController()
//            oauthDialog.serviceName = service.capitalizedString
//            oauthDialog.url = NSURL(string: url)
//            viewController.presentViewController(oauthDialog, animated: true, completion: nil)
//            
//        } else {
//            log.debug("Already have valid server login credentials. Logging in with preexisting login token")
//        }
        
    }
    
    /**
     Logs a user into the server using Twitter
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     */
    
    open static func loginWithTwitter<T: UIViewController>(_ viewController: T) {
        Meteor.loginWithService("twitter", clientId: "", viewController: viewController)
    }
    
    /**
     Logs a user into the server using Facebook
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithFacebook<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("facebook", clientId: clientId, viewController: viewController)
    }
    
    /**
     Logs a user into the server using Github
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithGithub<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("github", clientId: clientId, viewController: viewController)
    }

    /**
     Logs a user into the server using Google
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithGoogle<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("google", clientId: clientId, viewController: viewController)
    }
    
    /**
    Logs a user out of the server and executes a callback when the logout process has completed
    
    - parameter callback: An optional closure to be executed after the client has logged out
    */
    
    open static func logout(_ callback:DDPMethodCallback?) {
        client.logout(callback)
    }
    
    /**
    Logs a user out of the server
    */
    
    open static func logout() {
        client.logout()
    }
    
    /**
    Meteor.Client is a subclass of DDPClient that facilitates interaction with the MeteorCollection class
    */
    
    open class Client: DDPClient {
        
        typealias SubscriptionCallback = () -> ()
        let notifications = NotificationCenter.default
        
        public convenience init(url:String, email:String, password:String) {
            self.init()
        }
        
        /**
        Calls the documentWasAdded method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        - parameter fields:         an optional NSDictionary with the documents properties
        */
        
        open override func documentWasAdded(_ collection:String, id:String, fields:NSDictionary?) {
            if let meteorCollection = Meteor.collections[collection] {
                meteorCollection.documentWasAdded(collection, id: id, fields: fields)
            }
        }
        
        /**
        Calls the documentWasChanged method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        - parameter fields:         an optional NSDictionary with the documents properties
        - parameter cleared:        an optional array of string property names to delete
        */
        
        open override func documentWasChanged(_ collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
            if let meteorCollection = Meteor.collections[collection] {
                meteorCollection.documentWasChanged(collection, id: id, fields: fields, cleared: cleared)
            }
        }
        
        /**
        Calls the documentWasRemoved method in the MeteorCollection subclass instance associated with the document
        collection
        
        - parameter collection:     the string name of the collection to which the document belongs
        - parameter id:             the string unique id that identifies the document on the server
        */
        
        open override func documentWasRemoved(_ collection:String, id:String) {
            if let meteorCollection = Meteor.collections[collection] {
                meteorCollection.documentWasRemoved(collection, id: id)
            }
        }
    }
}
