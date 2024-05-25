// main.cpp: interrupts, timers, tasks

#include "sketch.h"
#include <Arduino.h>

uint8_t SWITCH_PIN = 14, LED_PIN = 32; // which GPIO we're using
static void eventsSetup(); // declare interrupts config routine
static bool flashTheLED = false; // when true flash the external LED

// comment this out to use digitalRead on the switch instead
#define USE_INTERRUPTS

void setup() {
  Serial.begin(115200);
  printf("\nahem, hello world\n");
  pinMode(LED_PIN, OUTPUT); // set up LED pion as a digital output

#ifdef USE_INTERRUPTS
  eventsSetup(); // deal with interrupt events
#else
  pinMode(SWITCH_PIN, INPUT_PULLUP); // digital input, built-in pullup
#endif
} // setup

void loop() {
#ifndef USE_INTERRUPTS
  if(digitalRead(SWITCH_PIN) == LOW) { // switch pressed
    Serial.printf("switch is pressed...\n");
    flashTheLED = ! flashTheLED;
    delay(100); // debounce: avoid registering another press immediately
  }
#endif

  if(flashTheLED) {
    Serial.printf("setting 32 HIGH...\n");
    digitalWrite(LED_PIN, HIGH);       // on...
    delay(500);
    Serial.printf("setting 32 LOW...\n");
    digitalWrite(LED_PIN, LOW);        // off...
    delay(500);
  }
} // loop

// gpio interrupt events
static void IRAM_ATTR gpio_isr_handler(void *arg) { // switch press handler
  uint32_t gpio_num = (uint32_t) arg;
  flashTheLED = ! flashTheLED;
}
static void eventsSetup() {
  // configure the switch pin (INPUT, falling edge interrupts)
  gpio_config_t io_conf;                        // params for switches
  io_conf.mode = GPIO_MODE_INPUT;               // set as input mode
  io_conf.pin_bit_mask = 1ULL << SWITCH_PIN;    // bit mask of pin(s) to set
  io_conf.pull_up_en = GPIO_PULLUP_DISABLE;     // disable pull-up mode
  io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE; // disable pull-down mode
  io_conf.intr_type = GPIO_INTR_NEGEDGE;        // interrupt on falling edge
  (void) gpio_config(&io_conf);                 // do the configuration

  // install gpio isr service & hook up isr handlers
  gpio_install_isr_service(0); // prints an error if already there; ignore!
  gpio_isr_handler_add(        // attach the handler
    (gpio_num_t) SWITCH_PIN, gpio_isr_handler, (void *) SWITCH_PIN
  );
}

// if we're an IDF build define app_main
#if ! defined(ARDUINO_IDE_BUILD) && ! defined(PLATFORMIO)
  extern "C" { void app_main(); }
  void app_main() {
    initArduino();
    setup();
    while(1) loop();
  } // app_main()
#endif
