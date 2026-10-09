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
  uint8_t breathMax;
  bool breath;
};

inline Slot fallback(uint8_t id) {
  switch (id) {
    case 1: return {0xFF, 0xB4, 0x6E, 255, 255, false};
    case 2: return {0xF6, 0xF1, 0xE7, 255, 255, false};
    case 3: return {0xD6, 0xE8, 0xFF, 255, 255, false};
    case 4: return {0x7C, 0x3A, 0xED, 40, 255, true};
    default: return {0x7C, 0x3A, 0xED, 191, 255, false};
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
  const uint8_t blob[5] = {
    slot.red,
    slot.green,
    slot.blue,
    slot.brightness,
    slot.breath ? slot.breathMax : 0
  };
  prefs.putBytes(storageKey(id), blob, sizeof(blob));
}

inline Slot readSlot(uint8_t id) {
  Preferences prefs;
  prefs.begin("lumina-modes", true);
  uint8_t blob[5] = {};
  if (prefs.getBytes(storageKey(id), blob, sizeof(blob)) != sizeof(blob)) {
    return fallback(id);
  }
  Slot slot = {blob[0], blob[1], blob[2], blob[3], blob[4], id == 4};
  if (id == 4 && slot.breathMax < slot.brightness) {
    const uint8_t swap = slot.brightness;
    slot.brightness = slot.breathMax;
    slot.breathMax = swap;
  }
  return slot;
}

struct Runner {
  enum Kind { steady, breath, flow } kind;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
  uint8_t breathMin;
  uint8_t breathMax;
  uint8_t flowCount;
  uint8_t flowBrightness;
  uint8_t flowRgb[LuminaProtocol::maxFlowColors * 3];
  uint8_t shownRed;
  uint8_t shownGreen;
  uint8_t shownBlue;
  bool showing;
  uint32_t lastPaint;
};

inline Runner &runner() {
  static Runner state = {};
  return state;
}

inline void remember(uint8_t red, uint8_t green, uint8_t blue) {
  Runner &state = runner();
  state.shownRed = red;
  state.shownGreen = green;
  state.shownBlue = blue;
  state.showing = true;
}

inline bool effectColor(uint8_t &red, uint8_t &green, uint8_t &blue) {
  const Runner &state = runner();
  if (!state.showing) {
    return false;
  }
  red = state.shownRed;
  green = state.shownGreen;
  blue = state.shownBlue;
  return true;
}

inline void paint(void (*apply)(uint8_t, uint8_t, uint8_t), uint8_t red, uint8_t green, uint8_t blue, uint8_t level) {
  const uint8_t scaledRed = static_cast<uint8_t>((static_cast<int>(red) * level) / 255);
  const uint8_t scaledGreen = static_cast<uint8_t>((static_cast<int>(green) * level) / 255);
  const uint8_t scaledBlue = static_cast<uint8_t>((static_cast<int>(blue) * level) / 255);
  remember(scaledRed, scaledGreen, scaledBlue);
  apply(scaledRed, scaledGreen, scaledBlue);
}

inline void stopEffect() {
  Runner &state = runner();
  state.kind = Runner::steady;
  state.showing = false;
}

inline void runBreath(const Slot &slot, void (*apply)(uint8_t, uint8_t, uint8_t)) {
  Runner &state = runner();
  state.kind = Runner::breath;
  state.red = slot.red;
  state.green = slot.green;
  state.blue = slot.blue;
  state.breathMin = slot.brightness;
  state.breathMax = slot.breathMax < slot.brightness ? 255 : slot.breathMax;
  state.lastPaint = 0;
  paint(apply, slot.red, slot.green, slot.blue, state.breathMax);
}

inline void saveFlow(const LuminaProtocol::Command &command) {
  Preferences prefs;
  prefs.begin("lumina-modes", false);
  uint8_t blob[2 + LuminaProtocol::maxFlowColors * 3] = {};
  blob[0] = command.flowCount;
  blob[1] = command.brightness;
  memcpy(blob + 2, command.flowRgb, command.flowCount * 3u);
  prefs.putBytes("flow", blob, 2 + command.flowCount * 3u);
}

inline bool loadFlow(Runner &state) {
  Preferences prefs;
  prefs.begin("lumina-modes", true);
  uint8_t blob[2 + LuminaProtocol::maxFlowColors * 3] = {};
  const size_t got = prefs.getBytes("flow", blob, sizeof(blob));
  if (got < 5 || blob[0] == 0 || blob[0] > LuminaProtocol::maxFlowColors || got < 2u + blob[0] * 3u) {
    return false;
  }
  state.flowCount = blob[0];
  state.flowBrightness = blob[1];
  memcpy(state.flowRgb, blob + 2, state.flowCount * 3u);
  return true;
}

inline void runFlow(const Runner &source, void (*apply)(uint8_t, uint8_t, uint8_t)) {
  Runner &state = runner();
  state.kind = Runner::flow;
  state.flowCount = source.flowCount;
  state.flowBrightness = source.flowBrightness;
  memcpy(state.flowRgb, source.flowRgb, source.flowCount * 3u);
  state.lastPaint = 0;
  paint(apply, state.flowRgb[0], state.flowRgb[1], state.flowRgb[2], state.flowBrightness);
}

inline void handle(const LuminaProtocol::Command &command, void (*apply)(uint8_t, uint8_t, uint8_t)) {
  if (command.kind == LuminaProtocol::Command::color) {
    stopEffect();
    return;
  }
  if (command.kind == LuminaProtocol::Command::flow) {
    Runner loaded = {};
    loaded.flowCount = command.flowCount;
    loaded.flowBrightness = command.brightness;
    memcpy(loaded.flowRgb, command.flowRgb, command.flowCount * 3u);
    saveFlow(command);
    runFlow(loaded, apply);
    return;
  }
  if (command.kind != LuminaProtocol::Command::mode) {
    return;
  }

  Slot slot = command.recalls ? readSlot(command.modeId) : Slot{
    command.red,
    command.green,
    command.blue,
    command.brightness,
    command.modeId == 4 ? command.breathMax : 255,
    command.breath
  };
  if (!command.recalls) {
    writeSlot(command.modeId, slot);
  }
  if (slot.breath) {
    runBreath(slot, apply);
  } else {
    stopEffect();
    paint(apply, slot.red, slot.green, slot.blue, slot.brightness);
    runner().showing = false;
  }
}

inline void tick(void (*apply)(uint8_t, uint8_t, uint8_t)) {
  Runner &state = runner();
  const uint32_t now = millis();
  if (now - state.lastPaint < 50) {
    return;
  }
  state.lastPaint = now;

  if (state.kind == Runner::breath) {
    const float wave = (sinf(static_cast<float>(now % 4800) * 2.0f * PI / 4800.0f) + 1.0f) / 2.0f;
    const int level = state.breathMin + static_cast<int>((state.breathMax - state.breathMin) * wave);
    paint(apply, state.red, state.green, state.blue, static_cast<uint8_t>(level));
    return;
  }

  if (state.kind != Runner::flow || state.flowCount == 0) {
    return;
  }
  const uint32_t stepMs = 2000;
  const uint32_t span = stepMs * state.flowCount;
  const uint32_t along = now % span;
  const uint8_t index = along / stepMs;
  const uint8_t next = (index + 1) % state.flowCount;
  const uint8_t frac = static_cast<uint8_t>((along % stepMs) * 255 / stepMs);
  const uint8_t *from = state.flowRgb + index * 3;
  const uint8_t *to = state.flowRgb + next * 3;
  const int red = from[0] + (static_cast<int>(to[0]) - from[0]) * frac / 255;
  const int green = from[1] + (static_cast<int>(to[1]) - from[1]) * frac / 255;
  const int blue = from[2] + (static_cast<int>(to[2]) - from[2]) * frac / 255;
  paint(apply, static_cast<uint8_t>(red), static_cast<uint8_t>(green), static_cast<uint8_t>(blue), state.flowBrightness);
}

}  // namespace LuminaModes
