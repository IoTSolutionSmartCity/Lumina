#include "../esp32s3_homekit_builtin_led/LuminaProtocol.h"

#include <cassert>
#include <cstring>
#include <iostream>

int main() {
  const uint8_t halfRed[] = {0x02, 255, 0, 0, 128, 1};
  LuminaProtocol::Command color = LuminaProtocol::parse(halfRed, sizeof(halfRed));
  assert(color.kind == LuminaProtocol::Command::color);
  assert(color.red == 128);
  assert(color.green == 0);
  assert(color.blue == 0);
  assert(!color.debugLed);

  const uint8_t debugOn[] = {0x02, 10, 20, 30, 255, 1, 1};
  LuminaProtocol::Command mirrored = LuminaProtocol::parse(debugOn, sizeof(debugOn));
  assert(mirrored.kind == LuminaProtocol::Command::color);
  assert(mirrored.debugLed);
  assert(mirrored.red == 10 && mirrored.green == 20 && mirrored.blue == 30);

  const uint8_t off[] = {0x02, 255, 255, 255, 255, 0};
  LuminaProtocol::Command poweredOff = LuminaProtocol::parse(off, sizeof(off));
  assert(poweredOff.kind == LuminaProtocol::Command::color);
  assert(poweredOff.red == 0 && poweredOff.green == 0 && poweredOff.blue == 0);

  const uint8_t wifi[] = {0x10, 4, 'H', 'o', 'm', 'e', 8, 'p', 'a', 's', 's', 'w', 'o', 'r', 'd'};
  LuminaProtocol::Command network = LuminaProtocol::parse(wifi, sizeof(wifi));
  assert(network.kind == LuminaProtocol::Command::wifi);
  assert(std::strcmp(network.ssid, "Home") == 0);
  assert(std::strcmp(network.password, "password") == 0);

  const uint8_t truncated[] = {0x10, 4, 'H', 'o'};
  assert(LuminaProtocol::parse(truncated, sizeof(truncated)).kind == LuminaProtocol::Command::invalid);

  const uint8_t scan[] = {0x11};
  assert(LuminaProtocol::parse(scan, sizeof(scan)).kind == LuminaProtocol::Command::scan);

  uint8_t packet[40];
  const size_t length = LuminaProtocol::encodeScanResult(packet, sizeof(packet), "Home", -40, true, true);
  assert(length == 8);
  assert(packet[0] == 0x11);
  assert(packet[1] == 0x81);
  assert(static_cast<int8_t>(packet[2]) == -40);
  assert(packet[3] == 4);
  assert(std::memcmp(packet + 4, "Home", 4) == 0);

  const uint8_t saveBreath[] = {0x03, 4, 124, 58, 237, 200, 1};
  LuminaProtocol::Command breath = LuminaProtocol::parse(saveBreath, sizeof(saveBreath));
  assert(breath.kind == LuminaProtocol::Command::mode);
  assert(breath.modeId == 4);
  assert(breath.breath);
  assert(!breath.recalls);
  assert(breath.red == 124 && breath.green == 58 && breath.blue == 237);
  assert(breath.brightness == 200);

  const uint8_t recallWarm[] = {0x03, 1};
  LuminaProtocol::Command warm = LuminaProtocol::parse(recallWarm, sizeof(recallWarm));
  assert(warm.kind == LuminaProtocol::Command::mode);
  assert(warm.modeId == 1);
  assert(warm.recalls);

  const uint8_t badMode[] = {0x03, 9};
  assert(LuminaProtocol::parse(badMode, sizeof(badMode)).kind == LuminaProtocol::Command::invalid);

  std::cout << "lumina protocol ok\n";
  return 0;
}
