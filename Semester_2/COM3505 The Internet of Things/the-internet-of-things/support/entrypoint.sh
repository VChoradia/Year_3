#!/bin/bash
# entrypoint.sh

# environment
echo entrypoint...
. $HOME/.bashrc
. $HOME/the-internet-of-things/support/tooling/platformio/penv/bin/activate
echo "\$0 = $0"
echo "\$* = $*"
echo "PATH = $PATH"
echo "MAGIC_COM = $MAGIC_COM"

# for convenience let's pull latest git repos
echo "pulling latest from git repos..."
(cd the-internet-of-things; git pull)
(cd unphone; git pull)
(cd unPhoneLibrary; git pull)

# uncomment to use latest dev release of platformio
#echo "upgrading to latest platformio..."
#pio upgrade --dev

# run a shell or a magic.sh command if we have one
cd project && echo "working in $(pwd)" || :
if [ -z "$MAGIC_COM" ]
then
  if [ ! -z "$*" ]
  then
    echo "running $*"
    $*
  else
    echo "running shell"
    bash
  fi
else
  echo "running magic.sh"
  ~/the-internet-of-things/support/magic.sh $*
fi

# ensure all mapped files are writeable back on the host (ignoring big dirs)
# TODO can't remember what was triggering a need for this, commenting out for
# now
#cd $HOME
#[ "$(find project |wc -l)" -gt 20000 ] && { echo 'big dir, no chmod'; exit 0; }
#chmod -R g+rw project                                   2>/dev/null
#chmod    g+s  `find project -type d 2>/dev/null`        2>/dev/null

echo "entrypoint exiting"
