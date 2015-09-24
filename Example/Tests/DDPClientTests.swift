import Quick
import Nimble
import SwiftDDP

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
                    let s = subs[0]! as! String
                    expect(s).to(equal("AllStates"))
                }
                client.ddpMessageHandler(nosub)
            }
        }
    }
}