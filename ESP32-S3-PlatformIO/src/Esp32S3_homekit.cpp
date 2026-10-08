/*
  Lumina ESP32-S3 HomeKit RGB Lamp
  - Bluetooth first: the Lumina app finds the lamp, sends color, then Wi-Fi
  - Saved Wi-Fi lets Apple Home / a HomePod mini pair over HomeKit
  - RGB PWM on GPIO 4, 5, and 6. There is no white channel.
  - HomeSpan still opens Lumina-Setup when no Wi-Fi is stored
*/

#include <Arduino.h>
#include <Preferences.h>
#include <esp_arduino_version.h>
#include <nvs.h>
#include "HomeSpan.h"
#include "LuminaWifi.h"
#include "SystemState.h"
#include "StatusLed.h"
#include "../../ESP32-S3-N16R8/LuminaBle.h"
#include "../../ESP32-S3-N16R8/LuminaWifiScan.h"

// ---- Onboard status LED configuration ----
// The onboard LED on ESP32S3-N16R8 is a single addressable WS2812 on GPIO 48.
// ESP32-S3 Arduino core defines LED_BUILTIN as 97 on many boards, which is not
// a valid GPIO for this purpose, so it is not used here.
#ifndef STATUS_LED_PIN
  #define STATUS_LED_PIN 48
#endif

// ---- External RGB lamp PWM pins ----
// GPIO 4 red, GPIO 5 green, GPIO 6 blue. GPIO 7 is not used.
#ifndef PWM_R_PIN
  #define PWM_R_PIN 4
#endif

#ifndef PWM_G_PIN
  #define PWM_G_PIN 5
#endif

#ifndef PWM_B_PIN
  #define PWM_B_PIN 6
#endif

#define PWM_FREQ_HZ 5000
#define PWM_RESOLUTION_BITS 12
#define PWM_MAX_DUTY ((1 << PWM_RESOLUTION_BITS) - 1)

#define PWM_R_CHANNEL 0
#define PWM_G_CHANNEL 1
#define PWM_B_CHANNEL 2

struct PwmOutput {
  uint8_t pin;
  uint8_t channel;
};

const PwmOutput RED_OUTPUT = { PWM_R_PIN, PWM_R_CHANNEL };
const PwmOutput GREEN_OUTPUT = { PWM_G_PIN, PWM_G_CHANNEL };
const PwmOutput BLUE_OUTPUT = { PWM_B_PIN, PWM_B_CHANNEL };

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

uint16_t dutyFromByte(uint8_t value) {
  return static_cast<uint16_t>((static_cast<uint32_t>(value) * PWM_MAX_DUTY) / 255);
}

void applyRgb(uint8_t red, uint8_t green, uint8_t blue) {
  writePwmOutput(RED_OUTPUT, dutyFromByte(red));
  writePwmOutput(GREEN_OUTPUT, dutyFromByte(green));
  writePwmOutput(BLUE_OUTPUT, dutyFromByte(blue));
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
      applyRgb(
        static_cast<uint8_t>(roundf(red * 255.0f)),
        static_cast<uint8_t>(roundf(green * 255.0f)),
        static_cast<uint8_t>(roundf(blue * 255.0f))
      );

      Serial.printf(
        "HomeKit RGB: power=%s brightness=%d hue=%.1f saturation=%.1f\n",
        isOn ? "ON" : "OFF",
        brightnessPercent,
        hueDegrees,
        saturationPercent
      );
    }

  public:
    RgbwLamp() : Service::LightBulb() {
      power = new Characteristic::On(false);
      brightness = new Characteristic::Brightness(100);
      hue = new Characteristic::Hue(0);
      saturation = new Characteristic::Saturation(0);
      new Characteristic::Name("Lumina Lamp");

      attachPwmOutput(RED_OUTPUT);
      attachPwmOutput(GREEN_OUTPUT);
      attachPwmOutput(BLUE_OUTPUT);
      applyState();
    }

    boolean update() override {
      applyState();
      return true;
    }
};

