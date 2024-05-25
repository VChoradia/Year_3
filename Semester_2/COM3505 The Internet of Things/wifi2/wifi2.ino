#include <Arduino.h>

extern char MAC_ADDRESS[];
void getMAC(char *);
extern const char *boiler[];

char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator  // a simple web server



void setup() {
  // put your setup code here, to run once:
   Serial.begin(9600);

   while(!Serial);

  getMAC(MAC_ADDRESS);  
  Serial.println(MAC_ADDRESS);   
  Serial.print("Hiiii");
  delay(3000);
  Serial.print("Helloo");
  
}

void loop() {
  // put your main code here, to run repeatedly:
}

void getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion...
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed relative to normal Arduino
  for(int i=0, j=11; i<=10; i+=2, j-=2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
}
