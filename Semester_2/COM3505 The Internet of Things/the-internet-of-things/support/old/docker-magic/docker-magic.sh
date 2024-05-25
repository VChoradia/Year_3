#!/bin/bash
# docker-magic.sh

# TODO
# dckr suite
# - test non-1000 users
# - maybe base off IDF image?
#   FROM espressif/idf:release-v5.0
#   and don't do installs except vim and openjdk, and pyserial
# - updated platformio.ini in HelloWorld
# - mkesp builds
# - docs
#   - magic.sh has pio and mkesp (later maybe also idf & ardcli) commands
#   - the dckr command just takes the same args and runs them in the container

DCKR_TAG=hamishcunningham/iot:magic
DCKR_IMAGE_WDIR=/home/ubuntu/project
# TODO
DCKR_DEV=/dev/ttyACM0
DCKR_DEV=/dev/ttyUSB0
DCKR_XSOCKS=/tmp/.X11-unix
DCKR_NO_CACHE=
export DCKR_UID=1000
export DCKR_GID=1000

# create an image and tag it
build-and-tag() {
  echo "building, DCKR_NO_CACHE=$DCKR_NO_CACHE"
  docker build $DCKR_NO_CACHE .
  LAST_BUILD=$(docker images --format='{{.ID}}' | head -1)
  echo "tagging"
  docker tag ${LAST_BUILD} ${DCKR_TAG}
}
build-and-tag-no-cache() {
  DCKR_NO_CACHE="--no-cache" build-and-tag $*
}

# push to hub.docker.com
push-to-hub() {
  docker push ${DCKR_TAG}
}

# pull from hub.docker.com
pull-from-hub() {
  docker pull ${DCKR_TAG}
}

# run a shell on the image; may or may not be interactive depending on $*
# note: was "shell"
shell() {
# TODO not needed now we have --group-add ?
# # try to fix uid problems if we're not user 1000
# if [ $(id -u) != 1000 ]
# then
#   echo "changing group: sudo chgrp -R $(id -g) ."
#   sudo chgrp -R $(id -g) . # if doesn't work try: chmod -R a+rw .
# fi

  # docker run
  COM="docker run --device=${DCKR_DEV} -it \
    --user ${DCKR_UID}:${DCKR_GID} --group-add=dialout --group-add=ubuntu \
    -v ${PWD}:${DCKR_IMAGE_WDIR} \
    -v ${DCKR_XSOCKS}:${DCKR_XSOCKS} \
    --env DISPLAY \
    ${DCKR_TAG} $*"
  echo "${COM}"
  ${COM}
}

# run
$*
