# Dockerfile for 2022 tiot magic.sh plus platformio core ("iot:magic")
#
# create an image using something like
#   docker build .
# run the image using something like
#   docker run --device=/dev/ttyUSB0 <image ID>
# tag and push to hub.docker.com something like
#   docker tag <image ID> hamishcunningham/iot:magic
#   docker push hamishcunningham/iot:magic
# run from docker hub with something like
#   docker run --device=/dev/ttyUSB0 -it \
#     -v $PWD:/home/ubuntu/project hamishcunningham/iot:magic

# params
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
SHELL ["/bin/bash", "-c"]
ARG CLONE_OPTS="--depth=1 --shallow-submodules"

# installs
RUN apt update -y
RUN apt install -y \
  sudo git wget make python3 python3-pip python3-setuptools vim openjdk-11-jre
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10
RUN pip install pyserial

# the ubuntu user
RUN useradd -m -d /home/ubuntu -s /bin/bash -u 1000 ubuntu -G dialout
USER ubuntu
WORKDIR /home/ubuntu
# TODO share these from magic?
ENV SUPPORT_DIR="/home/ubuntu/the-internet-of-things/support"
ENV TOOLING_DIR="${SUPPORT_DIR}/tooling"

# platformio config
ENV PIO_DIR="${TOOLING_DIR}/platformio"
ENV PLATFORMIO_CORE_DIR="${PIO_DIR}"
ENV PIO_BIN="${PIO_DIR}/penv/bin"
ENV PIO_CLI="${PIO_BIN}/pio"
#RUN ln -s "${PIO_DIR}" .platformio
RUN echo 'source ${PIO_BIN}/activate'              >>/home/ubuntu/.bashrc && \
    echo 'export PLATFORMIO_CORE_DIR="${PIO_DIR}"' >>/home/ubuntu/.bashrc && \
    echo 'export PATH=${SUPPORT_DIR}:${PATH}'      >>/home/ubuntu/.bashrc
RUN true

# clone sources and configure
RUN [ -d "the-internet-of-things" ] || \
  git clone ${CLONE_OPTS} https://gitlab.com/hamishcunningham/the-internet-of-things.git
RUN [ -d "unphone" ] || \
  git clone ${CLONE_OPTS} https://gitlab.com/hamishcunningham/unphone.git
RUN [ -d "the-internet-of-things/support/tooling" ] || \
  cd the-internet-of-things/support && ./magic.sh setup
RUN [ -d "the-internet-of-things/support/tooling/Arduino/libraries/unPhone_Library" ] || \
  cd the-internet-of-things/support/tooling/Arduino && \
  ( mv libraries /tmp || : ) && \
  ln -s /home/ubuntu/unphone/lib libraries
RUN true

# cache plaformio/platforms etc. for subsequent runs
ARG HACK_ME=0
RUN cd unphone && git pull && cd ../the-internet-of-things && git pull
RUN true
RUN . .bashrc && cd the-internet-of-things/exercises/HelloWorld && \
  ${PIO_CLI} run
RUN true
RUN . .bashrc && cd unphone/examples/2022 && ./hack.sh
ARG HACK_ME2=0
RUN chmod -R a+rw the-internet-of-things unphone
RUN true
RUN . .bashrc && cd unphone/examples/2022 && \
  ${PIO_CLI} run -e unphone6 && ${PIO_CLI} run -e unphone9

# startup commands
ENTRYPOINT [ "/home/ubuntu/entrypoint.sh" ]
CMD [ "" ]
RUN true
ADD --chown='ubuntu:ubuntu' entrypoint.sh entrypoint.sh
RUN true
RUN chmod 777 entrypoint.sh
