import SwiftUI

struct GlassSlider: View {
    @Binding var value: Double
    let icon: String
    var label: String?
    var range: ClosedRange<Double> = 0...1

    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            HStack {
                if let label = label {
                    Text(label)
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(LuminaTheme.neonPurple)
                Text("\(Int(value * 100))%")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.full)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.full)
                        .fill(LuminaTheme.primaryGradient)
                        .frame(width: geometry.size.width * value)

                    Circle()
                        .fill(.white)
                        .frame(width: isDragging ? 24 : 20, height: isDragging ? 24 : 20)
                        .shadow(color: LuminaTheme.neonPurple.opacity(0.6), radius: isDragging ? 10 : 6)
                        .offset(x: geometry.size.width * value - (isDragging ? 12 : 10))
                        .animation(.spring(response: 0.3), value: isDragging)
                }
                .frame(height: 8)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                HapticManager.shared.selection()
                            }
                            let newValue = min(max(gesture.location.x / geometry.size.width, 0), 1)
                            value = newValue
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)
        }
    }
}
