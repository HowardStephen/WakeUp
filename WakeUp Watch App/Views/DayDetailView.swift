import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var sleepVM: SleepViewModel
    let date: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Text(dateTitle())
                .font(.headline)

            List {
                ForEach(sessionsForDate(), id: \.id) { s in
                    VStack(alignment: .leading) {
                        Text(sessionTimeRange(s))
                        HStack {
                            Text("来源: \(s.source)")
                            Spacer()
                            if s.notificationSent { Text("已提醒").foregroundColor(.green) }
                        }
                    }
                    .contextMenu {
                        Button("删除") {
                            sleepVM.deleteSession(id: s.id)
                        }
                        Button("编辑结束时间") {
                            // quick edit: set endTime to now
                            var updated = s
                            updated.endDate = Date()
                            sleepVM.updateSession(updated)
                        }
                    }
                }
            }

            Button("关闭") { dismiss() }
        }
    }

    func sessionsForDate() -> [SleepSession] {
        sleepVM.sessions.filter { session in
            if let end = session.endDate {
                return Calendar.current.isDate(end, inSameDayAs: date) || Calendar.current.isDate(session.startDate, inSameDayAs: date)
            } else {
                return Calendar.current.isDate(session.startDate, inSameDayAs: date)
            }
        }
    }

    func sessionTimeRange(_ s: SleepSession) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        if let end = s.endDate {
            return "\(df.string(from: s.startDate)) - \(df.string(from: end))"
        } else {
            return "\(df.string(from: s.startDate)) - 进行中"
        }
    }

    func dateTitle() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}
