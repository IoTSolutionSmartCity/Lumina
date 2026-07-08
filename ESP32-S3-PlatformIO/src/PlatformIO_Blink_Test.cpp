/*
  Lumina PlatformIO HomeKit bring-up test for ESP32S3-N16R8

  - Pairs to Apple Home via HomeSpan
  - Controls the board built-in LED (GPIO 48) with PWM
  - Use this to verify Home app power, brightness, and color before wiring RGBW MOSFETs

  Note: the built-in LED is a single white LED, so Home app color changes are mapped
  to perceived brightness rather than true RGB color.

  Build with environment: esp32s3_n16r8_test
*/

#include <Arduino.h>
#include <esp_arduino_version.h>
#include "HomeSpan.h"
#include "LuminaWifi.h"

// ESP32-S3 Arduino core defines LED_BUILTIN as 97 on many boards, which is not a
// valid GPIO for LEDC. The onboard LED on ESP32S3-N16R8 is GPIO 48.
#define LED_PIN 48

// Update these to match your 2.4 GHz Wi-Fi network before uploading.
#ifndef WIFI_SSID
  #define WIFI_SSID "IoTSwitch"
#endif

#ifndef WIFI_PASSWORD
  #define WIFI_PASSWORD "88888888"
#endif

// BOOT/0 button on most ESP32-S3 boards. Used to enter HomeKit pairing mode.
#define CONTROL_BUTTON_PIN 0

#define LED_ACTIVE_LOW 0

#define PWM_FREQ_HZ 5000
#define PWM_RESOLUTION_BITS 12
#define PWM_MAX_DUTY ((1 << PWM_RESOLUTION_BITS) - 1)
#define BUILTIN_LED_CHANNEL 0

void printBoardInfo() {
  Serial.println("\n=== Lumina PlatformIO HomeKit Test ===");
  Serial.printf("Chip model: %s\n", ESP.getChipModel());
  Serial.printf("CPU frequency: %u MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Flash size: %u bytes\n", ESP.getFlashChipSize());
  Serial.printf("PSRAM found: %s\n", psramFound() ? "yes" : "no");

  if (psramFound()) {
    Serial.printf("PSRAM size: %u bytes\n", ESP.getPsramSize());
    Serial.printf("Free PSRAM: %u bytes\n", ESP.getFreePsram());
  }

  Serial.printf("Free heap: %u bytes\n", ESP.getFreeHeap());
  Serial.printf("Built-in LED pin: GPIO %d (PWM dimming)\n", LED_PIN);
  Serial.printf("Wi-Fi target: %s\n", WIFI_SSID);
  Serial.println("Pairing code: 46637726");
  Serial.println("Hold BOOT/0 button for 5 seconds to enter HomeKit pairing mode.");
  Serial.println("=====================================\n");
}

