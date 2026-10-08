#pragma once

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#include "LuminaProtocol.h"

// ponytail: open BLE, no passkey. Add one if the lamp sits somewhere public.
namespace LuminaBle {

static constexpr const char *deviceName = "Lumina ESP32S3 Lamp";
static constexpr const char *serviceUUID = "4c554d49-4e41-4000-8000-000000000001";
static constexpr const char *commandUUID = "4c554d49-4e41-4000-8000-000000000002";

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

class ServerCallbacks : public BLEServerCallbacks {
  void onDisconnect(BLEServer *server) override {
    (void)server;
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
