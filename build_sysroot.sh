#!/bin/bash

# Abort on errors, as well as unset variables. Makes the script less error prone.
set -eu

# Find the location of this script, as some required things are stored next to it.
SRC_DIR="$(pwd)"
TOOLS_DIR="${SRC_DIR}/tools"

# Location of the sysroot, which is used during cross compiling
SYSROOT="${TOOLS_DIR}/sysroot"

build_sysroot()
{
    echo "Going to build sysroot for cross compiling"

    mkdir -p "${SYSROOT}/etc/apt/trusted.gpg.d"
    rm -rf "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    curl https://ftp-master.debian.org/keys/archive-key-11.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"
    curl https://ftp-master.debian.org/keys/release-11.asc | gpg --dearmor >> "${SYSROOT}/etc/apt/trusted.gpg.d/debian-keyring.gpg"

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

if [ ! "$(id -u)" -eq 0 ]; then
    echo "This script should be run with root permissions."
    exit 1
fi

usage()
{
    echo ""
    echo "This is a build script for generation of a Debian based sysroot that can be used for cross-compiling."
    echo ""
    echo "  -c Clean the build output directory '_build'."
    echo "  -h Print this help text and exit"
    echo ""
    echo "  The package release version can be passed by passing 'RELEASE_VERSION' through the run environment."
}

while getopts ":ch" options; do
    case "${options}" in
    c)
        if [ -d "${SYSROOT}" ] && [ -z "${SYSROOT##*sysroot*}" ]; then
            rm -rf "${SYSROOT}"
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
    build_sysroot
    exit 0
fi


exit 0
