FROM debian:buster-slim

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker buster build environment"


RUN apt-get update && \
    apt-get install -y \
    wget build-essential curl crossbuild-essential-arm64 multistrap perl pkg-config python3-distutils libssl-dev python python3-dev python3-sip-dev ccache \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/*
