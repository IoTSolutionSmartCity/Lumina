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
- Built-in status LED: `GPIO48`

You can change the RGBW pins in `platformio.ini` through the `PWM_R_PIN`, `PWM_G_PIN`, `PWM_B_PIN`, and `PWM_W_PIN` build flags.

## HomeKit Library

This project uses HomeSpan:

```ini
lib_deps =
  https://github.com/HomeSpan/HomeSpan.git
```

Do not add `Arduino-HomeKit-ESP32` at the same time. Use one HomeKit stack per firmware project.
