#!/bin/bash
# magic.sh

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] command-name [args]"
DBG=:
OPTIONSTRING=hdni:
R='\033[0;31m' # red (use with echo -e)
G='\033[0;32m' # green
B='\033[1;34m' # blue
Y='\033[0;93m' # yellow
M='\033[0;95m' # magenta
C='\033[0;96m' # cyan
N='\033[0m'    # no color

# colourful echo
e() { (
  c=""; case $1 in R|G|B|Y|M|C|N) c=${!1}; shift;; esac; echo -e "${c}$*${N}";
) }

# message & exit if exit num present
usage() { e G "Usage: $USAGE"; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	$P build-help; echo; usage 0 ;;
    d)	DBG=echo ;;
    n)	USEXYZ="" ;;
    i)	ABC="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done
shift `expr $OPTIND - 1`
ARGS=$*

# colours example
colours() {
  echo -e \
    "white ${R}red ${G}green ${B}blue ${Y}yellow ${M}magenta ${C}cyan ${N}"
}

# short hash of the current commit
git-hash() { git log --pretty=format:'%h' -n 1; }

# common environment
# references to _VERSION commit hashes for the SDK repos are defaults;
# set-versions has others
common-env() {
  # project-specific env
  BASEDIR="$(cd `dirname ${P}` && pwd)"
  PROJECT_NAME=`basename $BASEDIR`
  FIRMWARE_VERSION=$(grep 'int firmwareVersion =' main/main.cpp \
    |sed -e 's,[^0-9]*,,' -e 's,;.*$,,' -e 's,//.*,,')
  PROJECT_VER=`echo $FIRMWARE_VERSION |sed -e 's,\(.\),\1.,g' -e 's,\.$,,'`

  # make sure virtualenv is on PATH
  PATH=$PATH:.local/bin
  PROJECT_PATH=$PWD

  # make a guess at the port
  ESPPORT=$([ ! -z "$ESPPORT" ] && echo $ESPPORT || \
    for p in ttyUSB0 ttyUSB1 cu.SLAB_USBtoUART; do \
    [ -r /dev/${p} ] && echo /dev/${p} && break; done)

  # locations
  SDKS_DIR=`dirname $IDF_PATH`

  # IDF
  ESP_IDF_GIT=https://github.com/espressif/esp-idf.git
  ESP_IDF_VERSION=357a27760
  ESP_IDF_DIR=${SDKS_DIR}/esp-idf

  # ESP arduino core
  ESP_ARD_GIT=https://github.com/espressif/arduino-esp32.git
  # littlefs bug here ESP_ARD_VERSION=esp32s2
  ESP_ARD_VERSION=41e392f66119f350cb476b4f56d1194e0b16dfa2
  ESP_ARD_DIR=${SDKS_DIR}/arduino-esp32

  # arduino core IDF builder
  ESP_LIB_BUILDER_GIT=https://github.com/espressif/esp32-arduino-lib-builder.git
  ESP_LIB_BUILDER_VERSION=release/v4.0
  ESP_LIB_BUILDER_DIR=${SDKS_DIR}/esp32-arduino-lib-builder

  # esp rainmaker
  ESP_RAINMAKER_GIT=https://github.com/espressif/esp-rainmaker.git
  ESP_RAINMAKER_VERSION=master
  ESP_RAINMAKER_DIR=${SDKS_DIR}/esp-rainmaker

  # arduino IDE dirs
  ARD_LIB_DIR=${SDKS_DIR}/Arduino/libraries
  ARD_HW_DIR=${SDKS_DIR}/Arduino/hardware/espressif

  # arduino IDE 1.9.0-beta
  ARD_IDE_VER=1.9.0-beta
  ARD_IDE_DIR=ide_beta/
  ARD_IDE_RUNNER_VER=9
  ARD_IDE_SDKS_DIR=${SDKS_DIR}/arduino-PR-beta1.9-BUILD-*

  # arduino IDE download page; linux 64 bit by default, or arm 32 bit
  ARD_IDE_FILE=arduino-${ARD_IDE_VER}-linux64.tar.xz
  case `uname -m` in
    arm*) ARD_IDE_FILE=arduino-${ARD_IDE_VER}-linuxarm.tar.xz ;;
  esac
  ARD_IDE_URL=https://downloads.arduino.cc/${ARD_IDE_DIR}${ARD_IDE_FILE}
}

# IDF environment
idf-env() {
  if [ -d local-sdks ]; then
    EXP=local-sdks/esp-idf/export.sh; e G sourcing $EXP; . $EXP || exit 1
  elif [ -d ~/esp ]; then
    EXP=~/esp/esp-idf/export.sh; e G sourcing $EXP; . $EXP || exit 1
  elif [ -d sdks ]; then
    EXP=sdks/esp-idf/export.sh; e G sourcing $EXP; . $EXP || exit 1
  elif [ -d ~/unphone/sdks ]; then
    EXP=~/unphone/sdks/esp-idf/export.sh; e G sourcing $EXP; . $EXP || exit 1
  elif [ x$IDF_PATH != x ]; then
    EXP=$IDF_PATH/export.sh; e G sourcing $EXP; . $EXP || exit 1
  else
    e R "can't find an ESP IDF... set IDF_PATH?"
    exit 1
  fi

  common-env
  [ -d local-sdks ] || ln -s $SDKS_DIR local-sdks
  e G seem to have an IDF at $IDF_PATH
}

