#pragma once

#include <cstdint>

// High-level provisioning/pairing lifecycle driven by HomeSpan's HS_STATUS
// callback (see onHomeSpanStatus() in Esp32S3_homekit.cpp) and mirrored on
// the onboard status LED.
enum class SystemState : uint8_t {
  AP_MODE,          // No WiFi credentials stored; Setup AP + captive portal is live.
  CONNECTING,        // Credentials stored; actively attempting to join home WiFi.
  HOMEKIT_PAIRING,   // Connected to WiFi, waiting to be paired via the Home app.
  READY,             // Paired and (at least once) connected to a HomeKit controller.
};
