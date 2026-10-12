#pragma once

#include <cstdarg>
#include <cstdio>
#include <cstring>

#include <WiFi.h>
#include "esp_coexist.h"
#include "esp_wifi.h"

#include "BoardLed.h"
#include "LuminaBle.h"
#include "LuminaProtocol.h"

// Reports the lamp's real Wi-Fi result on the scan characteristic.
namespace LuminaLink {

// The Arduino monitor is on the CH343 UART. With USB CDC on boot, Serial is the
// other port, so the join log is written to both.
inline void line(const char *text) {
  Serial.println(text);
#if ARDUINO_USB_CDC_ON_BOOT
  Serial0.println(text);
#endif
}

inline void linef(const char *fmt, ...) {
  char text[160];
  va_list args;
  va_start(args, fmt);
  vsnprintf(text, sizeof(text), fmt, args);
  va_end(args);
  line(text);
}

inline void copySsid(char *out, const uint8_t *ssid, uint8_t length) {
  if (length > 32) {
    length = 32;
  }
  memcpy(out, ssid, length);
  out[length] = '\0';
}

inline const char *reasonText(uint8_t reason) {
  switch (reason) {
    case 2:
      return "the router cancelled the login before the password check";
    case 15:
    case 204:
      return "wrong password, handshake timed out";
    case 201:
      return "network not found. This board only joins 2.4 GHz";
    case 202:
      return "password rejected";
    case 203:
      return "the access point refused the connection";
    default:
      return nullptr;
  }
}

inline bool &joinBusy() {
  static bool busy = false;
  return busy;
}

inline bool &ignoringDrop() {
  static bool ignoring = false;
  return ignoring;
}

inline void startLog() {
#if ARDUINO_USB_CDC_ON_BOOT
  Serial0.begin(115200);
#endif
  WiFi.onEvent([](arduino_event_id_t event, arduino_event_info_t info) {
    char name[33];
    switch (event) {
      case ARDUINO_EVENT_WIFI_STA_START:
        line("Wi-Fi radio on. Joining.");
        break;
      case ARDUINO_EVENT_WIFI_STA_CONNECTED:
        copySsid(name, info.wifi_sta_connected.ssid, info.wifi_sta_connected.ssid_len);
        linef("Joined \"%s\". Waiting for an IP address.", name);
        break;
      case ARDUINO_EVENT_WIFI_STA_GOT_IP:
        joinBusy() = false;
        LuminaBle::resumeAfterJoin();
        linef("Wi-Fi connected. IP %s, RSSI %d dBm.", WiFi.localIP().toString().c_str(), WiFi.RSSI());
        break;
      case ARDUINO_EVENT_WIFI_STA_DISCONNECTED: {
        if (ignoringDrop()) {
          break;
        }
        joinBusy() = false;
        LuminaBle::resumeAfterJoin();
        copySsid(name, info.wifi_sta_disconnected.ssid, info.wifi_sta_disconnected.ssid_len);
        const uint8_t reason = info.wifi_sta_disconnected.reason;
        const char *why = reasonText(reason);
        const int rssi = info.wifi_sta_disconnected.rssi;
        if (why != nullptr) {
          linef("Could not stay on \"%s\": %s (reason %u, RSSI %d). Retrying.", name, why, reason, rssi);
        } else {
          linef("Left \"%s\" (reason %u, RSSI %d). Retrying.", name, reason, rssi);
        }
        break;
      }
      default:
        break;
    }
  });
}

// HomeSpan calls this. A zero RSSI gate rejects every real access point, and
// a second begin while the first is still logging in makes the router cancel
// it (reason 2). Bluetooth is paused until this attempt finishes.
inline void beginWifi(const char *ssid, const char *password) {
  if (joinBusy()) {
    line("Join already running.");
    return;
  }
  if (ssid == nullptr || ssid[0] == '\0') {
    return;
  }
  joinBusy() = true;
  LuminaBle::pauseForJoin();
  delay(300);

  WiFi.setSleep(false);
  esp_coex_preference_set(ESP_COEX_PREFER_WIFI);
  if (WiFi.getMode() == WIFI_OFF) {
    WiFi.mode(WIFI_STA);
  }
  esp_wifi_set_ps(WIFI_PS_NONE);
  esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N);
  esp_wifi_set_bandwidth(WIFI_IF_STA, WIFI_BW_HT20);

  ignoringDrop() = true;
  esp_wifi_disconnect();
  delay(200);
  ignoringDrop() = false;

  wifi_config_t conf;
  memset(&conf, 0, sizeof(conf));
  strncpy(reinterpret_cast<char *>(conf.sta.ssid), ssid, sizeof(conf.sta.ssid) - 1);
  if (password != nullptr) {
    strncpy(reinterpret_cast<char *>(conf.sta.password), password, sizeof(conf.sta.password) - 1);
  }
  conf.sta.threshold.rssi = -127;
  conf.sta.threshold.authmode = WIFI_AUTH_WPA_PSK;
  conf.sta.scan_method = WIFI_ALL_CHANNEL_SCAN;
  conf.sta.sort_method = WIFI_CONNECT_AP_BY_SIGNAL;
  conf.sta.pmf_cfg.capable = true;
  conf.sta.pmf_cfg.required = false;

  const esp_err_t configured = esp_wifi_set_config(WIFI_IF_STA, &conf);
  const esp_err_t started = (configured == ESP_OK) ? esp_wifi_connect() : configured;
  if (configured != ESP_OK || started != ESP_OK) {
    joinBusy() = false;
    LuminaBle::resumeAfterJoin();
  }
  linef(
    "Starting join to \"%s\". config %s, connect %s.",
    ssid,
    esp_err_to_name(configured),
    esp_err_to_name(started)
  );
}

inline void joining(const char *ssid, const char *password) {
  linef(
    "Password saved. Joining \"%s\" with password \"%s\".",
    ssid == nullptr ? "" : ssid,
    password == nullptr ? "" : password
  );
}

inline uint32_t &lastPublish() {
  static uint32_t stamp = 0;
  return stamp;
}

inline void publish() {
  uint8_t state = 0;
  uint8_t ip[4] = {};
  int8_t rssi = 0;
  String ssid;
  switch (WiFi.status()) {
    case WL_CONNECTED:
      state = 1;
      {
        const IPAddress address = WiFi.localIP();
        ip[0] = address[0];
        ip[1] = address[1];
        ip[2] = address[2];
        ip[3] = address[3];
      }
      rssi = static_cast<int8_t>(WiFi.RSSI());
      ssid = WiFi.SSID();
      break;
    case WL_CONNECT_FAILED:
    case WL_NO_SSID_AVAIL:
      state = 2;
      break;
    default:
      state = 0;
      break;
  }

  uint8_t packet[8 + LuminaProtocol::maxSsid];
  const size_t length = LuminaProtocol::encodeWifiStatus(
    packet,
    sizeof(packet),
    state,
    rssi,
    ip,
    ssid.c_str()
  );
  if (length > 0) {
    LuminaBle::publishScan(packet, length);
  }
}

inline void poke() {
  lastPublish() = 0;
}

inline void onConnection(int status) {
  BoardLed::wifiUp = status != 0;
  poke();
}

inline void tick() {
  if (!LuminaBle::phoneConnected()) {
    return;
  }
  const uint32_t now = millis();
  if (lastPublish() != 0 && now - lastPublish() < 2000) {
    return;
  }
  lastPublish() = now;
  publish();
}

}  // namespace LuminaLink
