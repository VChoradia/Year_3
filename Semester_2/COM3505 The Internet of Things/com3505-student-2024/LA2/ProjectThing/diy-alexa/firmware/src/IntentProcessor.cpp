#include <Arduino.h>
#include "IntentProcessor.h"
#include "Speaker.h"
#include <dotstar_wing.h>
#include "tts.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ChatGPT.hpp>
#include <WiFiClientSecure.h>
#include <string>
#include <iostream>



/**
 * 
 * @param speaker Pointer to a Speaker object used for playing audio.
 */
IntentProcessor::IntentProcessor(Speaker *speaker)
{
    m_speaker = speaker;
}


/**
 * 
 * @return SILENT_SUCCESS Always returns SILENT_SUCCESS after playing the joke.
 */
IntentResult IntentProcessor::tellJoke()
{
    m_speaker->playRandomJoke();
    return SILENT_SUCCESS;
}



// /**
//  * Sends a query directly to ChatGPT and plays the response as TTS audio.
//  * 
//  * @param intent The Intent object containing the query text.
//  * @return SILENT_SUCCESS if the audio is successfully played, otherwise FAILED.
//  */

// IntentResult IntentProcessor::searchChatGPT(const Intent &intent)
// {   
//     // Serial.printf("I heard \"%s\"\n", intent.text.c_str());
//   
//     WiFiClientSecure client;
//     ChatGPT<WiFiClientSecure> chat_gpt(&client, "v1", "sk-proj-CoMJSNYgFPvj5VjZ1fYPT3BlbkFJeJfVjefdhKMR2GpCYYiM");
//
//     client.setInsecure();
//
//     std::string std_query = intent.intent_name;
//     String query = String(std_query.c_str());
//
//     String prompt = "Your responses should be brief and abstract, no more than 5 words. " + query;
//
//     String result;
//
//     Serial.println("[ChatGPT] Only print a content message");
//     if (chat_gpt.simple_message("gpt-3.5-turbo-0301", "user", prompt, result)) {
//         Serial.println("===OK===");
//         Serial.println(result);
//         if (fetchAndSaveTTSAudio(result, "/tts_audio.wav")) {
//         m_speaker->playDynamicWavFile("/tts_audio.wav");
//         return SILENT_SUCCESS;
//         } else {
//             Serial.println("Failed to retrieve TTS audio");
//             return FAILED;
//         }
//         return SILENT_SUCCESS;
//     } else {
//         Serial.println("===ERROR===");
//         Serial.println(result);
//         return FAILED;
//     }
//
//  
// }

/**
 * Sends a query to ChatGPT thorugh laptop server and plays the response as TTS audio.
 * 
 * @param intent The Intent object containing the query text.
 * @return SILENT_SUCCESS if the audio is successfully played, otherwise FAILED.
 */
IntentResult IntentProcessor::searchChatGPT(const Intent &intent) {

    String textToSynthesize = intent.text.c_str();
    
    if (fetchAndSaveTTSAudio("chatgpt", textToSynthesize, "/tts_audio.wav")) {
        m_speaker->playDynamicWavFile("/tts_audio.wav");
        return SILENT_SUCCESS;
    } else {
        Serial.println("Failed to retrieve TTS audio");
        return SILENT_SUCCESS;
    }

}

/**
 * Plays a "Good Morning" message as TTS audio and sends a request to turn on the lights.
 * 
 * @return IntentResult indicating the success of the light request.
 */
IntentResult IntentProcessor::goodMorning() {

    String textToSynthesize = "Good Morning";

    // Fetch and save the TTS audio to a local file
    if (fetchAndSaveTTSAudio("get-audio",textToSynthesize, "/tts_audio.wav")) {
        m_speaker->playDynamicWavFile("/tts_audio.wav");
    } else {
        Serial.println("Failed to retrieve TTS audio");
    }

    return sendRequestToLights("/lightson");
    
}


/**
 * Plays a "Good Night" message as TTS audio and sends a request to turn off the lights.
 * 
 * @return IntentResult indicating the success of the light request.
 */
IntentResult IntentProcessor::goodNight() {

    String textToSynthesize = "Good Night";
    
    // Fetch and save the TTS audio to a local file
    if (fetchAndSaveTTSAudio("get-audio", textToSynthesize, "/tts_audio.wav")) {
        m_speaker->playDynamicWavFile("/tts_audio.wav");
    } else {
        Serial.println("Failed to retrieve TTS audio");
    }


    return sendRequestToLights("/lightsoff");

}


/**
 * Sends an HTTP GET request to control the lights.
 * 
 * @param path The endpoint path for the light control request.
 * @return SILENT_SUCCESS if the request is successful, otherwise FAILED.
 */
IntentResult IntentProcessor::sendRequestToLights(const String& path) {
    
    HTTPClient http;
    String fullUrl = "http://143.167.55.210" + path;

    http.begin(fullUrl);
    int httpResponseCode = http.GET(); 

    if (httpResponseCode > 0) {

        Serial.printf("GET %s: %d\n", fullUrl.c_str(), httpResponseCode);
        http.end();
        return SILENT_SUCCESS;
    } else {

        Serial.printf("Error on GET %s: %s\n", fullUrl.c_str(), http.errorToString(httpResponseCode).c_str());
        http.end();
        return FAILED;
    }
}


