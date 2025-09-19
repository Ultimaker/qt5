#!/bin/bash
# This script builds the QT libraries with eglfs backend plugins, resulting into a Debian package.

set -eu

ARCH="${ARCH:-arm64}" # armhf or x86_64 or amr64
UM_ARCH="${UM_ARCH:-imx8}" # Empty string, or sun7i for R1, or imx6dl for R2, or imx8m for colorado

SRC_DIR="$(pwd)"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${BUILD_DIR:-${SRC_DIR}/${BUILD_DIR_TEMPLATE}_${UM_ARCH}}"


# Debian package information
PACKAGE_NAME="${PACKAGE_NAME:-qt-ultimaker}"
QT_VERSION="5.12.3"
RELEASE_VERSION="${RELEASE_VERSION:-${QT_VERSION}}"

DEBIAN_DIR="${BUILD_DIR}/debian"
TARGET_DIR="${DEBIAN_DIR}/opt"
CROSS_COMPILE="aarch64-linux-gnu-"

TOOLS_DIR="${SRC_DIR}/tools"
SYSROOT="${BUILD_DIR}/sysroot"

cpu_cnt="$(nproc)"
export MAKEFLAGS="-j${cpu_cnt}"
export CCACHE_DIR="${BUILD_DIR}/ccache"

PYQT_TARGET_PYTHON_VERSION="3.11"

export PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig:${SYSROOT}/usr/share/pkgconfig:${SYSROOT}/usr/local/lib/pkgconfig

# Add the UM_ARCH (if any) to release version keeping a possible -dev on the most right side
if [ -n "${UM_ARCH}" ]; then
    if [[ ${RELEASE_VERSION} == *'-dev' ]]; then
        RELEASE_VERSION="${RELEASE_VERSION/-dev/-${UM_ARCH}-dev}"
    else
        RELEASE_VERSION="${RELEASE_VERSION}-${UM_ARCH}"
    fi;
fi;

build_sysroot()
{
    echo "Going to build sysroot for cross compiling"

    rm -rf "${SYSROOT}"
    mkdir -p "${SYSROOT}/etc/apt/trusted.gpg.d"
    rm -rf "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    # shellcheck disable=SC2129
    curl https://ftp-master.debian.org/keys/archive-key-11.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    curl https://ftp-master.debian.org/keys/release-11.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    curl https://ftp-master.debian.org/keys/archive-key-12.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    curl https://ftp-master.debian.org/keys/release-12.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"

    multistrap -f "${TOOLS_DIR}/sysroot_multistrap.cfg" -d "${SYSROOT}"

    # Fix up the symlinks in the sysroot, find all links that start with absolute paths
    #  and replace them with relative paths inside the sysroot.
    cd "${SYSROOT}"
    symlinks="$(find . -type l)"
    for file in ${symlinks}
    do
        link="$(readlink "${file}" || echo '')"
        if [ -n "${link}" ]
        then
            if [ "${link:0:1}" == "/" ]
            then
                if [ -e "${SYSROOT}/${link}" ]; then
                    rm "${file}"
                    ln --relative -sf "${SYSROOT}${link}" "${file}"
                fi
            fi
        fi
    done
    cd "${SRC_DIR}"

    echo "Finished building sysroot in: ${SYSROOT}"
}

build()
{
    mkdir -p "${TARGET_DIR}/qt"

    cd "${BUILD_DIR}"
    "${SRC_DIR}/configure" \
        -ccache \
        -v \
        -platform linux-g++-64 \
        -device ultimaker-linux-imx8-g++ \
        -device-option CROSS_COMPILE="${CROSS_COMPILE}" \
        -sysroot "${SYSROOT}" \
        -extprefix "${TARGET_DIR}/qt" \
        -release \
        -no-xcb \
        -no-glib \
        -no-xcb-xlib \
        -confirm-license \
        -opensource \
        -pkg-config \
        -linuxfb \
        -no-eglfs \
        -opengl es2 \
        -xkbcommon \
        -openssl \
        -no-gbm \
        -no-kms \
        -no-directfb \
        -nomake tests \
        -nomake tools \
        -nomake examples \
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
        -skip qtserialport \
        -skip qtwayland \
        -skip qtgamepad \
        -skip qtscxml \
        -skip qtfeedback \
        -skip qtspeech \
        -skip qtpim \
        -skip qtpurchasing \
        -skip qtremoteobjects \
        -skip qtsystems \
        -skip qtwebview \
        -skip qt3d

# Add the following to build the examples and remove the -nomake-examples
#        -compile-examples \
#        -examplesdir /usr/share/examples \

    mkdir -p "${CCACHE_DIR}"

    make "${MAKEFLAGS}"
    make "${MAKEFLAGS}" install

    echo "Finished building."
}

build_pyqt()
{
    mkdir -p "${BUILD_DIR}/pyqt"

    cd "${BUILD_DIR}/pyqt"
    curl -L -o pyqt5.tar.gz https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.9.2/PyQt5_gpl-5.9.2.tar.gz
    tar -xf pyqt5.tar.gz

    cd "PyQt5"*

    python3 configure.py \
        --verbose -c --confirm-license --no-designer-plugin \
        --qml-debug --qml-plugindir="${TARGET_DIR}/pyqt" \
        --destdir "${TARGET_DIR}/pyqt" \
        --configuration "${TOOLS_DIR}/pyqt.cfg" \
        --target-py-version="${PYQT_TARGET_PYTHON_VERSION}" \
        --qmake="${BUILD_DIR}/qtbase/bin/qmake" \
        --no-sip-files \
        --no-stubs \
        --no-tools

    make "${MAKEFLAGS}"
    make "${MAKEFLAGS}" install
}

create_debian_package()
{
    echo "Building Debian package."

    mkdir -p "${DEBIAN_DIR}/DEBIAN"
    sed -e 's|@ARCH@|'"${ARCH}"'|g' \
        -e 's|@PACKAGE_NAME@|'"${PACKAGE_NAME}"'|g' \
        -e 's|@RELEASE_VERSION@|'"${RELEASE_VERSION}"'|g' \
        "${SRC_DIR}/debian/control.in" > "${DEBIAN_DIR}/DEBIAN/control"

    DEB_PACKAGE="${PACKAGE_NAME}_${RELEASE_VERSION}_${ARCH}.deb"

    # Build the Debian package
    dpkg-deb --build "${DEBIAN_DIR}" "${BUILD_DIR}/${DEB_PACKAGE}"

    mv "${BUILD_DIR}/${DEB_PACKAGE}" "${SRC_DIR}"

    echo "Finished building of Debian package version: ${RELEASE_VERSION}"
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


# Clean any lingering file from previous build
clean_debian_dir() {
    rm -rf "${DEBIAN_DIR}"
}

if [ "${#}" -eq 0 ]; then
    build_sysroot
    clean_debian_dir
    build
    build_pyqt
    create_debian_package
    exit 0
fi

case "${1-}" in
    deb)
        build_sysroot
        clean_debian_dir
        build
        build_pyqt
        create_debian_package
        ;;
    *)
        echo "Error, unknown build option given"
        usage
        exit 1
        ;;
esac

exit 0
