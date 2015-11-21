
import Foundation
@testable import SwiftDDP

//
//
//  Test Data
//
//

class Document: MeteorDocument {
    
    var state:String?
    var city:String?
    
}

//  *** methods that are tested against a server are tested against the url below ***

let url = "ws://swiftddp.meteor.com/websocket"
// let url = "ws://localhost:3000/websocket"
let user = "test@user.com"
let pass = "swiftddp"

let ready = DDPMessage(message: "{\"msg\":\"ready\", \"subs\":[\"AllStates\"]}")
let nosub = DDPMessage(message: ["msg":"nosub", "id":"AllStates"])

let added = [DDPMessage(message: "{\"collection\" : \"test-collection\", \"id\" : \"2gAMzqvE8K8kBWK8F\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Boston\"}, \"msg\" : \"added\"}"),
    DDPMessage(message:"{\"collection\" : \"test-collection\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Truro\"}, \"msg\" : \"added\"}"),
    DDPMessage(message:"{\"collection\" : \"test-collection\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Austin\"}, \"msg\" : \"added\"}")]

let removed = [DDPMessage(message: ["msg" : "removed", "id" : "2gAMzqvE8K8kBWK8F","collection" : "test-collection"]),
    DDPMessage(message: ["msg" : "removed", "id" : "ByuwhKPGuLru8h4TT", "collection" : "test-collection"]),
    DDPMessage(message:["msg" : "removed", "id" : "AGX6vyxCJtjqdxbFH", "collection" : "test-collection"])]

let changed = [DDPMessage(message: "{\"collection\" : \"test-collection\", \"id\" : \"2gAMzqvE8K8kBWK8F\",\"cleared\" : [\"city\"], \"fields\" : {\"state\" : \"MA\", \"city\" : \"Amherst\"}, \"msg\" : \"changed\"}"),
    DDPMessage(message:"{\"collection\" : \"test-collection\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Cambridge\"}, \"msg\" : \"changed\"}"),
    DDPMessage(message:"{\"collection\" : \"test-collection\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Houston\"}, \"msg\" : \"changed\"}")]

let userAddedWithPassword = DDPMessage(message: "{\"collection\" : \"users\", \"id\" : \"123456abcdefg\", \"fields\" : {\"roles\" : [\"admin\"], \"emails\" : [{\"address\" : \"test@user.com\", \"verified\" : false}], \"username\" : \"test\"}, \"msg\" : \"added\"}")



let addedRealm = [DDPMessage(message: "{\"collection\" : \"Cities\", \"id\" : \"2gAMzqvE8K8kBWK8F\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Boston\"}, \"msg\" : \"added\"}"),
    DDPMessage(message:"{\"collection\" : \"Cities\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Truro\"}, \"msg\" : \"added\"}"),
    DDPMessage(message:"{\"collection\" : \"Cities\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Austin\"}, \"msg\" : \"added\"}")]

let removedRealm = [DDPMessage(message: ["msg" : "removed", "id" : "2gAMzqvE8K8kBWK8F","collection" : "Cities"]),
    DDPMessage(message: ["msg" : "removed", "id" : "ByuwhKPGuLru8h4TT", "collection" : "Cities"]),
    DDPMessage(message:["msg" : "removed", "id" : "AGX6vyxCJtjqdxbFH", "collection" : "Cities"])]


let changedRealm = [DDPMessage(message: "{\"collection\" : \"Cities\", \"id\" : \"2gAMzqvE8K8kBWK8F\",\"cleared\" : [\"city\"], \"fields\" : {\"state\" : \"MA\", \"city\" : \"Amherst\"}, \"msg\" : \"changed\"}"),
    DDPMessage(message:"{\"collection\" : \"Cities\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Cambridge\"}, \"msg\" : \"changed\"}"),
    DDPMessage(message:"{\"collection\" : \"Cities\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Houston\"}, \"msg\" : \"changed\"}")]


