### How to build target base image with qemu enabled

docker build . -f Dockerfile-armv7hf-jessie-qemu -t armv7hf-jessie-qemu

### How to build QT and PyQt deb package for target

docker build . -f Dockerfile-qt-amd64 -t qt-amd64 --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --no-cache

or

docker build . -f Dockerfile-qt-arm -t qt-arm --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --no-cache

### How to get the deb file

Start the container and copy the deb file out:

CONTAINER=$(docker create qt-amd64) && docker cp $CONTAINER:/opt/qt-ultimaker-5.9.4-1_amd64.deb .

(replace architecture and version with the current version)

Alternatively, first not the name of teh .deb file for the docker output, then, outside the docker, identify the CONTAINER_ID
and copy the file as in the following example:

lmyerscough@UM-LAPTOP-456:~/src/qt5/build$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
7eff686af945        qt-arm:latest       "/usr/bin/qemu-arm..."   4 days ago          Up 4 days                               trusting_spence
lmyerscough@UM-LAPTOP-456:~/src/qt5/build$ docker cp 7eff686af945:/opt/qt-ultimaker-5.9.4-5_armhf.deb .


The reason that everything happens during container build is to take advantage of docker layers during development. Git recursive 
clone and configure/make is very lengthy. This way it is quicker to test modifications to for example the deb packaging steps 
at the end of the dockerfile.

A big disadvantage of this approach, however, is that *everything* in the docker has to be rebuilt for even the most trivial of changes.
You can mitigate this to a large extent by starting a bash shell within the docker, then copy-pasting sections from (e.g.) Dockerfile-qt-arm
to the command line. In this case, it can help to set up aliases as shown below.

alias ENV='echo === ENV ===  && export'
alias WORKDIR='echo === WORKDIR ===  && cd'
alias RUN='echo === RUN ===  &&'
