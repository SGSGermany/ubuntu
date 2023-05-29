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

source "$CI_TOOLS_PATH/helper/common.sh.inc"
source "$CI_TOOLS_PATH/helper/chkupd.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

TAG="${TAGS%% *}"

# check whether the base image was updated
chkupd_baseimage "$REGISTRY/$OWNER/$IMAGE" "$TAG" \
    || exit 0

# pull current image
echo + "CONTAINER=\"\$(buildah from $(quote "$REGISTRY/$OWNER/$IMAGE:$TAG"))\"" >&2
CONTAINER="$(buildah from "$REGISTRY/$OWNER/$IMAGE:$TAG" || true)"

if [ -z "$CONTAINER" ]; then
    echo "Failed to pull image '$REGISTRY/$OWNER/$IMAGE:$TAG': No image with this tag found" >&2
    echo "Image rebuild required" >&2
    echo "build"
    exit
fi

# run `apt-get update` and `apt list --upgradable` to check for package updates
cmd buildah run "$CONTAINER" -- \
    apt-get update >&2

echo + "PACKAGE_UPGRADES=\"\$(buildah run $(quote "$CONTAINER") -- apt list --upgradable)\"" >&2
PACKAGE_UPGRADES="$(buildah run "$CONTAINER" -- apt list --upgradable 2> /dev/null | sed -e '0,/^Listing.../d')"

if [ -n "$PACKAGE_UPGRADES" ]; then
    echo "Image is out of date: Package upgrades are available" >&2
    echo "$PACKAGE_UPGRADES" >&2
    echo "Image rebuild required" >&2
    echo "build"
    exit
fi
