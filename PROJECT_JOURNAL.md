# Lumina — Project Journal

> **Last Updated:** May 4, 2026
> **Current Phase:** Phase 1 Complete — Ready for Phase 2

---

## Project Overview

Lumina is a cyber-premium iOS companion app for the **Lumina ESP32-S3 Smart Lamp**, built with SwiftUI. The app delivers a glassmorphic dark UI, RealityKit 3D lamp preview, HomeKit integration, and BLE connectivity, following a feature-rich mobile development workflow.

---

## Hardware Reference

| Property | Value |
|---|---|
| Manufacturer | Lumina |
| Model | ESP32S3-N16R8 |
| Serial | LUMINA-S3-001 |
| HomeKit Pairing Code | 46637726 |
| BLE Service UUID | 180A (Device Information) |
| BLE Write Char UUID | 2A58 |
| Advertised BLE Name | "Lumina ESP32S3 Lamp" |
| ESP32 Firmware | HomeSpan |

---

## Completed Phases

### ✅ Phase 1 — Foundation & Architecture

**Phase 1 Status:** Complete as of May 4, 2026

#### 1. Project Scaffold
- [x] `project.yml` — XcodeGen configuration (iOS 17.0+, Swift Package Manager)
- [x] `SmartLampInfo.plist` — All required usage descriptions
- [x] `SmartLamp.entitlements` — HomeKit, WiFi Info, Multicast entitlements
- [x] `Podfile` — CocoaPods setup for Google Sign-In
- [x] `LuminaApp.swift` — App entry point with routing (Onboarding → SignIn → Dashboard)
- [x] `SmartLamp.entitlements` & `SmartLampInfo.plist` aligned and complete

#### 2. Design System — `LuminaTheme.swift`
- [x] 7 neon accent colors (Purple, Cyan, Pink, Green, Orange, Red, PurpleLight)
- [x] Dark background palette (Deep Navy, Dark Surface, Dark Card)
- [x] Glassmorphism colors (8% white fill, 15% glass border)
- [x] Typography scale (display, title, headline, body, caption, etc.)
- [x] 4 gradient presets (primary, accent, warm, card, background)
- [x] Glow shadow constants (neonGlow, cyanGlow)
- [x] Spacing system (xs → xxl)
- [x] Corner radius tokens (sm → full)
- [x] `Color(hex:)` initializer with RGB component extraction

#### 3. Design System — Components
| Component | Status | Notes |
|---|---|---|
| `GlassCard.swift` | ✅ | `glassCard(cornerRadius:)` view modifier + `neonGlow()` |
| `NeonButton.swift` | ✅ | Glass button with neon glow |
| `GlassSlider.swift` | ✅ | Glass-styled brightness slider |
| `ColorWheelPicker.swift` | ✅ | Full color wheel with preview |
| `ConnectionBadge.swift` | ✅ | BLE connection state badge |
| `GlowIcon.swift` | ✅ | SF Symbol with neon glow shadow |
| `ControlCard.swift` | ✅ | Power toggle + brightness + color in glass card |
| `LampPreview3D.swift` | ✅ | RealityKit 3D scene with dynamic PointLight |

#### 4. Core — Models
| Model | Status | Notes |
|---|---|---|
| `LampDevice.swift` | ✅ | Identifiable, with hardware metadata + runtime state |
| `UserProfile.swift` | ✅ | Display name, email, avatar initials |

#### 5. Core — Services
| Service | Status | Notes |
|---|---|---|
| `BluetoothManager.swift` | ✅ | Full BLE Central: scan for `180A`, match "Lumina ESP32S3 Lamp", connect, command queue |
| `HomeKitManager.swift` | ✅ | HMHomeManager + HMAccessorySetupManager for native pairing flow |
| `HapticManager.swift` | ✅ | Light, medium, heavy impact + success/error notifications |

#### 6. Core — Repositories
| Repository | Status | Notes |
|---|---|---|
| `DeviceRepository.swift` | ✅ | Add/update/remove/select `LampDevice`, UserDefaults persistence |

#### 7. Features — Authentication
- [x] `SignInView.swift` — Sign in with Apple + Google placeholder + Skip option
- [x] User profile persistence via `UserDefaults`

#### 8. Features — Onboarding
- [x] `OnboardingView.swift` — BLE scanning UI, device list, connect action
- [x] `OnboardingViewModel.swift` — BluetoothManager integration, connection state
- [x] Pulsing scan animation, Bluetooth disabled warning

#### 9. Features — Dashboard
- [x] `MainDashboardView.swift` — Header, connection status pill, 3D preview, control card, quick scenes
- [x] `DashboardViewModel.swift` — Full state management, scene presets (Focus/Relax/Party/Off), BLE command dispatch
- [x] `LampPreview3D.swift` — RealityKit scene: base, pole, shade, bulb, dynamic PointLight
- [x] `ConnectionBadge.swift` — Animated BLE status indicator

#### 10. Features — Settings
- [x] `SettingsView.swift` — Device list, account section, app info, sign out
- [x] `ProfileView.swift` — Editable display name, email, avatar

