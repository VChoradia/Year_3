#include "Speaker.h"
#include "I2SOutput.h"
#include "WAVFileReader.h"

Speaker::Speaker(I2SOutput *i2s_output)
{
    m_i2s_output = i2s_output;
    m_ok = new WAVFileReader("/ok.wav");
    m_ready_ping = new WAVFileReader("/ready_ping.wav");
    m_cantdo = new WAVFileReader("/cantdo.wav");
    m_jokes[0] = new WAVFileReader("/joke0.wav");
    m_jokes[1] = new WAVFileReader("/joke1.wav");
    m_jokes[2] = new WAVFileReader("/joke2.wav");
}

Speaker::~Speaker()
{
    delete m_ok;
    delete m_ready_ping;
    delete m_cantdo;
    delete m_jokes[0];
    delete m_jokes[1];
    delete m_jokes[2];
    delete m_dynamicFile;  // Ensure dynamic file is freed on object destruction
}

void Speaker::playOK()
{
    m_ok->reset();
    m_i2s_output->setSampleGenerator(m_ok);
}

void Speaker::playReady()
{
    m_ready_ping->reset();
    m_i2s_output->setSampleGenerator(m_ready_ping);
}

void Speaker::playCantDo()
{
    m_cantdo->reset();
    m_i2s_output->setSampleGenerator(m_cantdo);
}

void Speaker::playRandomJoke()
{
    int joke = random(3);
    m_i2s_output->setSampleGenerator(m_jokes[joke]);
}


void Speaker::playDynamicWavFile(const char* filename) {
    // Delete any previously allocated dynamic file
    if (m_dynamicFile != nullptr) {
        delete m_dynamicFile;
        m_dynamicFile = nullptr;
    }

    // Ensure file exists
    if (SPIFFS.exists(filename)) {
        WAVFileReader* dynamicFile = new WAVFileReader(filename);
        dynamicFile->reset();
        m_i2s_output->setSampleGenerator(dynamicFile);
    } else {
        Serial.printf("File %s does not exist\n", filename);
    }
}