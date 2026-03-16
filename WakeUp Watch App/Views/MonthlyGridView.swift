import SwiftUI

struct MonthlyGridView: View {
    @EnvironmentObject var sleepVM: SleepViewModel
    @Environment(\.sizeCategory) private var sizeCategory

    @State private var monthOffset = 0
    @State private var showingLegend = false
    // Use an Identifiable wrapper so we can use .sheet(item:)
    struct IdentifiedDate: Identifiable, Equatable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSince1970 }
    }
    @State private var selectedDate: IdentifiedDate? = nil

    private let rows = 6
    private let columns = 7
    private let interItemSpacing: CGFloat = 4

    var body: some View {
        GeometryReader { outerGeo in
            let topInset = outerGeo.safeAreaInsets.top
            let headerTop = max(20, topInset + 8)
            ScrollView(.vertical) {
                VStack(spacing: 8) {
                    // Weekday headers (Mon..Sun or localized)
                    let weekdaySymbols = shortWeekdaySymbols()
                    HStack(spacing: interItemSpacing) {
                        ForEach(weekdaySymbols, id: \.self) { s in
                            Text(s)
                                .font(weekdayFont())
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, horizontalPadding())

                    GeometryReader { geo in
                        let totalSpacing = interItemSpacing * CGFloat(columns - 1)
                        let availableWidth = geo.size.width - horizontalPadding() * 2 - totalSpacing
                        // compute cell size from available width (do not force increase beyond available)
                        let computed = floor(availableWidth / CGFloat(columns))
                        let cellSize = max(4, computed)
                        let gridItems = Array(repeating: GridItem(.fixed(cellSize), spacing: interItemSpacing), count: columns)
                        let dayCells = dayCellsForMonth(offset: monthOffset)

                        LazyVGrid(columns: gridItems, spacing: interItemSpacing) {
                            ForEach(Array(dayCells.enumerated()), id: \.offset) { index, optDate in
                                DayCellView(date: optDate, minutes: minutesForDate(optDate), cellSize: cellSize)
                                    .frame(width: cellSize, height: cellSize)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let d = optDate {
                                            selectedDate = IdentifiedDate(date: d)
                                        }
                                    }
                                    .transition(.opacity)
                            }
                        }
                        .id(monthOffset)
                        .padding(.horizontal, horizontalPadding())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 6)
                        .animation(.easeInOut, value: monthOffset)
                    }
                    // set a flexible height — allow content to grow/scroll when accessibility sizes are large
                    .frame(minHeight: gridMinHeight())

                    // bottom padding kept for safe area
                    Spacer().frame(height: 8)
                }
            }
            .sheet(item: $selectedDate) { identified in
                DayDetailView(date: identified.date)
                    .environmentObject(sleepVM)
            }
            .overlay(
                // Floating legend button bottom-right
                Button(action: { showingLegend = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15)))
                }
                .padding(.trailing, horizontalPadding())
                .padding(.bottom, horizontalPadding()), alignment: .bottomTrailing
            )
            .sheet(isPresented: $showingLegend) {
                LegendDetailView()
            }
        }
        // use system navigation title and toolbar arrows
        .navigationTitle(monthTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { withAnimation { monthOffset -= 1 } }) { Image(systemName: "chevron.left") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { withAnimation { monthOffset += 1 } }) { Image(systemName: "chevron.right") }
            }
        }
    }

    // MARK: - Helpers
    func monthTitle() -> String {
        let cal = Calendar.current
        if let m = cal.date(byAdding: .month, value: monthOffset, to: Date()) {
            let df = DateFormatter()
            df.locale = Locale.current
            df.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: Locale.current) ?? "MMMM yyyy"
            return df.string(from: m)
        }
        return ""
    }

    func horizontalPadding() -> CGFloat {
        // reduce padding for accessibility so the grid can fit
        return sizeCategory.isAccessibilityCategory ? 6 : 12
    }

    func weekdayFont() -> Font {
        return sizeCategory.isAccessibilityCategory ? .caption : .caption2
    }

    func shortWeekdaySymbols() -> [String] {
        let df = DateFormatter()
        df.locale = Locale.current
        // Use veryShortWeekdaySymbols for tighter layout if available
        if let symbols = df.veryShortWeekdaySymbols, !symbols.isEmpty {
            return symbols
        }
        return df.veryShortWeekdaySymbols ?? df.shortWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
    }

    // Return 42 cells (6 rows x 7 cols) as Date? array; nil means placeholder
    func dayCellsForMonth(offset: Int) -> [Date?] {
        let cal = Calendar.current
        guard let base = cal.date(byAdding: .month, value: offset, to: Date()) else { return Array(repeating: nil, count: rows * columns) }
        guard let range = cal.range(of: .day, in: .month, for: base) else { return Array(repeating: nil, count: rows * columns) }

        var comps = cal.dateComponents([.year, .month], from: base)
        comps.day = 1
        guard let firstOfMonth = cal.date(from: comps) else { return Array(repeating: nil, count: rows * columns) }

        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let firstWeekdayIndex = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        var cells: [Date?] = []
        for _ in 0..<firstWeekdayIndex { cells.append(nil) }
        for d in range {
            var c = comps
            c.day = d
            if let date = cal.date(from: c) {
                cells.append(date)
            }
        }
        while cells.count < rows * columns { cells.append(nil) }
        if cells.count > rows * columns { cells = Array(cells.prefix(rows * columns)) }
        return cells
    }

    func minutesForDate(_ date: Date?) -> Int {
        guard let date = date else { return 0 }
        let sessions = sleepVM.sessions.filter { session in
            if let end = session.endDate {
                return Calendar.current.isDate(end, inSameDayAs: date) || Calendar.current.isDate(session.startDate, inSameDayAs: date)
            } else {
                return Calendar.current.isDate(session.startDate, inSameDayAs: date)
            }
        }
        return sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    func gridMinHeight() -> CGFloat {
        // estimate a minimum height for the full grid; allow it to expand on large accessibility sizes
        return sizeCategory.isAccessibilityCategory ? CGFloat(rows) * 30 : CGFloat(rows) * 22
    }

    // Provide a color for a given ratio (0..1)
    func colorForRatio(_ ratio: Double) -> Color {
        switch ratio {
        case ..<0.25: return Color.green.opacity(0.28)
        case 0.25..<0.5: return Color.green.opacity(0.48)
        case 0.5..<0.75: return Color.green.opacity(0.72)
        default: return Color.green.opacity(1.0)
        }
    }
}

