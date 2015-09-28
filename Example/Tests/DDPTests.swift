import Quick
import Nimble
@testable import SwiftDDP


//
//
//  Test Data
//
//

//  *** methods that are tested against a server are tested against the url below ***

let url = "ws://swiftddp.meteor.com/websocket"
// let url = "ws://localhost:3000/websocket"
let user = "test@user.com"
let pass = "swiftddp"

let ready = DDP.Message(message: "{\"msg\":\"ready\", \"subs\":[\"AllStates\"]}")
let nosub = DDP.Message(message: ["msg":"nosub", "id":"AllStates"])

let added = [DDP.Message(message: "{\"collection\" : \"test-collection\", \"id\" : \"2gAMzqvE8K8kBWK8F\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Boston\"}, \"msg\" : \"added\"}"),
             DDP.Message(message:"{\"collection\" : \"test-collection\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Truro\"}, \"msg\" : \"added\"}"),
             DDP.Message(message:"{\"collection\" : \"test-collection\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Austin\"}, \"msg\" : \"added\"}")]

let removed = [DDP.Message(message: ["msg" : "removed", "id" : "2gAMzqvE8K8kBWK8F","collection" : "test-collection"]),
               DDP.Message(message: ["msg" : "removed", "id" : "ByuwhKPGuLru8h4TT", "collection" : "test-collection"]),
               DDP.Message(message:["msg" : "removed", "id" : "AGX6vyxCJtjqdxbFH", "collection" : "test-collection"])]

let changed = [DDP.Message(message: "{\"collection\" : \"test-collection\", \"id\" : \"2gAMzqvE8K8kBWK8F\",\"cleared\" : [\"city\"], \"fields\" : {\"state\" : \"MA\", \"city\" : \"Amherst\"}, \"msg\" : \"changed\"}"),
               DDP.Message(message:"{\"collection\" : \"test-collection\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Cambridge\"}, \"msg\" : \"changed\"}"),
               DDP.Message(message:"{\"collection\" : \"test-collection\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Houston\"}, \"msg\" : \"changed\"}")]

let userAddedWithPassword = DDP.Message(message: "{\"collection\" : \"users\", \"id\" : \"123456abcdefg\", \"fields\" : {\"roles\" : [\"admin\"], \"emails\" : [{\"address\" : \"test@user.com\", \"verified\" : false}], \"username\" : \"test\"}, \"msg\" : \"added\"}")

//
//
// Test Classes
//
//

// Requires connection to DDP Server
class DDPConnectionTest:QuickSpec {
    override func spec() {
        describe ("DDP Connection") {
            
            it ("can connect to a DDP server"){
                var testSession:String?
                let client = DDP.Client(url:url) { session in testSession = session }
                
                expect(client.connection.ddp).toEventually(beTrue())
                expect(client.connection.session).toEventually(equal(testSession))
            }
        }
    }
}

class DDPMessageTest:QuickSpec {
    override func spec() {
        describe ("DDPMessage") {
            
            it ("can be created from a Dictionary") {
                let message = DDP.Message(message: ["msg":"test", "id":"test100"])
                expect(message.hasProperty("msg")).to(beTrue())
                expect(message.hasProperty("id")).to(beTruthy())
                expect(message.id!).to(equal("test100"))
                expect(message.message!).to(equal("test"))
            }
            
            it ("can be created from a String") {
                let message = DDP.Message(message: "{\"msg\":\"test\", \"id\":\"test100\"}")
                expect(message.hasProperty("msg")).to(beTruthy())
                expect(message.hasProperty("id")).to(beTruthy())
                expect(message.id!).to(equal("test100"))
                expect(message.message!).to(equal("test"))
            }
            
            it ("handles malformed json without crashing") {
                let message = DDP.Message(message: "{\"msg\":\"test\", \"id\"test100\"}")
                let error = message.error!["error"] as! String
                expect(error).to(equal("SwiftDDP JSON serialization error."))
            }
        }
    }
}

class DDPMessageHandlerTest:QuickSpec {
    override func spec() {
        describe ("DDPMessageHandler routing") {
            
            it ("can handle an 'added' message"){
                let client = DDP.Client(url: url)
                client.events.onAdded = {collection, id, fields in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                    let city = fields!["city"]! as! String
                    expect(city).to(equal("Boston"))
                }
                client.ddpMessageHandler(added[0])
            }
            
            it ("can handle a 'removed' message") {
                let client = DDP.Client(url: url)
                client.events.onRemoved = {collection, id in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                }
                client.ddpMessageHandler(removed[0])
            }
        }
    }
}

