#include <WiFi.h>
#include <time.h>

const char* ssid = "uos-other";
const char* password = "shefotherkey05";

// Set the timezone offset in seconds (e.g., for UTC+1: 3600 seconds)
const long gmtOffset_sec = 3600;
const int daylightOffset_sec = 3600;  // Adjust for daylight saving time

void setup() {
    Serial.begin(115200);

    // Connect to WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.println("Connecting to WiFi...");
    }
    Serial.println("Connected to WiFi");

    // Initialize and get the time
    configTime(gmtOffset_sec, daylightOffset_sec, "pool.ntp.org", "time.nist.gov");

    // Wait for time to be set
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        Serial.println("Failed to obtain time");
        return;
    }
    Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
}

void loop() {
    delay(10000); // This delay is just for demonstration purposes
}
