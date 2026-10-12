#pragma once

#include <Arduino.h>

#include "LuminaBle.h"
#include "LuminaModes.h"

// Onboard WS2812 on GPIO 48. The lamp color itself is the PWM on GPIO 4, 5, and 6.
namespace BoardLed {

constexpr uint8_t pin = 48;

inline bool wifiConfigured = false;
inline bool wifiUp = false;
inline bool mirrorAppColor = false;
inline uint8_t mirrorRed = 0;
inline uint8_t mirrorGreen = 0;
inline uint8_t mirrorBlue = 0;
inline uint32_t greenUntil = 0;
inline uint8_t shownRed = 1;
inline uint8_t shownGreen = 1;
inline uint8_t shownBlue = 1;

inline void show(uint8_t red, uint8_t green, uint8_t blue) {
  if (red == shownRed && green == shownGreen && blue == shownBlue) {
    return;
  }
  shownRed = red;
  shownGreen = green;
  shownBlue = blue;
  neopixelWrite(pin, red, green, blue);
}

inline void setMirror(bool enabled, uint8_t red, uint8_t green, uint8_t blue) {
  mirrorAppColor = enabled;
  mirrorRed = red;
  mirrorGreen = green;
  mirrorBlue = blue;
}

inline void celebrateWifi() {
  wifiConfigured = true;
  greenUntil = millis() + 2500;
}

inline void update() {
  const uint32_t now = millis();
  uint8_t red = 0;
  uint8_t green = 0;
  uint8_t blue = 0;

  if (greenUntil != 0 && static_cast<int32_t>(greenUntil - now) > 0) {
    green = 160;
  } else if (LuminaModes::effectColor(red, green, blue)) {
  } else if (mirrorAppColor) {
    red = mirrorRed;
    green = mirrorGreen;
    blue = mirrorBlue;
  } else if (wifiUp || wifiConfigured) {
    // Wi-Fi is saved or connected. Red is only for "no Wi-Fi and no phone".
  } else if (LuminaBle::phoneConnected()) {
    if ((now / 800) % 2 == 0) {
      red = 200;
      green = 70;
    }
  } else {
    red = 160;
  }

  show(red, green, blue);
}

}  // namespace BoardLed