# check out a version set of an SDK repo
do-checkout() {
  D=$1; V=$2
  if [ ! -d $D ]
  then
    e R "oops: $D not found, ignoring"
  else
    (
      cd ${D} &&
        e M "git status in ${PWD}: $(git status)" &&
        e "going to checkout ${V}, present in these branches:" &&
        ( git branch -a --contains ${V} || : ) &&
        git checkout --recurse-submodules ${V} &&
        git submodule update --init --recursive &&
        e M "git status in ${PWD}: $(git status)"
    )
  fi
}

# IDF & Arduino core install
# https://docs.espressif.com/projects/esp-idf/en/stable/get-started/linux-setup.html
idf-install() {
  IDF_PATH=~/esp/esp-idf common-env

  e B going to install to ~/esp...; sleep 3
  e B doing prereq installs
  sudo apt-get install git wget flex bison gperf python3 python3-pip \
    python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util

  e B setting up python3
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
  e G running python is $(python --version)

  e B ~/esp
  mkdir -p ~/esp
  set-versions

  (
    cd ~/esp
    echo "SDK set $VNAME @ `date`" >version-set-name.txt
    echo "IDFVER=$IDFVER ARDVER=$ARDVER LBVER=$LBVER RMVER=$RMVER" \
      >>version-set-name.txt

    e B "IDF"
    [ ! -d ${ESP_IDF_DIR} ] && git clone ${ESP_IDF_GIT}
    do-checkout ${ESP_IDF_DIR} ${IDFVER}
    e B ${ESP_IDF_DIR}/install.sh... && ${ESP_IDF_DIR}/install.sh
    e G "IDF install at ${PWD} should be usable\n"

    e B "Arduino core"
    [ ! -d ${ESP_ARD_DIR} ] && git clone ${ESP_ARD_GIT}
    do-checkout ${ESP_ARD_DIR} ${ARDVER}
    e G "Arduino components done\n"

    e B "Lib Builder"
    [ ! -d ${ESP_LIB_BUILDER_DIR} ] && git clone ${ESP_LIB_BUILDER_GIT}
    do-checkout ${ESP_LIB_BUILDER_DIR} ${LBVER}
    e G "Lib Builder done\n"

    e B "RainMaker"
    [ ! -d ${ESP_RAINMAKER_DIR} ] && git clone ${ESP_RAINMAKER_GIT}
    do-checkout ${ESP_RAINMAKER_DIR} ${RMVER}
    e B "doing pip installs for rainmaker CLI..."
    e B see \
"https://rainmaker.espressif.com/docs/cli-setup.html#installing-dependencies"
    pip3 install -r ${ESP_RAINMAKER_DIR}/cli/requirements.txt
    e G "RainMaker done\n"
  )

  idf-env
  e G use idf.py at $(which idf.py)
}

# choose and set variables for an SDK version set
# these sets attempt to match IDF and the Arduino core (and lib-builder
# and RainMaker if appropriate)
set-versions() {
  # name / IDF v / Arduino core v / lib-builder v / Rainmaker v
  OIFS="$IFS"; IFS='
' VERSIONS=$(cat << EOF
idf-3.3.4--core-1.0.5-rc6 cd59d107b 1.0.5-rc6 master master
nov-2020-idf4.3-dev 357a27760 41e392f66 release/v4.0 master
idf4.2--core-b4.2 release/v4.2 idf-release/v4.2 master master
idf4.2-beta1-ish 494a124d9 29e3b640 master master
oct-2020-idf4.2-dev 357a27760 6ffe081f master master
idf3.3-core-rc4 b4c0751692a18db098a9a6139b2ab5a789d39167 1.0.5-rc4 master master
head-dev master master master master
EOF
  )

  e B "choose a version set:"
  echo -n "******** "
  e R "oops, I think only number 2 (idf4.3-dev etc.) works at present!"
  HEADINGS="name idf-ver ard-ver lib-build-ver rainmaker-ver"
  I=0
  declare -A VERMAP
  echo "$HEADINGS" |xargs printf "%20s	"; echo
  for v in $VERSIONS
  do
    I=$((I+1))
    echo -n "  $I "
    echo -en "$G"
    echo $v |xargs printf "%20s	"
    echo -e "$N"
    VERMAP[$I]="$v"
  done
  IFS="$OIFS"
  echo -ne "${B}? ${M}"
  read ANS; [ -z "$ANS" ] && ANS=0
  [ $ANS -gt $I -o $ANS == 0 ] &&
    { e R "oops, answer '$ANS' not found..."; exit 1; }
  e M "ok, going to set versions to $ANS"

  VER=${VERMAP[$ANS]}
  set $VER
  VNAME=$1; IDFVER=$2; ARDVER=$3; LBVER=$4; RMVER=$5
  e G "VNAME=$VNAME IDFVER=$IDFVER ARDVER=$ARDVER LBVER=$LBVER RMVER=$RMVER"
}

