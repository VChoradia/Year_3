// main.cpp

// OTA support //////////////////////////////////////////////////////////////
int firmwareVersion = 101;    // keep up-to-date! (used to check for updates)

/////////////////////////////////////////////////////////////////////////////
// libraries

#include "sketch.h"
#include <Arduino.h>
#include <Wire.h>
#include <esp_log.h>
#include <ESPAsyncWebServer.h>
#include "joinme-2021.h"
#include "private.h" // not for pushing; assumed to be at parent dir level

// initialise and run a touch sensor on T6
extern "C" void run_t6_touch_sensor();

// MAC address //////////////////////////////////////////////////////////////
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator
void getMAC(char *);

// LED utilities, loop slicing //////////////////////////////////////////////
void ledOn();
void ledOff();
void blink(int = 1, int = 300);
int loopIteration = 0;

// globals for a wifi access point and webserver ////////////////////////////
String apSSID = String("ProUpdThing-"); // SSID of the AP
String apPassword = _DEFAULT_AP_KEY;    // passkey for the AP


/////////////////////////////////////////////////////////////////////////////
// if we're an IDF build define app_main
#if ! defined(ARDUINO_IDE_BUILD) && ! defined(PLATFORMIO)
  extern "C" { void app_main(); }

  // main entry point
  void app_main() {
    // arduino land
    initArduino();
    setup();
    while(1)
      loop();
  } // app_main()

#endif


/////////////////////////////////////////////////////////////////////////////
// SETUP: initialisation entry point ////////////////////////////////////////
void setup() {
  Serial.begin(115200);         // initialise the serial line
  Serial.printf("Hello from ProUpdThing...\n");
  dbf(startupDBG, "looks like another %s day :)", "fine");
  getMAC(MAC_ADDRESS);          // store the MAC address
  apSSID.concat(MAC_ADDRESS);   // add the MAC to the AP SSID
  Serial.printf("\nsetup...\nESP32 MAC = %s\n", MAC_ADDRESS);
  pinMode(BUILTIN_LED, OUTPUT); // set up GPIO pin for built-in LED
  pinMode(32, OUTPUT); // set up pin 32 as a digital output (external LED)
  pinMode(14, INPUT_PULLUP);    // pin 14: digital input, use pullup (switch)

  // the access point and network joining webserver stuff from Ex09
  blink(3);             // blink the on-board LED to say "hi"
  Serial.printf("doing wifi manager\n");
  webServer = joinmeManageWiFi(apSSID.c_str(), apPassword.c_str()); // connect
  Serial.printf("wifi manager done\n\n");

  // check for and perform firmware updates as needed
  Serial.printf("firmware is at version %d\n", firmwareVersion);
  vTaskDelay(2000 / portTICK_PERIOD_MS); // let wifi settle
  joinmeOTAUpdate(
    firmwareVersion, _GITLAB_PROJ_ID,
    // "", // for publ repo "" works, else need valid PAT: _GITLAB_TOKEN,
    _GITLAB_TOKEN,
    "exercises%2FProUpdThing%2Ffirmware%2F"
  );

  delay(300); blink(3);         // signal we've finished config
  printf("\n"); delay(500); printf("\n");

  run_t6_touch_sensor();
}


/////////////////////////////////////////////////////////////////////////////
// LOOP: task entry point ///////////////////////////////////////////////////
void loop() {
  int sliceSize = 500;

  // TODO: add this for touch
  // Serial.printf("%d\n", touchRead(T6)); // check and print touch on pin 14

  if(loopIteration++ % sliceSize == 0) { // every sliceSize iterations
    dln(otaDBG, "OTA loop");
    printIPs();
  }
  vTaskDelay(100 / portTICK_PERIOD_MS); // 100 is min to allow IDLE on core 0
}


/////////////////////////////////////////////////////////////////////////////
// misc utilities ///////////////////////////////////////////////////////////
// get the ESP's MAC address
void getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion...
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed
  for(int i=0, j=11; i<=10; i+=2, j-=2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
}
void printIPs() {
  dbg(startupDBG, "AP SSID: ");
  dbg(startupDBG, apSSID);
  dbg(startupDBG, "; IP address(es): local=");
  dbg(startupDBG, WiFi.localIP());
  dbg(startupDBG, "; AP=");
  dln(startupDBG, WiFi.softAPIP());
}

// LED blinkers
void ledOn()  { digitalWrite(BUILTIN_LED, HIGH); }
void ledOff() { digitalWrite(BUILTIN_LED, LOW); }
void blink(int times, int pause) {
  ledOff();
  for(int i=0; i<times; i++) {
    ledOn(); delay(pause); ledOff(); delay(pause);
  }
}
