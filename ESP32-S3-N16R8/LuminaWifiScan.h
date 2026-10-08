#pragma once

#include <WiFi.h>

#include "LuminaBle.h"
#include "LuminaProtocol.h"

// The iPhone cannot scan Wi-Fi for an app, so the lamp scans and reports what it can join.
inline void publishWifiScan() {
  WiFi.mode(WIFI_STA);
  const int found = WiFi.scanNetworks(false, true);

  struct Hit {
    char ssid[LuminaProtocol::maxSsid + 1];
    int8_t rssi;
    bool secured;
  };
  Hit hits[12];
  int count = 0;

  if (found > 0) {
    for (int index = 0; index < found; index++) {
      const String name = WiFi.SSID(index);
      if (name.length() == 0 || name.length() > LuminaProtocol::maxSsid) {
        continue;
      }
      const bool secured = WiFi.encryptionType(index) != WIFI_AUTH_OPEN;
      const int rssiValue = WiFi.RSSI(index);
      const int8_t rssi = static_cast<int8_t>(rssiValue < -128 ? -128 : rssiValue);

      int existing = -1;
      for (int slot = 0; slot < count; slot++) {
        if (strcmp(hits[slot].ssid, name.c_str()) == 0) {
          existing = slot;
          break;
        }
      }
      if (existing >= 0) {
        if (rssi > hits[existing].rssi) {
          hits[existing].rssi = rssi;
          hits[existing].secured = secured;
        }
        continue;
      }

      int slot = count;
      if (count == 12) {
        slot = 0;
        for (int candidate = 1; candidate < count; candidate++) {
          if (hits[candidate].rssi < hits[slot].rssi) {
            slot = candidate;
          }
        }
        if (rssi <= hits[slot].rssi) {
          continue;
        }
      } else {
        count++;
      }

      strncpy(hits[slot].ssid, name.c_str(), LuminaProtocol::maxSsid);
      hits[slot].ssid[LuminaProtocol::maxSsid] = '\0';
      hits[slot].rssi = rssi;
      hits[slot].secured = secured;
    }
  }
  WiFi.scanDelete();

  for (int pass = 0; pass < count; pass++) {
    for (int index = pass + 1; index < count; index++) {
      if (hits[index].rssi > hits[pass].rssi) {
        const Hit swap = hits[pass];
        hits[pass] = hits[index];
        hits[index] = swap;
      }
    }
  }

  if (count == 0) {
    uint8_t packet[4];
    const size_t length = LuminaProtocol::encodeScanResult(packet, sizeof(packet), "", 0, false, true);
    LuminaBle::publishScan(packet, length);
    return;
  }

  for (int index = 0; index < count; index++) {
    uint8_t packet[4 + LuminaProtocol::maxSsid];
    const size_t length = LuminaProtocol::encodeScanResult(
      packet,
      sizeof(packet),
      hits[index].ssid,
      hits[index].rssi,
      hits[index].secured,
      index == count - 1
    );
    LuminaBle::publishScan(packet, length);
    delay(30);
  }
}