// Drives the onboard status LED from HomeSpan's own lifecycle status, so the
// indicator always reflects ground truth (including immediately after a
// reboot into an already-paired device) rather than a separately tracked
// state machine that could drift out of sync.
void onHomeSpanStatus(HS_STATUS status) {
  switch (status) {
    case HS_WIFI_NEEDED:
    case HS_WIFI_SCANNING:
    case HS_AP_STARTED:
    case HS_AP_CONNECTED:
      StatusLed::setState(SystemState::AP_MODE);
      break;

    case HS_WIFI_CONNECTING:
    case HS_ETH_CONNECTING:
      StatusLed::setState(SystemState::CONNECTING);
      break;

    case HS_PAIRING_NEEDED:
      StatusLed::setState(SystemState::HOMEKIT_PAIRING);
      break;

    case HS_PAIRED:
    case HS_CONNECTED:
      StatusLed::setState(SystemState::READY);
      break;

    default:
      // Transient states (Command Mode, OTA, reboot, factory reset, AP
      // teardown) intentionally leave the current pattern running so the
      // indicator doesn't flicker between unrelated states.
      break;
  }

  Serial.printf("HomeSpan status -> %s\n", homeSpan.statusString(status));
}

bool wifiCameFromApp() {
  Preferences prefs;
  prefs.begin("lumina", true);
  const bool savedByApp = prefs.getBool("appwifi", false);
  prefs.end();
  return savedByApp;
}

void markWifiFromApp() {
  Preferences prefs;
  prefs.begin("lumina", false);
  prefs.putBool("appwifi", true);
  prefs.end();
}

// HomeSpan keeps the last SSID in its own flash namespace. A normal sketch
// upload leaves that behind, so a lamp can boot straight into an old network.
void forgetLeftoverWifi() {
  nvs_handle_t wifiStore;
  if (nvs_open("WIFI", NVS_READWRITE, &wifiStore) != ESP_OK) {
    return;
  }
  nvs_erase_key(wifiStore, "WIFIDATA");
  nvs_commit(wifiStore);
  nvs_close(wifiStore);
}

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 5000) delay(10);  // wait for USB-CDC monitor, cap so headless boots don't hang

  if (!wifiCameFromApp()) {
    forgetLeftoverWifi();
    Serial.println("BLE first. Waiting for the Lumina app to send Wi-Fi.");
  }

  LuminaBle::begin();

  // Sane default until HomeSpan reports its first real status: HomeSpan
  // boots into HS_INITIAL_SETUP, which does not itself trigger the status
  // callback, and AP_MODE is the correct steady-state for a fresh device.
  StatusLed::begin(STATUS_LED_PIN);
  StatusLed::setState(SystemState::AP_MODE);

  homeSpan.setPairingCode("46637726");
  homeSpan.setControlPin(0);
  homeSpan.setConnectionCallback(LuminaWifi::onConnection);
  homeSpan.setStatusCallback(onHomeSpanStatus);
  homeSpan.setLogLevel(1);

  homeSpan.begin(Category::Lighting, "Lumina ESP32S3 Lamp");

  new SpanAccessory();
    new Service::AccessoryInformation();
      new Characteristic::Identify();
      new Characteristic::Name("Lumina Lamp");
      new Characteristic::Manufacturer("Lumina");
      new Characteristic::SerialNumber("LUMINA-S3-001");
      new Characteristic::Model("ESP32S3-N16R8");
      new Characteristic::FirmwareRevision("1.2.0");
    new RgbwLamp();

  Serial.println("\n=== HomeKit RGB Lamp Ready ===");
  Serial.printf("RGB PWM pins: R=%d G=%d B=%d, frequency=%d Hz, resolution=%d bits\n",
                PWM_R_PIN, PWM_G_PIN, PWM_B_PIN, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
}

void handleBleCommand(const LuminaProtocol::Command &command) {
  if (command.kind == LuminaProtocol::Command::wifi) {
    Serial.print("Saving Wi-Fi for HomeKit: ");
    Serial.println(command.ssid);
    markWifiFromApp();
    homeSpan.setWifiCredentials(command.ssid, command.password);
    delay(400);
    ESP.restart();
  } else if (command.kind == LuminaProtocol::Command::scan) {
    publishWifiScan();
  } else if (command.kind == LuminaProtocol::Command::color) {
    applyRgb(command.red, command.green, command.blue);
  }
}

void loop() {
  StatusLed::update();
  LuminaProtocol::Command command;
  if (LuminaBle::takeEvent(command)) {
    handleBleCommand(command);
  }
  homeSpan.poll();
}