---

## Current Architecture

```
Lumina-Swift/
├── App/
│   └── LuminaApp.swift                    # Root: routing + MainTabView
├── Core/
│   ├── Models/
│   │   ├── LampDevice.swift               # Device model + sample
│   │   └── UserProfile.swift              # User profile model
│   ├── Services/
│   │   ├── BluetoothManager.swift         # BLE Central (scan, connect, commands)
│   │   ├── HomeKitManager.swift           # HomeKit pairing + accessory management
│   │   └── HapticManager.swift            # iOS haptic feedback
│   ├── Repositories/
│   │   └── DeviceRepository.swift         # Device CRUD + persistence
│   └── Extensions/
│       └── HapticManager.swift            # (also in Services — same file)
├── Features/
│   ├── Authentication/
│   │   └── SignInView.swift               # Sign in with Apple / Google
│   ├── Dashboard/
│   │   ├── MainDashboardView.swift        # Main lamp control screen
│   │   ├── DashboardViewModel.swift       # Dashboard state + logic
│   │   ├── LampPreview3D.swift             # RealityKit 3D lamp preview
│   │   └── ControlCard.swift              # Power/brightness/color card
│   ├── Onboarding/
│   │   ├── OnboardingView.swift           # Device discovery flow
│   │   └── OnboardingViewModel.swift      # Onboarding state + BLE
│   └── Settings/
│       ├── SettingsView.swift             # App settings
│       └── ProfileView.swift              # User profile editor
└── DesignSystem/
    ├── LuminaTheme.swift                  # Colors, typography, gradients, spacing
    └── Components/
        ├── GlassCard.swift                # Glassmorphism card + modifier
        ├── NeonButton.swift               # Neon-styled button
        ├── GlassSlider.swift              # Brightness slider
        ├── ColorWheelPicker.swift         # Color selection wheel
        ├── ConnectionBadge.swift           # BLE status indicator
        └── GlowIcon.swift                 # SF Symbol with glow

Root/
├── SmartLampInfo.plist                    # Permissions: Bluetooth, HomeKit, LocalNetwork
├── SmartLamp.entitlements                 # HomeKit, WiFi Info, Multicast
├── Podfile                                # Google Sign-In dependency
└── project.yml                            # XcodeGen configuration
```

---

## What's Already Built (Summary)

### The "Brains" — Service Layer ✅
- **`BluetoothManager.swift`** — Configured to scan for `180A` service UUID and match the exact advertised name `"Lumina ESP32S3 Lamp"`. Full BLE state machine, command queue for power/brightness/color, connection timeout handling.
- **`HomeKitManager.swift`** — `HMAccessorySetupManager` integration for the native iOS HomeKit accessory setup flow. Handles pairing completion, accessory addition to home, brightness/color/power updates.

### The Device Model ✅
- **`LampDevice.swift`** — Hardcoded with exact hardware metadata:
  - Manufacturer: `"Lumina"`
  - Model: `"ESP32S3-N16R8"`
  - Serial: `"LUMINA-S3-001"`
  - Pairing Code: `"46637726"`

### Entitlements & Info.plist ✅
- **`SmartLamp.entitlements`** — `com.apple.developer.homekit`, WiFi Info, Multicast
- **`SmartLampInfo.plist`** — `NSBluetoothAlwaysUsageDescription`, `NSHomeKitUsageDescription`, `NSLocalNetworkUsageDescription`, `NSBonjourServices`, `UIBackgroundModes: bluetooth-central`

---

## Next: Phase 2 — Service Layer Integration & Physical Device Build

### 2.1 Bind BluetoothManager into OnboardingViewModel
**Why:** `OnboardingViewModel` creates its own `BluetoothManager()` instance instead of sharing one. On a physical device, each manager competes for BLE control.

```
Action: Extract a shared BluetoothManager instance (singleton or environment object) and inject it into both OnboardingViewModel and DashboardViewModel.
```

### 2.2 Add HomeKit Pairing Button to Onboarding
**Why:** The current onboarding flow scans via BLE but does not trigger the HomeKit `HMAccessorySetupManager` flow. The pairing code `46637726` must be entered during the HomeSpan pairing process.

```
Action: After BLE connection succeeds in OnboardingViewModel, call homeKitManager.triggerNativePairingFlow(). Handle the async result and update isSetupComplete.
```

### 2.3 Bind HomeKitManager into DashboardViewModel
**Why:** `DashboardViewModel` creates its own `HomeKitManager()` instance. BLE and HomeKit should be coordinated — when BLE commands fail, fall back to HomeKit write.

```
Action: Inject a shared HomeKitManager instance. On sendUpdate(), attempt BLE write first, then HomeKit write on failure.
```

### 2.4 Connect LuminaPreview3D to Real Device State
**Why:** The 3D preview currently shows hardcoded colors. On a real device, the lamp color should drive the preview, not the other way around.

```
Action: Add a callback from BluetoothManager/HomeKitManager that pushes actual lamp state (hue, brightness, power) back to the view model. The preview subscribes to this state.
```

