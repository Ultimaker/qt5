#!/bin/bash
#
# SPDX-License-Identifier: AGPL-3.0+
#
# Copyright (C) 2019 Ultimaker B.V.
#

set -eu

SRC_DIR="$(pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-999.999.999}"
DOCKER_WORK_DIR="/build"

run_linters="yes"
run_env_check="yes"
action="none"
rebuild_docker="no"

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
        -v "${SRC_DIR}:${DOCKER_WORK_DIR}" \
        -w "${DOCKER_WORK_DIR}" \
        "registry.hub.docker.com/koalaman/shellcheck-alpine:stable" \
        "./run_shellcheck.sh"
}

env_check()
{
    run_in_docker "./docker_env/buildenv_check.sh"
}

run_build()
{
    update_modules
    
    run_in_docker "./build.sh" "${@}"
}

run_linters()
{
    run_shellcheck
}

usage()
{
    echo "Usage: ${0} [OPTIONS]"
    echo "  -a   Run a specific action. It can be: docker_build,"
    echo "       shellcheck, lint, cppcheck, clang-tidy,"
    echo "       clang-format_check, build, unittest"    
    echo "  -c   Skip run of build environment checks"
    echo "  -d   Build a docker image from Dockerfile tagged as latest"
    echo "       and use it for the remaining build steps. It is meant"
    echo "       for testing a new Dockerfile release"    
    echo "  -l   Skip running the shellcheck linter"
    echo "  -h   Print usage"
    echo "  -t   Skip tests"    
    echo
    echo "Other options will be passed on to build.sh"
    echo "Run './build.sh -h' for more information."
}

while getopts ":cdlha:" options; do
    case "${options}" in
    a)
        action="${OPTARG}"
        ;;        
    c)
        run_env_check="no"
        ;;
    d)
        rebuild_docker="yes"
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

source ./docker_env/make_docker.sh qt5-ultimaker

if [[ "${rebuild_docker}" == "yes" || "${action}" == "docker_build" ]]; then
    DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-qt5-ultimaker}"
    DOCKER_IMAGE_VERSION="${DOCKER_IMAGE_VERSION:-latest}"
    build_docker
fi;

case "${action}" in
    shell)
        run_in_docker bash
        exit 0
        ;;
    shellcheck)
        run_shellcheck
        exit 0
        ;;
    build)
        run_build
        exit 0
        ;;
    docker_build)
        exit 0
        ;;
    none)
        ;;
    ?)
        echo "Invalid action: -${OPTARG}"
        exit 1
        ;;
esac

if [ "${run_env_check}" = "yes" ]; then
    env_check
fi

if [ "${run_linters}" = "yes" ]; then
    run_linters
fi

run_build "${@}"

exit 0
