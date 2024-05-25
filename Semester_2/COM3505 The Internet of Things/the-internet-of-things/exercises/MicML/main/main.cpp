// main.cpp

/*
new ICS43434 mic driver code from Chris Greening (thanks Chris!)
https://github.com/atomic14/ICS-43434-breakout-board


older code (below):

an i2s microphone read example for the SPH0645,
adafruit https://www.adafruit.com/product/3421

pin config and etc from 
espressif: esp-idf/examples/peripherals/i2s/main

mic read and data conversion code from 
felipeduque from: https://www.esp32.com/viewtopic.php?f=13&t=1756&start=40

other inspiration from
tschundler: https://www.esp32.com/viewtopic.php?t=4997
michaelboeckling: https://www.esp32.com/viewtopic.php?f=13&t=1756&start=10

etc.!


to test:
comment out DO_WIFI, load it via the Arduino IDE and open
Tools > Serial Plotter
(or: fix the _URL defines for your IPs and try ../server)
*/


#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include "I2SSampler.h"
#include "private.h"

// trigger pio library dependency finder to include tensorflow
#include "tensorflow/lite/core/api/tensor_utils.h"

// comment out to use printing intstead
#define DO_WIFI

// replace the ip address with your machine's ip address
#define I2S_SERVER_URL "http://10.0.0.14:5003/i2s_samples"
#define PING_URL "http://10.0.0.14:5003/ping"
// replace the SSID and PASSWORD with your WiFi settings
// in ../../../private.h and it should be linked...

// i2s config - this is set up to read fro the left channel
i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
    .sample_rate = 16000,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = i2s_comm_format_t(I2S_COMM_FORMAT_I2S),
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 4,
    .dma_buf_len = 1024,
    .use_apll = false,
    .tx_desc_auto_clear = false,
    .fixed_mclk = 0};

// i2s pins
i2s_pin_config_t i2s_pins = {
    .bck_io_num = 13,
//  .bck_io_num = GPIO_NUM_5,
    .ws_io_num = 15,
//  .ws_io_num = GPIO_NUM_19,
    .data_out_num = I2S_PIN_NO_CHANGE,
    .data_in_num = 21};
//  .data_in_num = GPIO_NUM_18};

WiFiClient *wifi_client = NULL;
HTTPClient *http_client = NULL;
I2SSampler *i2s_sampler = NULL;

// Task to write samples to our server
void i2sWriterTask(void *param)
{
  I2SSampler *sampler = (I2SSampler *)param;
  WiFiClient *wifi_client = new WiFiClient();
  HTTPClient *http_client = new HTTPClient();
  const TickType_t xMaxBlockTime = pdMS_TO_TICKS(100);
  while (true)
  {
    // wait for some samples to save
    uint32_t ulNotificationValue = ulTaskNotifyTake(pdTRUE, xMaxBlockTime);
    if (ulNotificationValue > 0)
    {
#ifdef DO_WIFI
Serial.println("doing POST");
      Serial.println("Sending data");
      http_client->begin(*wifi_client, I2S_SERVER_URL);
      http_client->addHeader("content-type", "application/octet-stream");
      http_client->POST((uint8_t *)sampler->getCapturedAudioBuffer(), sampler->getBufferSizeInBytes());
      http_client->end();
      Serial.println("Sent Data");
#else
      uint8_t i2s_data[1024];
      int i2s_data_len = sampler->getBufferSizeInBytes();
      for(int i = 0; i < i2s_data_len; i++)
        Serial.printf("%u\n", i2s_data[i]);
#endif
    }
  }
}

// Ping task - pings the server every 5 seconds so we know the connection is good
void pingTask(void *param)
{
  WiFiClient *wifi_client_ping = new WiFiClient();
  HTTPClient *http_client_ping = new HTTPClient();
  ;
  const TickType_t wait_time = pdMS_TO_TICKS(5000);
  while (true)
  {
#ifdef DO_WIFI
    Serial.println("Ping Server Start");
    http_client_ping->begin(*wifi_client_ping, PING_URL);
    http_client_ping->GET();
    http_client_ping->end();
    Serial.println("Ping Server Done");
#else
    yield();
#endif
    vTaskDelay(wait_time);
  }
}

