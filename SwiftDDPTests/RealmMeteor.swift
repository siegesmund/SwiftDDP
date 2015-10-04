import Quick
import Nimble
import RealmSwift
@testable import SwiftDDP

public class City: RealmDocument {
    
    dynamic public var collection = "test-collection"
    
    dynamic public var city = ""
    dynamic public var state = ""
    
    public convenience required init(json:NSDictionary) {
        self.init()
        apply(json)
    }
    
    override public func apply(fields:NSDictionary) {
        if let _city = fields["city"] as? String,
               _state = fields["state"] as? String {
                    city = _city
                    state = _state
        }
    }
}

class RealmCollectionTests:QuickSpec {
    override func spec() {
        describe ("RealmCollection") {
            
            let client = Meteor.client
            let collection = RealmCollection<City>(name: "Cities")
            
            beforeSuite() {
                collection.flush()
            }
            
            afterSuite() {
                collection.flush()
            }
            
            it ("It responds to DDP added messages") {
                // Adds a message then tests that it was added to the realm
                try! client.ddpMessageHandler(addedRealm[0])
                let doc = collection.findOne(addedRealm[0].id!)!
                expect(doc._id).to(equal(addedRealm[0].id!))
            }
            
            it ("It responds to DDP removed messages") {
                try! client.ddpMessageHandler(addedRealm[1])
                let doc = collection.findOne(addedRealm[1].id!)!
                expect(doc._id).to(equal(addedRealm[1].id!))
                try! client.ddpMessageHandler(removedRealm[1])
                
                var found = false
                if let _ = collection.findOne(addedRealm[1].id!) { found = true }
                expect(found).to(beFalse())

            }
            
            it ("It responds to DDP removed messages") {
                try! client.ddpMessageHandler(addedRealm[2])
                try! client.ddpMessageHandler(changedRealm[2])
                expect(collection.findOne(changedRealm[2].id!)?.city).toEventually(equal("Houston"))
            }

        }
    }
}
