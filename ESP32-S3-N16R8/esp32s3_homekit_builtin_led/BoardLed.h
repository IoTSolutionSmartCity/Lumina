#pragma once

#include <Arduino.h>

#include "LuminaBle.h"
#include "LuminaModes.h"

// Onboard WS2812 on GPIO 48. The lamp color itself is the PWM on GPIO 4, 5, and 6.
namespace BoardLed {

constexpr uint8_t pin = 48;

inline bool wifiConfigured = false;
inline bool mirrorAppColor = false;
inline uint8_t mirrorRed = 0;
inline uint8_t mirrorGreen = 0;
inline uint8_t mirrorBlue = 0;
inline bool restartWhenGreenEnds = false;
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
  greenUntil = millis() + 5000;
  restartWhenGreenEnds = true;
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
  } else if (!wifiConfigured && !LuminaBle::phoneConnected()) {
    red = 160;
  } else if (!wifiConfigured) {
    if ((now / 800) % 2 == 0) {
      red = 200;
      green = 70;
    }
  } else if (!LuminaBle::phoneConnected()) {
    red = 160;
  }

  show(red, green, blue);

  if (restartWhenGreenEnds && greenUntil != 0 && static_cast<int32_t>(now - greenUntil) >= 0) {
    restartWhenGreenEnds = false;
    show(0, 0, 0);
    delay(40);
    ESP.restart();
  }
}

}  // namespace BoardLed