# what version of IDF are we running? (returns 3 or 4)
idf-version() {
  idf-env >/dev/null
  (
    cd $IDF_PATH
    V=`git describe`
    e G "IDF version details are: $V" >&2
    case "$V" in
      v4*) echo 4;;
      v3*) echo 3;;
    esac
  )
}

# idf.py for IDF 4, or make -f idf3.mk for IDF 3
# Note: without arguments, **the default command is idf.py flash monitor** (or
# make -f idf3.mk flash monitor in IDF 3)
idf-py() {
  idf-env

  ARGS="$*"
  if [ -z "$ARGS" ]
  then
    ARGS="flash monitor"
  fi

  V=`idf-version`
  if [ $V == 4 ]
  then
    ESPBAUD=921600 idf.py $ARGS
  elif [ $V == 3 ]
  then
    ESPBAUD=921600 make -f idf3.mk $ARGS
  else
    e R "oops; `idf-version` unrecognised"
  fi
}

# clean up build stuff
clean() { rm -rf build; e B "maybe delete sdkconfig too if not modded"; }

# IDF help
idf-help() {
  echo; e Y "IDF help is:"
  idf-env >/dev/null 2>&1
  idf.py help
}

# local help
build-help() {
  e Y "$P commands available are:"
  tac $P >/tmp/$$
  for n in `grep -n '^[a-z0-9-]*() {' /tmp/$$ |sed 's,:.*$,,' |tac`
  do
    nn=$((n+1))
    FNAME=`sed -n "${n}p" /tmp/$$ |sed 's,().*,,'`
    [ $FNAME == e -o $FNAME == usage -o $FNAME = colours ] && continue
    echo -en "$G${FNAME}: $N"
    sed -n "${nn},/^$/p" /tmp/$$ |sed 's,^#, ,' |tac
  done
}

# report the commit hashes of the IDF and ESP arduino core clones
versions() {
  idf-env >/dev/null 2>&1
  e G "FIRMWARE_VERSION=${FIRMWARE_VERSION}\nPROJ_VER=${PROJECT_VER}      "
  e G "PROJECT_PATH=${PROJECT_PATH}\nSDKS_DIR=${SDKS_DIR}                 "
  e G "PROJECT_NAME=${PROJECT_NAME}                                       "
  for d in \
    ${ESP_IDF_DIR} ${ESP_ARD_DIR} ${ESP_RAINMAKER_DIR} ${ESP_LIB_BUILDER_DIR}
  do
    echo -e $G; cd ${d} && pwd && git log --pretty=format:'%h' -n 1
    git status
  done
  echo -e $N
}

# copy-me-to; assume $1 has the title/slug...
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

# push the firware for OTA
push-firmware() {
  e firmware version is ${FIRMWARE_VERSION}
  cp build/${PROJECT_NAME}.bin firmware/${FIRMWARE_VERSION}.bin
  git add -v firmware/${FIRMWARE_VERSION}.bin
  echo ${FIRMWARE_VERSION} >firmware/version
  git commit -vm "added OTA firmware version ${FIRMWARE_VERSION}" \
    firmware/${FIRMWARE_VERSION}.bin firmware/version
  git push
}

# set up the arduino IDE
# (assumes that ~/.espressif/tools/xtensa-esp32-elf has the cross compiler)
setup-arduino-ide() {
  e preparing Arduino IDE dirs
  IDF_PATH=~/esp/esp-idf idf-env

  # note: we're using sneaky symlinks instead of doing get.py from tools...
  mkdir -p ${ARD_HW_DIR};
# TODO need to choose correct xtensa/gcc somehow!
  [ -r ${ARD_HW_DIR}/esp32 ] || (
    cd ${ARD_HW_DIR} && ln -s ../../../`basename ${ESP_ARD_DIR}` esp32 &&
      cd esp32/tools && ln -s \
        ~/.espressif/tools/xtensa-esp32-elf/esp-2020r3-8.4.0/xtensa-esp32-elf &&
        ln -s $IDF_PATH/components/esptool_py/esptool
  )
  [ -d ${ARD_LIB_DIR} ] || mkdir -p ${ARD_LIB_DIR}

  if [ ! -d ${ARD_IDE_SDKS_DIR} ]; then
    e "\ndownloading Arduino IDE"
    (
      cd ${SDKS_DIR} && wget ${ARD_IDE_URL} &&
        tar xJf ${ARD_IDE_FILE} && rm ${ARD_IDE_FILE}
    )
  fi
  e "Arduino IDE available"
}

