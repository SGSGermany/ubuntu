#!/bin/bash
# Ubuntu
# @SGSGermany's base image for containers based on Ubuntu.
#
# Copyright (c) 2023  SGS Serious Gaming & Simulations GmbH
#
# This work is licensed under the terms of the MIT license.
# For a copy, see LICENSE file or <https://opensource.org/licenses/MIT>.
#
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

set -eu -o pipefail
export LC_ALL=C.UTF-8

[ -v CI_TOOLS ] && [ "$CI_TOOLS" == "SGSGermany" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS' not set or invalid" >&2; exit 1; }

[ -v CI_TOOLS_PATH ] && [ -d "$CI_TOOLS_PATH" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS_PATH' not set or invalid" >&2; exit 1; }

[ -x "$(type -P podman 2>/dev/null)" ] \
    || { echo "Missing script dependency: podman" >&2; exit 1; }

[ -x "$(type -P skopeo 2>/dev/null)" ] \
    || { echo "Missing script dependency: skopeo" >&2; exit 1; }

source "$CI_TOOLS_PATH/helper/common.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

BUILD_INFO=""
if [ $# -gt 0 ] && [[ "$1" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    BUILD_INFO=".${1,,}"
fi

# pull base image
echo + "IMAGE_ID=\"\$(podman pull $(quote "$BASE_IMAGE"))\"" >&2
IMAGE_ID="$(podman pull "$BASE_IMAGE" || true)"

if [ -z "$IMAGE_ID" ]; then
    echo "Failed to pull image '$BASE_IMAGE': No image with this tag found" >&2
    exit 1
fi

# read Ubuntu's version and codename from /etc/os-release
echo + "VERSION=\"\$(podman run -i --rm $IMAGE_ID sh -c '. /etc/os-release ; echo \"\$VERSION_ID\"')\"" >&2
VERSION="$(podman run -i --rm "$IMAGE_ID" sh -c '. /etc/os-release ; echo "$VERSION_ID"')"

if [ -z "$VERSION" ]; then
    echo "Unable to read Ubuntu's OS release file '/etc/os-release': Failed to read 'VERSION_ID' variable" >&2
    exit 1
elif ! [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    echo "Unable to read Ubuntu's OS release file '/etc/os-release': '$VERSION' is no valid version string" >&2
    exit 1
fi

echo + "CODENAME=\"\$(podman run -i --rm $IMAGE_ID sh -c '. /etc/os-release ; echo \"\$VERSION_CODENAME\"')\"" >&2
CODENAME="$(podman run -i --rm "$IMAGE_ID" sh -c '. /etc/os-release ; echo "$VERSION_CODENAME"')"

if [ -z "$CODENAME" ]; then
    echo "Unable to read Ubuntu's OS release file '/etc/os-release': Failed to read 'VERSION_CODENAME' variable" >&2
    exit 1
fi

# read version of latest Ubuntu image
LATEST=""
if [ "${BASE_IMAGE##*:}" != "latest" ]; then
    echo + "LATEST=\"\$(skopeo inspect --format '{{ index .Labels \"org.opencontainers.image.version\" }}' $(quote "docker://${BASE_IMAGE%:*}:latest"))\"" >&2
    LATEST="$(skopeo inspect --format '{{ index .Labels "org.opencontainers.image.version" }}' "docker://${BASE_IMAGE%:*}:latest")"

    if [ -z "$LATEST" ]; then
        echo "Unable to read 'org.opencontainers.image.version' label of container image 'docker://${BASE_IMAGE%:*}:latest'" >&2
        exit 1
    fi
fi

# build tags
BUILD_INFO="$(date --utc +'%Y%m%d')$BUILD_INFO"

TAGS=(
    "v$VERSION" "v$VERSION-$BUILD_INFO"
    "$CODENAME" "$CODENAME-$BUILD_INFO"
)

if [ -z "$LATEST" ] || [ "$VERSION" == "$LATEST" ]; then
    TAGS+=( "latest" )
fi

printf 'MILESTONE="%s"\n' "$VERSION"
printf 'VERSION="%s"\n' "$VERSION"
printf 'TAGS="%s"\n' "${TAGS[*]}"
