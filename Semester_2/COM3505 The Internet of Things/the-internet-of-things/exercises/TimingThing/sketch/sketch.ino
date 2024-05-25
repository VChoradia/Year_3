// sketch.ino: an example of using interrupts

#include <Arduino.h>

uint8_t SWITCH_PIN = 5, LED_PIN = 6; // which GPIO we're using (S3)
// for ESP32 Feather: uint8_t SWITCH_PIN = 14, LED_PIN = 32;
static void eventsSetup(); // declare interrupts config routine
static bool flashTheLED = false; // when true flash the external LED

void setup() {
  Serial.begin(115200);
  printf("\nahem, hello world\n");
  pinMode(LED_PIN, OUTPUT); // set up LED pion as a digital output

  eventsSetup(); // deal with interrupt events
} // setup

void loop() {
  if(flashTheLED) {
    Serial.printf("setting %u HIGH...\n", LED_PIN);
    digitalWrite(LED_PIN, HIGH);       // on...
    delay(500); // how would you avoid this?
    Serial.printf("setting %u LOW...\n", LED_PIN);
    digitalWrite(LED_PIN, LOW);        // off...
    delay(500); // hint: see chapter 7 on timers :)
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
  io_conf.pull_up_en = GPIO_PULLUP_ENABLE;      // enable pull-up mode
  io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE; // disable pull-down mode
  io_conf.intr_type = GPIO_INTR_NEGEDGE;        // interrupt on falling edge
  (void) gpio_config(&io_conf);                 // do the configuration

  // install gpio isr service & hook up isr handlers
  gpio_install_isr_service(0); // prints an error if already there; ignore!
  gpio_isr_handler_add(        // attach the handler
    (gpio_num_t) SWITCH_PIN, gpio_isr_handler, (void *) SWITCH_PIN
  );
}
