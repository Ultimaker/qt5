FROM debian:buster-slim

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker buster build environment"

# Debian Buster is EOL - switch to archive repositories
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y \
    wget build-essential curl crossbuild-essential-arm64 multistrap perl pkg-config python3-distutils libssl-dev python python3-dev python3-sip-dev ccache libwayland-bin \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/*

COPY docker_env/buildenv_check.sh buildenv_check.sh
