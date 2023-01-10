#!/bin/bash

# Abort on errors, as well as unset variables. Makes the script less error prone.
set -eu

# Find the location of this script, as some required things are stored next to it.
SRC_DIR="$(pwd)"
TOOLS_DIR="${SRC_DIR}/tools"
# Toolchain file location for cmake
TOOLCHAIN_FILE="${TOOLS_DIR}/arm-cross-compile.toolchain"

# Location of the sysroot, which is used during cross compiling
BUILD_DIR="${BUILD_DIR:-${SRC_DIR}/_build}"
SYSROOT="${BUILD_DIR}/sysroot"

COMPLETE_FLAG_FILE="${SYSROOT}/sysroot_complete"

build_sysroot()
{
    echo ""
    echo "==== Building sysroot for cross compiling ===="
    echo ""

    mkdir -p "${SYSROOT}/etc/apt/trusted.gpg.d"
    curl https://ftp-master.debian.org/keys/archive-key-10.asc | apt-key --keyring "${SYSROOT}/etc/apt/trusted.gpg.d/jessie.gpg" add -

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

    mount --bind "/dev" "${SYSROOT}/dev"
    mount --bind "/proc" "${SYSROOT}/proc"
    mount --bind "/sys" "${SYSROOT}/sys"

    # Install the forked specially configured dependencies
    # TODO: These should also come from cloudsmith and have a correct version number
    cp "${TOOLS_DIR}/"*".deb" "${SYSROOT}"

    chroot "${SYSROOT}" /usr/bin/dpkg -i /libdrm-ultimaker_2.4.102-imx8m_arm64.deb
    chroot "${SYSROOT}" /usr/bin/dpkg -i /mesa-ultimaker_19.0.1-imx8m_arm64.deb

    umount -lR "${SYSROOT}/dev"
    umount -lR "${SYSROOT}/proc"
    umount -lR "${SYSROOT}/sys"

    touch "${COMPLETE_FLAG_FILE}"

    echo "Finished building sysroot in: ${SYSROOT}"
    echo "You can now use cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} to build software"
}

# shellcheck disable=SC2317
cleanup()
{
    umount -qlR "${SYSROOT}/dev" || true; 
    umount -qlR "${SYSROOT}/proc" || true; 
    umount -qlR "${SYSROOT}/sys" || true exit
}

trap 'cleanup' EXIT


if [ ! "$(id -u)" -eq 0 ]; then
    echo "This script should be run with root permissions."
    exit 1
fi

usage()
{
    echo ""
    echo "This is a build script for generation of a Debian based sysroot that can be used for cross-compiling."
    echo ""
    echo "  -h Print this help text and exit"
    echo ""
}

while getopts ":h" options; do
    case "${options}" in
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

if [ -f "${COMPLETE_FLAG_FILE}" ]; then
    echo ""
    echo "==== Sysroot already done, skipping sysroot build. ===="
    echo ""
else
    rm -rf "${SYSROOT}"
    build_sysroot
fi

exit 0
