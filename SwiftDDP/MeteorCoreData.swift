
import Foundation

class MeteorCoreData {
    static let stack:MeteorCoreDataStack = {
        print("Initializing MeteorCoreDataStack")
        return MeteorCoreDataStack()
        }()
}