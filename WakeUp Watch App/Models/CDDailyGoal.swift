import Foundation
import CoreData

@objc(CDDailyGoal)
public class CDDailyGoal: NSManagedObject {
}

extension CDDailyGoal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyGoal> {
        return NSFetchRequest<CDDailyGoal>(entityName: "CDDailyGoal")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var weekday: Int16
    @NSManaged public var durationMinutes: Int32
}
