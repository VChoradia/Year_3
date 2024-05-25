#ifndef WIFI_CONTROL_H
#define WIFI_CONTROL_H

#include <WiFi.h>
#include <HTTPClient.h>

// network credentials
const char* ssid = "uos-other";
const char* password = "shefotherkey05";

// Adapted from COM 3505 Internet of Things Weekly Lab Solutions authored by Prof. Hamish Cunningham
void setupWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi!");
  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to WiFi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  String payload = "{\"mac_address\":\"" + WiFi.macAddress() + "\",";
  payload += "\"ip_address\":\"" + WiFi.localIP().toString() + "\",";
  payload += "\"passkey\":\""+devicePasskey+ "\",";
  payload += "\"nickname\":\"" + deviceNickname + "\"}";

  HTTPClient http;
  
  http.begin("http://143.167.36.42:5500/add-new-device");
  http.addHeader("Content-Type", "application/json");

  int httpResponseCode = http.POST(payload);

  if(httpResponseCode>0) {
    String response = http.getString();
    Serial.println(httpResponseCode);  
    Serial.println(response);          
    
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);
    
    if (doc.containsKey("device_id")) {
      device_id = doc["device_id"]; 
      Serial.print("Device ID: ");
      Serial.println(device_id);
    } else {
      Serial.println("Device ID not received in the response");
    }
  } else {
    Serial.print("Error on sending POST: ");
    Serial.println(httpResponseCode);
  }

  http.end();
}


#endif
