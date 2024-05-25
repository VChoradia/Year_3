#!/bin/bash
# magic.sh
# scripts for configuring and building iot firmware for the ESP32 and unPhone
# hamish, autumn 2021 (seeded from dckrbldr.sh and old magic.sh)
# (docker-magic.sh incorporated summer 2022)

# parameters ################################################################

# boilerplate locals
alias cd='builtin cd'
P="$(realpath -e $0)"
USAGE="
`basename ${P}` [-h(elp)] [-H(elp, long)] [-d(ebug)]
  [-D(ocker)]   (run the command in the docker container)
  [-t(ag)]      (name of the docker image)
  [-p(ort)]     (port of the board you want to operate on)
  [-P(ort)]     (for docker, which ports to map; can have multiple)
  [-b(oard)]    (board name, e.g. unphone7, unphone9, featheresp32)
  [-K(it off)]  (unset DOCKER_BUILDKIT)
  [-l(oop)]     loop the command, e.g. for repeating compile/burn/monitor
  [-M(ap)]      map VSCode directories locally in docker (tooling/vscode-...)
  [-I(DEs)]     install IDEs (Arduino, VSCode) in docker
  [-e(xtra)]    permissions on the (mapped) project directory (. when -D)
  command-name  (command to run)
  [args]        (command args)"
DBG=:
OPTIONSTRING=hHdt:p:b:P:DKMIel

# specific locals
export SUPPORT_DIR="$(cd `dirname ${P}` && pwd)"
export TOOLING_DIR="${SUPPORT_DIR}/tooling"
export UNPHONE_DIR="$(cd `dirname ${P}`/../../unphone 2>/dev/null && pwd || echo $HOME/unphone)"
export PYTHON_DIR="${SUPPORT_DIR}/circuitpython"
export HOST_ARCH=$(arch)
export ARM64_ARCH=aarch64
export X86_64_ARCH=x86_64
export MKESP_DIR="${TOOLING_DIR}/makeEspArduino"
export MKESP_BUILD_DIR="${PWD}/.mkESP"
export MKESP_GIT="https://github.com/plerup/makeEspArduino.git"
export ARDIDE_VER="arduino-1.8.19"
export ARDIDE_DIR=${TOOLING_DIR}/${ARDIDE_VER}
export ARDIDE_PREFS_DIR=${TOOLING_DIR}/dot-arduino15
export ARDIDE_PREFS=${ARDIDE_PREFS_DIR}/preferences.txt
export ARDIDE_SKETCHBOOK_DIR=${TOOLING_DIR}/Arduino
export ARDIDE_BIN_DIR="build/ardide-bin-output"
export ARDUINO_ESPRESSIF_DIR=${ARDIDE_SKETCHBOOK_DIR}/hardware/espressif
export ARDUINO_ESP32_DIR=${ARDUINO_ESPRESSIF_DIR}/esp32
export ARDUINO_ESP32_GIT="https://github.com/espressif/arduino-esp32"
#export ARDUINO_ESP32_GIT="https://github.com/hamishcunningham/arduino-esp32"
export ARDUINO_ESP32_VER="2.0.7"
export ARDUINO_ESP32_VER=HEAD
export TIOT_GIT="https://gitlab.com/hamishcunningham/the-internet-of-things.git/"
export UNPHONE_GIT="https://gitlab.com/hamishcunningham/unphone.git/"
export UNPHONE_LIBRARY_GIT="https://gitlab.com/hamishcunningham/unPhoneLibrary.git/"
export IDF_VER="v4.4.5"
export IDF_GIT="https://github.com/espressif/esp-idf.git"
export CLONE_OPTS="--depth=1 --shallow-submodules"
export PORTS_LIST=""
export DEFAULT_PORTS=\
"/dev/ttyACM0 /dev/ttyACM1 /dev/ttyACM2 /dev/ttyACM3 /dev/ttyUSB0 /dev/ttyUSB1"
export UPLOAD_PORT="$(for p in ${DEFAULT_PORTS}; do [ -e ${p} ] && echo ${p}; done)"
export MONITOR_PORT="${UPLOAD_PORT}"
export DCKR=""
export DCKR_TAG=hamishcunningham/iot:magic
export DCKR_PY_TAG=hamishcunningham/iot:circuitpython
export DCKR_IMAGE_WDIR=/home/ubuntu/project
export DCKR_XSOCKS=/tmp/.X11-unix
export DCKR_NO_CACHE=
export DCKR_UID=1000
export DCKR_GID=1000
export BOARD="unphone9"
#export BOARD="featheresp32"
export PLATFORMIO_CORE_DIR="${TOOLING_DIR}/platformio"
export VSCODE_PREFS_LINK=${HOME}/.vscode
export VSCODE_PREFS_DIR=${TOOLING_DIR}/dot-vscode
export VSCODE_SERVER_PREFS_LINK=${HOME}/.vscode-server
export VSCODE_SERVER_PREFS_DIR=${TOOLING_DIR}/dot-vscode-server
export VSCODE_EXTS="platformio.platformio-ide ms-vscode-remote.remote-containers"
export VSCODE_MAP_LOCALLY=
export INSTALL_IDES=
export EXTRA_PERMS=
export LOOPING=


# usage, options ############################################################

# message & exit if exit num present
R='\033[0;31m'; G='\033[0;32m'; B='\033[1;34m'; Y='\033[0;93m';
M='\033[0;95m'; C='\033[0;96m'; N='\033[0m'   ;
e() { (
  c=""; case $1 in R|G|B|Y|M|C|N) c=${!1}; shift; ;; esac; echo -e "${c}$*${N}";
) } # Y M C N
usage() { e G "usage: $USAGE"; [ ! -z "$1" ] && exit $1; }