class DDPPubSubTest:QuickSpec {
    override func spec() {
        describe("DDP PubSub") {
            
            // DDP Publication/Subscription
            // * Requires connection to DDP Server *

            // - When the client subscribes to a set of data,
            //   a subscription should be recorded in client.subscriptions
            // - The client should receive the correct number of 'added' messages for the subscription
            // - When the client receives a ready message, the ready property of the subscription tuple
            //   should be set to true
            // - When the client unsubscribes from a set of data, the tuple describing the subscription should
            //   be removed from client.subscriptions
            // - The client should receive the correct number of 'removed' messages for the subscription

            it ("can subscribe and unsubscribe to a collection") {
                var added = [String]()
                var removed = [String]()
                let client = DDP.Client(url: url)

                client.connect() {session in
                client.loginWithPassword(user, password: pass) {result, error in
                    client.events.onAdded = {collection, id, fields in added.append(id) }
                    client.events.onRemoved = {collection, id in removed.append(id) }
                    client.sub("AllStates", params:nil)
                    }
                }
                
                // The client should receive an ready message. When this message is received
                // the added array should contain all of the data items in the subscription (in this case 3 items)
                expect(client.findSubscription("AllStates")?.ready).toEventually(beTrue())
                expect(added.count).to(equal(3))

                client.unsub("AllStates")
                
                // After receiving a nosub message, the subscription entry in collections should have been removed
                // the removed array should contain a list of all of the items in the subscription
                expect(client.findSubscription("AllStates")).toEventually(beNil())
                expect(removed.count).toEventually(equal(3))

            }
            
        }
    }
}

// Requires connection to DDP Server
class DDPMethodTest:QuickSpec {
    override func spec() {
        describe ("DDP Methods") {
            
            // DDP Methods
            // tests :login, :logout, :insert, :remove, :update
            
            it ("can login to a Meteor server") {
                
                // On connect, the client should set the client.connection.session property
                // After logging in with a username and password, the client should receive a result
                // object that the session token
                
                var testResult:NSDictionary!
                var testSession:String!
                
                let client = DDP.Client(url: url)
                client.connect() { session in
                    testSession = session
                    client.loginWithPassword(user, password: pass) { result, e in
                    testResult = result!
                    }
                }
                
                // Both of these should be non nil; the callbacks should assign them their respective values
                expect(testResult).toEventuallyNot(beNil())
                expect(testSession).toEventuallyNot(beNil())
                
                let userDefaultsToken = client.userData.objectForKey("token") as! String
                let resultToken = (testResult!["result"] as! NSDictionary)["token"] as! String
                
                expect(userDefaultsToken).toEventually(equal(resultToken))
                expect(testSession).toEventually(equal(client.connection.session))
            }
            
            it ("can add and remove a document on the server"){
                
                let client = DDP.Client(url: url)
                client.connect() { session in
                    
                    client.loginWithPassword(user, password: pass) { result, e in }
                }
                
                var added = [NSDictionary]()
                var removed = [String]()
                
                client.events.onAdded = { collection, id, fields in added.append(fields!) }
                client.events.onRemoved = { collection, id in removed.append(id) }
                
                
                client.sub("test-collection2", params:nil)
                client.insert("test-collection2", doc: NSArray(arrayLiteral:["_id":"100", "foo":"bar"]))
                
                // the tuple that holds the subscription data in the client should be updated to reflect that the 
                // subscription is ready
                expect(client.findSubscription("test-collection2")?.ready).toEventually(beTrue())
                
                // test that the data is returned from the server
                expect(added.count).toEventually(equal(1))
                expect(added[0]["foo"] as? String).to(equal("bar"))
                
                // test that the data is removed from the server (can also me checked on the server)
                client.remove("test-collection2", doc:NSArray(arrayLiteral:["_id":"100"]))
                expect(removed.count).toEventually(equal(1))
                expect(removed[0]).to(equal("100"))
            }
            
            it ("can update a document in a collection") {
                
            }
        }
    }
}
