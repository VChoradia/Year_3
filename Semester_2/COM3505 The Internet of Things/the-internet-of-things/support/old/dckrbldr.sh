#!/bin/bash
#
# dckrbldr.sh
#
# build ESP32 Arduino/IDF firmware in a docker container, burn from the host
#
# uses ESP32 Arduino lib-builder at
#   https://github.com/espressif/esp32-arduino-lib-builder
#
# Hamish Cunningham, summer 2021

# boilerplate locals
alias cd='builtin cd'
P="$(realpath -e $0)"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] command-name [args]"
DBG=:
OPTIONSTRING=hdt:
R='\033[0;31m' # red (use with echo -e, or the e function below)
G='\033[0;32m' # green
B='\033[1;34m' # blue
Y='\033[0;93m' # yellow
M='\033[0;95m' # magenta
C='\033[0;96m' # cyan
N='\033[0m'    # no color

# lib builder locals
# we set lib builder to a particular commit to avoid unpleasant surprises
# as it evolves... d491d3a was from Fri 21st May 2021, for example
export TOOLING_DIR="$(cd `dirname ${P}` && pwd)/tooling"
export IDF_PATH=${TOOLING_DIR}/esp/esp-idf
export LIB_BUILDER_DIR=${TOOLING_DIR}/esp/lib-builder
export CORE_DIR=${LIB_BUILDER_DIR}/components/arduino
export COMPILERS_DIR=${CORE_DIR}/tools
export PATH=${PATH}\
:${COMPILERS_DIR}/xtensa-esp32-elf/bin\
:${COMPILERS_DIR}/xtensa-esp32s2-elf/bin\
:${COMPILERS_DIR}/riscv32-esp-elf/bin
export ARDIDE_PREFS_DIR=${HOME}/.arduino15
export ARDIDE_PREFS=${ARDIDE_PREFS_DIR}/preferences.txt
export ARDIDE_SKETCHBOOK_DIR=${HOME}/Arduino
export ARDIDE_CORE_DIR=${ARDIDE_SKETCHBOOK_DIR}/hardware/espressif/esp32
#export ARDIDE_VER="arduino-1.8.15"
export ARDIDE_VER="arduino-1.8.16"
#export ARDIDE_VER="ide_beta/arduino-1.9.0-beta"
export ARDIDE_DIR=${TOOLING_DIR}/${ARDIDE_VER}
export ARDIDE_BIN_DIR="build/ardide-bin-output"
export ARDIDE_SRC_DIR=arduino-ide-repo
export BURN_ME=${ARDIDE_BIN_DIR}/burn-me.sh
export BERNSTONE_DOCKERS=arduino-esp32-dockerfiles

# TODO old vars prob need deleting or merging into above
LB_DIR=${TOOLING_DIR}/esp/lib-builder
LB_VER=d491d3a
LB_IDF_DIR=${TOOLING_DIR}/esp/esp-idf
ARDCORE_BUILDER="$(dirname ${TOOLING_DIR})/ardcore-builder"
ARDCORE_OPT_ESP="${TOOLING_DIR}/opt-esp-out"
ARDCORE_IMAGE_TAG="hamishcunningham/iot:lib-builder-2.0.0a"

# message & exit if exit num present
e() { (
  c=""; case $1 in R|G|B|Y|M|C|N) c=${!1}; shift; ;; esac; echo -e "${c}$*${N}";
) }
usage() { e G "Usage: $USAGE"; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	$P build-help; echo; usage 0 ;;
    d)	DBG=echo ;;
    t)	tag="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`
ARGS=$*

# various utility functions #################################################

