#!/usr/bin/env bash
# Tags the multi-platform image: one index made from the per-platform images that
# funcd/image/build.sh pushed by digest.
#
#   funcd/image/index.sh <image>:<tag> <image>@<digest>...
#
# DOCKER picks the docker command, as for build.sh.
set -euo pipefail
docker=${DOCKER:-docker}
if [ $# -lt 2 ]; then
    echo "usage: $0 <image>:<tag> <image>@<digest>..." >&2
    exit 1
fi
target=$1
shift

# ghcr.io links a multi-platform image to its repository from the index, not from the
# per-platform labels; that link is what lets this repository's workflows push it
$docker buildx imagetools create -t "$target" \
    --annotation "index:org.opencontainers.image.source=https://github.com/pyvvo/funcd-rauthy" \
    --annotation "index:org.opencontainers.image.description=rauthy with its user-facing pages and mails in funcd's look" \
    --annotation "index:org.opencontainers.image.licenses=Apache-2.0" \
    "$@"
$docker buildx imagetools inspect "$target"
echo "== done: $target"
