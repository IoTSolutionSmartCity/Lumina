import SwiftUI

struct GlassSlider: View {
    @Binding var value: Double
    let icon: String
    var label: String?
    var tint: Color = LuminaTheme.neonPurple
    var range: ClosedRange<Double> = 0...1

    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaTheme.Spacing.sm) {
            HStack {
                if let label = label {
                    Text(label)
                        .font(LuminaTheme.Typography.caption)
                        .foregroundColor(LuminaTheme.textSecondary)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(tint)
                Text("\(Int(value * 100))%")
                    .font(LuminaTheme.Typography.captionBold)
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.full)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.full)
                        .fill(tint)
                        .frame(width: geometry.size.width * value, height: 8)
                        .shadow(color: tint.opacity(isDragging ? 0.55 : 0.25), radius: isDragging ? 8 : 4)

                    Circle()
                        .fill(.white)
                        .frame(width: isDragging ? 24 : 20, height: isDragging ? 24 : 20)
                        .shadow(color: tint.opacity(0.6), radius: isDragging ? 10 : 6)
                        .offset(x: geometry.size.width * value - (isDragging ? 12 : 10))
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isDragging)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
            .frame(height: 44)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Slider")
        .accessibilityValue("\(Int(value * 100))%")
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 20
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }
}
