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

The reason that everything happens during container build is to take advantage of docker layers during development. Git recursive 
clone and configure/make is very lengthy. This way it is quicker to test modifications to for example the deb packaging steps 
at the end of the dockerfile.