# run the Arduino IDE
arduino-ide() {
  ARDARGS=$*
  echo ARDARGS are $ARDARGS

  # IDF_PATH and also PATH settings are needed
  idf-env

  # this bit was from the Makefiles
  ARD_IDE_VERNAME=`echo ${ARD_IDE_VER} |sed 's,\.,,g'`
  ARD_DOT_DIR=${SDKS_DIR}/dot-arduino15-${ARD_IDE_VERNAME}
  [ -d ${ARD_DOT_DIR} ] || (
    PREFS_TXT=${ARD_DOT_DIR}/preferences.txt
    mkdir ${ARD_DOT_DIR}
    echo "sketchbook.path=${SDKS_DIR}/Arduino" >> ${PREFS_TXT}
    echo "board=featheresp32" >> ${PREFS_TXT}
    echo "update.check=false" >> ${PREFS_TXT}
    echo "custom_DebugLevel=featheresp32_none" >> ${PREFS_TXT}
    echo "custom_FlashFreq=featheresp32_80" >> ${PREFS_TXT}
    echo "custom_UploadSpeed=featheresp32_921600" >> ${PREFS_TXT}
    echo "serial.debug_rate=115200" >> ${PREFS_TXT}
    echo "target_package=espressif" >> ${PREFS_TXT}
    echo "target_platform=esp32" >> ${PREFS_TXT}
    :
  );
  e "running Arduino IDE"
  # old style: ./bin/arduino-ide-runner.sh -${ARD_IDE_RUNNER_VER};
  set -- -${ARD_IDE_RUNNER_VER}

  # the rest used to be in arduino-runner.sh
  # TODO there's some redundancy between the common-env ARD_ vars and the
  # below

  USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] [-e(rase flash)] [-S(taging)] [-H(EAD)] [-8 (1.8.9)] [-1 (1.8.1)] [-3 (1.8.3)] [-5 (1.8.5)] [-6 (1.8.6)] [-7 (1.8.7)] [-9 (1.9.x)] [args]"
  OPTIONSTRING=hdSHx:8135967

  # specific locals
  BASEDIR="$(cd `dirname ${P}` && pwd)"
  SDKS_DIR=${BASEDIR}/local-sdks
  LIB_DIR=${SDKS_DIR}/Arduino

  # specific locals
  ERASE=
  PORT='/dev/ttyUSB0'
  IDEHOME=${SDKS_DIR}
  IDEBASE=${IDEHOME}

  # arduino IDE vars
  PREFSDIR=~/.arduino15
  SPREFSDIR=${IDEBASE}/dot-arduino15-staging
  HPREFSDIR=${IDEBASE}/dot-arduino15-head
  EIGHTPREFSDIR=${IDEBASE}/dot-arduino15-188
  ONE8ONEPREFSDIR=${IDEBASE}/dot-arduino15-181
  ONE83PREFSDIR=${IDEBASE}/dot-arduino15-183
  ONE85PREFSDIR=${IDEBASE}/dot-arduino15-185
  ONE86PREFSDIR=${IDEBASE}/dot-arduino15-186
  ONE87PREFSDIR=${IDEBASE}/dot-arduino15-187
  ONE9xPREFSDIR=${IDEBASE}/dot-arduino15-190-beta
  X=
  STAGING=
  HEAD=
  EIGHT=
  ONE8ONE=
  ONE83=
  ONE85=
  ONE86=
  ONE87=
  ONE9x=
  STAGINGDIR=${IDEBASE}/arduino-1.6.5-r5
  HEADDIR=${IDEBASE}/arduino-1.6.5-r5--local-esp
  EIGHTDIR=${IDEBASE}/arduino-1.8.9
  ONE8ONEDIR=${IDEBASE}/arduino-1.8.1
  ONE83DIR=${IDEBASE}/arduino-1.8.3
  ONE85DIR=${IDEBASE}/arduino-1.8.5
  ONE86DIR=${IDEBASE}/arduino-1.8.6
  ONE87DIR=${IDEBASE}/arduino-1.8.7
  #ONE9xDIR=${IDEBASE}/arduino-PR-beta1.9-BUILD-107
  ONE9xDIR=${IDEBASE}/arduino-PR-beta1.9-BUILD-*

  # process options
  while getopts $OPTIONSTRING OPTION
  do
    case $OPTION in
      h)	usage 0 ;;
      d)	DBG=echo ;;
      e)	ERASE=yes ;;
      S)	STAGING=yes ;;
      H)	HEAD=yes ;;
      8)	EIGHT=yes ;;
      1)	ONE8ONE=yes ;;
      3)	ONE83=yes ;;
      5)	ONE85=yes ;;
      6)	ONE86=yes ;;
      7)	ONE87=yes ;;
      9)	ONE9x=yes ;;
      x)	X="${OPTARG}" ;;
      *)	usage 1 ;;
    esac
  done
  shift `expr $OPTIND - 1`

  # main action branches
  if [ x$ERASE == xyes ]
  then
    [ -d Arduino ] || { echo "can't find Arduino dir from `pwd`"; exit 10; }
    echo running erase on $PORT ...
    echo Arduino/hardware/espressif/esp32/tools/esptool.py --port "${PORT}" erase_flash
    Arduino/hardware/espressif/esp32/tools/esptool.py --port "${PORT}" erase_flash
    exit 0
  else
    # need to specify an IDE version to run
    if [ x$STAGING == x -a x$HEAD == x -a x$EIGHT == x -a x$ONE8ONE == x -a x$ONE83 == x -a x$ONE85 == x -a x$ONE86 == x -a x$ONE87 == x -a x$ONE9x == x ]
    then
      echo "you must choose staging or head or 8 or 1 or 3 or etc."
      usage 2
    fi
  fi

  # choose version
  e G preparing to run Arduino IDE...
  if [ x$STAGING == xyes ]
  then
    USEPREFS=${SPREFSDIR}
    USEIDE=${STAGINGDIR}
  elif [ x$HEAD == xyes ]
  then
    USEPREFS=${HPREFSDIR}
    USEIDE=${HEADDIR}
  elif [ x$EIGHT == xyes ]
  then
    USEPREFS=${EIGHTPREFSDIR}
    USEIDE=${EIGHTDIR}
  elif [ x$ONE8ONE == xyes ]
  then
    USEPREFS=${ONE8ONEPREFSDIR}
    USEIDE=${ONE8ONEDIR}
  elif [ x$ONE83 == xyes ]
  then
    USEPREFS=${ONE83PREFSDIR}
    USEIDE=${ONE83DIR}
  elif [ x$ONE85 == xyes ]
  then
    USEPREFS=${ONE85PREFSDIR}
    USEIDE=${ONE85DIR}
  elif [ x$ONE86 == xyes ]
  then
    USEPREFS=${ONE86PREFSDIR}
    USEIDE=${ONE86DIR}
  elif [ x$ONE87 == xyes ]
  then
    USEPREFS=${ONE87PREFSDIR}
    USEIDE=${ONE87DIR}
  elif [ x$ONE9x == xyes ]
  then
    USEPREFS=${ONE9xPREFSDIR}
    USEIDE=${ONE9xDIR}
  else
    echo 'erk!'
    usage 3
  fi

  # link the prefs dir if it doesn't exist
  if [ -d $PREFSDIR ]
  then
    mv $PREFSDIR $HOME/.saved-`basename $PREFSDIR`-$$
  fi
  if [ ! -e $PREFSDIR ]
  then
    echo linking $USEPREFS to $PREFSDIR ...
    ( cd; ln -s $USEPREFS $PREFSDIR; )
  fi

  # the prefs dir should be a link to a version-specific dir
  if [ ! -L $PREFSDIR ]
  then
    echo $PREFSDIR should be a link
    ls -l $PREFSDIR
    usage 4
  fi

  # switch the link to the required version
  rm $PREFSDIR
  ln -s $USEPREFS $PREFSDIR
  echo using $PREFSDIR: `ls -ld $PREFSDIR`

  # run the IDE
  echo running arduino IDE from `pwd`
  if [ -x `ls $USEIDE/arduino` ]
  then
    echo running arduino from `pwd`...
    echo $USEIDE/arduino $ARDARGS
    $USEIDE/arduino $ARDARGS
  else
    cd $USEIDE
    cd build
    echo doing ant run from `pwd`...
    ant run
  fi
}

