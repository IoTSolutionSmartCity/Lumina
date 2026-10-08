#pragma once

#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#include "LuminaProtocol.h"

// ponytail: open BLE, no passkey. Add one if the lamp sits somewhere public.
namespace LuminaBle {

static constexpr const char *deviceName = "Lumina ESP32S3 Lamp";
static constexpr const char *serviceUUID = "4c554d49-4e41-4000-8000-000000000001";
static constexpr const char *commandUUID = "4c554d49-4e41-4000-8000-000000000002";
static constexpr const char *scanUUID = "4c554d49-4e41-4000-8000-000000000003";

inline portMUX_TYPE &lock() {
  static portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;
  return mux;
}

inline LuminaProtocol::Command &pending() {
  static LuminaProtocol::Command command = {};
  return command;
}

inline bool &pendingReady() {
  static bool ready = false;
  return ready;
}

inline void handleWrite(const uint8_t *data, size_t length) {
  LuminaProtocol::Command command = LuminaProtocol::parse(data, length);
  if (command.kind == LuminaProtocol::Command::invalid) {
    return;
  }

  portENTER_CRITICAL(&lock());
  if (pendingReady() && pending().kind == LuminaProtocol::Command::wifi) {
    portEXIT_CRITICAL(&lock());
    return;
  }
  pending() = command;
  pendingReady() = true;
  portEXIT_CRITICAL(&lock());
}

inline volatile bool &phoneConnectedFlag() {
  static volatile bool connected = false;
  return connected;
}

inline bool phoneConnected() {
  return phoneConnectedFlag();
}

inline void setPhoneConnected(bool connected) {
  phoneConnectedFlag() = connected;
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    (void)server;
    setPhoneConnected(true);
  }

  void onDisconnect(BLEServer *server) override {
    (void)server;
    setPhoneConnected(false);
    BLEDevice::startAdvertising();
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    auto value = characteristic->getValue();
    if (value.length() == 0) {
      return;
    }
    handleWrite(reinterpret_cast<const uint8_t *>(value.c_str()), value.length());
  }
};

inline BLECharacteristic *&scanCharacteristic() {
  static BLECharacteristic *characteristic = nullptr;
  return characteristic;
}

inline void publishScan(const uint8_t *data, size_t length) {
  BLECharacteristic *characteristic = scanCharacteristic();
  if (characteristic == nullptr || data == nullptr || length == 0) {
    return;
  }
  characteristic->setValue(const_cast<uint8_t *>(data), length);
  characteristic->notify();
}

inline void begin() {
  BLEDevice::init(deviceName);
  BLEDevice::setMTU(247);

  static ServerCallbacks serverCallbacks;
  static CommandCallbacks commandCallbacks;

  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(&serverCallbacks);
  BLEService *service = server->createService(serviceUUID);
  BLECharacteristic *command = service->createCharacteristic(
    commandUUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  command->setCallbacks(&commandCallbacks);

  BLECharacteristic *scan = service->createCharacteristic(
    scanUUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  scan->addDescriptor(new BLE2902());
  scanCharacteristic() = scan;
  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(serviceUUID);
  advertising->setScanResponse(true);
  advertising->start();
  Serial.println("BLE advertising: Lumina ESP32S3 Lamp");
}

inline bool takeEvent(LuminaProtocol::Command &command) {
  portENTER_CRITICAL(&lock());
  if (!pendingReady()) {
    portEXIT_CRITICAL(&lock());
    return false;
  }
  command = pending();
  pendingReady() = false;
  portEXIT_CRITICAL(&lock());
  return true;
}

}  // namespace LuminaBle
