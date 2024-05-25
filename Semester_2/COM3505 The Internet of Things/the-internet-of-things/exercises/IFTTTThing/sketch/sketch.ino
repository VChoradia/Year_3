// sketch.ino for IFTTTThing

#include <Arduino.h>
#include <Wire.h>
#include <esp_log.h>
#include <WiFi.h>
#include <WiFiMulti.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

// create a file (or link) called private.h in your sketch/ directory (next to
// this file) and copy in your IFTTT link like this:
// #define _IFTTT_KEY "my long key string"
// see https://iot.unphone.net/#coding-hints-1 for details
#include "private.h"

// if we are using an ultrasonic sensor to control tweeting uncomment:
// #define USE_ULTRASONICS
#ifdef USE_ULTRASONICS
  #include "movingAvg.h"  // https://github.com/JChristensen/movingAvg
#endif


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
// constants etc.

// Serial speed /////////////////////////////////////////////////////////////
#define SERIAL_SPEED 115200

// MAC address //////////////////////////////////////////////////////////////
char *getMAC(char *buf); // get the MAC address
extern char MAC_ADDRESS[13]; // MACs are 12 chars, plus the NULL terminator

// OTA support, WiFi ////////////////////////////////////////////////////////
const char *myName = "IFTTTThing";
WiFiMulti WiFiMulti; // manage multiple access points

// ultrasonic sensor ////////////////////////////////////////////////////////
const int LEVEL_TRIG_PIN=A0;    // probably needs updating...
const int LEVEL_ECHO_PIN=A2;    // ...for the ESP32S3
long getDistance();             // read the distance
uint32_t zeroesSinceLast = 0;
#ifdef USE_ULTRASONICS
movingAvg distanceAvg(10);      // average of the last 10 values
#endif

// blink internal LED ///////////////////////////////////////////////////////
void blinkFeatherLED(uint8_t times);

// tweet via IFTTT
void setClock();                // we need the time to check certif expiry
void doPOST(String, String);    // HTTPS POST
void iftttTweet(uint64_t, long, uint32_t, int); // IFTTT hookup


/////////////////////////////////////////////////////////////////////////////
// setup ////////////////////////////////////////////////////////////////////
void setup() {
  Wire.begin();

  Serial.begin(SERIAL_SPEED);           // init Serial
  Serial.printf("Serial initialised at %d\n", SERIAL_SPEED);
  int startTime = millis();

  getMAC(MAC_ADDRESS);                  // store the MAC
  Serial.printf("MAC address is %s\n", MAC_ADDRESS);

  esp_log_level_set("*", ESP_LOG_ERROR); // IDF logging

  // NOTE: doesn't work with hidden SSIDs; use WiFi.begin() instead for those
  /*
  // the WiFiMulti class tries multiple access points; define their SSIDs and
  // passkeys in private.h, e.g.
  //   #define _MULTI_SSID1 "my-hotspot"
  //   #define _MULTI_KEY1  "my-key"
  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(_MULTI_SSID1, _MULTI_KEY1);
  WiFiMulti.addAP(_MULTI_SSID2, _MULTI_KEY2);
  WiFiMulti.addAP(_MULTI_SSID3, _MULTI_KEY3);
  Serial.print("waiting for WiFi to connect...");
  while ((WiFiMulti.run() != WL_CONNECTED)) {
    Serial.print(".");
  }
  Serial.println(" connected");
  */
  // WiFi.begin(_UOS_OTHER_SSID, _UOS_OTHER_KEY);
  WiFi.begin(); // only works if the network details are already stored!
  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("connected");

  pinMode(LED_BUILTIN, OUTPUT);          // turn built-in LED on

#ifdef USE_ULTRASONICS
  pinMode(LEVEL_TRIG_PIN, OUTPUT);       // set up the ultrasonic...
  pinMode(LEVEL_ECHO_PIN, INPUT);        // ...sensor pins

  distanceAvg.begin();                   // init the moving average
  setClock();                            // get NTP to set the time
#endif

  blinkFeatherLED(3);                    // signal we've finished config

  int now = millis();
  iftttTweet(now - startTime, 123, 456, 789);   // send a random tweet
}


