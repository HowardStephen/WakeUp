import Foundation
import CoreData

@objc(CDSleepSession)
public class CDSleepSession: NSManagedObject {
}

extension CDSleepSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSleepSession> {
        return NSFetchRequest<CDSleepSession>(entityName: "CDSleepSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var source: String?
    @NSManaged public var notificationSent: Bool
    @NSManaged public var healthKitUUID: String?
}
