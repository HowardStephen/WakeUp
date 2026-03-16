import SwiftUI

private func shortWeekdayName(for weekday: Int) -> String {
    let df = DateFormatter()
    df.locale = Locale.current
    let symbols = df.shortWeekdaySymbols ?? []
    guard !symbols.isEmpty else {
        // fallback to English short names
        let fallback = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let idx = (weekday - 1 + fallback.count) % fallback.count
        return fallback[idx]
    }
    let index = (weekday - 1 + symbols.count) % symbols.count
    return symbols[index]
}

struct WeeklyGoalsView: View {
    @EnvironmentObject var sleepVM: SleepViewModel

    var body: some View {
        List {
            ForEach(Array(1...7), id: \.self) { day in
                HStack {
                    Text(shortWeekdayName(for: day))
                    Spacer()
                    let minutes = sleepVM.goals.first(where: { $0.weekday == day })?.durationMinutes ?? 7*60
                    NavigationLink(destination: GoalEditorView(weekday: day, initialMinutes: minutes)) {
                        Text("\(minutes/60) 小时")
                    }
                }
            }
        }
        .navigationTitle("每周目标")
    }
}

struct GoalEditorView: View {
    @EnvironmentObject var sleepVM: SleepViewModel
    @Environment(\.dismiss) var dismiss
    let weekday: Int
    @State var minutes: Int

    init(weekday: Int, initialMinutes: Int) {
        self.weekday = weekday
        _minutes = State(initialValue: initialMinutes)
    }

    var body: some View {
        Form {
            Stepper(value: $minutes, in: 4*60...12*60, step: 30) {
                Text("目标: \(minutes/60) 小时 \(minutes%60) 分钟")
            }
            Button("保存") {
                sleepVM.updateGoal(weekday: weekday, minutes: minutes)
                dismiss()
            }
        }
        .navigationTitle(shortWeekdayName(for: weekday))
    }
}

#Preview {
    WeeklyGoalsView()
        .environmentObject(SleepViewModel.previewInstance())
}
