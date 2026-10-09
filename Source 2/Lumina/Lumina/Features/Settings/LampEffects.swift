import SwiftUI

enum LampEffects {
    static let breathHexKey = "luminaBreathHex"
    static let breathMinKey = "luminaBreathMin"
    static let breathMaxKey = "luminaBreathMax"
    static let flowHexKey = "luminaFlowHexes"
    static let flowBrightnessKey = "luminaFlowBrightness"

    static var breathHex: String {
        get { UserDefaults.standard.string(forKey: breathHexKey) ?? "7C3AED" }
        set { UserDefaults.standard.set(newValue, forKey: breathHexKey) }
    }

    static var breathMinimum: Double {
        get {
            let stored = UserDefaults.standard.object(forKey: breathMinKey) as? Double
            return stored ?? 0.16
        }
        set { UserDefaults.standard.set(newValue, forKey: breathMinKey) }
    }

    static var breathMaximum: Double {
        get {
            let stored = UserDefaults.standard.object(forKey: breathMaxKey) as? Double
            return stored ?? 1
        }
        set { UserDefaults.standard.set(newValue, forKey: breathMaxKey) }
    }

    static var breathColor: Color { Color(hex: breathHex) }

    static var flowHexes: [String] {
        get {
            let raw = UserDefaults.standard.string(forKey: flowHexKey) ?? "7C3AED,06B6D4,EC4899,F59E0B,3B82F6"
            let parts = raw.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
            return parts.isEmpty ? ["7C3AED", "06B6D4"] : Array(parts.prefix(5))
        }
        set { UserDefaults.standard.set(newValue.prefix(5).joined(separator: ","), forKey: flowHexKey) }
    }

    static var flowColors: [Color] { flowHexes.map { Color(hex: $0) } }

    static var flowBrightness: Double {
        get {
            let stored = UserDefaults.standard.object(forKey: flowBrightnessKey) as? Double
            return stored ?? 1
        }
        set { UserDefaults.standard.set(newValue, forKey: flowBrightnessKey) }
    }

    static func saveBreath(color: Color, minimum: Double, maximum: Double) {
        let low = min(minimum, maximum - 0.05)
        breathHex = color.hexString
        breathMinimum = max(0, low)
        breathMaximum = min(1, max(maximum, low + 0.05))
    }

    static func saveFlow(colors: [Color], brightness: Double) {
        let chosen = colors.isEmpty ? [Color(hex: "7C3AED"), Color(hex: "06B6D4")] : Array(colors.prefix(5))
        flowHexes = chosen.map(\.hexString)
        flowBrightness = min(1, max(0.05, brightness))
    }

    static func breathCommand() -> LampCommand {
        let parts = breathColor.components
        return .runBreath(
            red: parts.red,
            green: parts.green,
            blue: parts.blue,
            minimum: byte(breathMinimum),
            maximum: byte(breathMaximum)
        )
    }

    static func flowCommand() -> LampCommand {
        let colors = flowColors.map { color in
            let parts = color.components
            return LampColor(red: parts.red, green: parts.green, blue: parts.blue)
        }
        return .runFlow(colors: colors, brightness: byte(flowBrightness))
    }

    private static func byte(_ value: Double) -> UInt8 {
        UInt8(min(255, max(0, Int((value * 255).rounded()))))
    }
}
