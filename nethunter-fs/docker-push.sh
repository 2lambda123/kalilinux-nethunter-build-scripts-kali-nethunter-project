#!/usr/bin/env sh

set -e   # Quit on error (last in chain/pipe)
set -x   # Be more verbose

## Move to folder
cd "$( dirname "${0}" )"

## Local build
docker build -t nethunter .

## Remote build (GitLab.com)
docker build -t "${CI_REGISTRY_IMAGE}" .
docker push "${CI_REGISTRY_IMAGE}"

## Done
echo "[i] Done ~ ${CI_SERVER_PROTOCOL}://${CI_SERVER_HOST}/${CI_PROJECT_PATH}/container_registry"