/**
 * Sends a request to turn on the lights.
 * 
 * @return IntentResult indicating the success of the light request.
 */
IntentResult IntentProcessor::turnOnLights() {

    return sendRequestToLights("/lightson");
}


/**
 * Sends a request to turn off the lights.
 * 
 * @return IntentResult indicating the success of the light request.
 */
IntentResult IntentProcessor::turnOffLights() {

    return sendRequestToLights("/lightsoff");
}

// This was our previous attempt to get the data directly from the HTTPS API
// IntentResult IntentProcessor::checkWeather() {
//     const String apiKey = "PQYCREGHQ3D4JHK6UYY2YRDVX";
//     const String city = "sheffield";
//     // const String weatherUrl = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" + city + "?unitGroup=metric&include=current&key=" + apiKey + "&contentType=json";
//     const String weatherUrl = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/sheffield/today?unitGroup=metric&elements=tempmax%2Ctempmin%2Ctemp%2Cconditions&include=current&key=MEE48H3ALLS2M8FVGCZWPAU3E&contentType=json";
//     WiFiClientSecure client;
//     HTTPClient http;
//
//     // Allow insecure connections (not recommended for production)
//     client.setInsecure();
//
//     // Begin connection using the insecure client
//     http.begin(client, weatherUrl);
//     int httpResponseCode = http.GET();
//
//     // Check if the GET request was successful
//     if (httpResponseCode == 200) {
//         String response = http.getString();
//         // Serial.println(response);
//
//         // Parse JSON data
//         StaticJsonDocument<2048> doc;
//         DeserializationError error = deserializeJson(doc, response);
//
//         if (error) {
//             Serial.print("JSON Deserialization failed: ");
//             Serial.println(error.c_str());
//             return SILENT_SUCCESS;
//         }
//
//         // Extract temperature and condition information
//         float tempMax = doc["days"][0]["tempmax"];
//         float tempMin = doc["days"][0]["tempmin"];
//         const char* conditions = doc["days"][0]["conditions"];
//
//         // Print the extracted data
//         Serial.print("Max Temp: ");
//         Serial.println(tempMax);
//         Serial.print("Min Temp: ");
//         Serial.println(tempMin);
//         Serial.print("Conditions: ");
//         Serial.println(conditions);
//         http.end();
//
//         // String textToSynthesize = "The maximum temperature today is " + String(tempMax, 1) +
//         //                   "°C and the minimum would be " + String(tempMin, 1) +
//         //                   "°C. Conditions look like " + conditions + ".";
//
//         String textToSynthesize = "Today's weather is " + String(conditions) + ".";
//
//         if (fetchAndSaveTTSAudio(textToSynthesize, "/tts_audio.wav")) {
//             m_speaker->playDynamicWavFile("/tts_audio.wav");
//             return SILENT_SUCCESS;
//         } else {
//             Serial.println("Failed to retrieve TTS audio");
//             return SILENT_SUCCESS;
//         }
//
//         return SILENT_SUCCESS;
//     } else {
//         Serial.print("Error on HTTP request: ");
//         Serial.println(httpResponseCode);
//         http.end();
//         return FAILED;
//     }
//
//     // Free resource
// }



/**
 * Fetches the weather information and plays it as TTS audio.
 * 
 * @return SILENT_SUCCESS if the audio is successfully played, otherwise FAILED.
 */
IntentResult IntentProcessor::checkWeather() {
    String city = "sheffield"; 
    String endpoint = "weather?city=" + city;

    if (fetchAndSaveTTSAudio(endpoint, "" ,"/tts_audio.wav")) {
        m_speaker->playDynamicWavFile("/tts_audio.wav");
        return SILENT_SUCCESS;
    } else {
        Serial.println("Failed to retrieve TTS audio");
        return FAILED;
    }
}

/**
 * Sends a custom HTTP POST request to a specified path with a payload.
 * 
 * @param path The endpoint path for the custom request.
 * @param name The name parameter for the request payload.
 * @param message The message parameter for the request payload.
 * @return IntentResult indicating the success of the custom request.
 */
IntentResult IntentProcessor::sendCustomRequest(const std::string& path, const std::string& name, const std::string& message) {
    HTTPClient http;

    std::string fullURL = "http://143.167.38.236:5000/" + path;
    const char* serverName = fullURL.c_str();  

    http.begin(serverName);  
    http.addHeader("Content-Type", "application/json");  

    String payload;

    if (path == "text") { 
        StaticJsonDocument<200> doc;
        doc["name"] = name;
        doc["body"] = message;
        
        serializeJson(doc, payload);
    }

    if (path == "addTodo") {
        StaticJsonDocument<200> doc;
        doc["todo"] = message;
        
        serializeJson(doc, payload);
    }

    int httpResponseCode = http.POST(payload);  

    if (httpResponseCode == 200 || httpResponseCode == 201) { 
        String response = http.getString();  
        Serial.printf("HTTP POST to %s successful, response: %s\n", serverName, response.c_str());
        http.end();  
        return SUCCESS;
    } else {
        Serial.printf("HTTP POST failed, status code: %d\n", httpResponseCode);
        http.end(); 
        return FAILED;
    }
}