/////////////////////////////////////////////////////////////////////////////
// looooooooooooooooooooop //////////////////////////////////////////////////
uint64_t loopIteration = 0;
void loop() {

#ifdef USE_ULTRASONICS
  int gesture = 50;                     // 50 = no, 150 = yes
  long distance = getDistance();        // current sensor reading

  if(distance == 0) {                   // ignore zero readings
    zeroesSinceLast++;
  } else {
    int avg = distanceAvg.reading(distance); // add reading to moving average

    if(avg - distance > 100) {          // big deviations = "gestures"
      gesture = 150;
      Serial.printf(                    // register a gesture
        "GESTURE! distance: %4ld zeroes: %4u rolling: %4d\n",
        distance, zeroesSinceLast, avg
      );

      iftttTweet(loopIteration, distance, zeroesSinceLast, avg); // tweet it
      delay(2000);                      // don't send too many tweets!
    }

    if(false) Serial.printf(            // set true to print data for plotter
      "distance: %4ld gesture: %4d zeroes: %4u rolling: %4d\n",
      distance, gesture, zeroesSinceLast, avg
    );
    zeroesSinceLast = 0;
  }
  delay(35);                            // prevent sensor bouncing
  loopIteration++;
#endif
}


/////////////////////////////////////////////////////////////////////////////
// talk to IFTTT ////////////////////////////////////////////////////////////
void iftttTweet(
  uint64_t loopIteration, long distance, uint32_t zeroesSinceLast, int avg
) {
  // create a string describing the gesture
  char buf[1024], body[1124];
  sprintf(
    buf,
    "loop#: %4llu distance: %4ld zeroes: %4u rolling: %4d",
    loopIteration, distance, zeroesSinceLast, avg
  );
  /* twitter duplicate results seem stricter now... */
  // sprintf(
  //   body, "{ \"value1\": \"%s\", \"value2\": \"\", \"value3\": \"\" }\n", buf
  // );
  sprintf(body, "{ \"value1\": \"%4llu\" }\n", loopIteration + esp_random());
  Serial.printf("posting %s\n", body);

  String url(
    "https://maker.ifttt.com/trigger/COM3505-IFTTT-2023/json/with/key/" _IFTTT_KEY
  );
  // curl equivalent:
  // curl -X POST -H "Content-Type: application/json" -d '{"value1":"234234"}' \
  //    https://maker.ifttt.com/trigger/COM3505-IFTTT-2023/json/with/key/...

  doPOST(url, String(body));
}

