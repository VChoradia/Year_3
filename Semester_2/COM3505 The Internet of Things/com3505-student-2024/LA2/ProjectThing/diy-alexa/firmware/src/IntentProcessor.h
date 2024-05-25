#ifndef _intent_processor_h_
#define _intent_processor_h_

#include <map>
#include "WitAiChunkedUploader.h"

class Speaker;

enum IntentResult
{
    FAILED,
    SUCCESS,
    SILENT_SUCCESS // success but don't play ok sound
};

class IntentProcessor
{
private:
    std::map<std::string, int> m_device_to_pin;
    IntentResult searchChatGPT(const Intent &intent);
    IntentResult text(const Intent &intent);
    IntentResult sendCustomRequest(const std::string& path, const std::string& name, const std::string& message) ;
    IntentResult tellJoke();
    IntentResult life();
    IntentResult goodMorning();
    IntentResult goodNight();
    IntentResult sendRequestToLights(const String &path);
    IntentResult turnOnLights();
    IntentResult turnOffLights();
    IntentResult checkWeather();
    IntentResult completeSong(const Intent &intent);
    IntentResult addTodo(const Intent &intent);
    IntentResult tellTodos();

    Speaker *m_speaker;

public:
    IntentProcessor(Speaker *speaker);
    IntentResult processIntent(const Intent &intent);
};

#endif