/**
 * Sends a text message based on the provided intent.
 * 
 * @param intent The Intent object containing the text message details.
 * @return IntentResult indicating the success of the text message request.
 */
IntentResult IntentProcessor::text(const Intent &intent) {
    std::string nameValue;
    std::string messageValue;

    for (const auto& entity : intent.nameEntities) {
        if (entity.confidence > 0.9) {
            nameValue = entity.value;  
        }
    }

    for (const auto& entity : intent.messageEntities) {
        if (entity.confidence > 0.9) {
            messageValue = entity.value;  
        }
    }

    if (!nameValue.empty() && !messageValue.empty()) {
        return sendCustomRequest("text", nameValue, messageValue);
    }

    return FAILED;
}


/**
 * Completes the next line or two of a song using ChatGPT and plays it as TTS audio.
 * 
 * @param intent The Intent object containing the song details.
 * @return SILENT_SUCCESS if the audio is successfully played, otherwise FAILED.
 */
IntentResult IntentProcessor::completeSong(const Intent &intent) {

    std::string songValue;


    for (const auto& entity : intent.songEntities) {
        if (entity.confidence > 0.8) {
            songValue = entity.value;  
        }
    }

 
    if (!songValue.empty()) {
        if (fetchAndSaveTTSAudio("song", songValue.c_str(), "/tts_audio.wav")) {
            m_speaker->playDynamicWavFile("/tts_audio.wav");
            return SILENT_SUCCESS;
        } else {
            Serial.println("Failed to retrieve TTS audio");
            return FAILED;
        }
    }

    return FAILED;
}


/**
 * Adds a new todo item based on the provided intent.
 * 
 * @param intent The Intent object containing the todo item details.
 * @return IntentResult indicating the success of the addTodo request.
 */
IntentResult IntentProcessor::addTodo(const Intent &intent) {

    std::string todoValue;

    std::cout << "Processing Intent: " << intent.intent_name << std::endl;

   
    if (intent.todoEntities.empty()) {
        std::cout << "No todo entities found." << std::endl;
        return FAILED;
    }


    for (const auto& entity : intent.todoEntities) {
            todoValue = entity.value;  
            return sendCustomRequest("addTodo", "todo", todoValue);
    }
    return FAILED;

}



/**
 * Retrieves and plays a list of todo items as TTS audio.
 * 
 * This function fetches the list of todo items, converts it to speech using TTS,
 * and plays the resulting audio file. If the process fails, it logs an error message.
 * 
 * @return SILENT_SUCCESS if the audio is successfully played, otherwise FAILED.
 */
IntentResult IntentProcessor::tellTodos() {

    if (fetchAndSaveTTSAudio("tellTodos", "todos", "/tts_audio.wav")) {
        m_speaker->playDynamicWavFile("/tts_audio.wav");
        return SILENT_SUCCESS;
    } else {
        Serial.println("Failed to retrieve TTS audio");
        return FAILED;
    }

}


/**
 * Processes and executes the given intent.
 * 
 * Determines the action based on the intent's name and confidence level, 
 * calling the appropriate function to handle it. Logs errors for unrecognized or low-confidence intents.
 * 
 * @param intent The Intent object containing the user's intent details.
 * @return An IntentResult indicating the success or failure of the processing.
 */
IntentResult IntentProcessor::processIntent(const Intent &intent)
{
    Serial.printf(
      "processIntent: name=%s; confidence=%.f%%;",
      intent.intent_name.c_str(), 100 * intent.intent_confidence
    );

    if (intent.text.empty())
    {
        Serial.println("No text recognised");
        return FAILED;
    }
    Serial.printf("I heard \"%s\"\n", intent.text.c_str());
    if (intent.intent_name.empty())
    {
        Serial.println("Can't work out what you want to do with the device...");
        return FAILED;
    }
    Serial.printf("Intent is %s\n", intent.intent_name.c_str());
    if (intent.intent_name == "good_morning") {
        return goodMorning();
    }
    if (intent.intent_name == "good_night") {
        return goodNight();
    }
    if (intent.intent_name == "Tell_joke")
    {
        return tellJoke();
    }
    if (intent.intent_name == "turn_on") {
        return turnOnLights();
    }
    if (intent.intent_name == "turn_off") {
        return turnOffLights();
    }
    if (intent.intent_name == "weather") {
        return checkWeather();
    }
    if (intent.intent_name == "search") {
        return searchChatGPT(intent);
    }
    if (intent.intent_name == "text") {
        return text(intent);
    }
    if (intent.intent_name == "song") {
        return completeSong(intent);
    }
    if (intent.intent_name == "todo") {
        return addTodo(intent);
    }
    if (intent.intent_name == "tell_todos") {
        return tellTodos();
    }

    return FAILED;
}

