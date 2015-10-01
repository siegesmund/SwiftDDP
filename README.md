# SwiftDDP: A DDP Client for Meteor written in Swift

## Why?
There are already two great DDP clients for iOS: [ObjectiveDDP](https://github.com/boundsj/ObjectiveDDP), and [Meteor iOS](https://github.com/martijnwalraven/meteor-ios). Why a third?  
In a nutshell, Swift. Swift's syntax promotes simplicity and is stylistically closer to the code you're probably writing for your Meteor server. Written in pure Swift, SwiftDDP requires no bridging headers and for new projects it will reduce or eliminate the amount of Objective-C code you have to think about.

SwiftDDP aims for simplicity and is datastore agnostic. 

#### License
MIT  


[![CI Status](http://img.shields.io/travis/Peter/SwiftDDP.svg?style=flat)](https://travis-ci.org/Peter/SwiftDDP)
[![Version](https://img.shields.io/cocoapods/v/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![License](https://img.shields.io/cocoapods/l/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![Platform](https://img.shields.io/cocoapods/p/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)

## Installation

SwiftDDP is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftDDP"
```

## Usage

### Login  
SwiftDDP includes basic authentication.
Create a single client object in, for example, your app delegate.

###### Example 1
``` swift
client = DDP.Client(url: "ws://swiftddp.meteor.com/websocket", email: "test@user.com", password: "swiftddp") { result, error in 
// Do something post login in this closure
// The error variable will contain an error message if the login was unsuccessful

}
```

###### Example 2
``` swift 
client = DDP.Client(url: "ws://swiftddp.meteor.com/websocket") 
client.connect() { session in // This will create a ddp connection, returning the session id as a String
client.loginWithPassword(email: "test@user.com", password: "swiftddp") { result, error in 
// Do something post-login here
}
}
```

### Subscribe
``` swift 
// You can pass an array of parameters to the server, just as you would in Javascript
client.sub("AllCities", params: nil) { 
// Put some code here that will execute asynchronously when the subscription is ready
}
```

### Unsubscribe
SwiftDDP is not a datastore, so unsubscribe only triggers the server to send 'removed' messages for the documents that you are no longer subscribed to.

``` swift
client.unsub(withName: "AllCities) {
// Run code here when unsub is finished
}
```

### Document addition, update and removal
When documents change on the server, or when the set of documents that you're subscribed to changes, the server sends messages instructing the client which documents to add, which to remove and which to update in the local collection. You use the following methods to specify how documents should be added, removed and updated.
There are two ways to control what happens when a message is received to add a document to the local collection, to update it, or to remove it:  
#####1) You can subclass DDP.Client and override the following methods
- **collection** is a string containing the name of the collection that the document belongs to.  
- **id** is a string containing the _id field of the document on the server  
- **fields** is an NSDictionary with the fields of the Json document to be added, or the list of fields to be updated   
- **cleared** is a list of fields that should be deleted as part of the document update

``` swift  
documentWasAdded(collection:String, id:String, fields:NSDictionary?)  
documentWasRemoved(collection:String, id:String)  
documentWasChanged(collection:String, id:String, fields:NSDictionary?, cleared:[String]?)  

// These functions will execute for each document that is added, removed or changed.
```

#####2) You can assign closures to the DDP.Events object:
``` swift
// This pattern is appropriate for testing and if you prefer composition to inheritance.

client.events.onAdded = { collection, id, fields in // handle adding the document here } 
client.events.onRemoved = { collection, id in // handle removing the document here }
client.events.onChanged = { collection, id, fields, cleared in // handle changing the document here }
```



### Method Calls
```swift
client.method(name:"foo", params:["bar", "baz"]) { result, error in 
// Do something with the result of your method (or, if an error is returned, handle it)
}
```

###Todo
Documentation for insert, update, remove methods  
Improved error handling  
Additional tests