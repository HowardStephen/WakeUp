import Foundation
import CoreData

final class StorageCore {
    static let shared = StorageCore()

    private let context: NSManagedObjectContext

    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - SleepSession CRUD using a simple Core Data entity `CDSleepSession`
    func fetchSessions() -> [SleepSession] {
        let req: NSFetchRequest<CDSleepSession> = CDSleepSession.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        do {
            let cds = try context.fetch(req)
            return cds.compactMap { $0.toSleepSession() }
        } catch {
            print("fetchSessions error: \(error)")
            return []
        }
    }

    func saveSession(_ session: SleepSession) {
        let req: NSFetchRequest<CDSleepSession> = CDSleepSession.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        do {
            let results = try context.fetch(req)
            let cd: CDSleepSession
            if let existing = results.first {
                cd = existing
            } else {
                cd = CDSleepSession(context: context)
                cd.id = session.id
            }
            cd.startDate = session.startDate
            cd.endDate = session.endDate
            cd.source = session.source
            cd.notificationSent = session.notificationSent
            cd.healthKitUUID = session.healthKitUUID
            try context.save()
        } catch {
            print("saveSession error: \(error)")
        }
    }

    func deleteSession(id: UUID) {
        let req: NSFetchRequest<CDSleepSession> = CDSleepSession.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let results = try context.fetch(req)
            for obj in results { context.delete(obj) }
            try context.save()
        } catch {
            print("deleteSession error: \(error)")
        }
    }

    // MARK: - Goals CRUD using `CDDailyGoal`
    func fetchGoals() -> [DailyGoal] {
        let req: NSFetchRequest<CDDailyGoal> = CDDailyGoal.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "weekday", ascending: true)]
        do {
            let cds = try context.fetch(req)
            return cds.compactMap { $0.toDailyGoal() }
        } catch {
            print("fetchGoals error: \(error)")
            return defaultGoals()
        }
    }

    func saveGoals(_ goals: [DailyGoal]) {
        // naive: delete existing and recreate
        let req: NSFetchRequest<CDDailyGoal> = CDDailyGoal.fetchRequest()
        do {
            let existing = try context.fetch(req)
            for obj in existing { context.delete(obj) }
            for g in goals {
                let cd = CDDailyGoal(context: context)
                cd.id = g.id
                cd.weekday = Int16(g.weekday)
                cd.durationMinutes = Int32(g.durationMinutes)
            }
            try context.save()
        } catch {
            print("saveGoals error: \(error)")
        }
    }

    private func defaultGoals() -> [DailyGoal] {
        var list: [DailyGoal] = []
        for i in 1...7 {
            list.append(DailyGoal(weekday: i, durationMinutes: 7 * 60))
        }
        return list
    }
}

// MARK: - Core Data helper extensions

// Note: The CDSleepSession and CDDailyGoal Core Data entities must be created in the model.

extension CDSleepSession {
    func toSleepSession() -> SleepSession? {
        guard let id = id, let start = startDate else { return nil }
        return SleepSession(id: id, startDate: start, endDate: endDate, source: source ?? "", notificationSent: notificationSent, healthKitUUID: healthKitUUID)
    }
}

extension CDDailyGoal {
    func toDailyGoal() -> DailyGoal? {
        guard let id = id else { return nil }
        return DailyGoal(id: id, weekday: Int(weekday), durationMinutes: Int(durationMinutes))
    }
}
