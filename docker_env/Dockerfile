FROM debian:buster-slim

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker buster build environment"


RUN apt-get update && \
    apt-get install -y \
    build-essential curl crossbuild-essential-armhf multistrap perl pkg-config python python3 python3-distutils python3-pip \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/*
