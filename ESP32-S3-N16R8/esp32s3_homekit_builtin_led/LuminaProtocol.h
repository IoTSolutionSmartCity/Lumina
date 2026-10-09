#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

// Shared by the ESP32 firmware and the Lumina app.
// Color:  0x02, R, G, B, brightness, power, debugLed
// Mode:   0x03, id, R, G, B, brightness, breath
//         id 0 color, 1 warm, 2 soft, 3 cool, 4 breath.
//         A 2-byte packet (0x03, id) runs the copy saved on the lamp.
// Wi-Fi:  0x10, ssidLen, ssid..., passwordLen, password...
// Scan:   0x11 from the app. The lamp replies on the scan characteristic:
//         0x11, flags, rssi, ssidLen, ssid...
//         flags bit 0 = password required, bit 7 = last network in this scan.
namespace LuminaProtocol {

static constexpr uint8_t colorCommand = 0x02;
static constexpr uint8_t modeCommand = 0x03;
static constexpr uint8_t wifiCommand = 0x10;
static constexpr uint8_t scanCommand = 0x11;
static constexpr size_t maxSsid = 32;
static constexpr size_t maxPassword = 64;

struct Command {
  enum Kind { invalid, color, wifi, scan, mode } kind;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
  uint8_t brightness;
  uint8_t modeId;
  bool breath;
  bool recalls;
  bool debugLed;
  char ssid[maxSsid + 1];
  char password[maxPassword + 1];
};

inline Command parse(const uint8_t *data, size_t length) {
  Command command = {};
  command.kind = Command::invalid;
  if (data == nullptr || length == 0) {
    return command;
  }

  if (data[0] == colorCommand && length >= 4) {
    int red = data[1];
    int green = data[2];
    int blue = data[3];
    const bool powered = length < 6 || data[5] != 0;
    if (!powered) {
      red = 0;
      green = 0;
      blue = 0;
    } else if (length >= 5) {
      const int brightness = data[4];
      red = (red * brightness) / 255;
      green = (green * brightness) / 255;
      blue = (blue * brightness) / 255;
    }
    command.kind = Command::color;
    command.red = static_cast<uint8_t>(red);
    command.green = static_cast<uint8_t>(green);
    command.blue = static_cast<uint8_t>(blue);
    command.debugLed = length >= 7 && data[6] != 0;
    return command;
  }

  if (data[0] == modeCommand && length >= 2 && data[1] <= 4) {
    command.kind = Command::mode;
    command.modeId = data[1];
    command.recalls = length < 7;
    if (!command.recalls) {
      command.red = data[2];
      command.green = data[3];
      command.blue = data[4];
      command.brightness = data[5];
      command.breath = data[6] != 0;
    }
    return command;
  }

  if (data[0] == scanCommand) {
    command.kind = Command::scan;
    return command;
  }

  if (data[0] == wifiCommand && length >= 3) {
    const size_t ssidLength = data[1];
    if (ssidLength == 0 || ssidLength > maxSsid || length < 3 + ssidLength) {
      return command;
    }
    const size_t passwordLength = data[2 + ssidLength];
    if (passwordLength > maxPassword || length < 3 + ssidLength + passwordLength) {
      return command;
    }
    memcpy(command.ssid, data + 2, ssidLength);
    command.ssid[ssidLength] = '\0';
    memcpy(command.password, data + 3 + ssidLength, passwordLength);
    command.password[passwordLength] = '\0';
    command.kind = Command::wifi;
  }

  return command;
}

inline size_t encodeScanResult(
  uint8_t *out,
  size_t capacity,
  const char *ssid,
  int8_t rssi,
  bool secured,
  bool last
) {
  const size_t ssidLength = ssid == nullptr ? 0 : strnlen(ssid, maxSsid);
  if (out == nullptr || capacity < 4 + ssidLength) {
    return 0;
  }
  out[0] = scanCommand;
  out[1] = static_cast<uint8_t>((secured ? 0x01 : 0x00) | (last ? 0x80 : 0x00));
  out[2] = static_cast<uint8_t>(rssi);
  out[3] = static_cast<uint8_t>(ssidLength);
  if (ssidLength > 0) {
    memcpy(out + 4, ssid, ssidLength);
  }
  return 4 + ssidLength;
}

}  // namespace LuminaProtocol
