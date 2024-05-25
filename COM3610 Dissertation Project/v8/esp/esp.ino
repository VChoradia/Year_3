use//v8

#include <WiFi.h>
#include <PulseSensorPlayground.h> 
#include <OneWire.h>
#include <DallasTemperature.h> 
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"
#include <HTTPClient.h>
#include <sstream>
#include <ArduinoJson.h>
#include <AsyncEventSource.h>
#include <AsyncJson.h>
#include <AsyncWebSocket.h>
#include <AsyncWebSynchronization.h>
#include <ESPAsyncWebSrv.h>
#include <SPIFFSEditor.h>
#include <StringArray.h>
#include <WebAuthentication.h>
#include <WebHandlerImpl.h>
#include <WebResponseImpl.h>
#include <queue>
#include <EEPROM.h>

struct DeviceSettings {
  char name[50];      
  char phoneNumber[20]; 
  int bpmLowerThreshold;
  int bpmUpperThreshold;
  int tempLowerThreshold;
  int tempUpperThreshold;
  bool isPublishing;  
};


const int movingAverageWindowSize = 10;

// For BPM
float bpmSum = 0;
std::queue<int> bpmReadings;
float bpmMovingAverage = 0;

// For Temperature
float tempSum = 0;
std::queue<float> tempReadings;
float tempMovingAverage = 0;

// Tolerance constants
const int MOVING_AVERAGE_WINDOW_SIZE = 10;
const int BPM_TOLERANCE = 10; // Adjust based on testing and sensor accuracy
const float TEMP_TOLERANCE = 0.5; // Adjust based on testing and sensor accuracy


AsyncWebServer server(80);
const String deviceNickname = "smartpatch2";
const String devicePasskey = "smartpatch2";
int device_id = -1;

String global_to;
String global_name;
int global_bpm_lower_threshold;
int global_bpm_upper_threshold;
int global_temp_lower_threshold;
int global_temp_upper_threshold;
bool global_isPublishing;

static unsigned long lastSMSTime = 1800000; 
static unsigned long lastPublishTime = 0; 

#include "config.h"
#include "twilio_control.h"
#include "wifi_control.h"
#include "adafruit_control.h"


void setup() {

  Serial.begin(115200);

  pinMode(LED_PIN, OUTPUT);
  pinMode(SWITCH_PIN, INPUT_PULLUP); 
  isSwitchOn = digitalRead(SWITCH_PIN) == HIGH;

  setupWiFi();

  if (!EEPROM.begin(512)) { 
    Serial.println("Failed to initialize EEPROM");
    return;
  }

  DeviceSettings settings = loadSettings(); 
  global_name = settings.name;
  global_to = settings.phoneNumber;
  global_bpm_lower_threshold = settings.bpmLowerThreshold;
  global_bpm_upper_threshold = settings.bpmUpperThreshold;
  global_temp_lower_threshold = settings.tempLowerThreshold;
  global_temp_upper_threshold = settings.tempUpperThreshold;
  global_isPublishing = settings.isPublishing;


  lastSMSTime = 1800000; 
  lastPublishTime = 0; 

  setupServer();

  setupSensors();

  MQTT_connect();

  if (!nameFeed.publish(global_name.c_str())) {
      Serial.println(F("Failed Name"));
    }
  

  delay(500);
  
  }

void loop() {
  int currentButtonState = digitalRead(SWITCH_PIN);
  // Check if button state has changed from LOW to HIGH (button press)
  if (currentButtonState == HIGH && lastButtonState == LOW) {
    Serial.println("Button pressed");
    isSwitchOn = !isSwitchOn; 
    if (isSwitchOn && global_isPublishing) {
      ledOn();
    } else {
      ledOff();
    }
    delay(200); 
  }
  lastButtonState = currentButtonState;  

  if (isSwitchOn && global_isPublishing) {
    publishData();
  }
}   


void publishData() {
  
  unsigned long currentMillis = millis();    // Current timestamp

 
  if (currentMillis - lastPublishTime >= 5000) {

    lastPublishTime = currentMillis;

    int bpm;
    float tempC;

   
    MQTT_connect();

    if (!nameFeed.publish(global_name.c_str())) {
      Serial.println(F("Failed Name"));
    } 
    if (!mobileNumberFeed.publish(global_to.c_str())) {
      Serial.println(F("Failed Mobile Number Feed"));
    } 

    // Check for pulse and read BPM
    if (pulseSensor.sawStartOfBeat()) {
      bpm = pulseSensor.getBeatsPerMinute();
    } else {
      bpm = 0; 
      Serial.println("Warning: Zero BPM read, possible sensor error.");
    }

    tempSensors.requestTemperatures();
    tempC = tempSensors.getTempCByIndex(0);

    updateMovingAverage(bpm, tempC);

    Serial.print("BPM: ");
    Serial.println(bpm);

    Serial.print("Temp: ");
    Serial.println(tempC);
    
    
     if (abs(bpm - bpmMovingAverage) < BPM_TOLERANCE && abs(tempC - tempMovingAverage) < TEMP_TOLERANCE) {

    if(bpm >0) {
      if (!bpmFeed.publish(bpm)) {
        Serial.println(F("Failed BPM"));
      }
    }
    if (!temperatureFeed.publish(tempC)) {
      Serial.println(F("Failed Temp"));
    } 
    
      if(tempC > global_temp_upper_threshold || tempC < global_temp_lower_threshold || (bpm > global_bpm_upper_threshold &&  bpm>0) || (bpm < global_bpm_lower_threshold && bpm>0) ) {
        unsigned long currentMillis = millis();  

        if (currentMillis - lastSMSTime >= 1800000) {
          int cr = currentMillis - lastSMSTime;
          Serial.println(cr);
          char smsString[240]; 
          sprintf(smsString, "%s's Health Alert: Body Temperature has crossed %.2f°C and current BPM is %d.", global_name, tempC, bpm);
          if (sendSMS(smsString)) { 
              lastSMSTime = currentMillis;  
              Serial.println("SMS sent successfully");
          } else {
              Serial.println("Failed to send SMS");
          }
        } 
      }

      sendDetails(bpm, tempC);

    }

  }

}

