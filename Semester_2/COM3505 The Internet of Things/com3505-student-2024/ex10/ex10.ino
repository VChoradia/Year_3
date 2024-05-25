// Ex10.cpp/.ino
//
// OTA update from version.bin; run `python -m http.server 8000`
// to serve, and store the current revision number in "version.txt"
//
// when you bump the revision to higher than the current running number (in
// firmwareVersion) you should see an OTA update, and following restart you
// should be on the latest version

#include <Arduino.h>
// the wifi and HTTP server libraries ////////////////////////////////////////
#include <WiFi.h>
#include <WebServer.h>

#include "WiFiClientSecure.h"

#include <HTTPClient.h> // ESP32 library for making HTTP requests
#include <Update.h>     // OTA update library

extern int firmwareVersion; // used to check for updates
int doCloudGet(HTTPClient *, String);
void handleOTAProgress(size_t done, size_t total);


// debugging infrastructure; setting different DBGs true triggers prints ////
#define dbg(b, s) if(b) Serial.print(s)
#define dln(b, s) if(b) Serial.println(s)
#define startupDBG      true
#define loopDBG         true
#define monitorDBG      true
#define netDBG          true
#define miscDBG         true
#define analogDBG       true
#define otaDBG          true

extern char MAC_ADDRESS[];
//void getMAC(char *);
extern const char *boiler[];

typedef struct { int position; const char *replacement; } replacement_t;
void getHtml(String& html, const char *[], int, replacement_t [], int);
// getting the length of an array in C can be complex...
// https://stackoverflow.com/questions/37538/how-do-i-determine-the-size-of-my-array-in-c
#define ALEN(a) ((int) (sizeof(a) / sizeof(a[0]))) // only in definition scope!
#define GET_HTML(strout, boiler, repls) \
  getHtml(strout, boiler, ALEN(boiler), repls, ALEN(repls));

// globals for a wifi access point and webserver /////////////////////////////
extern String apSSID;           // SSID of the AP
extern WebServer webServer;   
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator  // a simple web server

// globals for a wifi access point and webserver /////////////////////////////
String apSSID;                  // SSID of the AP
WebServer webServer(80);        // a simple web server

extern const char* wifiSsid;
extern const char* wifiPassword;

const char* wifiSsid      = "uos-other";         // wifi AP for ESP to connect
const char* wifiPassword  = "shefotherkey05";     // wifi PSK

// what time did we start?
unsigned long firstSliceMillis;

// what time did we last run this action?
unsigned long lastSliceMillis;

void startAP() {
  apSSID = String("Thing-");
  apSSID.concat(MAC_ADDRESS);

  if(! WiFi.mode(WIFI_AP_STA))
    dln(startupDBG, "failed to set Wifi mode");
  if(! WiFi.softAP(apSSID.c_str(), "dumbpassword"))
    dln(startupDBG, "failed to start soft AP");
  printIPs();
}

void printIPs() {
  if(startupDBG) { // easier than the debug macros for multiple lines etc.
    Serial.print("AP SSID: ");
    Serial.print(apSSID);
    Serial.print("; IP address(es): local=");
    Serial.print(WiFi.localIP());
    Serial.print("; AP=");
    Serial.println(WiFi.softAPIP());
  }
  if(netDBG)
    WiFi.printDiag(Serial);
}


// a control iterator for slicing up the main loop ///////////////////////////
int loopIteration = 0;
const int LOOP_ROLLOVER = 25000000; // how many loops per action sequence


// what version of the firmware are we? (used to calculate need for updates)
// see firmwareVersion in sketch.ino
int firmwareVersion = 7; // used to check for updates, see Ex10

// IP address and port number: CHANGE THE IP ADDRESS!
#define FIRMWARE_SERVER_IP_ADDR "143.167.39.69"
#define FIRMWARE_SERVER_PORT    "8000"

