// main.cpp

#include "sketch.h"
#include <Arduino.h>

void setup() {
  Serial.begin(115200);

  pinMode(32, OUTPUT); // set up pin 32 as a digital output
  pinMode(14, INPUT_PULLUP); // pin 14: digital input, built-in pullup resistor

  printf("\nahem, hello world\n");
} // setup

bool flashTheLED = false;
void loop() {
  if(digitalRead(14) == LOW) { // switch pressed
    Serial.printf("switch is pressed...\n");
    delay(200); // debounce: avoid registering another press immediately
    flashTheLED = ! flashTheLED;
  }

  if(flashTheLED) {
    Serial.printf("setting 32 HIGH...\n");
    digitalWrite(32, HIGH);       // on...
    delay(500); // take a rest (but: what happens if switch pressed now?!)

    Serial.printf("setting 32 LOW...\n");
    digitalWrite(32, LOW);        // off...
    delay(500); // take a rest (but: what happens if switch pressed now?!)
  }
} // loop
