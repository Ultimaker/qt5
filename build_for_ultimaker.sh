#!/bin/sh
#
# SPDX-License-Identifier: LGPL-3.0+
#
# Copyright (C) 2019 Ultimaker B.V.
#

set -eu

LOCAL_REGISTRY_IMAGE="qt5-ultimaker"

ARCH="${ARCH:-armhf}"
SRC_DIR="$(pwd)"
PREFIX="/usr"
RELEASE_VERSION="${RELEASE_VERSION:-5.12.3}"
DOCKER_WORK_DIR="/docker_workdir"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${BUILD_DIR_TEMPLATE}"
run_linters="yes"
run_env_check="yes"


update_docker_image()
{
    echo "Building local Docker build environment."
    docker build ./docker_env -t "${LOCAL_REGISTRY_IMAGE}"
}

run_in_docker()
{
    docker run \
        --privileged \
        --cap-add=ALL \
        --security-opt seccomp:unconfined \
        --rm \
        -it \
        -u "$(id -u)" \
        -e "BUILD_DIR=${DOCKER_WORK_DIR}/${BUILD_DIR}" \
        -e "ARCH=${ARCH}" \
        -e "PREFIX=${PREFIX}" \
        -e "RELEASE_VERSION=${RELEASE_VERSION}" \
        -e "MAKEFLAGS=-j$(($(getconf _NPROCESSORS_ONLN) - 1))" \
        -e "CCACHE_DIR=${DOCKER_WORK_DIR}/tools/sysroot/ccache" \
        -v "${SRC_DIR}:${DOCKER_WORK_DIR}" \
        -w "${DOCKER_WORK_DIR}" \
        "${LOCAL_REGISTRY_IMAGE}" \
        "${@}"
}

shell_in_docker()
{
    docker run \
        --privileged \
        --cap-add=ALL \
        --security-opt seccomp:unconfined \
        --rm \
        -it \
        -u "$(id -u)" \
        -e "BUILD_DIR=${DOCKER_WORK_DIR}/${BUILD_DIR}" \
        -e "ARCH=${ARCH}" \
        -e "PREFIX=${PREFIX}" \
        -e "RELEASE_VERSION=${RELEASE_VERSION}" \
        -e "MAKEFLAGS=-j$(($(getconf _NPROCESSORS_ONLN) - 1))" \
        -e "CCACHE_DIR=${DOCKER_WORK_DIR}/tools/sysroot/ccache" \
        -v "${SRC_DIR}:${DOCKER_WORK_DIR}" \
        -w "${DOCKER_WORK_DIR}" \
        "${LOCAL_REGISTRY_IMAGE}" \
        "/bin/bash"
}

update_modules()
{
    git submodule update --init --recursive --depth 1
    cd "${SRC_DIR}/qtbase"
    for patch in "${SRC_DIR}/patches/qtbase/"*.patch; do
        if git apply --check "${patch}" > /dev/null 2>&1; then
            git apply "${patch}"
        fi
    done
    cd "${SRC_DIR}/qtdeclarative"
    for patch in "${SRC_DIR}/patches/qtdeclarative/"*.patch; do
        if git apply --check "${patch}" > /dev/null 2>&1; then
            git apply "${patch}"
        fi
    done
    cd "${SRC_DIR}"
}

run_shellcheck()
{
    docker run \
        --rm \
        -v "$(pwd):${DOCKER_WORK_DIR}" \
        -w "${DOCKER_WORK_DIR}" \
        "registry.hub.docker.com/koalaman/shellcheck-alpine:stable" \
        "docker_env/run_shellcheck.sh"
}

env_check()
{
    run_in_docker "./docker_env/buildenv_check.sh"
}

run_build()
{
    run_in_docker "./build.sh" "${@}"
}

run_linters()
{
    run_shellcheck
}

deliver_pkg()
{
    cp "${SRC_DIR}/${BUILD_DIR}/"*"deb" "${SRC_DIR}"
}

run_tests()
{
    echo "There are no tests available for this repository."
}

usage()
{
    echo "Usage: ${0} [OPTIONS]"
    echo "  -c   Clean the workspace"
    echo "  -C   Skip run of build environment checks"
    echo "  -l   Skip running the shellcheck linter"
    echo "  -h   Print usage"
    echo
    echo "Other options will be passed on to build.sh"
    echo "Run './build.sh -h' for more information."
}

while getopts ":cCslh" options; do
    case "${options}" in
    c)
        run_build "${@}"
        exit 0
        ;;
    C)
        run_env_check="no"
        ;;
    s)
        shell_in_docker
        exit 0
        ;;
    h)
        usage
        exit 0
        ;;
    l)
        run_linters="no"
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

if ! command -V docker; then
    echo "Docker not found, docker-less builds are not supported."
    exit 1
fi

update_docker_image

if [ "${run_env_check}" = "yes" ]; then
    env_check
fi

if [ "${run_linters}" = "yes" ]; then
    run_linters
fi

update_modules
run_build "${@}"
deliver_pkg

exit 0
