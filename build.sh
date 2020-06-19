#!/bin/bash
# This script builds the QT libraries with eglfs backend plugins, resulting into a Debian package.

set -eu

ARCH="armhf"
UM_ARCH="imx6dl" # Empty string, or sun7i for R1, or imx6dl for R2

SRC_DIR="$(pwd)"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${SRC_DIR}/${BUILD_DIR_TEMPLATE}"

# Debian package information
PACKAGE_NAME="${PACKAGE_NAME:-qt-ultimaker}"
QT_VERSION="5.12.3"
RELEASE_VERSION="${RELEASE_VERSION:-${QT_VERSION}}"

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

    mkdir -p "${DEBIAN_DIR}/usr/local"

    cd "${BUILD_DIR}"

    "${SRC_DIR}/configure" \
        -platform linux-g++-64 \
        -device ultimaker-linux-imx6-g++ \
        -device-option CROSS_COMPILE="${CROSS_COMPILE}" \
        -sysroot "${SYSROOT}" \
        -extprefix "${DEBIAN_DIR}/usr/local" \
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
        -nomake tests \
        -nomake tools \
        -nomake examples \
        -no-compile-examples \
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
        -libudev \
        -widgets \
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
        -skip qtremoteobjects \
        -skip qtwebview \
        -skip qtsystems \
        -skip qtwebview

# Add the following to build the examples
#        -compile-examples \
#        -examplesdir /usr/share/examples \

    make "${MAKEFLAGS}"
    make "${MAKEFLAGS}" install

    echo "Finished building."
}


#build_sip()
#{
#    cd "${BUILD_DIR}"
##    curl -L -o sip.tar.gz https://sourceforge.net/projects/pyqt/files/sip/sip-4.19.8/sip-4.19.8.tar.gz
#    curl -L -o sip.tar.gz https://www.riverbankcomputing.com/static/Downloads/sip/sip-5.3.1.dev2006052202.tar.gz
#    tar -xf sip.tar.gz
#    sip-*
#    python3 configure.py
#    make
#    make install
#}

#build_pyqt()
#{
#    cd "${BUILD_DIR}"
#    curl -L -o "pyqt${RELEASE_VERSION}.tar.gz" https://www.riverbankcomputing.com/static/Downloads/PyQt5/curl -L -o "pyqt${RELEASE_VERSION}.tar.gz/PyQt5_gpl-${RELEASE_VERSION}.tar.gz"
#    tar -xf "pyqt${RELEASE_VERSION}.tar.gz"
#    cd PyQt*
#    python3 configure.py -h
#    python3 configure.py -c --confirm-license --no-designer-plugin --qml-debug -e QtDBus -e QtCore -e QtGui -e QtQml \
#        -e QtQuick -e QtMultimedia -e QtNetwork --qmake="${BUILD_DIR}/qtbase/bin/qmake"
#    # -e QtCore -e QtGui -e QtQml -e QtQuickControls2 -e QtQuickLayouts -e QtMultimedia
#    make
#    make install

# Check & Go to Workspace
#RUN python3 -c "import PyQt5" && \
#    mkdir -p /opt/workspace
#
#WORKDIR /opt

#RUN mkdir $package && \
#    mkdir $package/DEBIAN && \
#    mkdir $package/opt && \
#    mkdir $package/opt/qt && \
#    cp -R /usr/lib/python3/dist-packages/ $package/opt/pyqt/ && \
#    cp -R /opt/qt/lib $package/opt/qt/ && \
#    cp -R /opt/qt/plugins $package/opt/qt/ && \
#    cp -R /opt/qt/qml $package/opt/qt/
#
#RUN echo "Package: $name" >> /opt/$package/DEBIAN/control && \
#    echo "Architecture: $arch" >> /opt/$package/DEBIAN/control && \
#    echo "Maintainer: Joost Jager" >> /opt/$package/DEBIAN/control && \
#    echo "Depends: libgl1-mesa-glx,libfontconfig,libpython3.4,libinput5" >> /opt/$package/DEBIAN/control && \
#    echo "Priority: optional" >> /opt/$package/DEBIAN/control && \
#    echo "Version: $version" >> /opt/$package/DEBIAN/control && \
#    echo "Description: Ultimaker-specific build of Qt and PyQt" >> /opt/$package/DEBIAN/control

#RUN dpkg-deb --build $package
#}

create_debian_package()
{
    echo "Building Debian package."

    mkdir -p "${DEBIAN_DIR}/DEBIAN"
    sed -e 's|@ARCH@|'"${ARCH}"'|g' \
        -e 's|@PACKAGE_NAME@|'"${PACKAGE_NAME}"'|g' \
        -e 's|@RELEASE_VERSION@|'"${RELEASE_VERSION}-${UM_ARCH}"'|g' \
        "${SRC_DIR}/debian/control.in" > "${DEBIAN_DIR}/DEBIAN/control"

    DEB_PACKAGE="${PACKAGE_NAME}_${RELEASE_VERSION}-${UM_ARCH}_${ARCH}.deb"

    # Add the QT runtime environment source script
    mkdir -p "${DEBIAN_DIR}/usr/local/share/qt5"
    cp "${SRC_DIR}/set_qt5_eglfs_env" "${DEBIAN_DIR}/usr/local/share/qt5"
    cp "${SRC_DIR}/qt_eglfs_kms_cfg.json" "${DEBIAN_DIR}/usr/local/share/qt5"
    chmod +x "${DEBIAN_DIR}/usr/local/share/qt5/set_qt5_eglfs_env"

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
