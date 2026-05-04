/*
  ESP32-S3 HomeKit Lamp (built-in LED first)
  - Pairs to Apple Home via HomeSpan
  - Exposes one Light accessory
  - Controls the ESP32-S3 built-in LED
*/

#include "HomeSpan.h"

// ---- Board LED configuration ----
// If your board does not respond, try:
// 1) change LED_PIN (common ESP32-S3 built-in LED pin is 48)
// 2) set LED_ACTIVE_LOW to 1
#ifndef LED_PIN
  #ifdef LED_BUILTIN
    #define LED_PIN LED_BUILTIN
  #else
    #define LED_PIN 48
  #endif
#endif

#define LED_ACTIVE_LOW 0

class BuiltInLamp : public Service::LightBulb {
  private:
    int ledPin;
    SpanCharacteristic *power;

    void applyState(bool on) {
      if (LED_ACTIVE_LOW) {
        digitalWrite(ledPin, on ? LOW : HIGH);
      } else {
        digitalWrite(ledPin, on ? HIGH : LOW);
      }
    }

  public:
    BuiltInLamp(int pin) : Service::LightBulb() {
      ledPin = pin;

      power = new Characteristic::On(false);
      new Characteristic::Name("ESP32S3 Built-in Lamp");

      pinMode(ledPin, OUTPUT);
      applyState(false);
    }

    boolean update() override {
      bool isOn = power->getNewVal();
      applyState(isOn);
      Serial.printf("HomeKit lamp state: %s\n", isOn ? "ON" : "OFF");
      return true;
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1. DONT use setStatusPin(-1) or setControlPin(-1) here if they cause 255 errors.
  // Instead, just set the pairing code and credentials.
  homeSpan.setPairingCode("46637726");
  homeSpan.setWifiCredentials("Wong", "93484972a");
  
  // 2. Set Log Level to 1 to see the handshake
  homeSpan.setLogLevel(1);

  // 3. Start HomeSpan
  homeSpan.begin(Category::Lighting, "Lumina ESP32S3 Lamp");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
      new Characteristic::Name("Lumina Built-in LED");
      new Characteristic::Manufacturer("Lumina");
      new Characteristic::SerialNumber("LUMINA-S3-001");
      new Characteristic::Model("ESP32S3-N16R8");
      new Characteristic::FirmwareRevision("1.0.0");
    new BuiltInLamp(LED_PIN);

  Serial.println("\n=== HomeKit Lamp Ready ===");
}

void loop() {
  homeSpan.poll();
}

