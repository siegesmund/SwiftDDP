
import Foundation
import SwiftDDP

class List: MeteorDocument {
    
    var collection:String = "lists"
    var incompleteCount:Int = 0
    var name:String?
    var userId:String?
    
}