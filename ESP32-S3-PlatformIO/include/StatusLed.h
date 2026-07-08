#pragma once

// Non-blocking WS2812 status indicator driven entirely off millis().
// Call StatusLed::begin() once in setup() and StatusLed::update() on every
// loop() iteration; never call delay() from this module.

#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include "SystemState.h"

namespace StatusLed {

inline Adafruit_NeoPixel *pixel = nullptr;
inline SystemState activeState = SystemState::AP_MODE;
inline unsigned long stateEnteredMs = 0;

inline void setColor(uint8_t r, uint8_t g, uint8_t b) {
  if (pixel == nullptr) {
    return;
  }
  pixel->setPixelColor(0, pixel->Color(r, g, b));
  pixel->show();
}

inline void begin(uint8_t pin, uint8_t brightness = 60) {
  static Adafruit_NeoPixel strip(1, pin, NEO_GRB + NEO_KHZ800);
  pixel = &strip;
  pixel->begin();
  pixel->setBrightness(brightness);
  pixel->show();
  stateEnteredMs = millis();
}

// Re-entering the same state is a no-op so timed patterns (e.g. the READY
// celebration window) don't restart on every duplicate callback.
inline void setState(SystemState state) {
  if (state != activeState) {
    activeState = state;
    stateEnteredMs = millis();
  }
}

inline void applyBreathing(unsigned long elapsedMs, unsigned long periodMs, uint8_t r, uint8_t g, uint8_t b) {
  float phase = static_cast<float>(elapsedMs % periodMs) / static_cast<float>(periodMs);
  float level = (sinf(phase * 2.0f * PI - PI / 2.0f) + 1.0f) / 2.0f;  // smooth 0..1 breathing curve
  setColor(static_cast<uint8_t>(r * level), static_cast<uint8_t>(g * level), static_cast<uint8_t>(b * level));
}

inline void applyBlink(unsigned long elapsedMs, unsigned long intervalMs, uint8_t r, uint8_t g, uint8_t b) {
  bool on = (elapsedMs / intervalMs) % 2 == 0;
  setColor(on ? r : 0, on ? g : 0, on ? b : 0);
}

inline void update() {
  if (pixel == nullptr) {
    return;
  }

  unsigned long elapsedMs = millis() - stateEnteredMs;

  switch (activeState) {
    case SystemState::AP_MODE:
      // Yellow/orange breathing, ~1s period: waiting for provisioning.
      applyBreathing(elapsedMs, 1000, 255, 140, 0);
      break;

    case SystemState::CONNECTING:
      // Blue rapid blink, 200ms interval: actively joining home WiFi.
      applyBlink(elapsedMs, 200, 0, 60, 255);
      break;

    case SystemState::HOMEKIT_PAIRING:
      // Purple/magenta steady blink, 500ms interval: ready to pair.
      applyBlink(elapsedMs, 500, 160, 0, 220);
      break;

    case SystemState::READY: {
      const unsigned long celebrateMs = 5000;
      if (elapsedMs < celebrateMs) {
        setColor(0, 255, 60);  // solid green celebration on first pairing/connect
      } else {
        unsigned long heartbeatElapsedMs = (elapsedMs - celebrateMs) % 5000;
        if (heartbeatElapsedMs < 150) {
          setColor(0, 120, 30);  // brief heartbeat pulse every 5s
        } else {
          setColor(0, 0, 0);
        }
      }
      break;
    }
  }
}

}  // namespace StatusLed
