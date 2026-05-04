import SwiftUI

struct NeonButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case destructive

        var gradient: LinearGradient {
            switch self {
            case .primary: return LuminaTheme.primaryGradient
            case .secondary: return LuminaTheme.accentGradient
            case .destructive: return LinearGradient(colors: [LuminaTheme.neonRed, Color(hex: "DC2626")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        var textColor: Color { .white }
    }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: LuminaTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(LuminaTheme.Typography.headline)
            }
            .foregroundColor(style.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LuminaTheme.Spacing.md)
            .padding(.horizontal, LuminaTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg)
                    .fill(style.gradient)
            )
            .shadow(color: style.gradient.colors.first?.opacity(0.5) ?? .clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: LuminaTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(LuminaTheme.Typography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LuminaTheme.Spacing.md)
            .padding(.horizontal, LuminaTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.lg)
                            .stroke(LuminaTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
