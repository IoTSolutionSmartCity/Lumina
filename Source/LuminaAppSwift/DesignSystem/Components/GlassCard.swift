import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(LuminaTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xl)
                            .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = LuminaTheme.CornerRadius.xl) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func neonGlow(color: Color = LuminaTheme.neonPurple, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}
