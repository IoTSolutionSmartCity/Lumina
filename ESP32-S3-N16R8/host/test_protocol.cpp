#include "../LuminaProtocol.h"

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

  std::cout << "lumina protocol ok\n";
  return 0;
}
