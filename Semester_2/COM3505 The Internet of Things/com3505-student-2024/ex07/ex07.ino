// Ex07.cpp/.ino
// develop simple utilities for creating web pages
#include <Arduino.h>
// the wifi and HTTP server libraries ////////////////////////////////////////
#include <WiFi.h>
#include <WebServer.h>




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

// a control iterator for slicing up the main loop ///////////////////////////
extern int loopIteration;
extern const int LOOP_ROLLOVER; // how many loops per action sequence



int loopIteration = 0;
const int LOOP_ROLLOVER = 25000000; // how many loops per action sequence

extern char MAC_ADDRESS[];
void getMAC(char *);
extern const char *boiler[];

typedef struct { int position; const char *replacement; } replacement_t;
void getHtml(String& html, const char *[], int, replacement_t [], int);
// getting the length of an array in C can be complex...
// https://stackoverflow.com/questions/37538/how-do-i-determine-the-size-of-my-array-in-c
#define ALEN(a) ((int) (sizeof(a) / sizeof(a[0]))) // only in definition scope!
#define GET_HTML(strout, boiler, repls) \
  getHtml(strout, boiler, ALEN(boiler), repls, ALEN(repls));
void handleSeven();

void startAP();
void printIPs();
void startWebServer();
void handleNotFound();
void handleRoot();
void handleHello();


// globals for a wifi access point and webserver /////////////////////////////
extern String apSSID;           // SSID of the AP
extern WebServer webServer;   
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator  // a simple web server

// globals for a wifi access point and webserver /////////////////////////////
String apSSID;                  // SSID of the AP
WebServer webServer(80);        // a simple web server


// there's a thousand ways to do this... below a version that is relatively
// simple to use and to code, based on an array of C strings that are
// concatenated into an Arduino (C++) String (so beware memory fragmentation!)
//
// the replacement_t type definition allows specification of a subset of the
// "boilerplate" strings, so we can e.g. replace only the title, or etc.
//
// note that to see the results you need to load a page at "/7", e.g. 
// http://192.168.4.1/7

const char *boiler[] = { // boilerplate: constants & pattern parts of template
  "<html><head><title>",                                                // 0
  "default title (7)",                                                  // 1
  "</title>\n",                                                         // 2
  "<meta charset='utf-8'>",                                             // 3

  // adjacent strings in C are concatenated:
  "<meta name='viewport' content='width=device-width, initial-scale=1.0'>\n"
  "<style>body{background:#FFF; color: #000; font-family: sans-serif;", // 4

  "font-size: 150%;}</style>\n",                                        // 5
  "</head><body>\n<h2>",                                                // 6
  "Welcome to Thing (again)!",                                          // 7
  "</h2>\n<p><a href='/'>Home</a>&nbsp;&nbsp;&nbsp;</p>\n",             // 8
  "</body></html>\n\n",                                                 // 9
};

void setup() {
  
  startAP();            // fire up the AP...
  startWebServer();     // ...and the web server 
  dln(startupDBG, "\nsetup07...");
  webServer.on("/7", handleSeven);
}

void loop() {
  if(! (loopIteration++ % 500000 == 0)) // a slice every 0.5m iterations
    return;
  webServer.handleClient(); // serve pending web requests every loop
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

void handleSeven() {
  dln(netDBG, "handleSeven: serving page at /7");
  replacement_t repls[] = { // the elements to replace in the boilerplate
    { 1, "a better title" },
    { 7, "Eat more green vegetables!" },
  };
  String toSend = "";
  getHtml(toSend, boiler, ALEN(boiler), repls, ALEN(repls)); // instantiate
  webServer.send(200, "text/html", toSend);
}

// startup utilities ////////////////////////////////////////////////////////
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
void startWebServer() {
  // register callbacks to handle different paths
  webServer.on("/", handleRoot);
  webServer.on("/hello", handleHello);

  // 404s...
  webServer.onNotFound(handleNotFound);

  webServer.begin();
  dln(startupDBG, "HTTP server started");
}

// HTML page creation utilities //////////////////////////////////////////////
// (we'll see a better version in Ex07!)
String getPageTop() {
  return
    "<html><head><title>COM3506 IoT [ID: " + apSSID + "]</title>\n"
    "<meta charset=\"utf-8\">"
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
    "\n<style>body{background:#FFF; color: #000; "
    "font-family: sans-serif; font-size: 150%;}</style>\n"
    "</head><body>\n"
  ;
};
String getPageBody() {
  return "<h2>Welcome to Thing!</h2>\n";
}
String getPageFooter() {
  return "\n<p><a href='/'>Home</a>&nbsp;&nbsp;&nbsp;</p></body></html>\n";
}

// webserver handler callbacks ///////////////////////////////////////////////
void handleNotFound() {
  dbg(netDBG, "URI Not Found: ");
  dln(netDBG, webServer.uri());
  webServer.send(200, "text/plain", "URI Not Found");
}
void handleRoot() {
  dln(netDBG, "serving page notionally at /");
  String toSend = getPageTop();
  toSend += getPageBody();
  toSend += getPageFooter();
  webServer.send(200, "text/html", toSend);
}
void handleHello() {
  dln(netDBG, "serving /hello");
  webServer.send(
    200,
    "text/plain",
    "Hello! Have you considered sending your lecturer a large gift today? :)\n"
  );
}
