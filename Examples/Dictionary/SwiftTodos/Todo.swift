
import Foundation
import SwiftDDP

class Todo: MeteorDocument {
    
    var collection:String = "todos"
    var listId:String?
    var text:String?
    var checked:Bool = false
    var createdAt:NSDate?
    
}