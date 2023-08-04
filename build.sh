#!/bin/bash

set -eo pipefail

build_docker() {
  tag=$1
  shift
  branch=$(git rev-parse --abbrev-ref HEAD)
  build_path="/tmp/qdon-build-${branch}/"
  # rm -rf "$build_path"
  rsync -au --info=progress2 --delete --filter=':- .gitignore' ./ "$build_path"
  cd "$build_path" || exit 1
  git reset --
  # git checkout .
  git clean -fdx
  docker buildx build --pull -t "$tag" . "$@" --load
}

branch=$(git rev-parse --abbrev-ref HEAD)

case $branch in
  qdon-glitch)
    build_docker qdon/glitch:latest
    ;;
  qdon-glitch-beta)
    build_docker qdon/glitch:beta
    ;;
  *)
    build_docker qdon/glitch:HEAD
    ;;
esac
