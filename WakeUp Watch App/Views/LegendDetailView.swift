import SwiftUI

struct LegendDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("睡眠颜色图例")
                .font(.headline)
            HStack(spacing: 10) {
                LegendItem(color: Color.green.opacity(0.28), text: "0-25%")
                LegendItem(color: Color.green.opacity(0.48), text: "25-50%")
                LegendItem(color: Color.green.opacity(0.72), text: "50-75%")
            }
            Text("颜色越深表示睡眠时间越接近期望目标。点击格子查看当日详细记录。")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    LegendDetailView()
}