# arduino build, IDF monitor
arduino-build() {
  arduino-ide --upload sketch/sketch.ino
  make -f idf3.mk simple_monitor
}

# run a web server in the build directory for firware OTA
ota-httpd() {
  # firmware versioning
  FIRMWARE_VERSION=$(grep 'int firmwareVersion =' main/main.cpp |
    sed -e 's,[^0-9]*,,' -e 's,;.*$,,')

  # create downloads for the httpd server, .bin and version
  cd build
  mkdir -p fwserver
  cd fwserver
  echo $FIRMWARE_VERSION >version
  [ -f Thing.bin ] || cp ../Thing.bin ${FIRMWARE_VERSION}.bin

  python -m http.server 8000
}

# setup of complete IDF + arduino core
setup() {
  # install software prerequisites
  e B "installing prerequisite packages"
  sudo apt-get install git wget flex bison gperf python3 python3-pip \
    python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util

  # make python3 the default
  e B "\nmaking python3 the default"
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10

  # clone the ESP-IDF and Arduino core git repositories
  ESPDIR=~/esp
  # random version of 4.3 dev tree that works with this arduino core commit
  IDFVER=357a27760
  ARDCOREVER=41e392f66
  mkdir -p $ESPDIR
  cd $ESPDIR
  e B "\ncloning, checking out and initialising ESP-IDF and the arduino core"
  git clone --recursive https://github.com/espressif/esp-idf.git
  git clone --recursive https://github.com/espressif/arduino-esp32.git
  cd esp-idf
  git checkout --recurse-submodules $IDFVER
  git submodule update --init --recursive
  cd ../arduino-esp32
  git checkout --recurse-submodules $ARDCOREVER
  git submodule update --init --recursive

  # toolchain: download the Xtensa compiler etc.
  e B "\ndownloading the toolchain"
  cd $ESPDIR/esp-idf
  ./install.sh

  # set up environment variables
  e B "\nmodifying ~/.bashrc for PATH and get_idf"
  echo "PATH=$PATH:~/.local/bin; export PATH" >>~/.bashrc
  echo "alias get_idf='. $HOME/esp/esp-idf/export.sh'" >>~/.bashrc

  # now you can run get_idf to set up or refresh the SDK in any
  # terminal session; check that this is working
  e G "\ntesting IDF environment export..."
  source "$ESPDIR/esp-idf/export.sh"
  e G "\ndoes 'which idf.py' say something sensible?"
  which idf.py
  e G "if so, you should be good to go :)"
}

