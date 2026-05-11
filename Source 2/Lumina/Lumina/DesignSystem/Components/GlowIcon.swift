import SwiftUI

struct GlowIcon: View {
    let systemName: String
    var color: Color
    var size: CGFloat
    var glowRadius: CGFloat

    init(systemName: String, color: Color = LuminaTheme.neonPurple, size: CGFloat = 24, glowRadius: CGFloat = 8) {
        self.systemName = systemName
        self.color = color
        self.size = size
        self.glowRadius = glowRadius
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: glowRadius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: glowRadius * 2, x: 0, y: 0)
    }
}

struct AnimatedGlowIcon: View {
    let systemName: String
    var color: Color
    var size: CGFloat

    @State private var isAnimating = false

    var body: some View {
        GlowIcon(systemName: systemName, color: color, size: size, glowRadius: isAnimating ? 16 : 6)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

struct PulsingDot: View {
    var color: Color
    var size: CGFloat

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: isPulsing)
        .onAppear { isPulsing = true }
    }
}
