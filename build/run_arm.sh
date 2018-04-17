#!/bin/sh

docker run -it --entrypoint=/usr/bin/qemu-arm-static -e QEMU_EXECVE=1 $1 /bin/bash