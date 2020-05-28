#!/bin/bash
# shellcheck disable=SC1117

# This script builds the kernel, kernel modules, device trees and boot scripts for the A20 linux system that we use.


set -eu

ARCH="armhf"
UM_ARCH="imx6dl" # Empty string, or sun7i for R1, or imx6dl for R2

SRC_DIR="$(pwd)"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${SRC_DIR}/${BUILD_DIR_TEMPLATE}"

# Debian package information
PACKAGE_NAME="${PACKAGE_NAME:-qt-ultimaker}"
RELEASE_VERSION="${RELEASE_VERSION:-5.12.3}"

DEBIAN_DIR="${BUILD_DIR}/debian"
CROSS_COMPILE="arm-linux-gnueabihf-"

TOOLS_DIR="${SRC_DIR}/tools"
SYSROOT="${TOOLS_DIR}/sysroot"
MAKEFLAGS=-j$(($(getconf _NPROCESSORS_ONLN) - 1))

export PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig:${SYSROOT}/usr/share/pkgconfig

build()
{
    if [ -d "${DEBIAN_DIR}" ]; then
        rm -rf "${DEBIAN_DIR}"
    fi

    mkdir -p "${DEBIAN_DIR}"

    cd "${BUILD_DIR}"

    ${SRC_DIR}/configure \
        -platform linux-g++-64 \
        -device linux-imx6-g++ \
        -device-option CROSS_COMPILE=${CROSS_COMPILE} \
        -sysroot ${SYSROOT} \
        -no-xcb \
        -release \
        -confirm-license \
        -opensource \
        -no-use-gold-linker \
        -pkg-config \
        -shared \
        -silent \
        -no-pch \
        -no-rpath \
        -eglfs \
        -gbm \
        -opengl es2 \
        -kms \
        -xcb \
        -xcb-xlib \
        -xkbcommon \
        -no-directfb \
        -no-linuxfb \
        -no-compile-examples \
        -nomake examples \
        -nomake tests \
        -nomake tools \
        -no-cups \
        -no-sql-db2 \
        -no-sql-ibase \
        -no-sql-mysql \
        -no-sql-oci \
        -no-sql-odbc \
        -no-sql-psql \
        -no-sql-sqlite \
        -no-sql-sqlite2 \
        -no-sql-tds \
        -skip qtconnectivity \
        -skip qtdoc \
        -skip qtlocation \
        -skip qtscript \
        -skip qtsensors \
        -skip qtwebchannel \
        -skip qtwebengine \
        -skip qtwebsockets \
        -skip qtandroidextras \
        -skip qtactiveqt \
        -skip qttools \
        -skip qt3d \
        -skip qtcanvas3d \
        -skip qtserialport \
        -skip qtwayland \
        -skip qtgamepad \
        -skip qtscxml \
        -skip qtcharts \
        -skip qtdatavis3d \
        -skip qtfeedback \
        -skip qtspeech \
        -skip qtnetworkauth \
        -skip qtpim \
        -skip qtpurchasing \
        -skip qtqa \
        -skip qtquickcontrols \
        -skip qtremoteobjects \
        -skip qtwebview \
        -skip qtsystems \
        -extprefix ${DEBIAN_DIR}/

    make "${MAKEFLAGS}"
    make "${MAKEFLAGS}" install

    echo "Finished building."
}


create_debian_package()
{
    echo "Building Debian package."

    mkdir -p "${DEBIAN_DIR}/DEBIAN"
    sed -e 's|@ARCH@|'"${ARCH}"'|g' \
        -e 's|@PACKAGE_NAME@|'"${PACKAGE_NAME}"'|g' \
        -e 's|@RELEASE_VERSION@|'"${RELEASE_VERSION}-${UM_ARCH}"'|g' \
        "${SRC_DIR}/debian/control.in" > "${DEBIAN_DIR}/DEBIAN/control"

    DEB_PACKAGE="${PACKAGE_NAME}_${RELEASE_VERSION}-${UM_ARCH}_${ARCH}.deb"

    # Build the Debian package
    fakeroot dpkg-deb --build "${DEBIAN_DIR}" "${BUILD_DIR}/${DEB_PACKAGE}"

    echo "Finished building Debian package."
    echo "To check the contents of the Debian package run 'dpkg-deb -c *.deb'"
}

usage()
{
    echo ""
    echo "This is the build script for the QT5 graphical user interface libraries."
    echo ""
    echo "  -c Clean the build output directory '_build'."
    echo "  -h Print this help text and exit"
    echo ""
    echo "  The package release version can be passed by passing 'RELEASE_VERSION' through the run environment."
}

while getopts ":ch" options; do
    case "${options}" in
    c)
        if [ -d "${BUILD_DIR}" ] && [ -z "${BUILD_DIR##*_build*}" ]; then
            rm -rf "${BUILD_DIR}"
        fi
        exit 0
        ;;
    h)
        usage
        exit 0
        ;;
    :)
        echo "Option -${OPTARG} requires an argument."
        exit 1
        ;;
    ?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"


if [ "${#}" -gt 1 ]; then
    echo "Too many arguments."
    usage
    exit 1
fi

if [ "${#}" -eq 0 ]; then
    build
    create_debian_package
    exit 0
fi

case "${1-}" in
    deb)
        build
        create_debian_package
        ;;
    *)
        echo "Error, unknown build option given"
        usage
        exit 1
        ;;
esac

exit 0
