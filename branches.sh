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

[ -x "$(type -P skopeo 2>/dev/null)" ] \
    || { echo "Missing script dependency: skopeo" >&2; exit 1; }

[ -x "$(type -P jq 2>/dev/null)" ] \
    || { echo "Missing script dependency: jq" >&2; exit 1; }

source "$CI_TOOLS_PATH/helper/common.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

EXIT_CODE=0

echo + "BRANCHES_LOCAL=\"\$(printf '%s\n' \"\${MILESTONES[@]}\" | sort_semver)\"" >&2
BRANCHES_LOCAL="$(printf '%s\n' "${MILESTONES[@]}" | sort_semver)"

echo + "BRANCHES_GLOBAL_JSON=\"\$(skopeo inspect $(quote "docker://${BASE_IMAGE%:*}:latest"))\"" >&2
BRANCHES_GLOBAL_JSON="$(skopeo inspect "docker://${BASE_IMAGE%:*}:latest" || true)"

if ! jq -e '.RepoTags[0]? and .Labels?["org.opencontainers.image.version"]?' &> /dev/null <<< "$BRANCHES_GLOBAL_JSON"; then
    echo "Unable to inspect image in container repository 'docker://${BASE_IMAGE%:*}:latest'" >&2
    exit 2
fi

echo + "BRANCHES_GLOBAL=\"\$(jq -re '.RepoTags[]|select(test(\"^[0-9]+\\.[0-9]+$\"))' <<< \"\$BRANCHES_GLOBAL_JSON\" | sort_semver)\"" >&2
BRANCHES_GLOBAL="$(jq -re '.RepoTags[]|select(test("^[0-9]+\\.[0-9]+$"))' <<< "$BRANCHES_GLOBAL_JSON" | sort_semver)"

echo + "LATEST_BRANCH=\"\$(jq -re '.Labels[\"org.opencontainers.image.version\"]' <<< \"\$BRANCHES_GLOBAL_JSON\")\"" >&2
LATEST_BRANCH="$(jq -re '.Labels["org.opencontainers.image.version"]' <<< "$BRANCHES_GLOBAL_JSON")"

if ! grep -q -Fx "$LATEST_BRANCH" <<< "$BRANCHES_LOCAL"; then
    echo "Explicit build instructions for the latest Ubuntu branch is missing" >&2
    echo "- $LATEST_BRANCH" >&2
    EXIT_CODE=1
fi

echo + "echo \"\$BRANCHES_LOCAL\"" >&2
[ -z "$BRANCHES_LOCAL" ] || echo "$BRANCHES_LOCAL"

exit $EXIT_CODE
