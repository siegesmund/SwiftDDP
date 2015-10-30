
import Foundation

public class MeteorCoreData {
    static let stack:MeteorCoreDataCollectionStack = {
        print("Initializing MeteorCoreDataStack")
        return MeteorCoreDataStackPersisted()
        }()
}