# do an upload and monitor with platformio core
pio-run() {
  ARGS="$*"
  if [ -z "$ARGS" ]
  then
    ARGS="-t upload -t monitor"
  fi

  COM="pio run $ARGS"
  e G $COM
  $COM
}

# lib builder suite #########################################################
# TODO
#
# - lb-build-core-local2 does a combined setup-tooling, core build and install
#   to ~/Arduino/hardware
# - ideally we would merge with previous kit to separate out steps
#
#
# - RainMaker: try once more, or back to WifMgr? https://github.com/khoih-prog/ESPAsync_WiFiManager
#
# - revise the core rebuild workflow to:
#   - download the development release of the core to Arduino/hardware
#   - download the desired version of lib-builder (currently in
#     tooling/esp32-arduino-lib-builder)
#   - call tooling/esp32-arduino-lib-builder/components/arduino/tools/get.py
#     in the location that the IDE expects the compilers etc. to exist
#   - run lb-build-core-docker (converted to use non-shallow clones, and
#     possibly converted to run locally, not in docker, so that the whole lb-
#     suite can be used for a more comprehensive docker build)
#   - merge tooling/opt-esp into Arduino/hardware
#
# - RM examples:
#   - partition table wrong, fixed by copying rainmaker.csv to
#     partitions.csv in the sketch dir
#   - ble provisioning not working, or soft ap
# - try IDF and esp-rm examples
#   - idf provisioning example doesn't work either
# - start work with Rainmaker example
#   run-lb.sh: lb-menuconfig: set local control on RM
# - poss fall back to https://github.com/khoih-prog/ESPAsync_WiFiManager
#
# - make the sketch dir a file tree and link from main, so Arduino build
#   easier on Windows
# - IDF build should use Arduino/hardware dir esp-idf tree
#
# - iot5 / tiot: replace magic.sh etc.
# - notes on larry b's dockerfiles:
#   - the shallow clones mean that IDF version doesn't appear in platform.txt,
#     and there are other small differences there
#   - all of the generated .a are different from the release versions
#   - the out dir is only the sdk and platform.txt, so need to first
#     download and unpack the release version

# lib builder locals
# we set lib builder to a particular commit to avoid unpleasant surprises
# as it evolves... d491d3a was from Fri 21st May 2021, for example
TOOLING_DIR="$(cd `dirname ${P}` && pwd)/tooling"
# pre-scratch: LB_DIR=${TOOLING_DIR}/esp32-arduino-lib-builder
LB_DIR=${TOOLING_DIR}/esp/lib-builder
LB_VER=d491d3a
LB_IDF_DIR=${TOOLING_DIR}/esp/esp-idf
ARDIDE_PREFS_DIR=${HOME}/.arduino15
ARDIDE_PREFS=${ARDIDE_PREFS_DIR}/preferences.txt
ARDIDE_SKETCHBOOK_DIR=${HOME}/Arduino
ARDIDE_CORE_DIR=${ARDIDE_SKETCHBOOK_DIR}/hardware/espressif/esp32
ARDIDE_VER="arduino-1.8.15"
ARDIDE_DIR=${TOOLING_DIR}/${ARDIDE_VER}
ARDIDE_BIN_DIR="build/ardide-bin-output"
ARDIDE_SRC_DIR=arduino-ide-repo
BERNSTONE_DOCKERS=arduino-esp32-dockerfiles
ARDCORE_BUILDER="$(dirname ${TOOLING_DIR})/ardcore-builder"
ARDCORE_OPT_ESP="${TOOLING_DIR}/opt-esp-out"
ARDCORE_IMAGE_TAG="hamishcunningham/iot:lib-builder-2.0.0a"

