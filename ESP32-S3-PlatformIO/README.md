# Lumina ESP32-S3 PlatformIO Firmware

This folder is the PlatformIO version of the Lumina ESP32-S3 HomeKit firmware. It keeps the Arduino framework and HomeSpan library, but builds from VS Code with PlatformIO instead of the Arduino IDE.

## Folder Layout

```text
ESP32-S3-PlatformIO/
├── platformio.ini
├── README.md
├── .gitignore
├── include/
│   └── README.md
├── lib/
│   └── README.md
├── src/
│   ├── Esp32S3_homekit.cpp
│   └── PlatformIO_Blink_Test.cpp
└── test/
    └── README.md
```

## Board Target

The project is configured for an `ESP32S3-N16R8` style module:

- 16 MB external flash
- 8 MB external PSRAM
- Arduino framework
- HomeSpan HomeKit accessory library
- 115200 baud serial monitor
- Native USB CDC enabled by default

If your exact board does not use native USB CDC for serial/upload, change these flags in `platformio.ini`:

```ini
-DARDUINO_USB_MODE=0
-DARDUINO_USB_CDC_ON_BOOT=0
```

## Build And Upload

Two PlatformIO environments are available:

| Environment | Source file | Purpose |
|---|---|---|
| `esp32s3_n16r8_test` | `src/PlatformIO_Blink_Test.cpp` | HomeKit test using built-in LED on GPIO 48 |
| `esp32s3_n16r8` | `src/Esp32S3_homekit.cpp` | HomeKit RGBW lamp firmware |

The default environment is `esp32s3_n16r8_test` so your first build does not pull HomeSpan until PlatformIO is confirmed working.

This project uses the `pioarduino` PlatformIO platform because HomeSpan 2.1.8+ requires Arduino-ESP32 3.3.0 or newer, which the stock `espressif32` platform does not provide yet.

Start with the test environment to confirm PlatformIO build, upload, and serial monitor:

```bash
pio run -e esp32s3_n16r8_test
pio run -e esp32s3_n16r8_test --target upload
pio device monitor -e esp32s3_n16r8_test
```

When the test works, switch to the HomeKit firmware:

```bash
pio run -e esp32s3_n16r8
pio run -e esp32s3_n16r8 --target upload
pio device monitor -e esp32s3_n16r8
```

In VS Code, open this `ESP32-S3-PlatformIO` folder, install the PlatformIO extension, choose the environment from the PlatformIO status bar, then use Build, Upload, and Monitor.

## Firmware Notes

The firmware exposes one HomeKit color `LightBulb` accessory and drives four external RGBW MOSFET channels:

- Red: `GPIO4`
- Green: `GPIO5`
- Blue: `GPIO6`
- White: `GPIO7`
- Onboard WS2812 status LED: `GPIO48`

You can change the RGBW pins in `platformio.ini` through the `PWM_R_PIN`, `PWM_G_PIN`, `PWM_B_PIN`, and `PWM_W_PIN` build flags, and the status LED pin through `STATUS_LED_PIN`.

### Wi-Fi provisioning and status LED

`esp32s3_n16r8` (`Esp32S3_homekit.cpp`) provisions Wi-Fi entirely through HomeSpan, which persists credentials and HomeKit pairing data in NVS so the device reconnects automatically after power loss with no re-configuration:

1. **No credentials stored** – HomeSpan auto-launches its open Setup Access Point `Lumina-Setup` (no password) with a captive-portal page that scans nearby networks and lets you enter your home Wi-Fi credentials.
2. **Connecting** – HomeSpan attempts to join the saved network.
3. **Pairing needed** – connected to Wi-Fi, waiting to be added in the Home app (default setup code `466-37-726`).
4. **Ready** – paired and has established a HomeKit connection.

`Esp32S3_homekit.cpp` maps HomeSpan's `HS_STATUS` callback onto these four phases and drives the onboard WS2812 (`include/StatusLed.h`) entirely off `millis()` (no blocking `delay()` calls), so Wi-Fi and HomeKit stay responsive during pairing:

| Phase | Color | Pattern |
|---|---|---|
| AP / Setup | Yellow-orange | Slow breathing, ~1s period |
| Connecting | Blue | Rapid blink, 200ms |
| HomeKit pairing needed | Purple/magenta | Steady blink, 500ms |
| Ready | Green | Solid 5s, then a brief heartbeat pulse every 5s |

`PlatformIO_Blink_Test.cpp` still uses hardcoded `WIFI_SSID`/`WIFI_PASSWORD` build flags and PWM-dims the onboard LED as a simple bring-up check; it does not use the WS2812 status LED module.

## HomeKit Library

This project uses HomeSpan:

```ini
lib_deps =
  https://github.com/HomeSpan/HomeSpan.git
```

Do not add `Arduino-HomeKit-ESP32` at the same time. Use one HomeKit stack per firmware project.