void doPOST(String url, String body) {
  // the SSL certificate for ifttt.com
  // this should be the last one in the chain reported by
  // openssl s_client -connect ifttt.com:443 -showcerts
  const char *iftttRootCertif = 
    "-----BEGIN CERTIFICATE-----\n"
    "MIIEdTCCA12gAwIBAgIJAKcOSkw0grd/MA0GCSqGSIb3DQEBCwUAMGgxCzAJBgNV\n"
    "BAYTAlVTMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTIw\n"
    "MAYDVQQLEylTdGFyZmllbGQgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0\n"
    "eTAeFw0wOTA5MDIwMDAwMDBaFw0zNDA2MjgxNzM5MTZaMIGYMQswCQYDVQQGEwJV\n"
    "UzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTElMCMGA1UE\n"
    "ChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjE7MDkGA1UEAxMyU3RhcmZp\n"
    "ZWxkIFNlcnZpY2VzIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEi\n"
    "MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVDDrEKvlO4vW+GZdfjohTsR8/\n"
    "y8+fIBNtKTrID30892t2OGPZNmCom15cAICyL1l/9of5JUOG52kbUpqQ4XHj2C0N\n"
    "Tm/2yEnZtvMaVq4rtnQU68/7JuMauh2WLmo7WJSJR1b/JaCTcFOD2oR0FMNnngRo\n"
    "Ot+OQFodSk7PQ5E751bWAHDLUu57fa4657wx+UX2wmDPE1kCK4DMNEffud6QZW0C\n"
    "zyyRpqbn3oUYSXxmTqM6bam17jQuug0DuDPfR+uxa40l2ZvOgdFFRjKWcIfeAg5J\n"
    "Q4W2bHO7ZOphQazJ1FTfhy/HIrImzJ9ZVGif/L4qL8RVHHVAYBeFAlU5i38FAgMB\n"
    "AAGjgfAwge0wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0O\n"
    "BBYEFJxfAN+qAdcwKziIorhtSpzyEZGDMB8GA1UdIwQYMBaAFL9ft9HO3R+G9FtV\n"
    "rNzXEMIOqYjnME8GCCsGAQUFBwEBBEMwQTAcBggrBgEFBQcwAYYQaHR0cDovL28u\n"
    "c3MyLnVzLzAhBggrBgEFBQcwAoYVaHR0cDovL3guc3MyLnVzL3guY2VyMCYGA1Ud\n"
    "HwQfMB0wG6AZoBeGFWh0dHA6Ly9zLnNzMi51cy9yLmNybDARBgNVHSAECjAIMAYG\n"
    "BFUdIAAwDQYJKoZIhvcNAQELBQADggEBACMd44pXyn3pF3lM8R5V/cxTbj5HD9/G\n"
    "VfKyBDbtgB9TxF00KGu+x1X8Z+rLP3+QsjPNG1gQggL4+C/1E2DUBc7xgQjB3ad1\n"
    "l08YuW3e95ORCLp+QCztweq7dp4zBncdDQh/U90bZKuCJ/Fp1U1ervShw3WnWEQt\n"
    "8jxwmKy6abaVd38PMV4s/KCHOkdp8Hlf9BRUpJVeEXgSYCfOn8J3/yNTd126/+pZ\n"
    "59vPr5KW7ySaNRB6nJHGDn2Z9j8Z3/VyVOEVqQdZe4O/Ui5GjLIAZHYcSNPYeehu\n"
    "VsyuLAOQ1xk4meTKCRlb/weWsKh/NEnfVqn3sF/tM+2MR7cwA130A4w=\n"
    "-----END CERTIFICATE-----\n";

  HTTPClient https;
  if(https.begin(url, iftttRootCertif)) { // HTTPS
    https.addHeader("User-Agent", "ESP32");
    https.addHeader("Content-Type", "application/json");

    Serial.printf("[HTTPS] POST %.90s\n", url.c_str());
    Serial.printf("    len = %.6d\n", strlen(body.c_str()));
    Serial.println("=================");
    Serial.print(body.c_str());
    Serial.println("=================");

    // start connection and send HTTP header
    int httpCode = https.POST((uint8_t *) body.c_str(), strlen(body.c_str()));

    // httpCode will be negative on error
    if(httpCode > 0) {
      // HTTP header has been send and response header has been handled
      Serial.printf("[HTTPS] POST... code: %d\n", httpCode);

      // file found at server
      if(
        httpCode == HTTP_CODE_OK ||
        httpCode == HTTP_CODE_MOVED_PERMANENTLY
      ) {
        String payload = https.getString();
        Serial.println(payload);
      }
    } else {
      Serial.printf(
        "[HTTPS] POST... failed, error: %s\n",
        https.errorToString(httpCode).c_str()
      );
    }

    https.end();
  } else {
    Serial.printf("[HTTPS] Unable to connect\n");
  }
} // doPOST()

// not sure if WiFiClientSecure checks the validity date of the certificate,
// but setting clock just to be sure...
void setClock() {
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  Serial.print(F("waiting for NTP time sync: "));
  time_t nowSecs = time(nullptr);
  while (nowSecs < 8 * 3600 * 2) {
    delay(500);
    Serial.print(F("."));
    yield();
    nowSecs = time(nullptr);
  }

  Serial.println();
  struct tm timeinfo;
  gmtime_r(&nowSecs, &timeinfo);
  Serial.print(F("current time: "));
  Serial.print(asctime(&timeinfo));
}

/////////////////////////////////////////////////////////////////////////////
// read from ultrasonics ////////////////////////////////////////////////////
long getDistance() { // don't call again without e.g. 35 mS debounce delay
  long duration;
  int TIMEOUT = 15000;                          // how long to wait for pulse

  digitalWrite(LEVEL_TRIG_PIN, LOW);            // prepare for ping
  delayMicroseconds(2); // or 5?
  digitalWrite(LEVEL_TRIG_PIN, HIGH);           // start ping
  delayMicroseconds(10);                        // allow 10ms ping
  digitalWrite(LEVEL_TRIG_PIN, LOW);            // stop ping
  duration = pulseIn(LEVEL_ECHO_PIN, HIGH, TIMEOUT); // wait for response

  // distance = traveltime/2 (there and back)  x  speed of sound
  // (the speed of sound is: 343m/s = 0.0343 cm/uS = 1/29.1 cm/uS)
  return ( duration / 2 ) / 29.1; // cms
}

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
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator
char *getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion..
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed relative to normal Arduino
  for(int i=0, j=11; i<=10; i+=2, j-=2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
  return buf;
}
