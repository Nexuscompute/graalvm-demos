#!/bin/bash

set -e
set -u
set -o pipefail

SOURCE_DOCKER_HUB="ghcr.io/graalvm/graalvm-ce"
BASE_GRAALVM_VERSION="21.2.0"
GRAALVM_JDK_VERSION="java11"
# See https://github.com/graalvm/container/pkgs/container/graalvm-ce for all tags related info
DEFAULT_GRAALVM_VERSION="${GRAALVM_JDK_VERSION}-${BASE_GRAALVM_VERSION}"
DOCKER_IMAGE_TAGS_WEBSITE="https://github.com/graalvm/container/pkgs/container/graalvm-ce"

FULL_GRAALVM_VERSION="${1:-"${DEFAULT_GRAALVM_VERSION}"}"
FULL_DOCKER_TAG_NAME="graalvm/demos"
GRAALVM_HOME_FOLDER="/graalvm"

MAVEN_VERSION="3.8.3"
GRADLE_VERSION="7.2"
SCALA_VERSION="3.0.2"
SBT_VERSION="1.5.5"
WORKDIR="/graalvm-demos"
DEMO_TYPE="console"


# Building wrk takes a while
echo; echo "--- Building docker image for 'wrk' utility: workload generator" >&2; echo
time docker build                          \
	             -t workload-generator/wrk \
	             -f Dockerfile-wrk "."


# Building micronaut-starter docker image is relatively quicker
echo; echo "--- Building Docker image for micronaut-starter:${FULL_GRAALVM_VERSION}" >&2; echo
time docker build                                                         \
	             --build-arg GRAALVM_HOME="${GRAALVM_HOME_FOLDER}"        \
                 --build-arg SOURCE_DOCKER_HUB="${SOURCE_DOCKER_HUB}"     \
                 --build-arg FULL_GRAALVM_VERSION="${FULL_GRAALVM_VERSION}" \
	             -t micronaut/micronaut-starter:${FULL_GRAALVM_VERSION}   \
	             -f Dockerfile-mn "."


# Building graalvm-demos (console) docker image is relatively quicker
echo; echo "--- Building Docker image (console) for GraalVM version ${FULL_GRAALVM_VERSION} for ${WORKDIR}" >&2; echo
time docker build                                                         \
	             --build-arg GRAALVM_HOME="${GRAALVM_HOME_FOLDER}"        \
                 --build-arg SOURCE_DOCKER_HUB="${SOURCE_DOCKER_HUB}"     \
                 --build-arg FULL_GRAALVM_VERSION="${FULL_GRAALVM_VERSION}" \
                 --build-arg MAVEN_VERSION=${MAVEN_VERSION}               \
                 --build-arg GRADLE_VERSION=${GRADLE_VERSION}             \
                 --build-arg SCALA_VERSION=${SCALA_VERSION}               \
                 --build-arg SBT_VERSION=${SBT_VERSION}                   \
                 --build-arg WORKDIR=${WORKDIR}                           \
	             -t ${FULL_DOCKER_TAG_NAME}:${FULL_GRAALVM_VERSION}       \
	             "."


# Building graalvm-demos (gui) docker image is relatively quicker
echo; echo "--- Building Docker image (gui) for GraalVM version ${FULL_GRAALVM_VERSION} for ${WORKDIR}" >&2; echo
time docker build                                                         \
                 --build-arg SOURCE_DOCKER_HUB="${SOURCE_DOCKER_HUB}"     \
                 --build-arg FULL_GRAALVM_VERSION="${FULL_GRAALVM_VERSION}" \
                 -t ${FULL_DOCKER_TAG_NAME}-gui:${FULL_GRAALVM_VERSION}   \
                 -f Dockerfile-gui "."


IMAGE_IDS="$(docker images -f dangling=true -q || true)"
if [[ -n ${IMAGE_IDS} ]]; then
    echo; echo "--- Cleaning up image(s)" >&2; echo
    docker rmi -f ${IMAGE_IDS} || true
fi