// setup ////////////////////////////////////////////////////////////////////
void setup() {
  Serial.begin(115200); // initialise the serial line
  while(!Serial);
  getMAC(MAC_ADDRESS);  // store the MAC address as a chip identifier
  dln(startupDBG, "\nsetup10..."); // debug printout
  Serial.printf("running firmware is at version %d\n", firmwareVersion);
  
  // get on the network
  WiFi.begin(wifiSsid, wifiPassword);
  uint16_t connectionTries = 0;
  Serial.print("trying to connect to Wifi...");
  while(WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    if(connectionTries++ % 75 == 0) Serial.println("");
    delay(250);
  }
  delay(500); // let things settle for half a second
  Serial.println("connected :)");

  // materials for doing an HTTPS GET on github from the BinFiles/ dir
  HTTPClient http;
  int respCode;
  int highestAvailableVersion = -1;

  // read the version file from the cloud
  respCode = doCloudGet(&http, "version.txt");
  Serial.println(respCode);
  if(respCode > 0) // check response code (-ve on failure)
    highestAvailableVersion = atoi(http.getString().c_str());
  else
    Serial.printf("couldn't get version! rtn code: %d\n", respCode);
  http.end(); // free resources

  // do we know the latest version, and does the firmware need updating?
  if(respCode < 0) {
    return;
  } else if(firmwareVersion >= highestAvailableVersion) {
    Serial.printf("firmware is up to date\n");
    return;
  }

  // do a firmware update
  Serial.printf(
    "upgrading firmware from version %d to version %d\n",
    firmwareVersion, highestAvailableVersion
  );

  // do a GET for the .bin, e.g. "23.bin" when "version.txt" contains 23
  String binName = String(highestAvailableVersion);
  binName += ".bin";
  respCode = doCloudGet(&http, binName);
  int updateLength = http.getSize();

  // possible improvement: if size is improbably big or small, refuse
  if(respCode > 0 && respCode != 404) { // check response code (-ve on failure)
    Serial.printf(".bin code/size: %d; %d\n\n", respCode, updateLength);
  } else {
    Serial.printf("failed to get .bin! return code is: %d\n", respCode);
    http.end(); // free resources
    return;
  }

/*
  // debug code, checks how much we can download of the bin file, then aborts
  if(Update.begin(updateLength)) {
    Serial.printf("starting OTA may take 2-5 mins to complete...\n");
  }
  WiFiClient s = http.getStream();
  int bytesRead = 0;
  while(s.available() > 0) {
    if(s.read() == -1)
      break;
    bytesRead++;
  }
  Serial.printf("read %d bytes from stream\n", bytesRead);
  Update.abort();
  Serial.printf("OTA aborted\n");
*/

  // write the new version of the firmware to flash
  WiFiClient stream = http.getStream();
  Update.onProgress(handleOTAProgress); // print out progress
  if(Update.begin(updateLength)) {
    Serial.printf("starting OTA may take a minute or two...\n");
    Update.writeStream(stream);
    if(Update.end()) {
      Serial.printf("update done, now finishing...\n");
      Serial.flush();
      if(Update.isFinished()) {
        Serial.printf("update successfully finished; rebooting...\n\n");
        ESP.restart();
      } else {
        Serial.printf("update didn't finish correctly :(\n");
        Serial.flush();
      }
    } else {
      Serial.printf("an update error occurred, #: %d\n" + Update.getError());
      Serial.flush();
    }
  } else {
    Serial.printf("not enough space to start OTA update :(\n");
    Serial.flush();
  }
  stream.flush();
}


// loop /////////////////////////////////////////////////////////////////////
void loop() {
  int sliceSize = 500000;
  loopIteration++;
  if(loopIteration % sliceSize == 0) // a slice every sliceSize iterations
    dln(otaDBG, "OTA loop");

  webServer.handleClient(); // serve pending web requests every loop, as Ex09
}

// helper for downloading from cloud firmware server; for experimental
// purposes just use a hard-coded IP address and port (defined above)
int doCloudGet(HTTPClient *http, String fileName) {
  // build up URL from components; for example:
  // http://192.168.4.2:8000/Thing.bin
  String url =
    String("http://") + FIRMWARE_SERVER_IP_ADDR + ":" +
    FIRMWARE_SERVER_PORT + "/" + fileName;
  Serial.printf("getting %s\n", url.c_str());

  // make GET request and return the response code
  http->begin(url);
  http->addHeader("User-Agent", "ESP32");
  return http->GET();
}

// callback handler for tracking OTA progress ///////////////////////////////
void handleOTAProgress(size_t done, size_t total) {
  float progress = (float) done / (float) total;
  // dbf(otaDBG, "OTA written %d of %d, progress = %f\n", done, total, progress);

  int barWidth = 70;
  Serial.printf("[");
  int pos = barWidth * progress;
  for(int i = 0; i < barWidth; ++i) {
    if(i < pos)
      Serial.printf("=");
    else if(i == pos)
      Serial.printf(">");
    else
      Serial.printf(" ");
  }
  Serial.printf(
    "] %d %%%c", int(progress * 100.0), (progress == 1.0) ? '\n' : '\r'
  );
  // Serial.flush();
}



void getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion...
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed relative to normal Arduino
  for(int i=0, j=11; i<=10; i+=2, j-=2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
}

void getHtml( // turn array of strings & set of replacements into a String
  String& html, const char *boiler[], int boilerLen,
  replacement_t repls[], int replsLen
) {
  for(int i = 0, j = 0; i < boilerLen; i++) {
    if(j < replsLen && repls[j].position == i)
      html.concat(repls[j++].replacement);
    else
      html.concat(boiler[i]);
  }
}
