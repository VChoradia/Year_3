#!/bin/bash
# download dudley's watch sketch and libraries

cat <<EOF

Setting up LilygoWatch from Bill Dudley...
  https://github.com/wfdudley/T-watch-2020
Versions:
  arduino-esp32 core 1.0.6, ESP IDF 3.3.5
(Won't currently compile with IDF 4+.)

EOF

# if we need a copy of Arduino IDE...
if [ x$1 == x-a ]
then
  wget https://downloads.arduino.cc/arduino-1.8.13-linux64.tar.xz
  tar xJvf arduino-1.8.13-linux64.tar.xz
  rm arduino-1.8.13-linux64.tar.xz
fi

# if we need a copy of the course tree...
# wget https://gitlab.com/hamishcunningham/the-internet-of-things/-/archive/master/the-internet-of-things-master.tar.gz && \
# tar xzf the-internet-of-things-master.tar.gz && \
# rm the-internet-of-things-master.tar.gz

wget https://github.com/wfdudley/T-watch-2020/archive/refs/heads/master.zip
unzip master.zip
mv T-watch-2020-master DudleyWatch
rm master.zip

mkdir lib
cd lib

wget https://github.com/Xinyuan-LilyGO/TTGO_TWatch_Library/archive/refs/heads/master.zip
unzip master.zip
mv TTGO_TWatch_Library-master TTGO_TWatch_Library
rm master.zip

wget https://github.com/bxparks/AceTime/archive/v1.6.tar.gz
tar xvzf v1.6.tar.gz 
rm       v1.6.tar.gz 

wget https://github.com/bxparks/AceCommon/archive/v1.4.3.tar.gz
tar xvzf v1.4.3.tar.gz 
rm       v1.4.3.tar.gz 

wget https://github.com/bblanchon/ArduinoJson/archive/v6.17.3.tar.gz
tar xvzf v6.17.3.tar.gz 
rm       v6.17.3.tar.gz 

wget https://github.com/Bodmer/TFT_eSPI/archive/2.3.60.tar.gz
tar xvzf 2.3.60.tar.gz 
rm       2.3.60.tar.gz 

wget https://github.com/earlephilhower/ESP8266Audio/archive/1.8.1.tar.gz
tar xvzf 1.8.1.tar.gz 
rm       1.8.1.tar.gz 

wget https://github.com/JHershey69/OpenWeatherOneCall/archive/v3.0.5.tar.gz
tar xvzf v3.0.5.tar.gz 
rm       v3.0.5.tar.gz 

wget https://github.com/knolleary/pubsubclient/archive/v2.8.tar.gz
tar xvzf v2.8.tar.gz 
rm       v2.8.tar.gz 

wget https://github.com/arduino-libraries/NTPClient/archive/3.2.0.tar.gz
tar xvzf 3.2.0.tar.gz 
rm       3.2.0.tar.gz 

echo You should be good to go. See README.mkd 
