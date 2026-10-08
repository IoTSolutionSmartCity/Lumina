#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

// Shared by the ESP32 firmware and the Lumina app.
// Color:  0x02, R, G, B, brightness, power
// Wi-Fi:  0x10, ssidLen, ssid..., passwordLen, password...
namespace LuminaProtocol {

static constexpr uint8_t colorCommand = 0x02;
static constexpr uint8_t wifiCommand = 0x10;
static constexpr size_t maxSsid = 32;
static constexpr size_t maxPassword = 64;

struct Command {
  enum Kind { invalid, color, wifi } kind;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
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

}  // namespace LuminaProtocol
