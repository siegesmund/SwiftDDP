# SwiftDDP: A DDP Client for Meteor written in Swift

## Why?
There are already two great DDP clients for iOS: [ObjectiveDDP](https://github.com/boundsj/ObjectiveDDP), and [Meteor iOS](https://github.com/martijnwalraven/meteor-ios). Why a third?  
In a nutshell, Swift. Swift's syntax promotes simplicity and is stylistically closer to the code you're probably writing for your Meteor server. Written in pure Swift, SwiftDDP requires no bridging headers and for new projects it will reduce or eliminate the amount of Objective-C code you have to think about.

SwiftDDP aims for simplicity and is datastore agnostic. 

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
####1. [DDP Client](Documentation/DDP.md)  
####2. [Realm Integration](Documentation/Realm.md)