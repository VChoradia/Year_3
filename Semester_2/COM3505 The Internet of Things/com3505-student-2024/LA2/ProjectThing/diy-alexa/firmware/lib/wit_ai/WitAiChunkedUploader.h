#ifndef _witai_chunked_uploaded_h_
#define _witai_chunked_uploaded_h_

#include <stdint.h>
#include <string>
#include <vector>

class WiFiClientSecure;

typedef struct
{
    std::string value;
    float confidence;
} Entity;

typedef struct
{
    std::string text;
    std::string intent_name;
    float intent_confidence;
    std::vector<Entity> nameEntities; 
    std::vector<Entity> messageEntities;
    std::vector<Entity> songEntities;
    std::vector<Entity> todoEntities;

} Intent;

class WitAiChunkedUploader
{
private:
    WiFiClientSecure *m_wifi_client;

public:
    WitAiChunkedUploader(const char *access_key);
    ~WitAiChunkedUploader();
    bool connected();
    void startChunk(int size_in_bytes);
    void sendChunkData(const uint8_t *data, int size_in_bytes);
    void finishChunk();
    Intent getResults();
};

#endif