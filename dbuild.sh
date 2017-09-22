#!/usr/bin/env bash

set -e

function print_usage {
    cat <<EOF
usage: dbuild [-h] {build,test,push,all} ...

Docker build pipeline tool.

positional arguments:
  {build,test,push,all}
    build               build the Docker Image
    test                test service functionality
    all                 do all of the above in that order

optional arguments:
  -h, --help            show this help message and exit
EOF
}

function check_deps {
    # Dependencies which should be in PATH.
    DEPS=( 'docker' )

    for i in "${DEPS[@]}"; do
        if ! hash "${i}" 2>/dev/null; then
            echo -e "${RED}[DBUILD] "${i}" is required. Please install it then try again.${NONE}"
            exit 1
        fi
    done
}

function run_build {
    # Build Docker Image.
    echo -e "${MAGENTA}[DBUILD] Building the ${NAMESPACE}/${IMAGE}:${TAG} Docker Image...${NONE}"
    docker build -t "${NAMESPACE}/${IMAGE}:${TAG}" .
    echo -e "${GREEN}[DBUILD] OK.${NONE}"
}

function run_test {
    echo -e "${MAGENTA}[DBUILD] Running tests...${NONE}"

    docker run \
        --rm \
        --privileged \
        -ti \
        -v "${SOCKET}:/var/run/docker.sock" \
        -v "${VOLUMES}:/var/lib/docker/volumes" \
        -v "${DATA}:/opt/Amsterdam/data" \
        "${NAMESPACE}/${IMAGE}:${TAG}"

    echo -e "${GREEN}[DBUILD] OK.${NONE}"
}

# Environment variable overrides.
export NAMESPACE=${DBUILD_NAMESPACE:='monokal'}
export IMAGE=${DBUILD_IMAGE:='amsterdam'}
export TAG=${DBUILD_VERSION:='latest'}
export SOCKET=${DBUILD_SOCKET:='/var/run/docker.sock'}
export VOLUMES=${DBUILD_VOLUMES:='/var/lib/docker/volumes'}
export DATA=${DBUILD_DATA:='data'}

MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NONE=$(tput sgr 0)

check_deps

case $1 in
    build)
        run_build
        ;;
    test)
        run_test
        ;;
    all)
        run_build
        run_test
        run_push
        ;;
    *)
        print_usage
        exit 1
esac

echo -e "${GREEN}[DBUILD] Finished.${NONE}"
