import Foundation
import Combine
import HealthKit

final class SleepViewModel: ObservableObject {
    @Published private(set) var sessions: [SleepSession] = []
    @Published var ongoingSession: SleepSession?
    @Published var goals: [DailyGoal] = []

    private var storage = StorageService.shared

    init() {
        load()
        // Do not start HealthKit subscription when running SwiftUI previews
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if !isPreview {
            subscribeToHealthKit()
        }
    }

    func load() {
        sessions = storage.fetchSessions()
        goals = storage.fetchGoals()
        ongoingSession = sessions.first(where: { $0.endDate == nil })
    }

    func startManualSession() {
        guard ongoingSession == nil else { return }
        let session = SleepSession(startDate: Date())
        ongoingSession = session
        sessions.insert(session, at: 0)
        storage.saveSession(session)
    }

    func endManualSession() {
        guard var session = ongoingSession else { return }
        session.endDate = Date()
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        storage.saveSession(session)
        ongoingSession = nil
    }

    func deleteSession(id: UUID) {
        storage.deleteSession(id: id)
        sessions.removeAll { $0.id == id }
    }

    func updateSession(_ session: SleepSession) {
        // save changes
        storage.saveSession(session)
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        }
    }

    func currentGoalMinutes(for date: Date = Date()) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return goals.first(where: { $0.weekday == weekday })?.durationMinutes ?? 7 * 60
    }

    func updateGoal(weekday: Int, minutes: Int) {
        if let idx = goals.firstIndex(where: { $0.weekday == weekday }) {
            goals[idx].durationMinutes = minutes
        } else {
            goals.append(DailyGoal(weekday: weekday, durationMinutes: minutes))
            goals.sort { $0.weekday < $1.weekday }
        }
        storage.saveGoals(goals)
        objectWillChange.send()
    }

    func saveGoals() {
        storage.saveGoals(goals)
    }

    // MARK: - HealthKit integration
    private func subscribeToHealthKit() {
        HealthKitService.shared.requestAuthorization { [weak self] granted in
            guard granted else { return }
            HealthKitService.shared.startObservingSleep { samples in
                DispatchQueue.main.async {
                    self?.processHealthKitSamples(samples)
                }
            }
        }
    }

    private func processHealthKitSamples(_ samples: [HKCategorySample]) {
        // Map HK samples to SleepSession and merge
        for sample in samples {
            let start = sample.startDate
            let end = sample.endDate
            let value = sample.value // 0=inBed, 1=asleep (HKCategoryValueSleepAnalysis)
            // Only consider asleep entries
            if value == HKCategoryValueSleepAnalysis.asleep.rawValue || value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                // prefer using sample UUID if available
                let hkUUID = sample.uuid.uuidString
                let hs = SleepSession(id: UUID(), startDate: start, endDate: end, source: "healthkit", notificationSent: false, healthKitUUID: hkUUID)

                // Deduplicate by healthKitUUID first
                if let idx = sessions.firstIndex(where: { $0.healthKitUUID == hkUUID && $0.healthKitUUID != nil }) {
                    // merge
                    var merged = sessions[idx]
                    merged.startDate = min(merged.startDate, hs.startDate)
                    if let hsEnd = hs.endDate {
                        if let mEnd = merged.endDate {
                            merged.endDate = max(mEnd, hsEnd)
                        } else {
                            merged.endDate = hsEnd
                        }
                    }
                    merged.source = "healthkit"
                    updateSession(merged)
                    continue
                }

                // Fallback dedupe by time proximity
                if let idx = sessions.firstIndex(where: { existing in
                    if let eEnd = existing.endDate {
                        return abs(existing.startDate.timeIntervalSince(hs.startDate)) < 60 && abs(eEnd.timeIntervalSince(hs.endDate ?? eEnd)) < 60
                    } else {
                        return abs(existing.startDate.timeIntervalSince(hs.startDate)) < 60
                    }
                }) {
                    var merged = sessions[idx]
                    merged.startDate = min(merged.startDate, hs.startDate)
                    if let hsEnd = hs.endDate {
                        if let mEnd = merged.endDate {
                            merged.endDate = max(mEnd, hsEnd)
                        } else {
                            merged.endDate = hsEnd
                        }
                    }
                    merged.healthKitUUID = hkUUID
                    merged.source = "healthkit"
                    updateSession(merged)
                } else {
                    // insert new
                    sessions.insert(hs, at: 0)
                    storage.saveSession(hs)
                }
            }
        }
        // update ongoingSession
        ongoingSession = sessions.first(where: { $0.endDate == nil })
        // check notifications
        checkAndNotifyIfNeeded()
    }

    func checkAndNotifyIfNeeded() {
        guard let session = ongoingSession else { return }
        let duration = session.durationMinutes
        let goal = currentGoalMinutes()
        if duration >= goal && !session.notificationSent {
            NotificationService.shared.scheduleImmediateWakeupNotification(title: "该起床了！", body: "你已睡满 \(goal/60) 小时")
            // mark notification as sent
            var updated = session
            updated.notificationSent = true
            updateSession(updated)
            ongoingSession = updated
        }
    }
}

extension SleepViewModel {
    /// Returns a session that currently contains 'now' (used to show auto-detected sleep state)
    var currentDetectedSession: SleepSession? {
        let now = Date()
        return sessions.first { session in
            let start = session.startDate
            let end = session.endDate ?? now
            return start <= now && end >= now
        }
    }

    /// Create a pre-populated view model for SwiftUI previews
    static func previewInstance() -> SleepViewModel {
        let vm = SleepViewModel()
        // Prevent preview from starting HealthKit subscription (in case environment detection differs)
        // Overwrite sessions/goals with sample data
        vm.goals = (1...7).map { DailyGoal(weekday: $0, durationMinutes: 7 * 60) }
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -3, to: now) ?? now.addingTimeInterval(-3*3600)
        let s = SleepSession(id: UUID(), startDate: start, endDate: nil, source: "healthkit", notificationSent: false)
        vm.sessions = [s]
        vm.ongoingSession = s
        return vm
    }
}