# tips for running the LB suite
lb-help() {
  (
    e G "\nNotes on using the Lib Builder suite"
    cat <<EOF

The "lb-" suite of commands uses esp32-arduino-lib-builder and the arduino IDE
to provide a CLI for installing tooling and for building and burning firmware.
It also provides export of the .bin etc. to the local filesystem with a view
to easing Dockerisation of build-in-container/burn-on-localhost workflows (to
get over the problem of Windows and Mac not passing through serial ports to
the container).

The lib builder tool itself provides the ability to reconfigure libraries in
ESP IDF and then rebuild the core (so we can adjust sdkconfig settings, for
example).

Workflow elements:

- lb-prereqs installs dependencies of the tools
- lb-setup-tooling downloads the core, the IDE and ESP IDF to ./tooling
- lb-menuconfig (run from tooling/esp32-arduino-lib-builder) reconfigures the
  core and IDF options; then use lb-build-core-... to rebuild the core
- lb-ardide runs the IDE UI
- lb-export uses the IDE to compile/upload firmware and save the output
  (including burn command) in ./build/ardide-bin-output
- lb-burn does an IDE CLI upload
- lb-idf-py runs the ESP IDF idf.py command
- lb-monitor uses IDF to monitor serial
- lb-erase-flash uses idf.py to erase the device flash

(There's also a utility, lb-recompile-ardide, to clone and compile the IDE
itself from source, if needed.)

Notes:

- during lb-setup-tooling you can safely ignore "fatal" error "cannot change
  to '.../components/arduino'"
- when running the IDE, you can ignore java.net.UnknownHostException messages
  (the script firewalls the IDE to prevent the endless DNS error messages in
  1.8...)

Commands:

EOF
    $P -h |sed -n '/lb-help/,$p' |grep -v 'Usage:'
  ) |less -r
}

# install prereqs
lb-prereqs() {
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
  e Y "this might not match your LB version!"

  groups |grep -q dialout ||
    e B "you should probably add yourself to group dialout"
  e G 'prerequisites installed :)'
}

# clone lib-builder, download arduino IDE, setup Arduino and .arduino15
# (several GB download, + build; can take about 30 minutes!)
# calls lb-setup-arduino and lb-build-core-...
lb-setup-tooling() {
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
    lb-build-core-local
  else
    cd $ARDCORE_BUILDER
    [ -d dist ] || cp -a ~/.espressif/dist .
    docker build \
      -t ${ARDCORE_IMAGE_TAG} \
      -f "Dockerfile-2.0.0a-tweaked" \
      .
    e Y "image $ARDCORE_IMAGE_TAG build..."
    e Y "to reconfigure and rebuild do TODO" # TODO

    lb-build-core-docker
  fi

  lb-setup-arduino
}

# rebuild the arduino esp32 core and copy into Arduino/hardware
# (to reconfigure run lb-menuconfig first); this version does the build
# using docker
lb-build-core-docker() {
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
# (merge with lb-build-core-local copy part?)
# the out dir is only the sdk and platform.txt, so need to first
# download and unpack the release version, e.g.
# wget https://github.com/espressif/arduino-esp32/releases/download/2.0.0-alpha1/esp32-2.0.0-alpha1.zip
# and also do get.py in tools
  # now copy the build into Arduino/hardware...
  [ -d $ARDIDE_CORE_DIR ] && mv ${ARDIDE_CORE_DIR} ~/saved-esp32-$$
  mkdir -p ${ARDIDE_CORE_DIR}
  rsync -a --dry-run ${ARDCORE_OPT_ESP}/tools ${ARDIDE_CORE_DIR}/tools
}

# rebuild the arduino esp32 core and copy into Arduino/hardware
# (to reconfigure run lb-menuconfig first); this version does the build on the
# local host
lb-build-core-local() {
  cd $LB_DIR

# if we want to only do a particular target uncomment this:
# # make a copy of the build script that only does esp32
# MODIFIED_BUILD=modified-build.sh
# T='TARGETS="esp32"'
# sed 's,^TARGETS=.*$,'${T}',' build.sh >$MODIFIED_BUILD
# chmod u+x $MODIFIED_BUILD
#
# # call the (modified) LB build.sh
# $MODIFIED_BUILD

  # run the build
  ./build.sh

  # now copy the build into Arduino/hardware...
  # if first time, copy whole core tree, and download the tools,
  # else just copy the built libraries
  if [ ! -d $ARDIDE_CORE_DIR ]
  then
    mkdir -p `dirname ${ARDIDE_CORE_DIR}`
    cp -a $LB_DIR/components/arduino ${ARDIDE_CORE_DIR}
    (
      cd ${ARDIDE_CORE_DIR}/tools
      python3 get.py
    )
  else
    export ESP32_ARDUINO=${ARDIDE_CORE_DIR}
    ./tools/copy-to-arduino.sh
  fi
}

# download and setup an Arduino IDE
lb-setup-arduino() {
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

  # create ~/Arduino
  [ -d $ARDIDE_SKETCHBOOK_DIR ] || mkdir $ARDIDE_SKETCHBOOK_DIR

# TODO
# [ -d $ARDIDE_CORE_DIR ] && mv ${ARDIDE_CORE_DIR} ~/saved-esp32-$$
# cd $(dirmame $ARDIDE_CORE_DIR)
# wget "https://github.com/espressif/arduino-esp32/releases/download/2.0.0-alpha1/esp32-2.0.0-alpha1.zip"
# unzip "esp32-2.0.0-alpha1.zip"
# mv "esp32-2.0.0-alpha1.zip" esp32
# cd esp32/tools
# # need to get.py but not included in the distribution :(
}

# run menuconfig
lb-menuconfig() {
  source ${LB_IDF_DIR}/export.sh
  idf.py menuconfig
}