# process options
ALL_ARGS=$*
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h) usage 0 ;;
    H) $P build-help |more ;;
    d) DBG=echo ;;
    D) DCKR=1 ;;
    b) BOARD="${OPTARG}" ;;
    t) DCKR_TAG="${OPTARG}" ;;
    p) UPLOAD_PORT="${OPTARG}"; MONITOR_PORT="${UPLOAD_PORT}" ;;
    P) PORTS_LIST="${PORTS_LIST} ${OPTARG}" ;;
    K) unset DOCKER_BUILDKIT ;;
    M) VSCODE_MAP_LOCALLY=1 ;;
    I) INSTALL_IDES=1 ;;
    e) EXTRA_PERMS=1 ;;
    l) LOOPING=1 ;;
    *) usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`
ARGS=$*
MAGIC_COM=$1

# debug
if [ "$DBG" != ":" ]
then
  MSG="
    $P in $PWD
    DCKR=$DCKR
    DCKR_TAG=$DCKR_TAG
    BOARD=$BOARD
    UPLOAD_PORT=|${UPLOAD_PORT}|
    MONITOR_PORT=|${MONITOR_PORT}|
    PORTS_LIST=|${PORTS_LIST}|
    \$*=$*
    ARGS=${ARGS}
    ALL_ARGS=${ALL_ARGS}
    MAGIC_COM=${MAGIC_COM}
  "
  e C "$MSG"
  exit 999
fi

e G "making magic in ${N}${PWD}"

# chip support ###############################################################
case $BOARD in
  unphone7) CHIP=esp32   ;;
  unphone9) CHIP=esp32s3 ;;
  *) e "R board unknown $BOARD"; usage 1 ;;
esac

# docker container support ##################################################

# ports to map for docker
PORTS_LIST="$(echo $PORTS_LIST |xargs)"
[ -z "${PORTS_LIST}" ] && PORTS_LIST="${UPLOAD_PORT}"

# run a shell on the image; may or may not be interactive depending on $*
# (PORTS_LIST defaults to UPLOAD_PORT; all ports given are --device mapped)
# (note: was "shell" in docker-magic.sh and do-dckr here previously)
if [ "$DCKR" == "1" ]
then
  DCKR_ARGS="$(echo ${ALL_ARGS} |sed 's,-D,,g')"
  e Y "going to docker run ${DCKR_ARGS}..."

  # if there's no sketch, check we want to continue
  FOUND_SKETCH=""
  for f in sketch/sketch.ino main/main.cpp src/main.cpp
  do
    [ -f $f ] && FOUND_SKETCH=1
  done
  [ x$FOUND_SKETCH != x1 -o ${PWD} == ${HOME} ] && {
    e R "no obvious sketch here, or in HOME; cd somewhere else?"
    e B "RTN to continue or CNTRL&C to exit"
    read X
  }

  # allow group write on the mapped project
  [ "$EXTRA_PERMS" == "1" ] && (
    chmod g+rw . 2>/dev/null
    chmod g+s `find . -type d -maxdepth 1 2>/dev/null` 2>/dev/null
  )

# TODO remove VScode everywhere
# # map ~/.vscode
# VSCODE_MAPS=
# if [ "$VSCODE_MAP_LOCALLY" == "1" ]
# then
#   e R "oops, not finished"
#   exit 0
## TODO need to be relative in the container (~ = ubuntu)
#   VSCODE_MAPS="-v ${VSCODE_PREFS_DIR}:${VSCODE_PREFS_DIR} \
#     -v ${VSCODE_SERVER_PREFS_DIR}:${VSCODE_SERVER_PREFS_DIR}"
# fi

  # NOTE: if you hit uid problems when not user 1000 on the host you might try:
  # if [ $(id -u) != 1000 ]
  # then
  #   e G "changing group: sudo chgrp -R $(id -g) ."
  #   sudo chgrp -R $(id -g) . # if doesn't work try: chmod -R a+rw .
  # fi
# TODO remove additional groups everywhere
  COM="docker run -it \
    $([ -e "${UPLOAD_PORT}" ] && echo -n --device=${UPLOAD_PORT}) \
    $(for p in ${PORTS_LIST}; do echo -n --device=${p}' '; done) \
    --user ${DCKR_UID}:${DCKR_GID} --group-add=dialout --group-add=ubuntu \
    -v ${PWD}:${DCKR_IMAGE_WDIR} \
    -v ${DCKR_XSOCKS}:${DCKR_XSOCKS} \
    --env DISPLAY --env MAGIC_COM=${MAGIC_COM} \
    ${DCKR_TAG} ${DCKR_ARGS}"
  e G "${COM}"
  ${COM}
  RTN_VAL=$?

# chmod g-s `find . -type f` 2>/dev/null
  e Y "...finished docker run"
  exit $RTN_VAL
fi


# various utility functions #################################################

# long help text
do-build-help() {
  e M "$P commands available are:"
  tac $P >/tmp/$$
  for n in `grep -n '^do-[a-z0-9-]*() {' /tmp/$$ |sed 's,:.*$,,' |tac`
  do
    $DBG $n >&2
    nn=$((n+1))
    FNAME=`sed -n "${n}p" /tmp/$$ |sed -e 's,do-,,' -e 's,().*,,'`
    echo -en "$G${FNAME}: $N"
    sed -n "${nn},/^$/p" /tmp/$$ |sed 's,^#, ,' |tac
  done
}

# list /dev/tty[UA]*
do-ls-ports() { ls /dev/tty[UA]*; }

# short hash of the current commit
do-git-hash() { git log --pretty=format:'%h' -n 1; }

# copy this firmware tree, modifying the name; $1 should have the new name
do-copy-me-to() {
  BASEDIR="$(cd `dirname ${P}` && pwd)"
  MYNAME=`basename $PWD`
  PROJECT=$1
  PDIR=$PROJECT
  PNAME=`basename $PDIR`

  [ -e $PROJECT ] && { e R "oops: $PROJECT exists"; exit 1; }
  e B "creating project $PROJECT ..."

  COPYCANDIDATES=`ls -A`
  mkdir -p $PDIR
  for f in $COPYCANDIDATES
  do
    grep -qs "^${f}$" .gitignore || { cp -a ${f} $PDIR && e B $f copied; }
  done
  (
    cd $PDIR
    for f in `grep -sl ${MYNAME} * */*`
    do
      e B "sed $MYNAME to $PNAME in $f"
      sed -i "s,${MYNAME},$PNAME,g" $f
    done
    e G "$PNAME created at $PDIR"
  )
}

# run a web server in the build directory for firware OTA
do-ota-httpd() {
  # firmware versioning
  FIRMWARE_VERSION=$(grep 'int firmwareVersion =' main/main.cpp |
    sed -e 's,[^0-9]*,,' -e 's,;.*$,,')

  # create downloads for the httpd server, .bin and version
  cd build
  mkdir -p fwserver
  cd fwserver
  echo $FIRMWARE_VERSION >version
# TODO use the exported .bin name from docker or /tmp/mkesp
# [ -f Thing.bin ] || cp ../Thing.bin ${FIRMWARE_VERSION}.bin

  python -m http.server 8000
}

# scratchpad
# tinyuf2 build derived from
# https://github.com/adafruit/tinyuf2/blob/master/.github/workflows/build_esp32.yml
do-scratch() {
  if false; then        # already done
    :
  elif true; then       # to do now
    :
    # build and flash a Tiny UF2 bootloader
#   [ -d ~/tinyuf2 ] || cd $HOME && git clone \
#     git@github.com:hamishcunningham/tinyuf2.git
#   cd ~/tinyuf2
    # pull in tinyusb
#   git submodule update --init lib/tinyusb lib/uf2
    # make the bootloader and flash it
    # TODO set XBOARD to unphone9
    # TODO should be 4mb psram board?
    #XBOARD=adafruit_feather_esp32s3
    XBOARD=unphone
    UPLOAD_PORT=/dev/ttyACM1
    docker run --rm -v $PWD:/project -w /project --device=${UPLOAD_PORT} \
      espressif/idf:release-v4.4 \
      /bin/bash -c "git config --global --add safe.directory /project && make -C ports/espressif/ BOARD=${XBOARD} all self-update copy-artifact flash"

#     /bin/bash -c "git config --global --add safe.directory /project && make -C ports/espressif/ BOARD=${XBOARD} all self-update copy-artifact && cd ports/espressif && /opt/esp/python_env/idf4.4_py3.8_env/bin/python ../../../opt/esp/idf/components/esptool_py/esptool/esptool.py -p ${UPLOAD_PORT} -b 460800 --before default_reset --after hard_reset --chip esp32s3 write_flash --flash_mode dio --flash_size detect --flash_freq 80m 0x0 _build/${XBOARD}/bootloader/bootloader.bin 0x8000 _build/${XBOARD}/partition_table/partition-table.bin 0xe000 _build/${XBOARD}/ota_data_initial.bin 0x2d0000 _build/${XBOARD}/tinyuf2.bin"


#   # flash it
#   # alternatively: "idf.py -p (PORT) flash"
#   docker run --rm -v $PWD:/project -w /project --device=${UPLOAD_PORT} \
#     espressif/idf:release-v4.4 \
#     /bin/bash -c "/opt/esp/python_env/idf4.4_py3.8_env/bin/python ../../../opt/esp/idf/components/esptool_py/esptool/esptool.py -p ${UPLOAD_PORT} -b 460800 --before default_reset --after hard_reset --chip esp32s3 write_flash --flash_mode dio --flash_size detect --flash_freq 80m 0x0 _build/adafruit_feather_esp32s3/bootloader/bootloader.bin 0x8000 _build/adafruit_feather_esp32s3/partition_table/partition-table.bin 0xe000 _build/adafruit_feather_esp32s3/ota_data_initial.bin 0x2d0000 _build/adafruit_feather_esp32s3/tinyuf2.bin"

  else                  # to do later
    :
#   XBOARD=adafruit_feather_esp32s3
#   docker run --rm -v $PWD:/project -w /project --device=${UPLOAD_PORT} \
#     espressif/idf:release-v4.4 \
#     /bin/bash -c "git config --global --add safe.directory /project && make -C ports/espressif/ BOARD=${XBOARD} LOG=1 all && cd ports/espressif && /opt/esp/python_env/idf4.4_py3.8_env/bin/python ../../../opt/esp/idf/components/esptool_py/esptool/esptool.py -p ${UPLOAD_PORT} -b 460800 --before default_reset --after hard_reset --chip esp32s3 write_flash --flash_mode dio --flash_size detect --flash_freq 80m 0x0 _build/${XBOARD}/bootloader/bootloader.bin 0x8000 _build/${XBOARD}/partition_table/partition-table.bin 0xe000 _build/${XBOARD}/ota_data_initial.bin 0x2d0000 _build/${XBOARD}/tinyuf2.bin"
  fi
}

# list likely device ports
do-lsports() { ls -l /dev/ttyUSB* /dev/ttyACM* /dev/cu.SLAB* 2>/dev/null; }

# test rig
do-test() {
  e G "testing, testing, 1 2 3... in $PWD"
  e Y "(expecting to see spins 6/7/8/9 on ports /dev/ttyUSB0/1/2 and /dev/ttyACM0)"
  port_num=0
  time for spin_num in 6 7 8 9
  do
    DO_ASK=''
    [ x$1 == x-i ] && DO_ASK='(y/n)'

    PORT="/dev/ttyUSB${port_num}"
    [ $port_num == 3 ] && PORT='/dev/ttyACM0'
    port_num=$((port_num+1))
    SPIN="unphone${spin_num}"
    e B "going to build $SPIN on $PORT...${DO_ASK}"

    # interactive mode
    MONITOR=""
    if [ x$1 == x-i ]
    then
      MONITOR="-t monitor"
      read ANS
      [ x$ANS == xy ] || { e Y "ok, skipping ${SPIN}"; continue; }
    fi

    do-pio run --upload-port $PORT --monitor-port $PORT \
      -e $SPIN -t upload $MONITOR
  done |tee /tmp/unphone6789-tests.txt
  e G "test done"
}

# a big, docker-based test, for spins 6/7/8/9 (on expected ports)
do-6789() {
  magic.sh -P /dev/ttyUSB0 -P /dev/ttyUSB1 -P /dev/ttyUSB2 -P /dev/ttyACM0 \
    -D test
}


# build methods #############################################################

# run the Arduino IDE, using preferences and Arduino/ from ./tooling
do-arduino() {
  e G "running ${ARDIDE_DIR}/arduino --preferences-file $ARDIDE_PREFS $*"
  ${ARDIDE_DIR}/arduino --preferences-file $ARDIDE_PREFS $*
}

# build with Espressif's ESP-IDF docker images (via idf.py); does things like:
#   docker run --device=/dev/ttyUSB0:/dev/ttyUSB0 -ti --rm -v \
#     $PWD:/project -w /project espressif/idf idf.py build
# results (e.g. build/, sdkconfig) will be exported to the current directory;
# options are passed to idf.py so use e.g.:
#   flash monitor         burn and listen (the default)
#   build                 just compile
#   set-target esp32s3    set a chip type
#   menuconfig            configure
#   monitor               listen on serial
do-idf() {
  ARGS=$*
  [ x"$*" == x ] && ARGS="flash monitor"
  docker run --device=/dev/ttyACM0:/dev/ttyACM0 -ti --rm \
    -v $PWD:/project -w /project espressif/idf:${IDF_VER} \
    /bin/bash
#   idf.py $ARGS
}

# build with makeEspArduino.mk
# takes a command name and .ino as arguments (in that order);
# if not given, the command defaults to "run", which does build/flash/monitor;
# if not given, the sketch defaults to sketch/sketch.ino if it exists, or
# other .ino if found;
# unphone libs are included if unphone.h is #included from the source (you
# can force their or other lib inclusion via e.g. LIBS=~/unphone/lib ...)
do-mkesp() {
  do-hack
  CNAME=run
  SFILE=sketch/sketch.ino
  ARGS=""
  while :
  do
    [ -z "$1" ] && break
    case "$1" in
      *.ino) SFILE="$1" ;;
      *=*)   ARGS="$1 ${ARGS}" ;;
      *)     CNAME="$1" ;;
    esac
    shift
  done
  [ -f "${SFILE}" ] || { set `find . -maxdepth 1 -name '*.ino'`; SFILE="$1"; }
  [ -f "${SFILE}" ] || { e R "can't find a .ino $SFILE, giving up!"; exit 1; }
  SKETCH="SKETCH=${SFILE}"
  SKETCH_DIR="`dirname ${SFILE}`"

  grep -q '^[      ]*#include[     ]*["<]unphone\.h' $SKETCH_DIR/* &&
    { e B adding unphone/lib to LIBS; LIBS="${UNPHONE_DIR}/lib ${LIBS}"; }

  COM="make -f ${MKESP_DIR}/makeEspArduino.mk ESP_ROOT=${ARDUINO_ESP32_DIR} \
    BOARD=${BOARD} UPLOAD_PORT=${UPLOAD_PORT} CHIP=esp32 LIBS=${LIBS} \
    BUILD_ROOT=${MKESP_BUILD_DIR} \
    ${SKETCH} ${ARGS} ${CNAME}"
  e Y "${COM}"
  eval ${COM}
}

# build with platformio core
# assumptions:
# - your platformio.ini includes an environment named after your
#   board (e.g. env:featheresp32 or env:unphone9)
# - you have a board attached and we know the port
# examples (on docker):
# - magic.sh -D pio run -e unphone9 -t upload -t monitor
# - magic.sh -b unphone9 -D pio
do-pio() {
  . ${PLATFORMIO_CORE_DIR}/penv/bin/activate
  do-hack

  if [ ! -f platformio.ini ]
  then
    e R "there's no platformio.ini here; create one? y/n"
    read ANS
    [ x$ANS == xy ] || { e B "ok, giving up"; exit 1; }
    cp ${SUPPORT_DIR}/pio-template.ini platformio.ini
  fi

  if [ -z "$*" ]
  then
    COM="pio run -e ${BOARD} \
      --upload-port ${UPLOAD_PORT} --monitor-port ${MONITOR_PORT} \
      -t upload -t monitor"
  else
    COM="pio $*"
  fi
  e Y "${COM}"
  eval ${COM}
}

# run a shell with the platformio core python environment activated
do-use-pio() {
  bash -c "( . ${PLATFORMIO_CORE_DIR}/penv/bin/activate;
    PROMPT_COMMAND='echo -n use-pio:\ ' bash; )"
}

# run a pio compile, an esptool burn and picocom monitoring
# (the advantage is that both the burn and monitoring start more quickly)
# NOTE that the esptool command needs tinkering with for boards other than 9
do-quick() {
  e M "\npio build"
  source ${PLATFORMIO_CORE_DIR}/penv/bin/activate
  pio run -e ${BOARD} || exit $?

  if [ $CHIP == esp32s3 ]
  then
    e M "\nesptool for unphone9"
    ${PLATFORMIO_CORE_DIR}/penv/bin/python \
      "${PLATFORMIO_CORE_DIR}/packages/tool-esptoolpy/esptool.py" \
      --chip ${CHIP} --port "${UPLOAD_PORT}" \
      --baud 921600 --before default_reset \
      --after hard_reset write_flash \
      -z \
      --flash_mode dio \
      --flash_freq 80m \
      --flash_size 8MB \
      0x0000 ${PLATFORMIO_CORE_DIR}/packages/framework-arduinoespressif32/tools/sdk/esp32s3/bin/bootloader_qio_80m.bin \
      0x8000 ${PWD}/.pio/build/${BOARD}/partitions.bin \
      0xe000 ${PLATFORMIO_CORE_DIR}/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin \
      0x10000 ${PWD}/.pio/build/${BOARD}/firmware.bin || exit $?
  elif [ $CHIP == esp32 ]
  then
    e M "\nesptool for unphone7"
    ${PLATFORMIO_CORE_DIR}/penv/bin/python \
      "${PLATFORMIO_CORE_DIR}/packages/tool-esptoolpy/esptool.py" \
      --chip ${CHIP} --port "${UPLOAD_PORT}" \
      --baud 921600 --before default_reset \
      --after hard_reset write_flash \
      -z \
      --flash_mode dio \
      --flash_freq 40m \
      --flash_size 4MB \
      0x1000 ${PLATFORMIO_CORE_DIR}/packages/framework-arduinoespressif32/tools/sdk/esp32/bin/bootloader_dio_40m.bin \
      0x8000 ${PWD}/.pio/build/${BOARD}/partitions.bin \
      0xe000 ${PLATFORMIO_CORE_DIR}/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin \
      0x10000 .pio/build/${BOARD}/firmware.bin || exit $?
  else
    e R "unknown chip ${CHIP}"; exit 1
  fi

  do-pico $*
}

# run picocom monitor
do-pico() {
  e M "\npicocom: C-a C-x to quit;${G} -r to loop; ${M}>STOP to quit loop"
  e Y picocom --quiet -b 115200 --nolock --imap lfcrlf ${MONITOR_PORT}
  while [ ! -f STOP ]
  do
    picocom --quiet -b 115200 --nolock --imap lfcrlf ${MONITOR_PORT}
    [ x$1 == x-r ] || break
  done
  [ -f STOP ] && mv STOP /tmp
}

# if ./hack.sh is executable, run it
# (to fix things like relative links, for example, before running platformio
# or docker builds)
do-hack() {
  [ -x ./hack.sh ] && ( e Y "running ./hack.sh..."; ./hack.sh )
}

# convert an old magic.sh build to a mkesp build by swapping the way main/ and
# sketch/ are linked (partly because mkesp's perl absolute path function
# dereferences links, so app_main.c won't compile as C, and partly because
# windoze Arduino IDE users can't open links from sketch/)
do-convert2mkesp() {
  [ -d main ]   || { e R "oops no main dir"; exit 1; }
  [ -d sketch ] || { e R "oops no sketch dir"; exit 1; }
  [ -L sketch/sketch.ino ] || {
    e R "oops, sketch.ino seems to be a file: has been converted already?"
    exit 1
  }
  cd sketch
  for f in *
  do
    [ -L $f ] || continue
    TARGET=$(readlink $f)
    rm $f
    mv $TARGET $f
    ( cd $(dirname $TARGET) && ln -s ../sketch/$f $(basename $TARGET) )
  done

  e Y "conversion changes made, check in?"
  cd ..
  e Y "sketch:"
  ls -l sketch
  e Y "main:"
  ls -l main
  git status .
}

# create a sketch suitable for mkesp (or ArdIDE) compilation from an IDF
# project; this is only a basic conversion for illustration purposes, and
# doesn't cope with extra components, or Kconfig, or etc.
do-idf2sketch() {
  [ -d sketch ] && { e R "oops, sketch already exists"; exit 1; }
  [ -d main ]   || { e R "oops, no main"; exit 2; }

  mkdir sketch
  cd sketch
  for f in ../main/*.h ../main/*.c
  do
    case $f in
      *main.c) continue ;;
      *) [ -f $f ] && ln -s $f ;;
    esac
  done
  sed -e 's,void app_main(,void loop(void) { }\nvoid setup(,' \
    ../main/*main.c >sketch.ino

  e G 'basics done; any config from main/Kconfig.projbuild also needed'
}


# setup methods #############################################################

# clone the-internet-of-things, unphone and unPhoneLibrary repositories from
# gitlab (normally this should be done to $HOME)
# if the repos already exist, do a pull
do-clone() {
  if [ ! -d the-internet-of-things ]
  then
    git clone ${CLONE_OPTS} $TIOT_GIT
  else
    ( cd the-internet-of-things && git pull )
  fi
  if [ ! -d unphone ]
  then
    git clone ${CLONE_OPTS} $UNPHONE_GIT
  else
    ( cd unphone && git pull )
  fi
  if [ ! -d unPhoneLibrary ]
  then
    git clone ${CLONE_OPTS} $UNPHONE_LIBRARY_GIT
  else
    ( cd unPhoneLibrary && git pull )
  fi
  e Y done
}

# download arduino core, platformio and makeEspArduino, and do get.py, and
# (if -I) download and setup an Arduino IDE, and VSCode; all into tooling/
do-setup() {
  e G "prereqs"
  do-setup-local

  e G "populating $TOOLING_DIR"

  [ -d $TOOLING_DIR ] || mkdir $TOOLING_DIR
  cd $TOOLING_DIR

  [ -d $ARDUINO_ESPRESSIF_DIR ] || (
    mkdir -p $ARDUINO_ESPRESSIF_DIR
    cd $ARDUINO_ESPRESSIF_DIR
    git clone ${CLONE_OPTS} $ARDUINO_ESP32_GIT esp32
    cd $ARDUINO_ESP32_DIR
    git fetch origin "${ARDUINO_ESP32_VER}:${ARDUINO_ESP32_VER}"
    git checkout $ARDUINO_ESP32_VER
    cd tools
    python3 get.py
    groups |grep -q dialout || sudo usermod -aG dialout $USER
  )
  e G "esp32 arduino core done"

  [ -d $MKESP_DIR ] || git clone ${CLONE_OPTS} $MKESP_GIT
  e G "mkesp done"

  # install Arduino IDE
  [ x$INSTALL_IDES == x1 ] && do-arduino-setup

  # pio
  [ -d $PLATFORMIO_CORE_DIR ] || (
    e Y 'platformio...'
    python3 -c \
      "$(wget -O - https://raw.githubusercontent.com/platformio/platformio/master/scripts/get-platformio.py)"
  )

  # vscode
  [ x$INSTALL_IDES == x1 ] && do-vscode-setup

  e Y "arduino-esp32 dir is $(ls -d $ARDUINO_ESP32_DIR)"
  e Y "arduino prefs dir is $(ls -d $ARDIDE_PREFS_DIR)"
  e Y "sketch        dir is $(ls -d $ARDIDE_SKETCHBOOK_DIR)"
  e Y "platformio    dir is $(ls -d $PLATFORMIO_CORE_DIR)"
  e Y "mkesp         dir is $(ls -d $MKESP_DIR)"
  e G "pio done"

  # vscode
  e G "$(basename $TOOLING_DIR) done"
}

# install Arduino IDE
do-arduino-setup() {
  cd $TOOLING_DIR

  (
    [ $HOST_ARCH == $ARM64_ARCH ] && ARD_ARCH=linuxaarch64
    [ $HOST_ARCH == $X86_64_ARCH ] && ARD_ARCH=linux64
    ARD_HOST="https://downloads.arduino.cc/${ARDIDE_VER}"
    ARD_DOWNLOAD_URL="${ARD_HOST}-${ARD_ARCH}.tar.xz"
    ARD_ZIP=arduino-${ARD_ARCH}.tar.xz
    [ -d $ARDIDE_VER ] || (
      wget -O $ARD_ZIP $ARD_DOWNLOAD_URL
      tar xJf $ARD_ZIP && rm $ARD_ZIP
    )
  )

  # create Arduino and dot-arduino15 and set initial prefs
  [ -d $ARDIDE_SKETCHBOOK_DIR ] || mkdir -p $ARDIDE_SKETCHBOOK_DIR
  [ -d $ARDIDE_PREFS_DIR ] || (
    mkdir $ARDIDE_PREFS_DIR && \
      echo "build.path=$ARDIDE_BIN_DIR"                 >> $ARDIDE_PREFS && \
      echo "sketchbook.path=$ARDIDE_SKETCHBOOK_DIR"     >> $ARDIDE_PREFS && \
      echo "update.check=false"                         >> $ARDIDE_PREFS && \
      echo "board=adafruit_feather_esp32s3"             >> $ARDIDE_PREFS && \
      echo "serial.debug_rate=115200"                   >> $ARDIDE_PREFS && \
      :

#custom_CDCOnBoot=adafruit_feather_esp32s3_cdc
#custom_CPUFreq=adafruit_feather_esp32s3_240
#custom_DFUOnBoot=adafruit_feather_esp32s3_default
#custom_DebugLevel=adafruit_feather_esp32s3_none
#custom_EraseFlash=adafruit_feather_esp32s3_none
#custom_EventsCore=adafruit_feather_esp32s3_1
#custom_FlashFreq=featheresp32_80
#custom_FlashMode=adafruit_feather_esp32s3_qio
#custom_FlashSize=adafruit_feather_esp32s3_4M
#custom_LoopCore=adafruit_feather_esp32s3_1
#custom_MSCOnBoot=adafruit_feather_esp32s3_default
#custom_PSRAM=adafruit_feather_esp32s3_enabled
#custom_PartitionScheme=adafruit_feather_esp32s3_tinyuf2
#custom_USBMode=adafruit_feather_esp32s3_default
#custom_UploadMode=adafruit_feather_esp32s3_cdc
#custom_UploadSpeed=adafruit_feather_esp32s3_921600

  )

  e Y "arduino-esp32 dir is $(ls -d $ARDUINO_ESP32_DIR)"
  e Y "arduino prefs dir is $(ls -d $ARDIDE_PREFS_DIR)"
  e Y "sketch        dir is $(ls -d $ARDIDE_SKETCHBOOK_DIR)"
  e G "arduino IDE install done"
}

# link vscode prefs dirs into tooling/, and install vscode and extensions
do-vscode-setup() {
  # code binary; note that this mysteriously doesn't work in the Dockerfile
  [ -z "$(which code)" ] && (
    e G "downloading $VSCODE_DOWNLOAD_URL"
    [ $HOST_ARCH == $ARM64_ARCH ] && VSCODE_ARCH=arm64
    [ $HOST_ARCH == $X86_64_ARCH ] && VSCODE_ARCH=x64
    VSCODE_HOST="https://code.visualstudio.com/sha/download"
    VSCODE_DOWNLOAD_URL="${VSCODE_HOST}?build=stable&os=linux-deb-${VSCODE_ARCH}"
    VSCODE_DEB=vscode-${VSCODE_ARCH}.deb
    wget -O $VSCODE_DEB $VSCODE_DOWNLOAD_URL
    sudo apt-get install -y ./$VSCODE_DEB
    rm $VSCODE_DEB
  )

  # vscode; we do a "normal" apt install for this one, but do store the
  # ~/.vscode prefs in TOOLING_DIR
  e G 'setting up .vscode link'
  if [ -d $VSCODE_PREFS_LINK -a ! -L $VSCODE_PREFS_LINK ]
  then
    rm -rf $VSCODE_PREFS_DIR
    mv $VSCODE_PREFS_LINK $VSCODE_PREFS_DIR
  fi
  [ -d $VSCODE_PREFS_DIR ] || mkdir $VSCODE_PREFS_DIR
  [ -L $VSCODE_PREFS_LINK ] || ln -s $VSCODE_PREFS_DIR $VSCODE_PREFS_LINK

  # vscode-server prefs
  e G 'setting up .vscode-server link'
  if [ -d $VSCODE_SERVER_PREFS_LINK -a ! -L $VSCODE_SERVER_PREFS_LINK ]
  then
    rm -rf $VSCODE_SERVER_PREFS_DIR
    mv $VSCODE_SERVER_PREFS_LINK $VSCODE_SERVER_PREFS_DIR
  fi
  [ -d $VSCODE_SERVER_PREFS_DIR ] || mkdir $VSCODE_SERVER_PREFS_DIR
  [ -L $VSCODE_SERVER_PREFS_LINK ] || \
    ln -s $VSCODE_SERVER_PREFS_DIR $VSCODE_SERVER_PREFS_LINK

  # extensions
  e G "installing extensions: $VSCODE_EXTS"
  for e in ${VSCODE_EXTS}
  do
    e M "code --install-extension $e"
    code --install-extension $e
  done

  e G "vscode done"
}

# install Vim extensions to VSCode
do-vim-vscode() {
  if [ -z "$(which code)" ]
  then
    e R "VSCode isn't installed?"
  else
    for e in vscodevim.vim naumovs.trailing-semicolon
    do
      e G "installing $e..."
      code --install-extension $e
    done
  fi
  e G "done"
}

# clone a version of ESP-IDF into tooling
do-clone-idf() {
  [ -d $TOOLING_DIR ] || mkdir $TOOLING_DIR
  cd $TOOLING_DIR

  e Y "git clone -b \"${IDF_VER}\" --recursive \"${IDF_GIT}\""
  git clone -b "${IDF_VER}" --recursive "${IDF_GIT}"
}

# do linux install list
do-setup-local() {
  sudo apt-get update -y
  e Y 'doing installs...'
  sudo apt-get install -y \
    sudo git wget make python3 python3-pip python3-setuptools python3-venv \
    vim picocom
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
  sudo pip install pyserial

  # cater for headless java in docker, for example:
  [ x$INSTALL_IDES == x1 ] && sudo apt-get install -y openjdk-11-jre

  e Y 'you may need to be in the dialout group..., e.g.'
  e Y "  sudo adduser $(id -un) dialout"
  e Y 'done'
}

# convenience fuction to add dot-bashrc environment to ~/.bashrc
# NOTE: you don't need to do this, and it pulls in various other utilities
# too, so think carefully before hitting the big red button!
do-install-env() {
  B=.bashrc
  E1='export TIOT_SUPPORT=${HOME}/the-internet-of-things/support'
  E2='[ -f ${TIOT_SUPPORT}/dot-bashrc ] && . ${TIOT_SUPPORT}/dot-bashrc'
  cd ${HOME}
  grep -Fq "${E2}" "${B}" || echo -e "${E1}\n${E2}" >>"${B}"
}

# update key repos, inc tooling
do-update-repos() {
  for d in unphone the-internet-of-things
  do
    ( cd $HOME/$d; e Y "pull in $PWD"; git pull )
  done
  (
    cd ${PLATFORMIO_CORE_DIR}
    for d in packages/*/.git platforms/*/.git
    do
      [ -d $d ] || continue
      ( cd $(dirname $d); e Y "pull in $PWD"; git pull )
    done
  )
  (
    [ -d ${ARDUINO_ESP32_DIR} ] || \
      git clone ${CLONE_OPTS} ${ARDUINO_ESP32_GIT} ${ARDUINO_ESP32_DIR}
    cd ${ARDUINO_ESP32_DIR}
    e Y "pull and checkout ${ARDUINO_ESP32_VER} in ${PWD}"
    git pull
    git fetch origin "${ARDUINO_ESP32_VER}:${ARDUINO_ESP32_VER}"
    git checkout ${ARDUINO_ESP32_VER}
  )
}


# docker suite ##############################################################

# run the magic image
do-dckr-run() {
  COM="docker run --rm --device=/dev/ttyACM0 -ti \
    -v $PWD:/home/ubuntu/project ${DCKR_TAG} $*"
  e G "doing ${COM}"
  ${COM}
}

# create an image and tag it
# NOTES:
# - if you hit odd apt crashes, try dckr-fix-apt
# - if you see timeout when pushing the image, try dckr-upgrade-buildx
# - local builds (that become available as docker images on the build host)
#   can't be multi-platform, so they have to be pushed to the hub (and then
#   re-downloaded). here we default to just building for the local
#   architecture, but allow multi-platform via $1 == -m
do-dckr-build-and-tag() {
  cd ${SUPPORT_DIR}
  e G "building docker image, PWD=${PWD}, DCKR_NO_CACHE=$DCKR_NO_CACHE"

  # local vs. multi / pushed builds
  if [ x$1 == x-m ]
  then
    e Y "doing multi"
    docker buildx build --platform linux/arm64/v8,linux/amd64 \
      --push -t ${DCKR_TAG} $DCKR_NO_CACHE .
  else
    e Y "doing local"
    docker buildx --builder default \
      build -o "type=docker" -t ${DCKR_TAG} $DCKR_NO_CACHE .
  fi
  e G "done"
}

# force no cache rebuild and tag of the image
do-dckr-build-and-tag-no-cache() {
  DCKR_NO_CACHE="--no-cache" do-dckr-build-and-tag $*
}

# push to hub.docker.com
do-dckr-push() { docker push ${DCKR_TAG}; }

# pull from hub.docker.com
do-dckr-pull() { docker pull ${DCKR_TAG}; }

# upgrade buildx for multi-arch support; see
# https://docs.docker.com/build/building/multi-platform/
do-dckr-upgrade-buildx() {
  e G 'upgrading buildx... current is:'
  docker buildx ls
  rm -rf ~/docker/buildx
  echo
  docker buildx create --name mybuilder
  docker buildx use mybuilder
  docker run --privileged --rm tonistiigi/binfmt --install \
    linux/arm64/v8,linux/amd64
  docker buildx inspect --bootstrap
  e G 'upgrade done... new is:'
  docker buildx ls
  echo
}

# install docker on ubuntu; this is a convenience method ONLY, and the best
# way is always to refer to docker's own instructions
# TODO set up a docker credential store
# https://github.com/docker/docker-credential-helpers
# https://docs.docker.com/engine/reference/commandline/login/#credentials-store
do-dckr-setup() {
  e Y '(hc: try setup.sh docker, cntrl&c now!)'
  sleep 10

  e R 'about to try and install docker, based off'
  e B 'https://docs.docker.com/engine/install/ubuntu/#installation-methods'
  e R 'this is a potentially dangerous and error-prone operation!'
  e B 'probably best to hide under your desk for an hour or two...'
  # set up docker group if missing
  groups |grep -q docker || (
    [[ -z `grep docker /etc/group` ]] && sudo groupadd docker
    sudo usermod -a -G docker $USER
    e Y "you need to relogin to trigger group add, then try again"
    exit 1
  )
  e Y "prob do this instead: curl https://get.docker.com | sh && sudo systemctl --now enable docker"
  read ANS

  # install: https://docs.docker.com/engine/install/ubuntu/
  e G installing prereqs
  sudo -E sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release"
  e G installing keyring and apt repo
  sudo -E sh -c "mkdir -p /etc/apt/keyrings && chmod -R 0755 /etc/apt/keyrings"
  sudo -E sh -c "curl -fsSL 'https://download.docker.com/linux/ubuntu/gpg' | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg"
  sudo -E sh -c "chmod a+r /etc/apt/keyrings/docker.gpg"
  sudo -E sh -c "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list"
  sudo -E sh -c "apt-get update -qq >/dev/null"
  e G installing docker packages
  sudo -E sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-scan-plugin docker-buildx-plugin"
  sudo -E sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce-rootless-extras"

  e G setting up buildx support
  e Y "you might want to magic.sh dckr-upgrade-buildx"

  # to move the data dir:
  # cd /var/lib; sudo service docker stop; sudo mv docker /data/var-lib-docker
  # sudo ln -s /data/var/lib-docker docker; sudo service docker start
  e G done
}

# fix multi-arch docker build apt issue
# following https://github.com/docker/buildx/issues/495
do-dckr-fix-apt() {
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
}

# attach to an already running docker container
do-dckr-attach() {
  docker attach $(docker container ls |grep ${DCKR_TAG} |sed 's,.* ,,')
}

# build circuit python
do-dckr-py-build() {
  DCKR_NO_CACHE=""
  #DCKR_NO_CACHE="--no-cache"
  cd $PYTHON_DIR
  docker buildx build --output type=docker --progress=plain \
    --build-arg TARGET_REPO_VERSION=hamishcunningham \
    --build-arg TARGET_REPO_BRANCH=unphone --build-arg TARGET_BOARD=unphone \
    -t ${DCKR_PY_TAG} ${DCKR_NO_CACHE} .
  e B "done; run the container and docker cp firmware.bin"
}

# run circuit python container
do-dckr-py-run() {
  docker run --device=${UPLOAD_PORT} -it ${DCKR_PY_TAG}
}

# rebuild and flash CP
do-dckr-py-flash() {
  docker run --device=${UPLOAD_PORT} -it ${DCKR_PY_TAG} \
    /bin/bash -c "cd /circuitpython/circuitpython/ports/espressif &&
      git pull && echo && git status && echo &&
      . ./esp-idf/export.sh && make BOARD=unphone clean && echo &&
      idf.py set-target esp32s3 && idf.py erase-flash &&
      make BOARD=unphone PORT=${UPLOAD_PORT} all flash && /bin/bash"
# DEBUG=1
}

# copy firmware from running circuitpython container; $1 is container name
do-dckr-py-copy() {
  [ x$1 == x ] && { e R 'oops no $1'; exit 1; }
  BDIR=/circuitpython/circuitpython/ports/espressif/build-unphone
  for f in firmware.bin firmware.uf2 circuitpython-firmware.bin
  do
    docker cp $1:${BDIR}/$f .
  done
}


# command runner ############################################################

# the main event... run commands
if [ -z "$*" ]
then
  :
else
  COMMAND="do-$*"
fi

while :
do
  e Y running $COMMAND ...
  eval $COMMAND
  EXIT_STATUS=$?

  if [ x${LOOPING} == x1 ]
  then
    echo -en "\n${G}loop? (rtn for yes, n for no)${N} " && \
      read ANS && [ x${ANS} != x ] && break
  else
    break
  fi
done
exit $EXIT_STATUS
