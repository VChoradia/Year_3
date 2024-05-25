#!/bin/bash
# entrypoint.sh

echo entrypoint...
source /home/ubuntu/.bashrc
source /home/ubuntu/the-internet-of-things/support/tooling/platformio/penv/bin/activate
echo $0
echo $*
echo $PATH

# TODO not needed?
# chmod -R a+rw project

(cd the-internet-of-things; git pull)
(cd unphone; git pull)

if [ -z "$*" ]
then
  echo running shell
  bash
elif [ "x$1" == "x--gen-cache" ]
then
  # TODO delete, as cache generation works at docker build time now :)
  cd unphone/examples/2022 && ./hack.sh &&
    ${PIO_CLI} run -e unphone6 && ${PIO_CLI} run -e unphone9;
  bash
else
  echo running magic.sh
  cd project && pwd && ~/the-internet-of-things/support/magic.sh $*
fi
