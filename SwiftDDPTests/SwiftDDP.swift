import Quick
import Nimble
@testable import SwiftDDP

//
//
// Test Classes
//
//

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
                expect(message.isError).to(beTrue())
                expect(message.reason!).to(equal("SwiftDDP JSON serialization error."))
            }
            
            it ("Sends malformed json to the error handler callback") {
                
                var error:DDP.Error!
                
                let client = DDP.Client()
                client.events.onError = {e in error = e }
                let message = DDP.Message(message: "{\"msg\":\"test\", \"id\"test100\"}")
                try! client.ddpMessageHandler(message)
                
                expect(message.isError).to(beTrue())
                expect(message.reason!).to(equal("SwiftDDP JSON serialization error."))
                
                expect(error).toNot(beNil())
                expect(error.isValid).to(beTrue())
                expect(error.reason!).to(equal("SwiftDDP JSON serialization error."))
            }
            
        }
        
        describe ("DDPMessageHandler routing") {
            
            it ("can handle an 'added' message"){
                let client = DDP.Client()
                client.events.onAdded = {collection, id, fields in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                    let city = fields!["city"]! as! String
                    expect(city).to(equal("Boston"))
                }
                try! client.ddpMessageHandler(added[0])
            }
            
            it ("can handle a 'removed' message") {
                let client = DDP.Client()
                client.events.onRemoved = {collection, id in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                }
                try! client.ddpMessageHandler(removed[0])
            }
            
            it ("can handle a result message that returns a value") {
                var value:String!
                var r:AnyObject?
                var e:DDP.Error?
                
                let client = DDP.Client()
                client.resultCallbacks["1"] = {(result:AnyObject?, error:DDP.Error?) -> () in
                    value = result as! String
                    r = result
                    e = error
                }
                
                try! client.ddpMessageHandler(DDP.Message(message: ["id":"1", "msg":"result", "result":"test123"]))
                expect(r).toNot(beNil())
                expect(e).to(beNil())
                expect(value).to(equal("test123"))
                
            }
            
            it ("can handle a result message that does not return a value") {
                var value:String!
                var r:AnyObject?
                var e:DDP.Error?
                
                let client = DDP.Client()
                client.resultCallbacks["1"] = {(result:AnyObject?, error:DDP.Error?) -> ()
                    in if let v = result as? String { value = v }
                    r = result
                    e = error
                }
                
                try! client.ddpMessageHandler(DDP.Message(message: ["id":"1", "msg":"result"]))
                expect(value).to(beNil())
                expect(r).to(beNil())
                expect(e).to(beNil())
            }
        }
    }
}

