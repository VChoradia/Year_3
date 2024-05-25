# Dockerfile for CircuitPython builds ("hamishcunningham/iot:circuitpython");
# based on https://learn.adafruit.com/building-circuitpython/build-circuitpython
# see https://iot.unphone.net/ for details

# params
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
SHELL ["/bin/bash", "-c"]
ARG TARGET_BOARD="adafruit_feather_esp32s3_4mbflash_2mbpsram"
ENV BUILD_BOARD=$TARGET_BOARD
ARG TARGET_REPO_VERSION="adafruit"
ENV BUILD_REPO_VERSION=$TARGET_REPO_VERSION
ARG TARGET_REPO_BRANCH="main"
ENV BUILD_REPO_BRANCH=$TARGET_REPO_BRANCH
WORKDIR /circuitpython

# installs
RUN apt update -y
RUN apt install -y \
  gettext \
  make vim nano apt-transport-https file \
  sudo git wget flex bison gperf python3 python3-pip python3-setuptools \
  cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10
RUN pip install pyserial

# pull in the sources
RUN git clone https://github.com/${BUILD_REPO_VERSION}/circuitpython.git
WORKDIR /circuitpython/circuitpython
RUN git fetch --tags --recurse-submodules=no --shallow-since="2021-07-01" \
  https://github.com/adafruit/circuitpython HEAD
RUN git checkout ${BUILD_REPO_BRANCH}
RUN make fetch-submodules

# install Python packages from pypi.org
RUN pip3 install --upgrade -r requirements-dev.txt
RUN pip3 install --upgrade -r requirements-doc.txt

# intall pre-commit
RUN pre-commit install

# build the cross compiler
RUN make -C mpy-cross

# set up IDF
WORKDIR ports/espressif
RUN esp-idf/install.sh esp32s3

# fix up some python dependencies that didn't make it through pip
RUN . esp-idf/export.sh && \
  /root/.espressif/python_env/idf4.4_py3.10_env/bin/pip install minify_html jsmin && \
  /root/.espressif/python_env/idf4.4_py3.10_env/bin/pip install --no-deps gdbgui

# run a build for the target board
RUN . esp-idf/export.sh && make BOARD="${BUILD_BOARD}"

# we're done; try something like this:
RUN echo "docker cp mycontainer:${PWD}/build-${BUILD_BOARD}/firmware.bin ."
RUN echo "and flash the .bin to your board; good luck!"