void setup()
{
  Serial.begin(115200);
  // launch WiFi
#ifdef DO_WIFI
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);
  if (WiFi.waitForConnectResult() != WL_CONNECTED)
  {
    Serial.println("Connection Failed! Rebooting...");
    delay(5000);
    ESP.restart();
  }
#endif
  Serial.println("Started up");
#ifdef DO_WIFI
WiFi.printDiag(Serial);
Serial.println(WiFi.localIP());
#endif
  // set up i2s to read from our microphone
  i2s_sampler = new I2SSampler();

  // set up the i2s sample writer task
  TaskHandle_t writer_task_handle;
  xTaskCreate(i2sWriterTask, "I2S Writer Task", 4096, i2s_sampler, 1, &writer_task_handle);

  // start sampling from i2s device
  i2s_sampler->start(I2S_NUM_1, i2s_pins, i2s_config, 32768, writer_task_handle);

  // set up the ping task
  TaskHandle_t ping_task_handle;
  xTaskCreate(pingTask, "Ping Task", 4096, nullptr, 1, &ping_task_handle);
}

void loop()
{
  // nothing to do here - it's all driven by the i2s peripheral reading samples

  //  vTaskDelay(10 / portTICK_PERIOD_MS); // to allow IDLE
  yield();
}

























/* old Adafruit I2S SPH0645LM4H microphone code...


#include "sketch.h"
#include <Arduino.h>
#include <Wire.h>
#include <esp_log.h>
#include "driver/i2s.h"
#include "soc/i2s_reg.h"


/////////////////////////////////////////////////////////////////////////////
// i2s decls
void i2s_setup();
int i2s_loop();
bool REPORT_READING = false; // set this false...
bool PRINT_VALUES = true;    // ...and this true to use ArdIDE plotter


/////////////////////////////////////////////////////////////////////////////
// utilities

// delay/yield macros
#define WAIT_A_SEC   vTaskDelay(    1000/portTICK_PERIOD_MS); // 1 second
#define WAIT_SECS(n) vTaskDelay((n*1000)/portTICK_PERIOD_MS); // n seconds
#define WAIT_MS(n)   vTaskDelay(       n/portTICK_PERIOD_MS); // n millis

int firmwareVersion = 100; // used to check for updates
#define ECHECK ESP_ERROR_CHECK_WITHOUT_ABORT

// IDF logging
static const char *TAG = "main";


/////////////////////////////////////////////////////////////////////////////
// arduino-land entry points

void setup() {
  Wire.setPins(SDA, SCL);
  Wire.begin();
  Serial.begin(115200);

  i2s_setup();
  WAIT_A_SEC

  // for the serial plotter, to set its scale
  Serial.print("1000\n1001\n1002\n1000\n1001\n1002\n"); WAIT_MS(10)
  Serial.print("1000\n1001\n1002\n1000\n1001\n1002\n"); WAIT_MS(10)
  Serial.print("1000\n1001\n1002\n1000\n1001\n1002\n"); WAIT_MS(10)
} // setup

int loopIteration = 0;
void loop() {
  int sliceSize = 10;
  int reading = i2s_loop();
  if(loopIteration++ % sliceSize == 0 && REPORT_READING)
    Serial.printf("reading: %d\n", reading);
  vTaskDelay(10 / portTICK_PERIOD_MS); // to allow IDLE
} // loop


/////////////////////////////////////////////////////////////////////////////
// if we're an IDF build define app_main
// (TODO probably fails to identify a platformio *idf* build)

#if ! defined(ARDUINO_IDE_BUILD) && ! defined(PLATFORMIO)
  extern "C" { void app_main(); }

  // main entry point
  void app_main() {
    // arduino land
    initArduino();
    setup();
    while(1)
      loop();
  } // app_main()
#endif


/////////////////////////////////////////////////////////////////////////////
// i2s

#define BUFLEN 256                              // size of read buffer
char buf[BUFLEN];                               // read buffer
static const i2s_port_t i2s_num = I2S_NUM_0;    // i2s port number

static const i2s_config_t i2s_config = {        // i2s IDF configuration
  .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
  .sample_rate = 8000,
  .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
  .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
  // IDF 4.3: .communication_format = (i2s_comm_format_t) I2S_COMM_FORMAT_STAND_I2S,
  // but Chris' mic seems to work better with this, even in 4.3:
  .communication_format = i2s_comm_format_t(I2S_COMM_FORMAT_I2S),
  .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
  .dma_buf_count = 32,
  .dma_buf_len = 64,
  .use_apll = false
};

static const i2s_pin_config_t i2s_pin_config = { // which pins for i2s
  .bck_io_num = 13,
  .ws_io_num = 15,
  .data_out_num = I2S_PIN_NO_CHANGE,
  .data_in_num = 21
};

void i2s_setup() { // initialise pins, load driver, toggle
  pinMode(21, INPUT);
  pinMode(13, OUTPUT);
  pinMode(15, OUTPUT);

  i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_NUM_0, &i2s_pin_config);

  i2s_stop(I2S_NUM_0);
  i2s_start(I2S_NUM_0);
}

// adapted from felipeduque
int i2s_loop() {
  size_t bytes_read;
  char *p = buf;
  i2s_read(I2S_NUM_0, buf, sizeof(buf), &bytes_read, 2048);

  uint32_t samples_read = bytes_read / 2 / (I2S_BITS_PER_SAMPLE_32BIT / 8);
  bytes_read = 0;

  // sending only one of two channels (R, L)
  int sum = 0;
  for(int i = 0; i < samples_read; i++) {
    int16_t rightSample = (p[3] << 8) + p[2];   // read right channel bits
    sum += rightSample;                         // computing the average
    p += 2 * (I2S_BITS_PER_SAMPLE_32BIT / 8);   // advance read buffer pointer

    if(PRINT_VALUES) // for the serial plotter
      printf("%d,-600,600\n", rightSample);
  }

  return sum / samples_read;                    // return the mean
}

*/






