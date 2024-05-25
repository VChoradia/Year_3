# a Makefile to drive docker-based firmware builds

# TODO
# could map pwd instead, and run it with docker -f from magic.sh ?
# local install of esptool for burn and monitor? or pio?
# check the builds work :)
# document in micasa

# here's what pio does for burn:
# "/home/hamish/.platformio/penv/bin/python"
#   "/home/hamish/.platformio/packages/tool-esptoolpy/esptool.py" --chip esp32
#   --port "/dev/ttyUSB0" --baud 921600 --before default_reset --after
#   hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size
#   detect 0x1000
#   /home/hamish/.platformio/packages/framework-arduinoespressif32/tools/sdk/esp32/bin/bootloader_dio_40m.bin
#   0x8000
#   /home/hamish/the-internet-of-things/exercises/HelloWorld/.pio/build/featheresp32/partitions.bin
#   0xe000
#   /home/hamish/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin
#   0x10000 .pio/build/featheresp32/firmware.bin


VERSION=0.0.1
FWPATH=$(shell [ ! -z "$(FW)" ] && cd "$(FW)" && pwd \
  || echo "oops, cannot cd to FW $(FW)")

default: check build-image run build-fw stop

help:
	@echo "Makefile for ESP firmware builds; invoke with path source, e.g.:"
	@echo "  make FW=../../exercises/HelloWorld build"
	@echo "requires docker, bash and GNU make"

test:
	rm -f ../../exercises/HelloWorld/firmware.bin
	make FW=../../exercises/HelloWorld

# FW must be a directory
check:
	@[ -d "$(FW)" ] || \
          { echo "oops, FW ($(FW)) is not a directory"; exit 1; }
	@cd $(FW) && echo have a firmware path at `pwd`...

# create a docker image with ESP IDF, Ardiono core, PlatformIO, ...
# then use it to build firmware from FW
build-image: check
	@echo creating or updating docker image...
	sudo docker build . -t fw-builder:$(VERSION)

# run it, with the target firmware mapped into ~/fw-builder-target
run:
	sudo docker stop fw-builder || :
	sudo docker rm fw-builder   || :
	sudo docker run --name fw-builder -dt \
          -v $(FWPATH):/home/ubuntu/fw-builder-target \
          fw-builder:$(VERSION)

# check the container exists
ps:
	sudo docker ps -a |grep fw-builder
psa:
	sudo docker ps -a

# shut it down
stop:
	sudo docker stop fw-builder

# start it up again
start:
	sudo docker start fw-builder

# connect to the running container
exec:
	sudo docker exec -it fw-builder /bin/bash -i

# connect to the running container, do a pio build and copy out the .bin
build-fw:
	@cd $(FW) && echo going to build firmware in `pwd`...; \
	sudo docker exec -it fw-builder \
          /bin/bash -c "cd fw-builder-target && pwd && pio run"; \
	cp .pio/build/featheresp32/firmware.bin .; \
        ls -l firmware.bin
#         /bin/bash -c "cd fw-builder-target && ../magic.sh"

# notes for script version:
abbreviated:
	sudo docker build . -t fw-builder:$(VERSION)
	sudo docker rm fw-builder   || :
	sudo docker run --name fw-builder -dt \
          -v $(FWPATH):/home/ubuntu/fw-builder-target \
          fw-builder:$(VERSION)
	@cd $(FW) && echo going to build firmware in `pwd`...; \
          sudo docker exec -it fw-builder \
            /bin/bash -c "cd fw-builder-target && pwd && pio run"; \
          sudo docker stop fw-builder || :; \
          cp .pio/build/featheresp32/firmware.bin .; \
            ls -l firmware.bin
