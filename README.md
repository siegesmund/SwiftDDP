SwiftDDP  <img src="https://github.com/siegesmund/SwiftDDP/blob/master/assets/logo.jpg" height="75" width="75"/> 
=====
## A client for Meteor servers, written in Swift
### version 0.3.1

#### License
MIT  

[![Version](https://img.shields.io/cocoapods/v/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![License](https://img.shields.io/cocoapods/l/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![Platform](https://img.shields.io/cocoapods/p/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Installation](#installation)
- [Documentation](#documentation)
  - [Quick Start](#quick-start)
    - [Setting basic configuration options](#setting-basic-configuration-options)
    - [Connecting to a Meteor server](#connecting-to-a-meteor-server)
    - [Login & Logout with Facebook, Twitter, etc. (beta)](#login-&-logout-with-facebook-twitter-etc-beta)
    - [Gotchas and implementation notes for OAuth login flows](#gotchas-and-implementation-notes-for-oauth-login-flows)
    - [Login & Logout with password](#login-&-logout-with-password)
    - [Subscribe to a subset of a collection](#subscribe-to-a-subset-of-a-collection)
    - [Change the subscription's parameters and manage your subscription with unsubscribe](#change-the-subscriptions-parameters-and-manage-your-subscription-with-unsubscribe)
    - [Call a method on the server](#call-a-method-on-the-server)
    - [Simple in-memory persistence](#simple-in-memory-persistence)
- [Example Projects](#example-projects)
    - [Todos](#todos)
- [Example: Creating an array based custom collection](#example-creating-an-array-based-custom-collection)
- [Changelog](#changelog)
  - [0.3.1](#031)
  - [0.3.0](#030)
  - [0.2.2.1](#0221)
  - [0.2.1](#021)
  - [0.2.0](#020)
- [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

With [CocoaPods](http://cocoapods.org). Add the following line to your Podfile:

```ruby
pod "SwiftDDP", "~> 0.3.0"
```

## Documentation
###[API Reference](https://siegesmund.github.io/SwiftDDP)

### Quick Start

#### Setting basic configuration options
```swift
import SwiftDDP

Meteor.client.allowSelfSignedSSL = true     // Connect to a server that uses a self signed ssl certificate
Meteor.client.logLevel = .Info              // Options are: .Verbose, .Debug, .Info, .Warning, .Error, .Severe, .None
```


#### Connecting to a Meteor server

```swift

// Meteor.connect will automatically connect and will sign in using
// a stored login token if the client was previously signed in.

Meteor.connect("wss://todos.meteor.com/websocket") {
    // do something after the client connects
}
```

#### Login & Logout with Facebook, Twitter, etc. (beta)
These services use the standard Meteor accounts packages. Just add the appropriate package on the server (e.g.  ```meteor add accounts-facebook```) and follow the web-based provider setup. Choose redirect, rather than popup and save your appId/clientId as you'll need it again in your iOS application.

In your iOS app, create a UIButton and associate its' action with the appropriate Meteor login method. That's it!
```swift
class ViewController: UIViewController {

    // client id is the id that Facebook, Google etc. assigns your app.
    let GITHUB_CLIENT_ID = "1234567890"
    let FACEBOOK_CLIENT_ID = "qwertyuiop"
    let GOOGLE_CLIENT_ID = "asdfghjkl"

    // Note that Twitter does not require a client id
    @IBAction func loginWithTwitterWasClicked(sender: UIButton) {
        Meteor.loginWithTwitter(self)
    }

    @IBAction func loginWithFacebookWasClicked(sender: UIButton) {
        Meteor.loginWithFacebook(FACEBOOK_CLIENT_ID, viewController: self)
    }

    @IBAction func loginWithGoogleWasClicked(sender: UIButton) {
        Meteor.loginWithGoogle(GOOGLE_CLIENT_ID, viewController: self)
    }

    @IBAction func loginWithGithubWasClicked(sender: UIButton) {
        Meteor.loginWithGithub(GITHUB_CLIENT_ID, viewController: self)
    }
}

```
#### Gotchas and implementation notes for OAuth login flows
When configuring OAuth services
* If you connect over wss (as you should), then you must provide a https:// app url and redirect url to the service provider. If you connect over ws, you must use http:// for your app url and redirect url. In other words, you can't mix the two.  
* You'll need to choose redirect rather than popup in the Meteor OAuth configuration dialog
* Once configured, Meteor provides the appId/clientId via the "meteor.loginServiceConfiguration" publication, which SwiftDDP automatically subscribes to. However, SwiftDDP currently requires that you explicitly provide the appId as this allows the user to begin logging in immediately, rather than waiting for the initial batch of subscriptions to finish.

#### Login & Logout with password

Login using email and password.

```swift
Meteor.loginWithPassword("user@swiftddp.com", password: "********") { result, error in
    // do something after login
}
```

Login using username and password.

```swift
Meteor.loginWithUsername("swiftddp", password: "********") { result, error in
    // do something after login
}
```

Log out.

```swift
Meteor.logout() { result, error in
    // do something after logout
}

```
The client also posts a notification when the user signs in and signs out.

```swift
// Notification name (a string global variable)
DDP_USER_DID_LOGIN
DDP_USER_DID_LOGOUT

// Example
NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDidLogin", name: DDP_USER_DID_LOGIN, object: nil)
NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDidLogout", name: DDP_USER_DID_LOGOUT, object: nil)

func userDidLogin() {
    print("The user just signed in!")
}

func userDidLogout() {
    print("The user just signed out!")
}
```

#### Subscribe to a subset of a collection

```swift
Meteor.subscribe("todos")

Meteor.subscribe("todos") {
    // Do something when the todos subscription is ready
}

Meteor.subscribe("todos", [1,2,3,4]) {
    // Do something when the todos subscription is ready
}
```

#### Change the subscription's parameters and manage your subscription with unsubscribe
```swift

// Suppose you want to subscribe to a list of all cities and towns near a specific major city

// Subscribe to cities near Boston
let id1 = Meteor.subscribe("cities", ["lat": 42.358056 ,"lon": -71.063611]) {
    // You are now subscribed to cities associated with the coordinates 42.358056, -71.063611
    // id1 contains a key that allows you to cancel the subscription associated with 
    // the parameters ["lat": 42.358056 ,"lon": -71.063611]
}

// Subscribe to cities near Paris
let id2 = Meteor.subscribe("cities", ["lat": 48.8567, "lon": 2.3508]){
    // You are now subscribed to cities associated with the coordinates 48.8567, 2.3508
    // id2 contains a key that allows you to cancel the subscription associated with 
    // the parameters ["lat": 48.8567 ,"lon": 2.3508]
}

// Subscribe to cities near New York
let id3 = Meteor.subscribe("cities", ["lat": 40.7127, "lon": -74.0059]){
    // You are now subscribed to cities associated with the coordinates 40.7127, -74.0059
    // id3 contains a key that allows you to cancel the subscription associated with 
    // the parameters ["lat": 40.7127 ,"lon": -74.0059]
}

// When these subscriptions have completed, the collection associated with "cities" will now contain all
// documents returned from the three subscriptions

Meteor.unsubscribe(withId: id2) 
// Your collection will now contain cities near Boston and New York, but not Paris
Meteor.unsubscribe("cities")    
// You are now unsubscribed to all subscriptions associated with the publication "cities"
```

#### Call a method on the server

```swift
Meteor.call("foo", [1, 2, 3, 4]) { result, error in
    // Do something with the method result
}
```
When passing parameters to a server method, the parameters object must be serializable with NSJSONSerialization

#### Simple in-memory persistence
SwiftDDP includes a class called MeteorCollection that provides simple, ephemeral dictionary backed persistence. MeteorCollection stores objects subclassed from MeteorDocument. Creating a collection is as simple as:

```swift
class List: MeteorDocument {

    var collection:String = "lists"
    var name:String?
    var userId:String?

}

let lists = MeteorCollection<List>(name: "lists")   // As with Meteorjs, the name is the name of the server-side collection  
Meteor.subscribe("lists")
```
For client side insertions, updates and removals:

```swift
let list = List(id: Meteor.client.getId(), fields: ["name": "foo"])

// Insert the object on both the client and server.
lists.insert(list)

// Update the object on both the client and server
list.name = "bar"
lists.update(list)

// Remove the object on both the client and server
lists.remove(list)
```
For each operation the action is executed on the client, and rolled back if the server returns an error.

## Example Projects
#### Todos
These are iOS implementations of [Meteor's Todos example](https://www.meteor.com/todos). The best way to run the examples is to connect to a local instance of Meteor's Todos app: ``` meteor create --example todos && cd todos && meteor ```. You can specify the server that the Todos app connects to by changing the url variable in AppDelegate.swift. There are currently two flavors: a simple example with dictionary based persistence and an example showing how to use SwiftDDP with Core Data and NSFetchedResultsController.
- [Meteor Todos with dictionary based in-memory storage](https://github.com/siegesmund/SwiftDDP/tree/master/Examples/Dictionary)
- [Meteor Todos Core Data integration](https://github.com/siegesmund/SwiftDDP/tree/master/Examples/CoreData)

When running the examples with preexisting instances of the todos app hosted at *.meteor.com, note that connectivity to apps hosted on Meteor's free hosting (not to be confused with Galaxy) can be erratic as the server periodically idles. If SwiftTodos does not connect or you cannot add or remove items or login, try connecting to a different instance. The surest way to do this is to run an instance of the todos app locally.

```bash meteor create --example todos```

Once you've created and started the Meteor todos server, set the url variable in AppDelegate.swift to ws://localhost:3000/websocket, then run the iOS app.


## Example: Creating an array based custom collection
**The following pattern can be used to create custom collections backed by any datastore**

In this example, we'll create a simple collection to hold a list of contacts. The first thing we'll do is create an object to represent a contact. This object has four properties and a method named *update* that maps the *fields* NSDictionary to the struct's properties. *Update* is called when an object is created and when an update is performed. Meteor will always transmit an **id** to identify the object that should be added, updated or removed, so objects that represent Meteor documents must **always** have an id field. Here we're sticking to the MongoDB convention of naming our id *_id*.

```swift

struct Contact {

    var _id:String?
    var name:String?
    var phone:String?
    var email:String?

    init(id:String, fields:NSDictionary?) {
        self._id = id
        update(fields)
    }

    mutating func update(fields:NSDictionary?) {

        if let name = fields?.valueForKey("name") as? String {
            self.name = name
        }

        if let phone = fields?.valueForKey("phone") as? String {
            self.phone = phone
        }

        if let email = fields?.valueForKey("email") as? String {
            self.email = email
        }
    }
}

```
Next, we'll create the collection class that will hold our contacts and provide the logic to respond to server-side changes to the documents and the subscription set. SwiftDDP contains an abstract class called AbstractCollection that can be used to build custom collections. Subclassing AbstractCollection allows you to override three methods that are called in response to events on the server: *documentWasAdded*, *documentWasChanged* and *documentWasRemoved*.

```swift
class UserCollection: AbstractCollection {

    var contacts = [Contact]()

    // Include any logic that needs to occur when a document is added to the collection on the server
    override public func documentWasAdded(collection:String, id:String, fields:NSDictionary?) {
        let user = User(id, fields)
        users.append(user)
    }

    // Include any logic that needs to occur when a document is changed on the server
    override public func documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?) {
        if let index = contacts.indexOf({ contact in return contact._id == id }) {
            contact = contacts[index]
            contact.update(fields)
            contacts[index] = contact
        }
    }

  // Include any logic that needs to occur when a document is removed on the server
  override public func documentWasRemoved(collection:String, id:String) {
    if let index = contacts.indexOf({ contact in return contact._id == id }) {
        contacts[index] = nil
        }
    }
}
```
So far, we're able to process documents that have been added, changed or removed on the server. But the UserCollection class still lacks the ability to make changes to both the local datastore and on the server. We'll change that. In the UserCollection class, create a method called insert.

```swift
class UserCollection: AbstractCollection {
    /*
    override public func documentWasAdded ...
    override public func documentWasChanged ...
    override public func documentWasRemoved ...
    */

    public func insert(contact: Contact) {

        // (1) save the document to the contacts array
        contacts[contacts._id] = contact

        // (2) now try to insert the document on the server
        client.insert(self.name, document: [contacts.fields()]) { result, error in

            // (3) However, if the server returns an error, reverse the action on the client by
            //     removing the document from the contacts collection
            if error != nil {
                self.contacts[contact._id] = nil
                log.error("\(error!)")
            }

        }

    }
}
```
The key parts of this method are:
- (1) save the new contact to the array we created in UserCollection
- (2) invoke client.insert to initiate an insert on the server
- (3) remove the contact from the local store if the server rejects the insert

Creating update and remove methods are also easy to create, and follow the same patern as insert. For a more extensive example of the patterns shown here, have a look at [MeteorCollection.swift](https://github.com/siegesmund/SwiftDDP/blob/master/SwiftDDP/MeteorCollection.swift). MeteorCollection is an in-memory collection implementation suitable for simple applications.


## Changelog
### 0.3.1
- Bug fixed that affected DDP dates in 32 bit environments 

### 0.3.0
- Changed default subscription behavior
- Added a method to sign a user in via username

**Version 0.3.0 contains breaking changes**
- You can now update a subscription by changing its parameters without first unsubscribing. This will subscribe the client to any documents associated with the new subscription and parameters. When you pass a new set of parameters to a subscription that you have previously subscribed to, you remain subscribed to any documents associated with that prior subscription.  
- The subscription method returns an id. To unsubscribe to documents associated with a specific set of parameters, you must unsubscribe with this id.
- Unsubscribing by name now works differently. When unsubscribing by name, you unsubscribe to any and all subscriptions with that name.
- You can no longer pass a callback to ``unsubscribe(name:String)``. It now returns an array with the ids of the subscriptions you've unsubscribed to.

### 0.2.2.1

- Improved subscription handling across app states
- Dependencies updated for Swift 2.2

### 0.2.1
- Reconnection behavior improvements: reconnect attempts now follow an exponential backoff pattern
- Client now connects to servers using self signed SSL certificates when allowSelfSignedSSL is set to true
- The loglevel can now be set directly using the logLevel property on the client. The default setting is .None

### 0.2.0
- Integration with Meteor's Facebook, Twitter & other login services

## Contributing
Pull requests, feature requests are feedback are welcome. If you're using SwiftDDP in a production app, let us know.
