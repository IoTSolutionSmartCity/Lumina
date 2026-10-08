/*
  Circuit test. No HomeSpan.
  GPIO3 red, GPIO4 blue, GPIO5 green.
  First each pin is held solid HIGH (no PWM). Then the same pins PWM.
  Serial Monitor: 115200.
*/

#include <Arduino.h>
#include <esp_arduino_version.h>

#define PWM_R_PIN 3
#define PWM_B_PIN 4
#define PWM_G_PIN 5
#define PWM_FREQ_HZ 1000
#define PWM_BITS 8
#define PWM_MAX ((1 << PWM_BITS) - 1)

const uint8_t pins[] = { PWM_R_PIN, PWM_B_PIN, PWM_G_PIN };
const uint8_t channels[] = { 0, 1, 2 };
const char *names[] = { "RED GPIO3", "BLUE GPIO4", "GREEN GPIO5" };

void attachPwm(uint8_t pin, uint8_t channel) {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  if (!ledcAttachChannel(pin, PWM_FREQ_HZ, PWM_BITS, channel)) {
    Serial.printf("PWM attach failed on GPIO %u\n", pin);
  }
#else
  ledcSetup(channel, PWM_FREQ_HZ, PWM_BITS);
  ledcAttachPin(pin, channel);
#endif
}

void writePwm(uint8_t pin, uint8_t channel, uint8_t level) {
  uint32_t duty = (uint32_t)level * PWM_MAX / 255;
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(pin, duty);
#else
  ledcWrite(channel, duty);
#endif
}

void allLow() {
  for (uint8_t pin : pins) {
    digitalWrite(pin, LOW);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  for (uint8_t pin : pins) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }
  Serial.println("RGB circuit test running");
}

void loop() {
  Serial.println("--- solid HIGH, meter the gate: it must be 3.3 V ---");
  for (int i = 0; i < 3; i++) {
    allLow();
    digitalWrite(pins[i], HIGH);
    Serial.printf("%s HIGH\n", names[i]);
    delay(2000);
  }

  allLow();
  Serial.println("ALL HIGH");
  for (uint8_t pin : pins) {
    digitalWrite(pin, HIGH);
  }
  delay(2000);
  allLow();

  for (int i = 0; i < 3; i++) {
    attachPwm(pins[i], channels[i]);
  }

  Serial.println("--- PWM ---");
  const uint8_t levels[][3] = {
    {255, 0, 0},
    {0, 255, 0},
    {0, 0, 255},
    {255, 255, 255},
  };
  const char *labels[] = { "PWM RED", "PWM BLUE", "PWM GREEN", "PWM WHITE" };
  for (int s = 0; s < 4; s++) {
    for (int i = 0; i < 3; i++) {
      writePwm(pins[i], channels[i], levels[s][i]);
    }
    Serial.println(labels[s]);
    delay(2000);
  }
}
