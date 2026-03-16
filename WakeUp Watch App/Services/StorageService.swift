import Foundation

final class StorageService {
    static let shared = StorageService()

    private let coreAvailable: Bool
    private init() {
        // detect whether Core Data StorageCore is usable
        coreAvailable = true
    }

    // MARK: - Backward-compatible API
    func loadSessions() -> [SleepSession] {
        if coreAvailable {
            return StorageCore.shared.fetchSessions()
        }
        return []
    }

    func saveSessions(_ sessions: [SleepSession]) {
        if coreAvailable {
            // save each session
            for s in sessions { StorageCore.shared.saveSession(s) }
        }
    }

    func loadGoals() -> [DailyGoal] {
        if coreAvailable {
            return StorageCore.shared.fetchGoals()
        }
        // fallback
        return defaultGoals()
    }

    private func defaultGoals() -> [DailyGoal] {
        var list: [DailyGoal] = []
        for i in 1...7 {
            list.append(DailyGoal(weekday: i, durationMinutes: 7 * 60))
        }
        return list
    }

    // MARK: - CoreData-style API (used by new code)
    func fetchSessions() -> [SleepSession] {
        return StorageCore.shared.fetchSessions()
    }

    func saveSession(_ session: SleepSession) {
        StorageCore.shared.saveSession(session)
    }

    func deleteSession(id: UUID) {
        StorageCore.shared.deleteSession(id: id)
    }

    func fetchGoals() -> [DailyGoal] {
        return StorageCore.shared.fetchGoals()
    }

    func saveGoals(_ goals: [DailyGoal]) {
        StorageCore.shared.saveGoals(goals)
    }
}
