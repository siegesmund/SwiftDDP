
import Foundation
import SwiftDDP

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



let addedRealm = [DDP.Message(message: "{\"collection\" : \"Cities\", \"id\" : \"2gAMzqvE8K8kBWK8F\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Boston\"}, \"msg\" : \"added\"}"),
    DDP.Message(message:"{\"collection\" : \"Cities\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Truro\"}, \"msg\" : \"added\"}"),
    DDP.Message(message:"{\"collection\" : \"Cities\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Austin\"}, \"msg\" : \"added\"}")]

let removedRealm = [DDP.Message(message: ["msg" : "removed", "id" : "2gAMzqvE8K8kBWK8F","collection" : "Cities"]),
    DDP.Message(message: ["msg" : "removed", "id" : "ByuwhKPGuLru8h4TT", "collection" : "Cities"]),
    DDP.Message(message:["msg" : "removed", "id" : "AGX6vyxCJtjqdxbFH", "collection" : "Cities"])]


let changedRealm = [DDP.Message(message: "{\"collection\" : \"Cities\", \"id\" : \"2gAMzqvE8K8kBWK8F\",\"cleared\" : [\"city\"], \"fields\" : {\"state\" : \"MA\", \"city\" : \"Amherst\"}, \"msg\" : \"changed\"}"),
    DDP.Message(message:"{\"collection\" : \"Cities\", \"id\" : \"ByuwhKPGuLru8h4TT\", \"fields\" : {\"state\" : \"MA\", \"city\" : \"Cambridge\"}, \"msg\" : \"changed\"}"),
    DDP.Message(message:"{\"collection\" : \"Cities\", \"id\" : \"AGX6vyxCJtjqdxbFH\", \"fields\" : {\"state\" : \"TX\", \"city\" : \"Houston\"}, \"msg\" : \"changed\"}")]


