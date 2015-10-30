// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import SwiftDDP

class MeteorTest: QuickSpec {
    override func spec() {
        
        let client = Meteor.client
        let collection = MeteorCollection(name: "test-collection")
        
        describe("Collections") {
            /*
            it ("returns a singleton") {
                let collection2 = Meteor.collection("test-collection") as Collection
                let collection3 = Meteor.collection("test-collection2") as Collection
                expect((collection === collection2)).to(beTrue())
                expect((collection2 === collection3)).to(beFalse())
            }
            */
        }
        
        describe("Document methods send notifications") {
            
            it("sends a message when a document is added") {
                var _id:String!
                
                collection.onAdded = {collection, id, fields in
                    if (id == "2gAMzqvE8K8kBWK8F") { _id = id }
                }
                
                try! client.ddpMessageHandler(added[0])
                expect(_id).toEventuallyNot(beNil())
                expect(_id).toEventually(equal("2gAMzqvE8K8kBWK8F"))
            }
            
            it("sends a message when a document is removed") {
                var _id:String!
                
                collection.onRemoved = {collection, id in
                    if (id == "2gAMzqvE8K8kBWK8F") { _id = id }
                }
                
                try! client.ddpMessageHandler(removed[0])
                expect(_id).toEventuallyNot(beNil())
                expect(_id).toEventually(equal("2gAMzqvE8K8kBWK8F"))
            }
            
            it("sends a message when a document is updated") {
                var _id:String!
                
                collection.onChanged = {collection, id, fields, cleared in
                     if (id == "2gAMzqvE8K8kBWK8F") { _id = id }
                }
                
                try! client.ddpMessageHandler(changed[0])
                expect(_id).toEventuallyNot(beNil())
                expect(_id).toEventually(equal("2gAMzqvE8K8kBWK8F"))
            }
        }
    }
}