# local help
build-help() {
  e Y "$P commands available are:"
  tac $P >/tmp/$$
  for n in `grep -n '^[a-z0-9-]*() {' /tmp/$$ |sed 's,:.*$,,' |tac`
  do
    $DBG $n >&2
    nn=$((n+1))
    FNAME=`sed -n "${n}p" /tmp/$$ |sed 's,().*,,'`
    [ $FNAME == e -o $FNAME == usage -o $FNAME = colours ] && continue
    echo -en "$G${FNAME}: $N"
    sed -n "${nn},/^$/p" /tmp/$$ |sed 's,^#, ,' |tac
  done
}

# short hash of the current commit
git-hash() { git log --pretty=format:'%h' -n 1; }

# copy this firmware tree, modifying the name; $1 should have the new name
copy-me-to() {
  BASEDIR="$(cd `dirname ${P}` && pwd)"
  MYNAME=`basename $BASEDIR`
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

# a quicker clone, one commit only (tnx Larry Bernstone!)
shallow-clone() {
  e G shallow-clone $1 $2 $3
  if [ -z "$3" ]; then
    echo "Usage: $0 <GIT_URL> <GIT_COMMIT> <PATH>"; exit 1
  fi
  mkdir -p $3 || { e R "oops can't create $3"; exit 2; }
  cd $3 || { e R "oops can't cd to $3"; exit 3; }
  git init
  git remote add origin $1
  git fetch --progress --depth 1 origin $2
  git checkout FETCH_HEAD
}

# run a web server in the build directory for firware OTA
ota-httpd() {
  # firmware versioning
  FIRMWARE_VERSION=$(grep 'int firmwareVersion =' main/main.cpp |
    sed -e 's,[^0-9]*,,' -e 's,;.*$,,')

  # create downloads for the httpd server, .bin and version
# TODO use the exported .bin name from docker
  cd build
  mkdir -p fwserver
  cd fwserver
  echo $FIRMWARE_VERSION >version
  [ -f Thing.bin ] || cp ../Thing.bin ${FIRMWARE_VERSION}.bin

  python -m http.server 8000
}

# scratchpad
scratch() {
  if false; then        # already done
    :
  elif true; then       # to do now
    :
  else                  # to do later
    :
  fi
}

# lib builder (aka docker builder, or "dbr-") functions #####################
#
# TODO
#
# - we need to see IDE output, so move to 1.9 and sack firejail
#
# - if export uses /dev/nonexistent port, need to fix that up in burn-me.sh
#
# - dbr-build-core-local does a combined setup-tooling, core build and install
#   to ~/Arduino/hardware; most of that should be in setup
# - ideally we would merge with previous kit to separate out steps
#
# - make the sketch dir a file tree and link from main, so Arduino build
#   easier on Windows
# - IDF build should use Arduino/hardware dir esp-idf tree

# tips for running the dbr suite
dbr-help() {
  (
    e G "\nNotes on using the Lib Builder suite"
    cat <<EOF

The "dbr-" suite of commands uses esp32-arduino-lib-builder and the arduino IDE
to provide a CLI for installing tooling and for building and burning firmware.
It also provides export of the .bin etc. to the local filesystem with a view
to easing Dockerisation of build-in-container/burn-on-localhost workflows (to
get over the problem of Windows and Mac not passing through serial ports to
the container).

The lib builder tool itself provides the ability to reconfigure libraries in
ESP IDF and then rebuild the core (so we can adjust sdkconfig settings, for
example).

Workflow elements:

- dbr-prereqs installs dependencies of the tools
- dbr-setup-tooling downloads the core, the IDE and ESP IDF to ./tooling
- dbr-menuconfig (run from tooling/esp32-arduino-lib-builder) reconfigures the
  core and IDF options; then use dbr-build-core-... to rebuild the core
- dbr-ardide runs the IDE UI
- dbr-export uses the IDE to compile/upload firmware and save the output
  (including burn command) in ./build/ardide-bin-output
- dbr-burn does an IDE CLI upload
- dbr-idf-py runs the ESP IDF idf.py command
- dbr-monitor uses IDF to monitor serial
- dbr-erase-flash uses idf.py to erase the device flash

(There's also a utility, dbr-recompile-ardide, to clone and compile the IDE
itself from source, if needed.)

Notes:

- during dbr-setup-tooling you can safely ignore "fatal" error "cannot change
  to '.../components/arduino'"
- when running the IDE, you can ignore java.net.UnknownHostException messages
  (the script firewalls the IDE to prevent the endless DNS error messages in
  1.8...)

Commands:

EOF
    $P -h |sed -n '/dbr-help/,$p' |grep -v 'Usage:'
  ) |less -r
}

# install prereqs
dbr-prereqs() {
  e G "installing prerequistites..."

  INSTALL_JAVA=
  [ -z "`which java`" ] && INSTALL_JAVA=openjdk-11-jdk
  sudo apt-get install \
    apt-utils bison ca-certificates ccache check cmake curl dfu-util \
    firejail flex git gperf lcov libffi-dev libncurses-dev libssl-dev \
    libusb-1.0-0 libusb-1.0-0-dev locales make nano ninja-build \
    python-is-python3 python3 python3-click python3-cryptography \
    python3-future python3-pip python3-pyelftools python3-pyparsing \
    python3-serial python3-setuptools unzip vim wget xz-utils zip \
    $INSTALL_JAVA

  # having both an apt venv installed and a pip version causes probs...
  sudo apt-get remove python3-virtualenv
  python3 -m pip install --upgrade pip virtualenv

  # need to get requirements.txt here, as otherwise have to wait for LB build
  # to create esp-idf dir :(
  cd $TOOLING_DIR
  wget \
    https://raw.githubusercontent.com/espressif/esp-idf/master/requirements.txt
  [ `uname` == Linux ] &&
    sed -i 's,^\(file:.*IDF_PATH.*windows-curses.*win32.*\),# \1,' \
      requirements.txt
  IDF_PATH=$LB_IDF_DIR pip3 install --user --no-warn-script-location \
    -r requirements.txt
  mv requirements.txt /tmp
  e Y "warning: have installed the latest version of IDF requirements.txt..."
  e Y "this might not match your lib builder version!"

  groups |grep -q dialout ||
    e B "you should probably add yourself to group dialout"
  e G 'prerequisites installed :)'
}

# clone lib-builder, download arduino IDE, setup Arduino and .arduino15
# (several GB download, + build; can take about 30 minutes!)
# calls dbr-setup-arduino and dbr-build-core-...
dbr-setup-tooling() {
  [ -d $TOOLING_DIR ] || mkdir $TOOLING_DIR
  cd $TOOLING_DIR

  [ -d $LB_DIR ] || (
    git clone git@github.com:espressif/esp32-arduino-lib-builder.git
    cd esp32-arduino-lib-builder
    git checkout $LB_VER
  )
  [ -d $BERNSTONE_DOCKERS ] ||
    git clone git@github.com:lbernstone/arduino-esp32-dockerfiles.git

  # build the core
  if [ x$1 == x-local ]
  then
    dbr-build-core-local
  else
    cd $ARDCORE_BUILDER
    [ -d dist ] || cp -a ~/.espressif/dist .
    docker build \
      -t ${ARDCORE_IMAGE_TAG} \
      -f "Dockerfile-2.0.0a-tweaked" \
      .
    e Y "image $ARDCORE_IMAGE_TAG build..."
    e Y "to reconfigure and rebuild do TODO" # TODO

    dbr-build-core-docker
  fi

  dbr-setup-arduino
}

# rebuild the arduino esp32 core and copy into Arduino/hardware
# (to reconfigure run dbr-menuconfig first); this version does the build
# using docker
dbr-build-core-docker() {
  [ -d $ARDCORE_OPT_ESP ] || mkdir $ARDCORE_OPT_ESP
  docker run -it -v "${ARDCORE_OPT_ESP}:/opt/out" \
    ${ARDCORE_IMAGE_TAG} \
    /bin/bash -ic \
"cd /opt/esp/lib-builder && ./build.sh && cp -a out/* /opt/out && \
mkdir /opt/out/cache && 
cp -a /opt/esp/lib-builder /opt/out/cache && \
cp -a /opt/esp/idf /opt/out/cache && \
ESP32_ARDUINO=/opt/out tools/copy-to-arduino.sh"

  ID=$(id -nu)
  chmod -R ${ID}:${ID} ${ARDCORE_OPT_ESP}

# TODO copy into ~/Arduino ${ARDIDE_CORE_DIR}
# (use dbr-install-core?)
# the out dir is only the sdk and platform.txt, so need to first
# download and unpack the release version, e.g.
# wget https://github.com/espressif/arduino-esp32/releases/download/2.0.0-alpha1/esp32-2.0.0-alpha1.zip
# and also do get.py in tools
  # now copy the build into Arduino/hardware...
  [ -d $ARDIDE_CORE_DIR ] && mv ${ARDIDE_CORE_DIR} ~/saved-esp32-$$
  mkdir -p ${ARDIDE_CORE_DIR}
  rsync -a --dry-run ${ARDCORE_OPT_ESP}/tools ${ARDIDE_CORE_DIR}/tools
}

# download and setup an Arduino IDE
dbr-setup-arduino() {
  [ -d $TOOLING_DIR ] || mkdir $TOOLING_DIR
  cd $TOOLING_DIR

  [ -d $ARDIDE_PREFS_DIR ] && e Y $(ls -ld $ARDIDE_PREFS_DIR)
  [ -d $ARDIDE_SKETCHBOOK_DIR ] && e Y $(ls -ld $ARDIDE_SKETCHBOOK_DIR)

# for 1.9 beta
#https://downloads.arduino.cc/ide_beta/arduino-1.9.0-beta-linux64.tar.xz
#ARDUINO_IDE_VER=1.9.0-beta
#ARDUINO_IDE_FILE=arduino-$ARDUINO_IDE_VER-linux64.tar.xz
#ARDUINO_IDE_DIR=ide_beta/
#ARDUINO_IDE_URL=https://downloads.arduino.cc/$ARDUINO_IDE_DIR$ARDUINO_IDE_FILE
#wget $ARDUINO_IDE_URL && tar xJf $ARDUINO_IDE_FILE && rm $ARDUINO_IDE_FILE
#exit 0

  # install Arduino IDE
  [ -d $ARDIDE_VER ] ||
    (
      wget https://downloads.arduino.cc/${ARDIDE_VER}-linux64.tar.xz &&
      tar xJf ${ARDIDE_VER}-linux64.tar.xz &&
      rm ${ARDIDE_VER}-linux64.tar.xz
    )

  # create ~/.arduino15 and set initial prefs
  [ -d $ARDIDE_PREFS_DIR ] || (
    mkdir $ARDIDE_PREFS_DIR &&
    echo "build.path=$ARDIDE_BIN_DIR" >> $ARDIDE_PREFS &&
    echo "sketchbook.path=$ARDIDE_SKETCHBOOK_DIR" >> $ARDIDE_PREFS &&
    echo "board=featheresp32" >> $ARDIDE_PREFS &&
    echo "update.check=false" >> $ARDIDE_PREFS &&
    echo "custom_DebugLevel=featheresp32_none" >> $ARDIDE_PREFS &&
    echo "custom_FlashFreq=featheresp32_80" >> $ARDIDE_PREFS &&
    echo "custom_UploadSpeed=featheresp32_921600" >> $ARDIDE_PREFS &&
    echo "serial.debug_rate=115200" >> $ARDIDE_PREFS &&
    echo "target_package=espressif" >> $ARDIDE_PREFS &&
    echo "target_platform=esp32" >> $ARDIDE_PREFS &&
    :
  );

# TODO
  # create ~/Arduino
# [ -d $ARDIDE_SKETCHBOOK_DIR ] || mkdir $ARDIDE_SKETCHBOOK_DIR


# [ -d $ARDIDE_CORE_DIR ] && mv ${ARDIDE_CORE_DIR} ~/saved-esp32-$$
# cd $(dirmame $ARDIDE_CORE_DIR)
# wget "https://github.com/espressif/arduino-esp32/releases/download/2.0.0-alpha1/esp32-2.0.0-alpha1.zip"
# unzip "esp32-2.0.0-alpha1.zip"
# mv "esp32-2.0.0-alpha1.zip" esp32
# cd esp32/tools
# # need to get.py but not included in the distribution :(
}

# run menuconfig
dbr-menuconfig() {
  source ${LB_IDF_DIR}/export.sh
  idf.py menuconfig
}

# run lb tooling ardide
dbr-ardide() {
  e G running ${ARDIDE_DIR}/arduino $* from $PWD
  ${ARDIDE_DIR}/arduino $*
}

# do a firmware compile/upload ($1) and drop the .bin in pwd
# (also captures the burn command for later use)
dbr-export() {
  e G "setting build.path in ${ARDIDE_PREFS}"
  grep -q "^build.path=${ARDIDE_BIN_DIR}" ${ARDIDE_PREFS} || (
    grep -v '^build.path=' ${ARDIDE_PREFS} >/tmp/$$-prefs
    mv /tmp/$$-prefs ${ARDIDE_PREFS}
    echo "build.path=${ARDIDE_BIN_DIR}" >> ${ARDIDE_PREFS}
  )
  grep 'build.path' ${ARDIDE_PREFS}

  e G "setting serial.port in ${ARDIDE_PREFS}"
  grep -q "^serial.port=${ARDIDE_BIN_DIR}" ${ARDIDE_PREFS} || (
    grep -v '^serial.port=' ${ARDIDE_PREFS} >/tmp/$$-prefs
    mv /tmp/$$-prefs ${ARDIDE_PREFS}
    echo "serial.port=/dev/ttyUSB0" >> ${ARDIDE_PREFS}
  )
  grep 'serial.port' ${ARDIDE_PREFS}

  e B "deleting previous build if any"
  [ -d ${ARDIDE_BIN_DIR} ] && rm -rf ${ARDIDE_BIN_DIR}
  mkdir -p ${ARDIDE_BIN_DIR}

  # the arduino IDE will print the appropriate burn command, so we can grep
  # that and create a script to be run from outside of docker, but it will
  # only do it if a) we're using --upload (not just --verify) and b) if
  # there's a port specified (even though this may not actually exist)
  echo '#!/bin/bash' >${BURN_ME}
  chmod 755 ${BURN_ME}

  ARD_OUT=${ARDIDE_BIN_DIR}/arduino-output.txt
  e G "running ${ARDIDE_DIR}/arduino --verify (ish) $* from ${PWD}"
  ${ARDIDE_DIR}/arduino --verbose --upload $* 2>&1 | \
    tee ${ARD_OUT} | \
    grep --text '^python.*esptool.py.*write_flash' | \
      sed -e 's,/home[^ ]*\(build.ardide-bin-output\),\1,g' \
          -e 's,/home/[a-z][a-z]*/,${HOME}/,g' \
      >>${BURN_ME}
  [ $DBG == ":" ] || 
    e Y "compile output ends:\n$(tail ${ARD_OUT} |grep -v tools.xtensa)"

  e B "burn command is:\n`tail -1 ${BURN_ME}`"

  # the burn command shape is specified in platform.txt, e.g.:
  #
  # tools.esptool_py.upload.pattern_args=
  # --chip {build.mcu}
  # --port "{serial.port}"
  # --baud {upload.speed}
  # {upload.flags}
  # --before default_reset
  # --after hard_reset
  # write_flash -z
  # --flash_mode {build.flash_mode}
  # --flash_freq {build.flash_freq}
  # --flash_size detect
  # 0xe000 "{runtime.platform.path}/tools/partitions/boot_app0.bin"
  # {build.bootloader_addr} "{build.path}/{build.project_name}.bootloader.bin"
  # 0x10000 "{build.path}/{build.project_name}.bin"
  # 0x8000 "{build.path}/{build.project_name}.partitions.bin"
  # {upload.extra_flags}
  #
  # this results in something like:
  #
  # python ${HOME}/Arduino/hardware/espressif/esp32/tools/esptool/esptool.py
  # --chip esp32 --port /dev/ttyUSB0 --baud 921600 --before default_reset
  # --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m
  # --flash_size detect 0xe000
  # ${HOME}/Arduino/hardware/espressif/esp32/tools/partitions/boot_app0.bin
  # 0x1000 build/ardide-bin-output/sketch.ino.bootloader.bin 0x10000
  # build/ardide-bin-output/sketch.ino.bin 0x8000
  # build/ardide-bin-output/sketch.ino.partitions.bin
}

# do a compile and upload of sketch at $1; if a previous export has produced a
# burn.sh then run that, otherwise do an arduino --upload
dbr-burn() {
  if [ -x ${BURN_ME} ]
  then
    e G running ${BURN_ME}
    ${BURN_ME}  
  else
    e G running ${ARDIDE_DIR}/arduino --upload $* from $PWD
    firejail --noprofile --net=none /bin/bash -c \
      "${ARDIDE_DIR}/arduino --upload $*"
  fi
}

# run the core's copy of ESP IDF idf.py
dbr-idf-py() {
  source ${LB_IDF_DIR}/export.sh
  idf.py $*
}

# use the LB copy of IDF to erase flash
dbr-erase-flash() {
  source ${LB_IDF_DIR}/export.sh
  esptool.py erase_flash
}

# use the LB copy of IDF to monitor serial
dbr-monitor() {
  cd ${LB_IDF_DIR}
  source ./export.sh
  cd examples/get-started/hello_world
  idf.py app monitor
}

# recompile a copy of the arduino IDE checkout out in tooling/arduino-ide-repo
# (will clone if doesn't exist already)
dbr-recompile-ardide() {
  cd $TOOLING_DIR

  [ -d $ARDIDE_SRC_DIR ] ||
    git clone --depth 1 git@github.com:arduino/Arduino.git $ARDIDE_SRC_DIR
  cd $ARDIDE_SRC_DIR/build
  ant build

  # (e.g. for build.path investigations stored in misc/*.java); copy the Base
  # class .jar to the in use IDE lib/ dir; not needed in anger at present as
  # turns out setting build.path reliably preserves the .bin etc. see also
  # https://github.com/arduino/Arduino/wiki/Building-Arduino
  # cp linux/work/lib/pde.jar $ARDIDE_DIR/lib
}

# env for building the core
dbr-core-build-env() { source $IDF_PATH/export.sh &> /dev/null; }

# create a fresh install of the core at ~/Arduino; seed prefs at ~/.arduino15
# (call it following a successful core build)
dbr-install-core() {
  dbr-core-build-env

  # seed ~/.arduino15
  [ -e ${ARDIDE_PREFS_DIR} ] &&
    mv ${ARDIDE_PREFS_DIR} ${ARDIDE_PREFS_DIR}-saved-$$
  mkdir -p ${ARDIDE_PREFS_DIR}
  echo "build.path=${ARDIDE_BIN_DIR}" >> ${ARDIDE_PREFS}
  echo "board=featheresp32" >> ${ARDIDE_PREFS}
  echo "update.check=false" >> ${ARDIDE_PREFS}
  echo "custom_DebugLevel=featheresp32_none" >> ${ARDIDE_PREFS}
  echo "custom_FlashFreq=featheresp32_80" >> ${ARDIDE_PREFS}
  echo "custom_UploadSpeed=featheresp32_921600" >> ${ARDIDE_PREFS}
  echo "serial.debug_rate=115200" >> ${ARDIDE_PREFS}
  echo "target_package=espressif" >> ${ARDIDE_PREFS}
  echo "target_platform=esp32" >> ${ARDIDE_PREFS}
  cat ${ARDIDE_PREFS}

  # copy the build core from lib-builder/components/arduino into ~/Arduino
  [ -e ${ARDIDE_SKETCHBOOK_DIR} ] &&
    mv ${ARDIDE_SKETCHBOOK_DIR} ${ARDIDE_SKETCHBOOK_DIR}-saved-$$
  mkdir -p $(dirname ${ARDIDE_CORE_DIR})
  cp -a ${CORE_DIR} ${ARDIDE_CORE_DIR}

  # copy the sdk build etc. from lib-builder/out into the core tree
  rsync -a $LIB_BUILDER_DIR/out/* $ARDIDE_CORE_DIR
}

# (new) lb core build
#   - download the development release of the core to Arduino/hardware
#   - download the desired version of lib-builder (currently in
#     tooling/esp32-arduino-lib-builder)
#   - call tooling/esp32-arduino-lib-builder/components/arduino/tools/get.py
#     in the location that the IDE expects the compilers etc. to exist
#   - run dbr-build-core-docker (converted to use non-shallow clones, and
#     possibly converted to run locally, not in docker, so that the whole dbr-
#     suite can be used for a more comprehensive docker build)
#   - merge tooling/opt-esp into Arduino/hardware
#   - OR, try https://github.com/plerup/makeEspArduino ?!
dbr-build-core-local() {
  e G "preparing core build in $TOOLING_DIR"

  shallow-clone https://github.com/espressif/esp-idf \
    cf457d412a7748139b77c94e7debe72ee86199af $IDF_PATH \
    && cd $IDF_PATH && git submodule update --progress --depth 1 \
      --init --recursive \
    && rm $IDF_PATH/components/expat/expat/testdata/largefiles/* \
    && rm -rf $IDF_PATH/components/tinyusb/tinyusb/examples \
    && rm -rf $IDF_PATH/docs

  # pull in Larry Bernstone's Dockerfiles; the below adapted from there
  cd $TOOLING_DIR && [ -d $BERNSTONE_DOCKERS ] ||
    git clone git@github.com:lbernstone/arduino-esp32-dockerfiles.git

  # IDF installs (prevent installing compilers etc., we'll use get.py)
  cd $IDF_PATH
  sed -i 's/"install.*/"install": "never",/' $IDF_PATH/tools/tools.json
  sed -i "s/'--no-site-packages',//" $IDF_PATH/tools/idf_tools.py \
    && $IDF_PATH/install.sh
  # TODO
  # && rm -rf ${HOME}/.cache ${HOME}/.local \
  # && true

  [ -d $LIB_BUILDER_DIR ] ||
    shallow-clone https://github.com/espressif/esp32-arduino-lib-builder \
      d491d3a565f016d86aa474098a5abf2e88dd0df8 $LIB_BUILDER_DIR

  # TODO check existence before cloning?
  shallow-clone https://github.com/espressif/arduino-esp32 \
    5d9b98c9b04e591044078ac2304da95e8c7e997b \
    $LIB_BUILDER_DIR/components/arduino \
    && rm -rf $LIB_BUILDER_DIR/components/arduino/tools/sdk

  shallow-clone https://github.com/espressif/esp32-camera/ \
    2dded7c578623ebeff5b5ff468275eabf2650ea2 \
    $LIB_BUILDER_DIR/components/esp32-camera

  shallow-clone https://github.com/joltwallet/esp_littlefs \
    d268e18d774431fb6f0e444feef4e97a2dfaaa29 \
    $LIB_BUILDER_DIR/components/esp_littlefs \
    && git -C $LIB_BUILDER_DIR/components/esp_littlefs \
    submodule update --progress --depth 1 --init --recursive

  shallow-clone https://github.com/espressif/esp-rainmaker \
    ec23bd8aa6843966fd13e92940e41863779260d4 \
    $LIB_BUILDER_DIR/components/esp-rainmaker \
    && git -C $LIB_BUILDER_DIR/components/esp-rainmaker submodule update \
    --progress --depth 1 --init --recursive

  shallow-clone https://github.com/lbernstone/esp-dsp riscv \
    $LIB_BUILDER_DIR/components/esp-dsp \
    && git -C $LIB_BUILDER_DIR/components/esp-dsp submodule update \
    --progress --depth 1 --init --recursive

  shallow-clone https://github.com/espressif/esp-face/ \
    420fc7e219ba98e40a5493b9d4be270db2f2d724 \
    $LIB_BUILDER_DIR/components/esp-face

  # install compilers etc.
  cd $LIB_BUILDER_DIR/components/arduino/tools && ./get.py

  # all the little fixes
  rm $LIB_BUILDER_DIR/components/esp32-camera/idf_component.yml
  shallow-clone https://github.com/hathach/tinyusb \
    70c89da7ba550b398f83068ca342cfe23e9c720c \
    $LIB_BUILDER_DIR/components/arduino_tinyusb/tinyusb

  sed -i '16,21s/^/#/;/version.txt/d' $LIB_BUILDER_DIR/build.sh
  sed -i "1 i if(CONFIG_IDF_TARGET_ARCH_XTENSA)" \
    $LIB_BUILDER_DIR/components/esp-face/CMakeLists.txt && \
    echo "endif()" >> $LIB_BUILDER_DIR/components/esp-face/CMakeLists.txt
  echo "v2.0.0alpha1" > $LIB_BUILDER_DIR/version.txt

  dbr-core-build-env
  cd $LIB_BUILDER_DIR && ./build.sh

  dbr-install-core
   
  # this is how LB does the tools install:
  #mkdir -p /opt/esp/tools
  #dist/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz /opt/esp/tools/
  #dist/xtensa-esp32s2-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz /opt/esp/tools/
  ##dist/riscv32-esp_1.24.0-123-g64eb9ff-linux-repack.tar.gz /opt/esp/tools/
  #dist/riscv32-esp-elf-gcc8_4_0-crosstool-ng-1.24.0-123-g64eb9ff-linux-amd64.tar.gz /opt/esp/tools/
  #dist/binutils-esp32s2ulp-linux-amd64-2.28.51-esp-20191205.tar.gz /opt/esp/tools/
  #dist/binutils-esp32ulp-linux-amd64-2.28.51-esp-20191205.tar.gz /opt/esp/tools/
  #dist/openocd-esp32-linux64-0.10.0-esp32-20200709.tar.gz /opt/esp/tools/
  #dist/openocd-esp32-linux64-0.10.0-esp32-20210401.tar.gz /opt/esp/tools/
  # echo "PATH=$PATH:/opt/esp/tools/xtensa-esp32-elf/bin:/opt/esp/tools/xtensa-esp32s2-elf/bin:/opt/esp/tools/riscv32-esp-elf/bin\n \
  # cd $LIB_BUILDER_PATH\n \
  # source $IDF_PATH/export.sh &> /dev/null" >> ${HOME}/.bashrc

  # Arduino IDE expects: 
  # /home/hamish/.arduino15/packages/esp32/tools/xtensa-esp32-elf-gcc/gcc8_4_0-esp-2020r3/bin/xtensa-esp32-elf-g++
}

# the main event... run commands
if [ -z "$*" ]
then
  usage
  exit 0
else
  COMMAND="$*"
fi
e Y running $COMMAND ...
eval $COMMAND
exit $?