void attachBuiltInLedPwm() {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  if (!ledcAttach(LED_PIN, PWM_FREQ_HZ, PWM_RESOLUTION_BITS)) {
    Serial.printf("Failed to attach PWM on GPIO %d\n", LED_PIN);
  }
#else
  ledcSetup(BUILTIN_LED_CHANNEL, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
  ledcAttachPin(LED_PIN, BUILTIN_LED_CHANNEL);
#endif
}

void writeBuiltInLedPwm(uint16_t duty) {
  if (duty > PWM_MAX_DUTY) {
    duty = PWM_MAX_DUTY;
  }

  if (LED_ACTIVE_LOW) {
    duty = PWM_MAX_DUTY - duty;
  }

#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(LED_PIN, duty);
#else
  ledcWrite(BUILTIN_LED_CHANNEL, duty);
#endif
}

uint16_t dutyFromFloat(float value) {
  value = constrain(value, 0.0f, 1.0f);
  return static_cast<uint16_t>(roundf(value * PWM_MAX_DUTY));
}

void hsvToRgb(float hue, float saturation, float value, float &red, float &green, float &blue) {
  hue = fmodf(hue, 360.0f);
  if (hue < 0.0f) {
    hue += 360.0f;
  }

  saturation = constrain(saturation, 0.0f, 1.0f);
  value = constrain(value, 0.0f, 1.0f);

  if (saturation <= 0.0f) {
    red = value;
    green = value;
    blue = value;
    return;
  }

  float chroma = value * saturation;
  float huePrime = hue / 60.0f;
  float x = chroma * (1.0f - fabsf(fmodf(huePrime, 2.0f) - 1.0f));
  float match = value - chroma;

  if (huePrime < 1.0f) {
    red = chroma;
    green = x;
    blue = 0.0f;
  } else if (huePrime < 2.0f) {
    red = x;
    green = chroma;
    blue = 0.0f;
  } else if (huePrime < 3.0f) {
    red = 0.0f;
    green = chroma;
    blue = x;
  } else if (huePrime < 4.0f) {
    red = 0.0f;
    green = x;
    blue = chroma;
  } else if (huePrime < 5.0f) {
    red = x;
    green = 0.0f;
    blue = chroma;
  } else {
    red = chroma;
    green = 0.0f;
    blue = x;
  }

  red += match;
  green += match;
  blue += match;
}

float perceivedLuminance(float red, float green, float blue) {
  return (0.2126f * red) + (0.7152f * green) + (0.0722f * blue);
}

class BuiltInHomeKitLamp : public Service::LightBulb {
  private:
    SpanCharacteristic *power;
    SpanCharacteristic *brightness;
    SpanCharacteristic *hue;
    SpanCharacteristic *saturation;

    int currentBrightness() {
      return brightness->updated() ? brightness->getNewVal() : brightness->getVal();
    }

    float currentHue() {
      return hue->updated() ? hue->getNewVal() : hue->getVal();
    }

    float currentSaturation() {
      return saturation->updated() ? saturation->getNewVal() : saturation->getVal();
    }

    bool currentPower() {
      return power->updated() ? power->getNewVal() : power->getVal();
    }

    void applyState() {
      bool isOn = currentPower();
      int brightnessPercent = constrain(currentBrightness(), 0, 100);
      float hueDegrees = currentHue();
      float saturationPercent = constrain(currentSaturation(), 0.0f, 100.0f);
      float value = isOn ? brightnessPercent / 100.0f : 0.0f;

      float red = 0.0f;
      float green = 0.0f;
      float blue = 0.0f;
      hsvToRgb(hueDegrees, saturationPercent / 100.0f, value, red, green, blue);

      float ledLevel = isOn ? perceivedLuminance(red, green, blue) : 0.0f;
      uint16_t duty = dutyFromFloat(ledLevel);
      writeBuiltInLedPwm(duty);

      Serial.printf(
        "HomeKit built-in LED: power=%s brightness=%d hue=%.1f saturation=%.1f pwm=%u\n",
        isOn ? "ON" : "OFF",
        brightnessPercent,
        hueDegrees,
        saturationPercent,
        duty
      );
    }

  public:
    BuiltInHomeKitLamp() : Service::LightBulb() {
      power = new Characteristic::On(false);
      brightness = new Characteristic::Brightness(100);
      hue = new Characteristic::Hue(0);
      saturation = new Characteristic::Saturation(0);
      new Characteristic::Name("Lumina Built-in LED");

      attachBuiltInLedPwm();
      applyState();
    }

    boolean update() override {
      applyState();
      return true;
    }
};

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 5000) delay(10);  // wait for USB-CDC monitor, cap so headless boots don't hang
  printBoardInfo();

  homeSpan.setPairingCode("46637726");
  homeSpan.setControlPin(CONTROL_BUTTON_PIN);
  homeSpan.setWifiCredentials(WIFI_SSID, WIFI_PASSWORD);
  homeSpan.setConnectionCallback(LuminaWifi::onConnection);
  homeSpan.setLogLevel(1);

  homeSpan.begin(Category::Lighting, "Lumina ESP32S3 Lamp");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
      new Characteristic::Name("Lumina Built-in LED");
      new Characteristic::Manufacturer("Lumina");
      new Characteristic::SerialNumber("LUMINA-S3-TEST");
      new Characteristic::Model("ESP32S3-N16R8");
      new Characteristic::FirmwareRevision("1.1.0-test");
    new BuiltInHomeKitLamp();

  Serial.println("HomeKit test ready.");
  Serial.println("1) Wait until serial shows Wi-Fi connected.");
  Serial.println("2) iPhone must use the same 2.4 GHz Wi-Fi network.");
  Serial.println("3) Home app -> Add Accessory -> enter code 466-37-726.");
  Serial.println("4) If not found, hold BOOT button 5 sec, then search again.");
}

void loop() {
  homeSpan.poll();
}
