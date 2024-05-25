// sketch.ino

#include <Arduino.h>
#include <Wire.h>
#include <esp_log.h>


/////////////////////////////////////////////////////////////////////////////
// constants etc.

// Serial speed /////////////////////////////////////////////////////////////
#define SERIAL_SPEED 115200

// LEDs, ordered accoding to the 9 LEDs board layout
uint8_t ledPins[] = {
  18, // A0, was 26
  17, // A1, was 25
  12, // was 21
   8, // A5, was  4
  11, // was 27
  10, // was 33
   9, // was 15
   6, // was 32
   5, // was 14
};
uint8_t numLedPins = sizeof(ledPins) / sizeof(uint8_t);

// blink internal LED
void blinkFeatherLED(uint8_t times);


/////////////////////////////////////////////////////////////////////////////
// utilities

// delay/yield macros
#define WAIT_A_SEC   vTaskDelay(    1000/portTICK_PERIOD_MS); // 1 second
#define WAIT_SECS(n) vTaskDelay((n*1000)/portTICK_PERIOD_MS); // n seconds
#define WAIT_MS(n)   vTaskDelay(       n/portTICK_PERIOD_MS); // n millis

int firmwareVersion = 100; // used to check for updates
#define ECHECK ESP_ERROR_CHECK_WITHOUT_ABORT

// IDF logging
static const char *TAG = "main";


/////////////////////////////////////////////////////////////////////////////
// arduino-land entry points

void setup() {
  Serial.begin(SERIAL_SPEED);
  Serial.printf("Serial initialised at %d\n", SERIAL_SPEED);
  esp_log_level_set("*", ESP_LOG_ERROR); // IDF logging

  pinMode(LED_BUILTIN, OUTPUT);          // turn built-in LED on

  for(int i = 0; i < numLedPins; i++) {
    pinMode(ledPins[i], OUTPUT);         // set up the external LED pins
    digitalWrite(ledPins[i], LOW);       // off to begin
  }

  delay(300);
  blinkFeatherLED(5);                    // signal we've finished config
  delay(500);
} // setup

uint32_t loopIndex = 0;
void loop() {
  Serial.printf("starting loop %2d\n", loopIndex++);

  for(int i = 0; i < numLedPins; i++) {
    digitalWrite(ledPins[i], HIGH);
    delay(300);
    digitalWrite(ledPins[i], LOW);
    delay(300);
  }
} // loop


/////////////////////////////////////////////////////////////////////////////
// misc utils ///////////////////////////////////////////////////////////////

void blinkFeatherLED(uint8_t times) {
  for(int i=0; i<times; i++) {
    digitalWrite(LED_BUILTIN, LOW);
    delay(300);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(300);
  }
}
