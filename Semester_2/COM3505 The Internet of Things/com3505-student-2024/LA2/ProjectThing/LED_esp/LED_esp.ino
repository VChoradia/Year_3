#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>

const char *ssid = "uos-other";
const char *password = "shefotherkey05";

const int LED_PIN = 13;

AsyncWebServer server(80);

void setup() {
  Serial.begin(115200);

  pinMode(LED_PIN, OUTPUT); 

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  
  Serial.println("Connected to WiFi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  // Route for turning lights on
  server.on("/lightson", HTTP_GET, [](AsyncWebServerRequest *request) {
    digitalWrite(LED_PIN, HIGH); 
    request->send(200, "text/plain", "Lights turned on");
  });

  // Route for turning lights off
  server.on("/lightsoff", HTTP_GET, [](AsyncWebServerRequest *request) {
    digitalWrite(LED_PIN, LOW); 
    request->send(200, "text/plain", "Lights turned off");
  });

  server.begin();
}

void loop() {}
