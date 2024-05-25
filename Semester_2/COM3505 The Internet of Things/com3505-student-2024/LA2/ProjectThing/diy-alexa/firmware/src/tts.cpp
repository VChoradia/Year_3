// #include <WiFi.h>
// #include <WiFiClientSecure.h>
// #include "FS.h"
// #include "SPIFFS.h"
// #include "tts.h"

// const char* base64_chars =
//     "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
//     "abcdefghijklmnopqrstuvwxyz"
//     "0123456789+/";


// /**
//  * Encodes a given string to Base64.
//  * 
//  * @param input The input string to encode.
//  * @return A Base64 encoded string.
//  */
// String base64_encode(const String& input) {
//     const unsigned char* bytes_to_encode = reinterpret_cast<const unsigned char*>(input.c_str());
//     unsigned int in_len = input.length();
//     String ret;
//     int i = 0, j = 0;
//     unsigned char char_array_3[3], char_array_4[4];

//     while (in_len--) {
//         char_array_3[i++] = *(bytes_to_encode++);
//         if (i == 3) {
//             char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
//             char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
//             char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
//             char_array_4[3] = char_array_3[2] & 0x3f;

//             for (i = 0; (i < 4); i++)
//                 ret += base64_chars[char_array_4[i]];
//             i = 0;
//         }
//     }

//     if (i) {
//         for (j = i; j < 3; j++)
//             char_array_3[j] = '\0';

//         char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
//         char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
//         char_array_4[2] = ((char_array_3[1] & 0x0f) << 2);
//         char_array_4[3] = 0;

//         for (j = 0; (j < i + 1); j++)
//             ret += base64_chars[char_array_4[j]];

//         while ((i++ < 3))
//             ret += '=';
//     }

//     return ret;
// }

// const char* watsonApiUrl = "https://api.eu-gb.text-to-speech.watson.cloud.ibm.com/v1/synthesize";
// const char* watsonApiKey = "YOUR_API_KEY";
// String watsonAuthHeader = "Basic " + base64_encode("apikey:" + String(watsonApiKey));


// /**
//  * Fetches TTS audio from IBM Watson and saves it to a file.
//  * 
//  * @param text The text to be converted to speech.
//  * @param filename The filename to save the audio file as.
//  * @return True if the audio is successfully fetched and saved, otherwise false.
//  */
// bool fetchAndSaveTTSAudio(const String& text, const char* filename) {

//     WiFiClientSecure client;
//     client.setInsecure(); 

//     // Connect to IBM Watson API endpoint
//     if (!client.connect("api.eu-gb.text-to-speech.watson.cloud.ibm.com", 443)) {
//         Serial.println("Error: Unable to connect to Watson TTS API");
//         return false;
//     }

//     // Construct and send HTTP request
//     client.print(String("POST ") + "/v1/synthesize HTTP/1.1\r\n" +
//                  "Host: api.eu-gb.text-to-speech.watson.cloud.ibm.com\r\n" +
//                  "Authorization: " + watsonAuthHeader + "\r\n" +
//                  "Content-Type: application/json\r\n" +
//                  "Accept: audio/wav\r\n" +
//                  "Content-Length: " + String(text.length() + 10) + "\r\n\r\n" +
//                  "{\"text\":\"" + text + "\"}");


//     while (client.connected() && !client.available()) {
//         delay(100);
//     }

//     String response = client.readStringUntil('\n');
//     if (!response.startsWith("HTTP/1.1 200")) {
//         Serial.println("Error: " + response);
//         client.stop();
//         return false;
//     }

//     while (client.readStringUntil('\n').length() > 1) {}

//     File audioFile = SPIFFS.open(filename, FILE_WRITE);
//     if (!audioFile) {
//         Serial.println("Error: Unable to open file for writing");
//         client.stop();
//         return false;
//     }

//     uint8_t buffer[128];
//     while (client.available()) {
//         size_t bytesRead = client.readBytes(buffer, sizeof(buffer));
//         audioFile.write(buffer, bytesRead);
//     }

//     audioFile.close();
//     Serial.println("TTS audio saved successfully!");
//     client.stop();
//     return true;
// }

#include <WiFi.h>
#include <HTTPClient.h>
#include "FS.h"
#include "SPIFFS.h"
#include "tts.h"

const char* server_url = "http://143.167.38.236:5000/"; 


/**
 * Fetches TTS audio from a specified endpoint and saves it to a file.
 * 
 * @param endpoint The API endpoint to send the request to.
 * @param text The text to be converted to speech.
 * @param filename The filename to save the audio file as.
 * @return True if the audio is successfully fetched and saved, otherwise false.
 */
bool fetchAndSaveTTSAudio(const String& endpoint, const String& text, const char* filename) {

    String requestBody = "";

    HTTPClient http;

    Serial.print(server_url+endpoint);

    http.begin(server_url+endpoint);

    if(endpoint == "chatgpt" || endpoint == "song") {
        http.addHeader("Content-Type", "application/json");
        requestBody = "{\"query\":\"" + text + "\"}";

    } else {
        http.addHeader("Content-Type", "application/json");
        requestBody = "{\"text\":\"" + text + "\"}";
    }

    int httpResponseCode = http.POST(requestBody);
    if (httpResponseCode != 200) {
        Serial.printf("HTTP Error: %d\n", httpResponseCode);
        http.end();
        return false;
    }

    // Open file in SPIFFS to store the audio
    File audioFile = SPIFFS.open(filename, FILE_WRITE);
    if (!audioFile) {
        Serial.println("Error: Unable to open file for writing");
        http.end();
        return false;
    }

    // Read the audio data and write it to a file
    WiFiClient* client = http.getStreamPtr();
    uint8_t buffer[256];
    while (client->available()) {
        size_t bytesRead = client->readBytes(buffer, sizeof(buffer));
        audioFile.write(buffer, bytesRead);
    }

    audioFile.close();
    Serial.println("Audio saved successfully!");
    http.end();
    return true;
}