### 2.5 Replace `LampPreviewPlaceholder` in Onboarding
**Why:** `OnboardingView` uses `LampPreviewPlaceholder()` as a static fallback. The actual `LampPreview3D` should be used instead.

```
Action: Replace LampPreviewPlaceholder() in OnboardingView with a simplified LampPreview3D or a "discovering" animation variant.
```

### 2.6 Physical Device Build Verification
**Why:** The app targets iOS 17.0+ on a physical device. The following must be verified before running:

| Checklist Item | Status |
|---|---|
| Xcode Development Team set in Signing & Capabilities | ☐ |
| iPhone physical device connected | ☐ |
| ESP32-S3 powered on and advertising BLE | ☐ |
| HomeSpan pairing mode active (hold setup button) | ☐ |
| HomeKit pairing code `46637726` ready | ☐ |
| Pod install completed (`pod install`) | ☐ |
| `SmartLamp.xcworkspace` opened (not `.xcodeproj`) | ☐ |
| `NSBluetoothAlwaysUsageDescription` accepted by user on first launch | ☐ |
| `NSHomeKitUsageDescription` accepted by user | ☐ |

### 2.7 Fix `DashboardViewModel` Combine Bindings
**Why:** `BluetoothManager` uses `@Observable` (iOS 17), but `DashboardViewModel.setupBindings()` uses Combine's `$connectionState` which requires `@Published`. These are incompatible.

```
Action: Remove Combine bindings. Instead, use a custom Binding or polling approach:
  - On each `sendUpdate()`, check `bluetoothManager.connectionState` directly.
  - Use `Task` with `@MainActor` to observe state changes reactively.
  - Alternatively, call bluetoothManager.sendCommand() and await its result for immediate feedback.
```

### 2.8 Complete `DeviceRepository.loadDevices()`
**Why:** `loadDevices()` is a stub that only restores IDs from UserDefaults. Actual device data (brightness, color, isOn) is not persisted.

```
Action: Encode the full LampDevice struct to UserDefaults using Codable. On app launch, restore all device state so the dashboard reflects the last session.
```

### 2.9 Add Color Wheel Real-time Feedback to ESP32
**Why:** Dragging the color wheel fires `onChange` rapidly. Each frame sends a BLE command, which may overwhelm the ESP32 UART buffer.

```
Action: Add a debounce (300ms) in `DashboardViewModel.sendUpdate()`. Use `Timer.publish(every: 0.3, on: .main, in: .common)` to batch rapid color changes into a single command.
```

---

## Phase Roadmap

| Phase | Description | Priority |
|---|---|---|
| **Phase 1** ✅ | Foundation, Design System, Core Models & Services | Complete |
| **Phase 2** | Service Layer Integration + Physical Device Build | **Current** |
| **Phase 3** | Firebase Backend (Auth, Firestore device sync) | Next |
| **Phase 4** | Notifications, Widgets, Shortcuts integration | Future |
| **Phase 5** | Watch App companion | Future |

---

## Known Issues

1. **`DashboardViewModel` Combine vs `@Observable` incompatibility** — `BluetoothManager` is `@Observable`, but bindings use Combine `Publishers`. Fix as described in Phase 2.7 above.

2. **`OnboardingViewModel` creates its own `BluetoothManager`** — Each manager opens its own `CBCentralManager`. Only one should exist. Fix via shared instance or `@Environment`.

3. **`DeviceRepository.loadDevices()` is a stub** — Device state is not persisted across sessions. Fix as described in Phase 2.8.

4. **Color wheel sends commands per frame** — No debounce, risks UART buffer overflow on ESP32. Fix as described in Phase 2.9.

5. **`LampPreviewPlaceholder` in Onboarding** — Static placeholder should be replaced with animated preview variant.

---

## File Manifest

```
SmartLamp.entitlements
SmartLampInfo.plist
project.yml
Podfile
README.md

Lumina-Swift/
├── App/
│   └── LuminaApp.swift
├── Core/
│   ├── Models/
│   │   ├── LampDevice.swift
│   │   └── UserProfile.swift
│   ├── Services/
│   │   ├── BluetoothManager.swift
│   │   ├── HomeKitManager.swift
│   │   └── HapticManager.swift
│   ├── Repositories/
│   │   └── DeviceRepository.swift
│   └── Extensions/
│       └── HapticManager.swift          # duplicate, same content as Services/
├── Features/
│   ├── Authentication/
│   │   └── SignInView.swift
│   ├── Dashboard/
│   │   ├── MainDashboardView.swift
│   │   ├── DashboardViewModel.swift
│   │   ├── LampPreview3D.swift
│   │   └── ControlCard.swift
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── OnboardingViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── ProfileView.swift
└── DesignSystem/
    ├── LuminaTheme.swift
    └── Components/
        ├── GlassCard.swift
        ├── NeonButton.swift
        ├── GlassSlider.swift
        ├── ColorWheelPicker.swift
        ├── ConnectionBadge.swift
        └── GlowIcon.swift
```

---

*Maintained by: Lumina Development Team*
*Document Version: 1.0*
