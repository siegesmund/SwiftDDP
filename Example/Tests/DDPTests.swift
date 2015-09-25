import Quick
import Nimble
@testable import SwiftDDP

// Requires connection to DDP Server
class DDPConnectionTest:QuickSpec {
    override func spec() {
        describe ("DDP Connection") {
            
            var client:DDP.Client!
            
            beforeEach() {
                client = DDP.Client(url:url)
                client.userData.removeObjectForKey("id")
                client.userData.removeObjectForKey("token")
                client.userData.removeObjectForKey("tokenExpires")
            }
            
            it ("can connect to a DDP server"){
                var connected = false
                client.connect() {result, error in
                    guard let e = error else {
                        connected = true
                        return
                    }
                    print(e)
                }
                expect(client.connected).toEventually(beTrue())
                expect(connected).toEventually(beTrue())
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
        }
    }
}

class DDPMessageHandlerTest:QuickSpec {
    override func spec() {
        describe ("DDPMessageHandler routing") {
            
            // Will try to make a websocket connection, but not a DDP connection
            let client = DDP.Client(url: url)

            
            it ("can handle an 'added' message"){
                
                client.events.onAdded = {collection, id, fields in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                    let city = fields!["city"]! as! String
                    expect(city).to(equal("Boston"))
                }
                client.ddpMessageHandler(added[0])
            }
            
            it ("can handle a 'removed' message") {
                client.events.onRemoved = {collection, id in
                    expect(collection).to(equal("test-collection"))
                    expect(id).to(equal("2gAMzqvE8K8kBWK8F"))
                }
                client.ddpMessageHandler(removed[0])
            }
            
            it ("can handle a 'ready' message") {
                client.events.onReady = {subs in
                    let s = subs[0] as! String
                    expect(s).to(equal("AllStates"))
                }
                client.ddpMessageHandler(nosub)
            }
        }
    }
}

// Requires connection to DDP Server
class DDPPubSubTest:QuickSpec {
    override func spec() {
        describe("DDP PubSub") {
            let client = DDP.Client(url: url)
            
            it ("can subscribe and unsubscribe to a collection") {
                var added = [String]()
                var removed = [String]()
                
                client.connect() {result, error in
                client.loginWithPassword(user, password: pass) {result, error in
                    client.events.onAdded = {collection, id, fields in added.append(id) }
                    client.events.onRemoved = {collection, id in removed.append(id) }
                    client.sub("AllStates", params:nil)
                    }
                }
                expect(added.count).toEventually(equal(3))
                
                client.unsub("AllStates")
                expect(removed.count).toEventually(equal(3))
            }
            
        }
    }
}

// Requires connection to DDP Server
class DDPMethodTest:QuickSpec {
    override func spec() {
        describe ("DDP Methods") {
            
            // Will try to make a websocket connection, but not a DDP connection
            let client = DDP.Client(url: url)
            
            it ("can login to a Meteor server") {
                client.connect() {result, error in
                    client.loginWithPassword(user, password: pass) {result, error in
                        expect(result).to(beTruthy())
                    }
                }
            }
            
            
            it ("can add and remove a document on the server"){
                var added = [NSMutableDictionary]()
                var removed = [String]()
                var ready = false
                
                client.events.onReady = {subs in
                    let sub = subs[0] as! String
                    if (sub == client.subscriptions["test-collection2"]!) {
                        ready = true
                    }
                }
                
                
                client.events.onNosub = {id, error in
                    let subname = client.subscriptions[id]!
                    print("NOSUB \(subname) \(error)")
                }
                
                client.events.onAdded = {collection, id, fields in
                    if let doc = fields {
                        let docCopy = doc.mutableCopy() as! NSMutableDictionary
                        docCopy["_id"] = id;
                        added.append(docCopy)
                    }
                }
                
                client.events.onRemoved = {collection, id in
                    removed.append(id)
                }
                
                client.sub("test-collection2", params:nil)
                client.insert("test-collection2", doc: NSArray(arrayLiteral:["_id":"100", "foo":"bar"]))
                
                expect(ready).toEventually(beTrue())
                expect(added.count).toEventually(equal(1))
                expect(added[0]["_id"] as? String).to(equal("100"))
                
                client.remove("test-collection2", doc:NSArray(arrayLiteral:["_id":"100"]))
                expect(removed.count).toEventually(equal(1))
                expect(removed[0]).to(equal("100"))
            }
            
            it ("can update a document in a collection") {
                
            }
        }
    }
}
