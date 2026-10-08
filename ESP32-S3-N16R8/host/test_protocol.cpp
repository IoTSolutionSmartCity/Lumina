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

  std::cout << "lumina protocol ok\n";
  return 0;
}
