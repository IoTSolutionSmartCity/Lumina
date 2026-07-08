#pragma once

#include <Arduino.h>
#include <WiFi.h>

// HomeSpan owns the Wi-Fi lifecycle (STA connect, reconnect backoff, BSSID scan,
// and the captive-portal setup AP). Don't stop/mode-flip the radio around it --
// doing so races HomeSpan's own WiFi.mode() calls and makes STA/AP netif start
// time out ("Failed to start STA!/AP!"). This header now only logs connection
// state via HomeSpan's setConnectionCallback() hook.
namespace LuminaWifi {

inline void onConnection(int status) {
  if (status) {
    Serial.printf("Wi-Fi connected. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("Wi-Fi disconnected.");
  }
}

}  // namespace LuminaWifi
