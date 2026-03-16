import SwiftUI

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 18, height: 12)
            Text(text)
                .font(.caption2)
        }
    }
}

#Preview {
    LegendItem(color: Color.green.opacity(0.5), text: "示例")
}
