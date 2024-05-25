# Dockerfile for IoT on ESP32 ("hamishcunningham/iot:magic"); see
# https://iot.unphone.net/ for details

# params (espressif IDF 5.1 image is based off ubuntu 20.04)
FROM espressif/idf:v5.1.1
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
SHELL ["/bin/bash", "-c"]
ENV SUPPORT_DIR="/home/ubuntu/the-internet-of-things/support"
ENV TOOLING_DIR="${SUPPORT_DIR}/tooling"
COPY container.gitconfig /root/.gitconfig

# installs
RUN apt update -y
RUN apt install -y \
  apt-transport-https file git libusb-1.0-0 make nano picocom python3 \
  python-is-python3 python3-num2words python3-pip python3-requests \
  python3-setuptools python3-venv tio vim wget
RUN pip install pyserial

# the ubuntu user; clone repos
RUN useradd -l -m -d /home/ubuntu -s /bin/bash -u 1000 ubuntu -G dialout
COPY --chown=1000 container.gitconfig /home/ubuntu/.gitconfig
RUN cd /home/ubuntu && wget \
  https://gitlab.com/hamishcunningham/the-internet-of-things/-/raw/master/support/magic.sh && \
  chmod 755 magic.sh && ./magic.sh clone && pwd && ls && \
  rm magic.sh && \
  chown -R ubuntu:ubuntu the-internet-of-things unphone unPhoneLibrary
USER ubuntu
WORKDIR /home/ubuntu

# platformio config and install
ENV PIO_DIR="${TOOLING_DIR}/platformio"
ENV PLATFORMIO_CORE_DIR="${PIO_DIR}"
ENV PIO_BIN="${PIO_DIR}/penv/bin"
ENV PIO_CLI="${PIO_BIN}/pio"
RUN echo 'source ${PIO_BIN}/activate'              >>/home/ubuntu/.bashrc && \
    echo 'export PLATFORMIO_CORE_DIR="${PIO_DIR}"' >>/home/ubuntu/.bashrc && \
    echo 'export PATH=${SUPPORT_DIR}:${PATH}'      >>/home/ubuntu/.bashrc
RUN mkdir -p ${PIO_DIR}
RUN wget "https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py"
RUN PLATFORMIO_CORE_DIR="${PIO_DIR}" python3 ./get-platformio.py

# cache platformio build dependencies
RUN . .bashrc && cd unPhoneLibrary/examples/everything && ${PIO_CLI} run -e unphone9 \
              && ${PIO_CLI} pkg install --global -t tool-mkspiffs --global -t tool-mkfatfs --global -t tool-mklittlefs \
              && ${PIO_CLI} pkg install --global -t "platformio/framework-arduinoespressif32@^3.20014.231204"
RUN . .bashrc && cd the-internet-of-things/exercises/HelloWorld && ${PIO_CLI} run

# startup commands
ENTRYPOINT [ "/home/ubuntu/entrypoint.sh" ]
CMD [ "" ]
ADD --chown='ubuntu:ubuntu' entrypoint.sh entrypoint.sh
RUN chmod 775 entrypoint.sh