/////////////////////////////////////////////////////////////////////////////
// sources of inspiration!

/*
from https://hackaday.io/project/162059-street-sense/log/160705-new-i2s-microphone/discussion-124677
doesn't seem to make a difference in this case
REG_SET_BIT(I2S_TIMING_REG(I2S_NUM_0), BIT(9));
REG_SET_BIT(I2S_CONF_REG(I2S_NUM_0), I2S_RX_MSB_SHIFT); // make sure Philips mode is active
*/


/* from tschundler
https://www.esp32.com/viewtopic.php?t=4997

#include "driver/i2s.h"
#include "soc/i2s_reg.h"

#define BUFLEN 256

static const i2s_port_t i2s_num = I2S_NUM_0; // i2s port number

static const i2s_config_t i2s_config = {
     .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
     .sample_rate = 22050,
     .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
     .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
     .communication_format = (i2s_comm_format_t)(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
     .intr_alloc_flags = 0, // default interrupt priority
     .dma_buf_count = 8,
     .dma_buf_len = 64,
     .use_apll = false
};

static const i2s_pin_config_t pin_config = {
    .bck_io_num = 26,
    .ws_io_num = 25,
    .data_out_num = I2S_PIN_NO_CHANGE,
    .data_in_num = 22
};

void setup() { 
   pinMode(22, INPUT);
   i2s_driver_install(i2s_num, &i2s_config, 0, NULL);   //install and start i2s driver
   REG_SET_BIT(  I2S_TIMING_REG(i2s_num),BIT(9));   //  #include "soc/i2s_reg.h"   I2S_NUM -> 0 or 1
   REG_SET_BIT( I2S_CONF_REG(i2s_num), I2S_RX_MSB_SHIFT);
   i2s_set_pin(i2s_num, &pin_config);
}

int32_t audio_buf[BUFLEN];

void loop() {
    int bytes_read = i2s_read_bytes(i2s_num, audio_buf, sizeof(audio_buf), 0);
    // have fun with your data
}
*/