// MARK: - DayCellView
private struct DayCellView: View {
    let date: Date?
    let minutes: Int
    let cellSize: CGFloat
    @EnvironmentObject var sleepVM: SleepViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor())
            if let date = date {
                let ratio = ratioFor(date: date)
                VStack(spacing: 2) {
                    HStack {
                        Text(dayNumber(from: date))
                            .font(.system(size: min(12, max(8, cellSize * 0.12))))
                            .foregroundColor(dayTextColor(for: ratio, hasData: minutes > 0))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.leading, 6)
                            .padding(.top, 6)
                        Spacer()
                    }
                    Spacer()
                    if minutes > 0 {
                        Image(systemName: "bed.double.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: cellSize * 0.44, height: cellSize * 0.44)
                            .foregroundColor(iconColor(for: ratio))
                            .padding(.bottom, 4)
                    } else {
                        Color.clear
                            .frame(width: cellSize * 0.08, height: cellSize * 0.08)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
    }

    func dayNumber(from date: Date) -> String { String(Calendar.current.component(.day, from: date)) }

    func ratioFor(date: Date) -> Double {
        guard minutes > 0 else { return 0 }
        let goal = sleepVM.currentGoalMinutes(for: date)
        guard goal > 0 else { return 1.0 }
        return min(1.0, Double(minutes) / Double(goal))
    }

    func dayTextColor(for ratio: Double, hasData: Bool) -> Color {
        if !hasData { return .primary }
        return ratio >= 0.5 ? .white : .primary
    }

    func iconColor(for ratio: Double) -> Color { ratio >= 0.5 ? .white : .green }

    func backgroundColor() -> Color {
        guard let date = date else { return Color.gray.opacity(0.02) }
        guard minutes > 0 else { return Color.gray.opacity(0.06) }
        let goal = sleepVM.currentGoalMinutes(for: date)
        guard goal > 0 else { return Color.green.opacity(0.28) }
        let ratio = Double(minutes) / Double(goal)
        switch ratio {
        case ..<0.25: return Color.green.opacity(0.28)
        case 0.25..<0.5: return Color.green.opacity(0.48)
        case 0.5..<0.75: return Color.green.opacity(0.72)
        default: return Color.green.opacity(1.0)
        }
    }
}
