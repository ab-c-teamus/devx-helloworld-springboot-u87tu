#!/usr/bin/env bash

set -e

./scripts/setup-kubectl-for-gcloud.sh

service_name="${PWD##*/}" #TODO: Quick hack, need to fix.

helm upgrade --install --atomic "${service_name}-dev" src/main/helm -n default -f src/main/helm/values-"${ENV}.yaml" --set config.image.tag="${TAG}"