# run lb tooling ardide
lb-ardide() {
  e G running ${ARDIDE_DIR}/arduino $* from $PWD
  ${ARDIDE_DIR}/arduino $*
}

# do a firmware compile/upload ($1) and drop the .bin in pwd
# (also captures the burn command for later use)
lb-export() {
  e G "setting build.path in ${ARDIDE_PREFS}"
  grep -q "^build.path=${ARDIDE_BIN_DIR}" ${ARDIDE_PREFS} || (
    grep -v '^build.path=' ${ARDIDE_PREFS} >/tmp/$$-prefs
    mv /tmp/$$-prefs ${ARDIDE_PREFS}
    echo "build.path=${ARDIDE_BIN_DIR}" >> ${ARDIDE_PREFS}
  )
  grep 'build.path' ${ARDIDE_PREFS}

  e B "deleting previous build if any"
  [ -d ${ARDIDE_BIN_DIR} ] && rm -rf ${ARDIDE_BIN_DIR}
  mkdir -p ${ARDIDE_BIN_DIR}

  BURN_ME=${ARDIDE_BIN_DIR}/burn-me.sh
  echo '#!/bin/bash' >${BURN_ME}
  chmod 755 ${BURN_ME}

  e G "running ${ARDIDE_DIR}/arduino --verify (ish) $* from ${PWD}"
  ${ARDIDE_DIR}/arduino --verbose --upload $* 2>&1 | \
    grep '^python.*esptool.py.*write_flash' | \
      sed -e 's,/home[^ ]*\(build.ardide-bin-output\),\1,g' \
          -e 's,/home/[a-z][a-z]*/,${HOME}/,g' \
      >>${BURN_ME}

  e B "burn command is `tail -1 ${BURN_ME}`"

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

# do a compile and upload of sketch at $1
lb-burn() {
# TODO option to run burn-me.sh here?
  e G running ${ARDIDE_DIR}/arduino --upload $* from $PWD
  firejail --noprofile --net=none /bin/bash -c \
    "${ARDIDE_DIR}/arduino --upload $*"
}

# run the core's copy of ESP IDF idf.py
lb-idf-py() {
  source ${LB_IDF_DIR}/export.sh
  idf.py $*
}

# use the LB copy of IDF to erase flash
lb-erase-flash() {
  source ${LB_IDF_DIR}/export.sh
  esptool.py erase_flash
}

# use the LB copy of IDF to monitor serial
lb-monitor() {
  cd ${LB_IDF_DIR}
  source ./export.sh
  cd examples/get-started/hello_world
  idf.py app monitor
}

# recompile a copy of the arduino IDE checkout out in tooling/arduino-ide-repo
# (will clone if doesn't exist already)
lb-recompile-ardide() {
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


# TODO this is the new stuff, needing integration

# env for core-based LB
e G preparing LB env...
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
export ARDIDE_BIN_DIR="build/ardide-bin-output"
e G tooling is $TOOLING_DIR

# env for building the core
lb-core-build-env() { source $IDF_PATH/export.sh &> /dev/null; }

# a quicker clone, one commit only
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

# create a fresh install of the core at ~/Arduino; seed prefs at ~/.arduino15
# (call it following a successful core build)
lb-install-core() {
  lb-core-build-env

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

# scratchpad
scratch() {
  if false; then
    # done
    :
  elif true; then
    # now
    :
  else
    # to do
    :
  fi
  exit 0
}

# (new) lb core build
#   - download the development release of the core to Arduino/hardware
#   - download the desired version of lib-builder (currently in
#     tooling/esp32-arduino-lib-builder)
#   - call tooling/esp32-arduino-lib-builder/components/arduino/tools/get.py
#     in the location that the IDE expects the compilers etc. to exist
#   - run lb-build-core-docker (converted to use non-shallow clones, and
#     possibly converted to run locally, not in docker, so that the whole lb-
#     suite can be used for a more comprehensive docker build)
#   - merge tooling/opt-esp into Arduino/hardware
#   - OR, try https://github.com/plerup/makeEspArduino ?!
lb-build-core-local2() {
  e G "preparing core build in $TOOLING_DIR"

  shallow-clone https://github.com/espressif/esp-idf \
    cf457d412a7748139b77c94e7debe72ee86199af $IDF_PATH \
    && cd $IDF_PATH && git submodule update --progress --depth 1 \
      --init --recursive \
    && rm $IDF_PATH/components/expat/expat/testdata/largefiles/* \
    && rm -rf $IDF_PATH/components/tinyusb/tinyusb/examples \
    && rm -rf $IDF_PATH/docs

  # pull in Larry Bernstone's Dockerfiles
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

  lb-core-build-env
  cd $LIB_BUILDER_DIR && ./build.sh

  lb-install-core
   
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
  e R "warning, new behaviour: doing nothing; use idf-py to replicate old"
  exit 0
else
  COMMAND="$*"
fi
e Y running $COMMAND ...
eval $COMMAND
exit $?