void clearUserDetails() {
    DeviceSettings settings = loadSettings();  
 
    strcpy(settings.name, ""); 
    strcpy(settings.phoneNumber, "");  
    settings.bpmLowerThreshold = 0;
    settings.bpmUpperThreshold = 0;
    settings.tempLowerThreshold = 0;
    settings.tempUpperThreshold = 0;
    settings.isPublishing = false;
    
    saveSettings(settings);  

    isSwitchOn = false;
    ledOff();

    global_name = settings.name;
    global_to = settings.phoneNumber;
    global_bpm_lower_threshold = settings.bpmLowerThreshold;
    global_bpm_upper_threshold = settings.bpmUpperThreshold;
    global_temp_lower_threshold = settings.tempLowerThreshold;
    global_temp_upper_threshold = settings.tempUpperThreshold;
    global_isPublishing = settings.isPublishing;
    
}


void setupServer() {
    
    server.on("/stop-publishing", handleStopPublishing);


  server.on("/receive-user-details", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL, handleAssignDeviceToUser);


  server.on("/clear-user-details", HTTP_POST, [](AsyncWebServerRequest *request) {

    Serial.println("Device unassigned.");
    clearUserDetails(); 
    request->send(200, "application/json", "{\"message\":\"Device unassigned successfully.\"}");
  });

    
  server.begin();
}



void handleStopPublishing(AsyncWebServerRequest *request)
{

    Serial.println("Received request to stop publishing data.");

    DeviceSettings settings = loadSettings(); 

    strcpy(settings.name, "");  
    strcpy(settings.phoneNumber, "");  
    settings.bpmLowerThreshold = 0;
    settings.bpmUpperThreshold = 0;
    settings.tempLowerThreshold = 0;
    settings.tempUpperThreshold = 0;
    settings.isPublishing = false;
    
    saveSettings(settings);  
    global_name = settings.name;
    global_to = settings.phoneNumber;
    global_bpm_lower_threshold = settings.bpmLowerThreshold;
    global_bpm_upper_threshold = settings.bpmUpperThreshold;
    global_temp_lower_threshold = settings.tempLowerThreshold;
    global_temp_upper_threshold = settings.tempUpperThreshold;
    global_isPublishing = settings.isPublishing;

    isSwitchOn = false;
    ledOff();
    
    lastSMSTime = 1800000;
    lastPublishTime = 0;

    request->send(200, "application/json", "{\"status\":\"success\"}");
}


void handleAssignDeviceToUser(AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
  DynamicJsonDocument doc(1024);
  deserializeJson(doc, data);

  DeviceSettings settings = loadSettings();
  strcpy(settings.name, doc["username"].as<String>().c_str());
  strcpy(settings.phoneNumber, doc["phone_number"].as<String>().c_str()); 
  settings.bpmLowerThreshold = doc["bpm_lower_threshold"].as<int>();
  settings.bpmUpperThreshold = doc["bpm_upper_threshold"].as<int>();
  settings.tempLowerThreshold = doc["temp_lower_threshold"].as<int>();
  settings.tempUpperThreshold = doc["temp_upper_threshold"].as<int>();
  settings.isPublishing = true;
 
  saveSettings(settings);

  global_name = settings.name;
  global_to = settings.phoneNumber;
  global_bpm_lower_threshold = settings.bpmLowerThreshold;
  global_bpm_upper_threshold = settings.bpmUpperThreshold;
  global_temp_lower_threshold = settings.tempLowerThreshold;
  global_temp_upper_threshold = settings.tempUpperThreshold;
  global_isPublishing = settings.isPublishing;


  Serial.println("Received user details for device assignment:");
  Serial.print("Name: "); Serial.println(settings.name);
  Serial.print("Phone Number: "); Serial.println(settings.phoneNumber);

    if (isSwitchOn && global_isPublishing) {
        ledOn();
    } else {
        ledOff();
    }

  request->send(200, "application/json", "{\"message\":\"User details received and device assigned.\"}");
}


void updateMovingAverage(int bpm, float tempC) {
    if (bpm > 0) {
      if (bpmReadings.size() >= movingAverageWindowSize) {
          bpmSum -= bpmReadings.front();
          bpmReadings.pop();
      }
      bpmSum += bpm;
      bpmReadings.push(bpm);
      if (bpmReadings.size() > 0) {  
          bpmMovingAverage = bpmSum / bpmReadings.size();
      }
    }


    if (tempReadings.size() >= movingAverageWindowSize) {
        tempSum -= tempReadings.front();
        tempReadings.pop();
    }
    tempSum += tempC;
    tempReadings.push(tempC);
    if (tempReadings.size() > 0) {
        tempMovingAverage = tempSum / tempReadings.size();
    }
}
