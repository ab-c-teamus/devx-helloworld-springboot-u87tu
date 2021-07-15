#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo "Installing svu..."
brew install caarlos0/tap/svu
echo "Install complete."
echo

tags=$(git tag)

if [[ $tags == "" ]]; then
    next_version='v0.0.1'
else
    next_version="$(svu n)"
fi

default_branch=$([ -f .git/refs/heads/master ] && echo master || echo main)
current_branch=$(git branch --show-current)

if ! [[ "${default_branch}" == "${current_branch}" ]]; then
    next_version="${next_version}-SNAPSHOT"
fi

./mvnw spring-boot:build-image -Drevision="${next_version}"

# Using current dir name as service_name for short term...
# Long term, a repo may host multiple services...
service_name="${PWD##*/}"
artifact_tag="${service_name}:${next_version}"

docker tag "${artifact_tag}" "${service_name}:latest"
