# a Makefile to drive docker build of arduino-esp32 release/v4.2
#
# this is LIKELY BROKEN since the core 4.2 branch was deleted...

all: build run ps copy stop ps
	echo 'done, results are in "out"'

# build the libraries in a docker image
build:
	sudo docker build -f Dockerfile-v42-tweaked -t arduino-core:v4.2 .

# run it
run:
	sudo docker run --name ardcore -dt arduino-core:v4.2

# check the container exists
ps:
	sudo docker ps -a |grep ardcore
psa:
	sudo docker ps -a

# copy the output
copy:
	rm -rf out
	mkdir out tempdir
	chmod 777 tempdir
	sudo docker cp ardcore:/opt/esp/lib-builder/out tempdir
	sudo docker cp \
          ardcore:/opt/esp/lib-builder/components/arduino tempdir/arduino-esp32
	sudo chown -R `whoami`:`whoami` tempdir
	mv tempdir/out/* tempdir/arduino-esp32 out
	rm -rf tempdir

whole-esp-copy:
	rm -rf out
	mkdir out tempdir
	chmod 777 tempdir
	sudo docker cp ardcore:/opt/esp tempdir
	sudo chown -R `whoami`:`whoami` tempdir
	mv tempdir/* out
	rm -rf tempdir

# shut it down
stop:
	sudo docker stop ardcore

# start it up again
start:
	sudo docker start ardcore

# connect to the running container
exec:
	sudo docker exec -it ardcore /bin/bash -i

# merge into Arduino/hardware/espressif
merge-to-arduino-core:
	rsync -iav out/arduino-esp32/ ~/esp/arduino-esp32/
	rsync -iav out/tools/ ~/esp/arduino-esp32/tools/
	rsync -iav out/platform.txt ~/esp/arduino-esp32/

# merge into ~/.platformio
# TODO broken, doesn't update pio's toolchain in
# .platformio/packages/toolchain-xtensa32/bin/xtensa-esp32-elf-g++
merge-to-pio:
	rsync -iav out/tools/sdk/esp32/ \
          ~/.platformio/packages/framework-arduinoespressif32/tools/sdk/
	rsync -iav out/arduino-esp32/ \
          ~/.platformio/packages/framework-arduinoespressif32/
