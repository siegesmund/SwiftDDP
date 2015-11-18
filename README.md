# SwiftDDP: A DDP Client for Meteor written in Swift

#### License
MIT  

[![Version](https://img.shields.io/cocoapods/v/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![License](https://img.shields.io/cocoapods/l/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)
[![Platform](https://img.shields.io/cocoapods/p/SwiftDDP.svg?style=flat)](http://cocoapods.org/pods/SwiftDDP)

## Installation

Install using [Carthage](https://github.com/Carthage/Carthage) by adding the following line to your Cartfile:

```ruby
github "siegesmund/SwiftDDP"
```

Or, use [CocoaPods](http://cocoapods.org). Add the following line to your Podfile:

```ruby
pod "SwiftDDP"
```

## Documentation ##
###[API Reference](https://siegesmund.github.io/SwiftDDP)###

## Quick Start ##
### Getting an instance of the client ####

```swift
import SwiftDDP

// Returns a singleton instance of the client
let meteor = Meteor.client
```

### Connecting to a Meteor server

```swift
// Meteor.connect will automatically connect and will sign in using
// a stored login token if the client was previously signed in.

Meteor.connect("wss://todos.meteor.com/websocket") {
// do something after the client connects
}
```

### Login & Logout ###
```swift
Meteor.loginWithPassword("user@swiftddp.com", password: "********") { result, error in 
// do something after login
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

### Subscribe to a subset of a collection on the server
```swift
Meteor.subscribe("todos") 

Meteor.subscribe("todos") {
// Do something when the todos subscription is ready
}

Meteor.subscribe("todos", [1,2,3,4]) {
// Do something when the todos subscription is ready
} 
```

### Call a method on the server ###
```swift
Meteor.call("foo", [1, 2, 3, 4]) {
// Do something with the method result
}
```

### Todos ###
Complete documentation for Meteor.Collection & MeteorCollectionType protocol