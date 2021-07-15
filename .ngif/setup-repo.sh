#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

tags=$(git tag)

if [[ $tags == "" ]]; then
    # Add the first version tag.
    first_version_tag='v0.0.1'
    git tag "${first_version_tag}"
    echo "Added first tag: ${first_version_tag}"
fi
