import Foundation

struct SleepSession: Identifiable, Codable, Equatable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    var source: String
    var notificationSent: Bool
    var healthKitUUID: String?

    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil, source: String = "manual", notificationSent: Bool = false, healthKitUUID: String? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.source = source
        self.notificationSent = notificationSent
        self.healthKitUUID = healthKitUUID
    }

    var durationMinutes: Int {
        guard let end = endDate else { return Int(Date().timeIntervalSince(startDate) / 60) }
        return Int(end.timeIntervalSince(startDate) / 60)
    }
}
