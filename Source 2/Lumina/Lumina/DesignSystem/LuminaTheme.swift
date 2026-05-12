import SwiftUI

struct LuminaTheme {
    // MARK: - Primary Colors
    static let neonPurple = Color(hex: "7C3AED")
    static let neonPurpleLight = Color(hex: "A855F7")
    static let neonCyan = Color(hex: "06B6D4")
    static let neonPink = Color(hex: "EC4899")
    static let neonGreen = Color(hex: "10B981")
    static let neonOrange = Color(hex: "F59E0B")
    static let neonRed = Color(hex: "EF4444")

    static let deepNavy = Color(hex: "0F0F23")
    static let darkSurface = Color(hex: "1A1A2E")
    static let darkCard = Color(hex: "16213E")
    static let glassBackground = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)

    // MARK: - Typography
    struct Typography {
        static let display = Font.system(size: 34, weight: .bold, design: .default)
        static let title = Font.system(size: 22, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)
    }

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [neonPurple, neonPurpleLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [neonCyan, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [neonOrange, neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let backgroundGradient = LinearGradient(
        colors: [deepNavy, Color(hex: "050510")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows
    static let neonGlow = Color(hex: "7C3AED").opacity(0.4)
    static let cyanGlow = Color(hex: "06B6D4").opacity(0.3)

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let full: CGFloat = 9999
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    var components: (red: UInt8, green: UInt8, blue: UInt8) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
    }

    var hexString: String {
        let components = self.components
        return String(format: "%02X%02X%02X", components.red, components.green, components.blue)
    }

    var hsbaComponents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b, a)
    }
}