/*
from 
https://www.esp32.com/viewtopic.php?f=13&t=1756&start=10
Author: michaelboeckling

#include <stdlib.h>
#include <stddef.h>
#include <inttypes.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <sys/time.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_log.h"
#include "driver/i2s.h"

#define TAG "main"

static void init_i2s()
{
	const int sample_rate = 44100;

	// TX: I2S_NUM_0
    i2s_config_t i2s_config_tx = {
	.mode = I2S_MODE_MASTER | I2S_MODE_TX,
	.sample_rate = sample_rate,
	.bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
	.channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,   // 2-channels
	.communication_format = I2S_COMM_FORMAT_I2S_MSB,
	.dma_buf_count = 32,                            // number of buffers, 128 max.
	.dma_buf_len = 32 * 2,                          // size of each buffer
	.intr_alloc_flags = ESP_INTR_FLAG_LEVEL1        // Interrupt level 1
    };

    i2s_pin_config_t pin_config_tx = {
			.bck_io_num = GPIO_NUM_26,
			.ws_io_num = GPIO_NUM_25,
			.data_out_num = GPIO_NUM_22,
			.data_in_num = GPIO_NUM_23
	};
    i2s_driver_install(I2S_NUM_0, &i2s_config_tx, 0, NULL);
    i2s_set_pin(I2S_NUM_0, &pin_config_tx);


    // RX: I2S_NUM_1
    i2s_config_t i2s_config_rx = {
	.mode = I2S_MODE_MASTER | I2S_MODE_RX, // Only TX
	.sample_rate = sample_rate,
	.bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,    // Only 8-bit DAC support
	.channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,   // 2-channels
	.communication_format = I2S_COMM_FORMAT_I2S_MSB,
	.dma_buf_count = 32,                            // number of buffers, 128 max.
	.dma_buf_len = 32 * 2,                          // size of each buffer
	.intr_alloc_flags = ESP_INTR_FLAG_LEVEL1        // Interrupt level 1
	};

	i2s_pin_config_t pin_config_rx = {
		.bck_io_num = GPIO_NUM_17,
		.ws_io_num = GPIO_NUM_18,
		.data_out_num = I2S_PIN_NO_CHANGE,
		.data_in_num = GPIO_NUM_5
	};

	i2s_driver_install(I2S_NUM_1, &i2s_config_rx, 0, NULL);
	i2s_set_pin(I2S_NUM_1, &pin_config_rx);

}


void task_megaphone(void *pvParams)
{
	uint16_t buf_len = 1024;
	char *buf = calloc(buf_len, sizeof(char));

	struct timeval tv = {0};
	struct timezone *tz = {0};
	gettimeofday(&tv, &tz);
	uint64_t micros = tv.tv_usec + tv.tv_sec * 1000000;
	uint64_t micros_prev = micros;
	uint64_t delta = 0;

	init_i2s();

	int cnt = 0;
	int bytes_written = 0;

	while(1)
	{
		char *buf_ptr_read = buf;
		char *buf_ptr_write = buf;

		// read whole block of samples
		int bytes_read = 0;
		while(bytes_read == 0) {
			bytes_read = i2s_read_bytes(I2S_NUM_1, buf, buf_len, 0);
		}

		uint32_t samples_read = bytes_read / 2 / (I2S_BITS_PER_SAMPLE_32BIT / 8);

		//  convert 2x 32 bit stereo -> 1 x 16 bit mono
		for(int i = 0; i < samples_read; i++) {

			// const char samp32[4] = {ptr_l[0], ptr_l[1], ptr_r[0], ptr_r[1]};

			// left
			buf_ptr_write[0] = buf_ptr_read[2]; // mid
			buf_ptr_write[1] = buf_ptr_read[3]; // high

			// right
			buf_ptr_write[2] = buf_ptr_write[0]; // mid
			buf_ptr_write[3] = buf_ptr_write[1]; // high


			buf_ptr_write += 2 * (I2S_BITS_PER_SAMPLE_16BIT / 8);
			buf_ptr_read += 2 * (I2S_BITS_PER_SAMPLE_32BIT / 8);
		}

		// local echo
		bytes_written = samples_read * 2 * (I2S_BITS_PER_SAMPLE_16BIT / 8);
		i2s_write_bytes(I2S_NUM_0, buf, bytes_written, portMAX_DELAY);

		cnt += samples_read;

		if(cnt >= 44100) {
			gettimeofday(&tv, &tz);
			micros = tv.tv_usec + tv.tv_sec * 1000000;
			delta = micros - micros_prev;
			micros_prev = micros;
			printf("%d samples in %" PRIu64 " usecs\n", cnt, delta);

			cnt = 0;
		}
	}
}

void app_main()
{
    printf("starting app_main()\n");
    xTaskCreatePinnedToCore(&task_megaphone, "task_megaphone", 16384, NULL, 20, NULL, 0);
}
 */


