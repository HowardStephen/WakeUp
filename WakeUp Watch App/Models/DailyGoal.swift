import Foundation

struct DailyGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var weekday: Int // 1...7 (Calendar.current.weekday)
    var durationMinutes: Int

    init(id: UUID = UUID(), weekday: Int, durationMinutes: Int) {
        self.id = id
        self.weekday = weekday
        self.durationMinutes = durationMinutes
    }
}