// Tests against a Meteor instance at swiftddp.meteor.com
class DDPServerTests:QuickSpec {
    override func spec() {
        
        describe ("DDP Connection") {
            
            it ("can connect to a DDP server"){
                var testSession:String?
                let client = DDP.Client()
                client.connect(url) { session in testSession = session }
                expect(client.connection.ddp).toEventually(beTrue(), timeout:5)
                expect(client.connection.session).toEventually(equal(testSession), timeout:5)
            }
        }
        
        // DDP Methods
        // tests login:, logout:, insert:, remove:, update:
        describe ("DDP Methods") {
            
            it ("can login to a Meteor server") {
                
                // On connect, the client should set the client.connection.session property
                // After logging in with a username and password, the client should receive a result
                // object that the session token
                
                var testResult:NSDictionary!
                var testSession:String!
                
                let client = DDP.Client()
                client.connect(url) { session in
                    testSession = session
                    client.loginWithPassword(user, password: pass) { result, e in
                        testResult = result! as! NSDictionary
                    }
                }
                
                // Both of these should be non nil; the callbacks should assign them their respective values
                expect(testResult).toEventuallyNot(beNil(), timeout:5)
                expect(testSession).toEventuallyNot(beNil(), timeout:5)
                
                let userDefaultsToken = client.userData.objectForKey("token") as! String
                let resultToken = testResult["token"] as! String
                
                expect(userDefaultsToken).toEventually(equal(resultToken), timeout:5)
                expect(testSession).toEventually(equal(client.connection.session), timeout:5)
            }
            
            it ("can add and remove a document on the server"){
                var added = [NSDictionary]()
                var removed = [String]()
                let client = DDP.Client()
                let _id = client.getId()
                
                client.events.onAdded = { collection, id, fields in if ((collection == "test-collection2") && (_id == id)) { added.append(fields!) } }
                client.events.onRemoved = { collection, id in removed.append(id) }
                
                client.connect(url) { session in
                    print("Connected to DDP server!!! \(session)")
                    client.loginWithPassword(user, password: pass) { result, e in
                        print("Login data: \(result), \(e)")
                        client.sub("test-collection2", params:nil)
                        client.insert("test-collection2", document: NSArray(arrayLiteral:["_id":_id, "foo":"bar"]))
                    }
                }
                
                
                // the tuple that holds the subscription data in the client should be updated to reflect that the
                // subscription is ready
                expect(client.findSubscription("test-collection2")?.ready).toEventually(beTrue(), timeout:5)
                
                // test that the data is returned from the server
                expect(added.count).toEventually(equal(1), timeout:5)
                expect(added[0]["foo"] as? String).toEventually(equal("bar"), timeout:5)
                
                // test that the data is removed from the server (can also me checked on the server)
                client.remove("test-collection2", document:NSArray(arrayLiteral:["_id":_id]))
                expect(removed.count).toEventually(equal(1), timeout:5)
                // expect(removed[0]).toEventually(equal("100"), timeout:5)
            }
            
            it ("can update a document in a collection") {
                var added = [NSDictionary]()
                var updated = [NSDictionary]()
                let client = DDP.Client()
                
                let _id = client.getId()
                
                client.events.onAdded = { collection, id, fields in
                    if ((collection == "test-collection2") && (_id == id)) {
                        added.append(fields!)
                    }
                }
                
                client.events.onChanged = { collection, id, fields, cleared in
                    if ((collection == "test-collection2") && (_id == id)) {
                        updated.append(fields!)
                    }
                }
               
                
                client.connect(url) { session in
                    print("Connected to DDP server!!! \(session)")
                    client.loginWithPassword(user, password: pass) { result, e in
                        print("Login data: \(result), \(e)")
                        client.sub("test-collection2", params:nil)
                        client.insert("test-collection2", document: NSArray(arrayLiteral:["_id":_id, "foo":"bar"]))
                    }
                }
                
                expect(added.count).toEventually(equal(1), timeout:10)
                var params = NSMutableDictionary()
                params = ["$set":["foo":"baz"]]
                client.update("test-collection2", document: [["_id":_id], params]) { result, error in }
                expect(updated.count).toEventually(equal(1))
                client.remove("test-collection2", document: [["_id":_id]])
            }
            
            it ("can execute a method on the server that returns a value") {
                var response:String!
                let client = DDP.Client()
                
                client.connect(url) { session in
                    client.loginWithPassword(user, password: pass) { result, error in
                        client.method("test", params: nil) { result, error in
                            let r = result as! String
                            response = r
                        }
                    }
                }
                
                expect(response).toEventually(equal("test123"), timeout:5)
            }
        }
        
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
                let client = DDP.Client()
                client.connect(url) {session in
                    client.loginWithPassword(user, password: pass) {result, error in
                        client.events.onAdded = {collection, id, fields in added.append(id) }
                        client.events.onRemoved = {collection, id in removed.append(id) }
                        client.sub("AllStates", params:nil)
                    }
                }
                
                // The client should receive an ready message. When this message is received
                // the added array should contain all of the data items in the subscription (in this case 3 items)
                expect(client.findSubscription("AllStates")?.ready).toEventually(beTrue(), timeout:5)
                expect(added.count).toEventually(equal(3), timeout:5)
                
                client.unsub(withName: "AllStates")
                
                // After receiving a nosub message, the subscription entry in collections should have been removed
                // the removed array should contain a list of all of the items in the subscription
                expect(client.findSubscription("AllStates")).toEventually(beNil(), timeout:5)
                expect(removed.count).toEventually(equal(3), timeout:5)
                
            }
        }
    }
}
