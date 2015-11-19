// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import SwiftDDP

class MeteorTest: QuickSpec {
    override func spec() {
        
        let client = Meteor.client
        let collection = MeteorCollection<Document>(name: "test-collection")
        
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
                
                try! client.ddpMessageHandler(added[0])
                
                print("Collection -> \(collection.documents)")
                
                expect(collection.documents["2gAMzqvE8K8kBWK8F"]).toEventuallyNot(beNil())
                expect(collection.documents["2gAMzqvE8K8kBWK8F"]?.city).toEventually(equal("Boston"))
            }
            
            it("sends a message when a document is removed") {
                
                try! client.ddpMessageHandler(added[1])
                expect(collection.documents["ByuwhKPGuLru8h4TT"]).toEventuallyNot(beNil())
                expect(collection.documents["ByuwhKPGuLru8h4TT"]!.city).toEventually(equal("Truro"))
                
                try! client.ddpMessageHandler(removed[1])
                expect(collection.documents["ByuwhKPGuLru8h4TT"]).toEventually(beNil())
            }
            
        
            it("sends a message when a document is updated") {
                
                try! client.ddpMessageHandler(added[2])
                expect(collection.documents["AGX6vyxCJtjqdxbFH"]).toEventuallyNot(beNil())
                expect(collection.documents["AGX6vyxCJtjqdxbFH"]!.city).toEventually(equal("Austin"))
                
                try! client.ddpMessageHandler(changed[2])
                expect(collection.documents["AGX6vyxCJtjqdxbFH"]!.city).toEventually(equal("Houston"))

            }
        
        }
    }
}