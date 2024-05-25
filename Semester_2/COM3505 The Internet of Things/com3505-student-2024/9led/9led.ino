
bool useInternalLED = true; // which LED to blink
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator

// pin definitions
// changes from ESP32 Feather to ESP32S3: pin 32 becomes 6, 14 becomes 5

#define PIN1  A3
#define PIN2  A2
#define PIN3  9
#define PIN4  10
#define PIN5  11
#define PIN6  12
#define PIN7  13
#define PIN8  A4
#define PIN9  A5


void macro_prints(); // print some helpful macros

void setup() {
  //  setup(); // include previous setup for serial, and for the internal LED
  Serial.begin(115200);           // initialise the serial line
  getMAC(MAC_ADDRESS);            // store the MAC address as a chip identifier
  pinMode(LED_BUILTIN, OUTPUT);   // set up GPIO pin for built-in LED
  Serial.println("\nsetup01..."); // say hi
  Serial.printf("\nsetup02...\nESP32 MAC = %s\n", MAC_ADDRESS); // ESP's "ID"

  // set up GPIO pin for an external LED
  pinMode(PIN1, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN2, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN3, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN4, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN5, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN6, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN7, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN8, OUTPUT); // set up LED pin as a digital output
  pinMode(PIN9, OUTPUT); // set up LED pin as a digital output

//  // set up GPIO pin for a switch
//  pinMode(SWITCH_PIN, INPUT_PULLUP); // digital in, built-in pullup resistor

  macro_prints();
}

void getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion...
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed relative to normal Arduino
  for (int i = 0, j = 11; i <= 10; i += 2, j -= 2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
}

void ledOn()  {
  digitalWrite(LED_BUILTIN, HIGH);
}
void ledOff() {
  digitalWrite(LED_BUILTIN, LOW);
}

void blink(int times, int pause) {
  ledOff();
  for (int i = 0; i < times; i++) {
    ledOn(); delay(pause); ledOff(); delay(pause);
  }
}


void loop() {
    digitalWrite(PIN1, HIGH);       // on...
    digitalWrite(PIN2, HIGH);       // on...
    digitalWrite(PIN3, HIGH);       // on...
    digitalWrite(PIN4, HIGH);       // on...
    digitalWrite(PIN5, HIGH);       // on...
    digitalWrite(PIN6, HIGH);       // on...
    digitalWrite(PIN7, HIGH);       // on...
    digitalWrite(PIN8, HIGH);       // on...
    digitalWrite(PIN9, HIGH);       // on...
}

// some helpful macro printouts from ../HelloWorld
void macro_prints() {
#ifdef ESP_IDF_VERSION_MAJOR
  Serial.printf( // IDF version
    "IDF version: %d.%d.%d\n",
    ESP_IDF_VERSION_MAJOR, ESP_IDF_VERSION_MINOR, ESP_IDF_VERSION_PATCH
  );
#endif
#ifdef ESP_ARDUINO_VERSION_MAJOR
  Serial.printf(
    "ESP_ARDUINO_VERSION_MAJOR=%d; MINOR=%d; PATCH=%d\n",
    ESP_ARDUINO_VERSION_MAJOR, ESP_ARDUINO_VERSION_MINOR,
    ESP_ARDUINO_VERSION_PATCH
  );
#endif
#ifdef ARDUINO_FEATHER_ESP32
  Serial.printf("ARDUINO_FEATHER_ESP32 is defined\n");
#endif
#ifdef ARDUINO_ARCH_ESP32
  Serial.printf("ARDUINO_ARCH_ESP32 is defined\n");
#endif
#if CONFIG_IDF_TARGET_ESP32
  Serial.printf("CONFIG_IDF_TARGET_ESP32\n");
#endif
#if CONFIG_IDF_TARGET_ESP32S3
  Serial.printf("CONFIG_IDF_TARGET_ESP32S3\n");
#endif
#ifdef ESP_PLATFORM
  Serial.printf("ESP_PLATFORM is defined\n");
#endif
#ifdef ESP32
  Serial.printf("ESP32 is defined\n");
#endif
#ifdef IDF_VER
  Serial.printf("IDF_VER=%s\n", IDF_VER);
#endif
#ifdef ARDUINO
  Serial.printf("ARDUINO=%d\n", ARDUINO);
#endif
#ifdef ARDUINO_BOARD
  Serial.printf("ARDUINO_BOARD=%s\n", ARDUINO_BOARD);
#endif
#ifdef ARDUINO_VARIANT
  Serial.printf("ARDUINO_VARIANT=%s\n", ARDUINO_VARIANT);
#endif
#ifdef ARDUINO_SERIAL_PORT
  Serial.printf("ARDUINO_SERIAL_PORT=%d\n", ARDUINO_SERIAL_PORT);
#endif
}
