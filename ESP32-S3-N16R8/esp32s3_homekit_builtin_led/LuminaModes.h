#pragma once

#include "LuminaProtocol.h"

#include <Arduino.h>
#include <Preferences.h>
#include <math.h>

// Saves Color, Warm, Soft, Cool, and Breath on the lamp.
// Calling a mode runs that saved copy. Breath keeps fading on the chip.
namespace LuminaModes {

struct Slot {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
  uint8_t brightness;
  bool breath;
};

inline Slot fallback(uint8_t id) {
  switch (id) {
    case 1: return {0xFF, 0xB4, 0x6E, 255, false};
    case 2: return {0xF6, 0xF1, 0xE7, 255, false};
    case 3: return {0xD6, 0xE8, 0xFF, 255, false};
    case 4: return {0x7C, 0x3A, 0xED, 255, true};
    default: return {0x7C, 0x3A, 0xED, 191, false};
  }
}

inline const char *storageKey(uint8_t id) {
  static char key[3];
  key[0] = 'm';
  key[1] = static_cast<char>('0' + id);
  key[2] = '\0';
  return key;
}

inline void writeSlot(uint8_t id, const Slot &slot) {
  Preferences prefs;
  prefs.begin("lumina-modes", false);
  const uint8_t blob[5] = {slot.red, slot.green, slot.blue, slot.brightness, slot.breath ? 1 : 0};
  prefs.putBytes(storageKey(id), blob, sizeof(blob));
}

inline Slot readSlot(uint8_t id) {
  Preferences prefs;
  prefs.begin("lumina-modes", true);
  uint8_t blob[5] = {};
  if (prefs.getBytes(storageKey(id), blob, sizeof(blob)) != sizeof(blob)) {
    return fallback(id);
  }
  Slot slot = {blob[0], blob[1], blob[2], blob[3], blob[4] != 0};
  return slot;
}

struct Runner {
  bool breath;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
  uint8_t brightness;
  uint32_t lastPaint;
};

inline Runner &runner() {
  static Runner state = {};
  return state;
}

inline void paint(void (*apply)(uint8_t, uint8_t, uint8_t), const Slot &slot, uint8_t wave) {
  const int scale = (static_cast<int>(slot.brightness) * wave) / 255;
  apply(
    static_cast<uint8_t>((static_cast<int>(slot.red) * scale) / 255),
    static_cast<uint8_t>((static_cast<int>(slot.green) * scale) / 255),
    static_cast<uint8_t>((static_cast<int>(slot.blue) * scale) / 255)
  );
}

inline void runSlot(const Slot &slot, void (*apply)(uint8_t, uint8_t, uint8_t)) {
  Runner &state = runner();
  state.red = slot.red;
  state.green = slot.green;
  state.blue = slot.blue;
  state.brightness = slot.brightness;
  state.breath = slot.breath;
  state.lastPaint = millis();
  paint(apply, slot, 255);
}

inline void stopBreath() {
  runner().breath = false;
}

inline void handle(const LuminaProtocol::Command &command, void (*apply)(uint8_t, uint8_t, uint8_t)) {
  if (command.kind == LuminaProtocol::Command::color) {
    stopBreath();
    return;
  }
  if (command.kind != LuminaProtocol::Command::mode) {
    return;
  }

  Slot slot = command.recalls
    ? readSlot(command.modeId)
    : Slot{command.red, command.green, command.blue, command.brightness, command.breath};
  if (!command.recalls) {
    writeSlot(command.modeId, slot);
  }
  runSlot(slot, apply);
}

inline void tick(void (*apply)(uint8_t, uint8_t, uint8_t)) {
  Runner &state = runner();
  if (!state.breath) {
    return;
  }
  const uint32_t now = millis();
  if (now - state.lastPaint < 50) {
    return;
  }
  state.lastPaint = now;
  const float wave = (sinf(static_cast<float>(now % 4800) * 2.0f * PI / 4800.0f) + 1.0f) / 2.0f;
  const uint8_t level = static_cast<uint8_t>((0.22f + 0.78f * wave) * 255.0f);
  const Slot slot = {state.red, state.green, state.blue, state.brightness, true};
  paint(apply, slot, level);
}

}  // namespace LuminaModes
