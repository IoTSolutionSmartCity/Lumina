/*
  Lumina ESP32-S3 HomeKit RGBW Lamp
  - Pairs to Apple Home via HomeSpan
  - Exposes one color LightBulb accessory
  - Drives four external 12 V RGBW channels with PWM MOSFET stages
  - Keeps the built-in LED as a simple on/off status indicator
*/

#include <Arduino.h>
#include <esp_arduino_version.h>
#include "HomeSpan.h"

// ---- Board LED configuration ----
// GPIO 48 is common for the ESP32-S3 built-in RGB/status LED on many boards.
#ifndef LED_PIN
  #ifdef LED_BUILTIN
    #define LED_PIN LED_BUILTIN
  #else
    #define LED_PIN 48
  #endif
#endif

#define LED_ACTIVE_LOW 0

// ---- External RGBW lamp PWM pins ----
// Confirm these against your exact ESP32-S3-N16R8 board before wiring.
// Avoid boot strap pins, USB pins, flash/PSRAM pins, and GPIO 48.
#ifndef PWM_R_PIN
  #define PWM_R_PIN 4
#endif

#ifndef PWM_G_PIN
  #define PWM_G_PIN 5
#endif

#ifndef PWM_B_PIN
  #define PWM_B_PIN 6
#endif

#ifndef PWM_W_PIN
  #define PWM_W_PIN 7
#endif

#define PWM_FREQ_HZ 5000
#define PWM_RESOLUTION_BITS 12
#define PWM_MAX_DUTY ((1 << PWM_RESOLUTION_BITS) - 1)

#define PWM_R_CHANNEL 0
#define PWM_G_CHANNEL 1
#define PWM_B_CHANNEL 2
#define PWM_W_CHANNEL 3

struct PwmOutput {
  uint8_t pin;
  uint8_t channel;
};

const PwmOutput RED_OUTPUT = { PWM_R_PIN, PWM_R_CHANNEL };
const PwmOutput GREEN_OUTPUT = { PWM_G_PIN, PWM_G_CHANNEL };
const PwmOutput BLUE_OUTPUT = { PWM_B_PIN, PWM_B_CHANNEL };
const PwmOutput WHITE_OUTPUT = { PWM_W_PIN, PWM_W_CHANNEL };

void attachPwmOutput(const PwmOutput &output) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcAttachChannel(output.pin, PWM_FREQ_HZ, PWM_RESOLUTION_BITS, output.channel);
#else
  ledcSetup(output.channel, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
  ledcAttachPin(output.pin, output.channel);
#endif
}

void writePwmOutput(const PwmOutput &output, uint16_t duty) {
  if (duty > PWM_MAX_DUTY) {
    duty = PWM_MAX_DUTY;
  }

#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(output.pin, duty);
#else
  ledcWrite(output.channel, duty);
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

class RgbwLamp : public Service::LightBulb {
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

    void setStatusLed(bool on) {
      if (LED_ACTIVE_LOW) {
        digitalWrite(LED_PIN, on ? LOW : HIGH);
      } else {
        digitalWrite(LED_PIN, on ? HIGH : LOW);
      }
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

      // Extract shared white content for the physical W channel.
      float white = min(red, min(green, blue));
      red -= white;
      green -= white;
      blue -= white;

      writePwmOutput(RED_OUTPUT, dutyFromFloat(red));
      writePwmOutput(GREEN_OUTPUT, dutyFromFloat(green));
      writePwmOutput(BLUE_OUTPUT, dutyFromFloat(blue));
      writePwmOutput(WHITE_OUTPUT, dutyFromFloat(white));
      setStatusLed(isOn);

      Serial.printf(
        "HomeKit RGBW: power=%s brightness=%d hue=%.1f saturation=%.1f duty[R=%u G=%u B=%u W=%u]\n",
        isOn ? "ON" : "OFF",
        brightnessPercent,
        hueDegrees,
        saturationPercent,
        dutyFromFloat(red),
        dutyFromFloat(green),
        dutyFromFloat(blue),
        dutyFromFloat(white)
      );
    }

  public:
    RgbwLamp() : Service::LightBulb() {
      power = new Characteristic::On(false);
      brightness = new Characteristic::Brightness(100);
      hue = new Characteristic::Hue(0);
      saturation = new Characteristic::Saturation(0);
      new Characteristic::Name("Lumina RGBW Lamp");

      pinMode(LED_PIN, OUTPUT);
      attachPwmOutput(RED_OUTPUT);
      attachPwmOutput(GREEN_OUTPUT);
      attachPwmOutput(BLUE_OUTPUT);
      attachPwmOutput(WHITE_OUTPUT);
      applyState();
    }

    boolean update() override {
      applyState();
      return true;
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);

  homeSpan.setPairingCode("46637726");
  homeSpan.setWifiCredentials("Wong", "93484972a");
  homeSpan.setLogLevel(1);

  homeSpan.begin(Category::Lighting, "Lumina ESP32S3 Lamp");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
      new Characteristic::Name("Lumina RGBW Lamp");
      new Characteristic::Manufacturer("Lumina");
      new Characteristic::SerialNumber("LUMINA-S3-001");
      new Characteristic::Model("ESP32S3-N16R8");
      new Characteristic::FirmwareRevision("1.1.0");
    new RgbwLamp();

  Serial.println("\n=== HomeKit RGBW Lamp Ready ===");
  Serial.printf("RGBW PWM pins: R=%d G=%d B=%d W=%d, frequency=%d Hz, resolution=%d bits\n",
                PWM_R_PIN, PWM_G_PIN, PWM_B_PIN, PWM_W_PIN, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
}

void loop() {
  homeSpan.poll();
}
