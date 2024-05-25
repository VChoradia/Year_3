# Dockerfile to do ESP-IDF/arduino-esp32 setup and firmware build, with a view
# to copying firmware.bin out into the host and doing burn from there; see the
# Makefile for usage details

# basic config
FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Sheffield
WORKDIR /home/ubuntu

# install prerequisites
RUN apt-get update -y
RUN apt-get install -y sudo git wget flex bison gperf \
    python-setuptools cmake ninja-build ccache \
    libffi-dev libssl-dev dfu-util curl unzip xxd \
    python3 python3-pip python3-setuptools
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# install platformio
RUN python3 -c "$(curl -fsSL https://raw.githubusercontent.com/platformio/platformio/master/scripts/get-platformio.py)"
ENV PATH=${PATH}:/root/.platformio/penv/bin

# force install of platforms so as to cache them in a docker layer
RUN cd /home/ubuntu && \
  wget https://gitlab.com/hamishcunningham/the-internet-of-things/-/archive/master/the-internet-of-things-master.tar.gz && \
  tar xzf the-internet-of-things-master.tar.gz && \
  ln -s the-internet-of-things-master tiot
RUN cd /home/ubuntu && \
  cd tiot/exercises/HelloWorld && pio run

# perhaps do older IDF setup too?
# RUN [ -d esp ] || /home/ubuntu/tiot/exercises/HelloWorld/magic.sh setup
