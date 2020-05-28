FROM debian:buster-slim

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker buster build environment"


RUN apt-get update && \
    apt-get install -y \
    build-essential curl perl pkg-config crossbuild-essential-armhf python python3 multistrap \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/*
