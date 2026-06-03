#pragma once

#include <Arduino.h>
#include <WiFi.h>
#include <esp_wifi.h>

namespace LuminaWifi {

inline unsigned long connectStartedMs = 0;
inline bool connectPending = false;

inline void resetStack() {
  esp_wifi_stop();
  delay(100);
  WiFi.mode(WIFI_STA);
  delay(50);
}

inline void begin(const char *ssid, const char *pwd) {
  if (WiFi.status() == WL_CONNECTED) {
    connectPending = false;
    return;
  }

  if (connectPending && (millis() - connectStartedMs < 15000)) {
    return;
  }

  connectPending = true;
  connectStartedMs = millis();
  Serial.printf("Connecting to Wi-Fi: %s\n", ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, pwd);
}

inline void onConnection(int status) {
  connectPending = false;

  if (status) {
    Serial.printf("Wi-Fi connected. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("Wi-Fi disconnected.");
  }
}

}  // namespace LuminaWifi
