# SwiftDDP: A DDP Client for Meteor written in Swift

#### License
MIT  

[![Version](https://img.shields.io/cocoapods/v/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![License](https://img.shields.io/cocoapods/l/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![Platform](https://img.shields.io/cocoapods/p/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)

### New in version 0.2.0:
#### Integration with Meteor's Facebook, Twitter & other login services.


## Installation

Install using [Carthage](https://github.com/Carthage/Carthage) by adding the following line to your Cartfile:

```ruby
github "siegesmund/SwiftDDP" ~> 0.2.0
```

Or, use [CocoaPods](http://cocoapods.org). Add the following line to your Podfile:

```ruby
pod "SwiftDDP", "~> 0.2.0"
```

## Documentation
###[API Reference](https://siegesmund.github.io/SwiftDDP)

### Quick Start

#### Connecting to a Meteor server

```swift
import SwiftDDP 

// Meteor.connect will automatically connect and will sign in using
// a stored login token if the client was previously signed in.

Meteor.connect("wss://todos.meteor.com/websocket") {
// do something after the client connects
}
```

#### Login & Logout with Facebook, Twitter, etc.
Create a UIButton and associate its' action with the appropriate Meteor login method.
```swift
class ViewController: UIViewController {

@IBAction func loginWithTwitterWasClicked(sender: UIButton) {
Meteor.loginWithTwitter(self)
}

@IBAction func loginWithFacebookWasClicked(sender: UIButton) {
Meteor.loginWithFacebook(self)
}

}
```


#### Login & Logout with password

```swift
Meteor.loginWithPassword("user@swiftddp.com", password: "********") { result, error in 
// do something after login
}

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

#### Subscribe to a subset of a collection on the server

```swift
Meteor.subscribe("todos") 

Meteor.subscribe("todos") {
// Do something when the todos subscription is ready
}

Meteor.subscribe("todos", [1,2,3,4]) {
// Do something when the todos subscription is ready
} 
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

## Example: Creating an array based custom collection
#### The following pattern can be used to create custom collections backed by any datastore
In this example, we'll create a simple collection to hold a list of contacts. The first thing we'll do is create an object to represent a contact. This object has four properties and a method named *update* that maps the *fields* NSDictionary to the struct's properties. *Update* is called when an object is created and when an update is performed. Meteor will always transmit an **id** to identify the object that should be added, updated or removed, so objects that represent Meteor documents must **always** have an id field. Here we're sticking to the MongoDB convention of naming our id *_id*.

```swift

var contacts = [Contact]()

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
