
import Foundation

public class MeteorCoreData {
    static let stack:MeteorCoreDataStack = {
        print("Initializing MeteorCoreDataStack")
        return MeteorCoreDataStackPersisted()
        }()
}