/*
felipeduque
from https://www.esp32.com/viewtopic.php?f=13&t=1756&start=40


#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event_loop.h"
#include "esp_log.h"
#include "nvs_flash.h"

#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include "lwip/netdb.h"
#include "lwip/dns.h"
#include "driver/i2s.h"


#define EXAMPLE_ESP_WIFI_MODE_AP   0 //TRUE:AP FALSE:STA
#define EXAMPLE_ESP_WIFI_SSID      "myssid"
#define EXAMPLE_ESP_WIFI_PASS      "mypass"
#define EXAMPLE_MAX_STA_CONN       4

#define SOCKET_PORT "9030"
#define SERVER_IP "10.11.12.13"


static EventGroupHandle_t wifi_event_group;

const int WIFI_CONNECTED_BIT = BIT0;

static const char *TAG = "simple wifi";

static esp_err_t event_handler(void *ctx, system_event_t *event)
{
    switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
        esp_wifi_connect();
        break;
    case SYSTEM_EVENT_STA_GOT_IP:
        ESP_LOGI(TAG, "got ip:%s",
                 ip4addr_ntoa(&event->event_info.got_ip.ip_info.ip));
        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
        break;
    case SYSTEM_EVENT_AP_STACONNECTED:
        ESP_LOGI(TAG, "station:"MACSTR" join, AID=%d",
                 MAC2STR(event->event_info.sta_connected.mac),
                 event->event_info.sta_connected.aid);
        break;
    case SYSTEM_EVENT_AP_STADISCONNECTED:
        ESP_LOGI(TAG, "station:"MACSTR"leave, AID=%d",
                 MAC2STR(event->event_info.sta_disconnected.mac),
                 event->event_info.sta_disconnected.aid);
        break;
    case SYSTEM_EVENT_STA_DISCONNECTED:
        esp_wifi_connect();
        xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);
        break;
    default:
        break;
    }
    return ESP_OK;
}

void wifi_init_softap()
{
    wifi_event_group = xEventGroupCreate();

    tcpip_adapter_init();
    ESP_ERROR_CHECK(esp_event_loop_init(event_handler, NULL));

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    wifi_config_t wifi_config = {
        .ap = {
            .ssid = EXAMPLE_ESP_WIFI_SSID,
            .ssid_len = strlen(EXAMPLE_ESP_WIFI_SSID),
            .password = EXAMPLE_ESP_WIFI_PASS,
            .max_connection = EXAMPLE_MAX_STA_CONN,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK
        },
    };
    if (strlen(EXAMPLE_ESP_WIFI_PASS) == 0) {
        wifi_config.ap.authmode = WIFI_AUTH_OPEN;
    }

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_AP, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "wifi_init_softap finished.SSID:%s password:%s",
             EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);
}

void wifi_init_sta()
{
    wifi_event_group = xEventGroupCreate();

    tcpip_adapter_init();
    ESP_ERROR_CHECK(esp_event_loop_init(event_handler, NULL) );

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    wifi_config_t wifi_config = {
        .sta = {
            .ssid = EXAMPLE_ESP_WIFI_SSID,
            .password = EXAMPLE_ESP_WIFI_PASS
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA) );
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config) );
    ESP_ERROR_CHECK(esp_wifi_start() );

    ESP_LOGI(TAG, "wifi_init_sta finished.");
    ESP_LOGI(TAG, "connect to ap SSID:%s password:%s",
             EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);

}

static void init_i2s()
{
	const int sample_rate = 8000;

    i2s_config_t i2s_config_rx = {
	.mode = I2S_MODE_MASTER | I2S_MODE_RX,
	.sample_rate = sample_rate,
	.bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
	.channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
	.communication_format = (i2s_comm_format_t) (I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
	.dma_buf_count = 32,                            // number of buffers, 128 max.
	.dma_buf_len = 32 * 2,                          // size of each buffer
	.use_apll = 0,
	.intr_alloc_flags = ESP_INTR_FLAG_LEVEL1        // Interrupt level 1
	};

	i2s_pin_config_t pin_config_rx = {
		.bck_io_num = GPIO_NUM_26,
		.ws_io_num = GPIO_NUM_25,
		.data_out_num = I2S_PIN_NO_CHANGE,
		.data_in_num = GPIO_NUM_23
	};

	i2s_driver_install(I2S_NUM_1, &i2s_config_rx, 0, NULL);
	i2s_set_pin(I2S_NUM_1, &pin_config_rx);

	i2s_stop(I2S_NUM_1);
	i2s_start(I2S_NUM_1);

}

void capture_and_send_mic_data()
{
    const struct addrinfo hints = {
        .ai_family = AF_INET,
        .ai_socktype = SOCK_STREAM,
        //.ai_socktype = SOCK_DGRAM,
    };
    struct addrinfo *res = NULL;
	struct addrinfo *rp = NULL;
    int socket_desc = -1;

    // i2s stuff
	uint16_t buf_len = 512;
	char *buf = calloc(buf_len, sizeof(char));

	init_i2s();

    while(1)
    {

        xEventGroupWaitBits(wifi_event_group, WIFI_CONNECTED_BIT,
                            false, true, portMAX_DELAY);
        ESP_LOGI(TAG, "Connected to AP");

        int e = getaddrinfo(SERVER_IP, SOCKET_PORT, &hints, &res);

        if (e != 0)
        {
            ESP_LOGE(TAG, "... getaddrinfo failed errno=%d", errno);
            freeaddrinfo(res);
            vTaskDelay(5000 / portTICK_PERIOD_MS);
            continue;
        }

        for (rp = res; rp != NULL; rp = rp->ai_next)
        {

        	socket_desc = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);

        	if (socket_desc == -1)
        		continue;

        	// if successfully connected, break the loop and go on
			if(connect(socket_desc, rp->ai_addr, rp->ai_addrlen) != -1) {
				break;
			}

			close(socket_desc);
        }


        if (rp == NULL)
        {
        	ESP_LOGE(TAG, "could not connect to socket\n");
			close(socket_desc);
			continue;
        }

        if(socket_desc < 0)
        {
        	ESP_LOGE(TAG, "... Failed to allocate socket.");
        	vTaskDelay(2000 / portTICK_PERIOD_MS);
			close(socket_desc);
        	continue;
        }

        ESP_LOGI(TAG, "... allocated and connected to socket");

		esp_err_t err = ESP_OK;

		size_t bytes_read = 0;

		while(1)
		{
			char *buf_ptr_read = buf;

			while(bytes_read == 0)
			{
				// the last argument plays an important role when trying to
				// reduce buffer underrun when streaming audio. buffer underrun
				// means that the audio player is trying to play an empty buffer.
				err = i2s_read(I2S_NUM_1, buf, buf_len, &bytes_read, 2048);
			}

			uint32_t samples_read = bytes_read / 2 / (I2S_BITS_PER_SAMPLE_32BIT / 8);
			bytes_read = 0;

			// sending only one of two channels (R, L)
			for(int i = 0; i < samples_read; i++)
			{

				int16_t currRSample = (buf_ptr_read[3] << 8) + buf_ptr_read[2];
				//int16_t currLSample = (buf_ptr_read[1] << 8) + buf_ptr_read[0];
				int16_t data = currRSample;

				buf_ptr_read += 2 * (I2S_BITS_PER_SAMPLE_32BIT / 8);

				if (write(socket_desc, &data, sizeof(data)) < 0)
				{
					close(socket_desc);
					freeaddrinfo(res);
					ESP_LOGE(TAG, "... socket send failed. Must try to reconnect...");
					exit(EXIT_FAILURE);
				}
			}

		}

	}
}


void app_main()
{
    //Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
      ESP_ERROR_CHECK(nvs_flash_erase());
      ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

#if EXAMPLE_ESP_WIFI_MODE_AP
    ESP_LOGI(TAG, "ESP_WIFI_MODE_AP");
    wifi_init_softap();
#else
    ESP_LOGI(TAG, "ESP_WIFI_MODE_STA");
    wifi_init_sta();
#endif

    xTaskCreate(&capture_and_send_mic_data, "capture_and_send_mic_data", 4096, NULL, 5, NULL);

}
*/
