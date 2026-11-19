#!/usr/bin/env bash
# Builds the funcd-rauthy image the way upstream's `just build` does: the UI and
# both release binaries in a builder container, then the distroless runtime image.
#
#   funcd/image/build.sh           load the build host's platform into docker
#   funcd/image/build.sh --push    push linux/amd64 and linux/arm64 to the registry
#
# DOCKER picks the docker command (e.g. "docker --context colima-funcd-build"),
# IMAGE the repository (default ghcr.io/pyvvo/funcd-rauthy), TAG the tag. The
# default tag is <rauthy version>-funcd.<commit>, so the tree must be committed;
# the release workflow passes the release version.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

docker=${DOCKER:-docker}
image=${IMAGE:-ghcr.io/pyvvo/funcd-rauthy}
push=false
[ "${1:-}" = "--push" ] && push=true

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "uncommitted changes: the tag names the commit, commit them first" >&2
    exit 1
fi
version=$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1)
revision=$(git rev-parse HEAD)
tag=${TAG:-$version-funcd.${revision:0:8}}

ctx=$(mktemp -d)
trap 'rm -rf "$ctx"' EXIT

echo "== builder image"
cp assets/node_setup_builder/node_setup_22.sh "$ctx/"
$docker build -q -t funcd-rauthy-builder -f funcd/image/builder.Dockerfile "$ctx"
rm "$ctx/node_setup_22.sh"

# The target dir, the cargo registry and node_modules live in volumes: the Linux
# node_modules must not replace the host's, and a bind-mounted target is slow.
in_builder() {
    $docker run --rm \
        -v "$PWD:/work" \
        -v funcd-rauthy-cargo:/usr/local/cargo/registry \
        -v funcd-rauthy-target:/target \
        -v funcd-rauthy-node-modules:/work/frontend/node_modules \
        -e CARGO_TARGET_DIR=/target \
        -w /work \
        "$@"
}

# The UI build rewrites templates/html even when nothing changed, and the release binaries
# embed those templates, so every rebuild relinks both (full LTO, minutes each). A stamp of
# the committed sources the UI is built from skips it when they are unchanged.
echo "== UI"
ui_sources=$(git ls-files -s frontend src/wasm-modules | git hash-object --stdin)
ui_stamp=templates/html/.funcd-ui-sources
if [ -f "$ui_stamp" ] && [ "$(cat "$ui_stamp")" = "$ui_sources" ]; then
    echo "reusing the UI built from these sources"
else
    # The builder runs as root, and on a Linux host templates/html comes back owned by root,
    # so the container removes and writes the stamp itself.
    in_builder -e "UI_SOURCES=$ui_sources" -e "UI_STAMP=$ui_stamp" funcd-rauthy-builder bash -c \
        'rm -f "$UI_STAMP" && just build-wasm && (cd frontend && npm ci --no-audit --no-fund) && just build-ui && echo "$UI_SOURCES" > "$UI_STAMP"'
fi

# a release build refuses to compile without the FIDO metadata dataset (src/data/build.rs),
# which is not checked in: upstream fetches it from mds.fidoalliance.org the same way. The
# service rate-limits repeated fetches (429), so a fetched dataset is reused unless
# FIDO_MDS_REFRESH=1.
echo "== FIDO metadata dataset"
if [ -s assets/fido_mds/dataset.bin ] && [ "${FIDO_MDS_REFRESH:-}" != 1 ]; then
    echo "reusing assets/fido_mds/dataset.bin from $(date -r assets/fido_mds/dataset.bin +%Y-%m-%d)"
else
    in_builder funcd-rauthy-builder just fido-mds-prep
fi

echo "== release binary, amd64"
in_builder funcd-rauthy-builder cargo build --release --target x86_64-unknown-linux-gnu

echo "== release binary, arm64"
in_builder -e JEMALLOC_SYS_WITH_LG_PAGE=16 funcd-rauthy-builder \
    cargo build --release --target aarch64-unknown-linux-gnu

echo "== runtime image $image:$tag"
mkdir -p "$ctx/out/empty"
in_builder funcd-rauthy-builder bash -c \
    'mkdir -p out && cp /target/x86_64-unknown-linux-gnu/release/rauthy out/rauthy_amd64 && cp /target/aarch64-unknown-linux-gnu/release/rauthy out/rauthy_arm64'
cp out/rauthy_amd64 out/rauthy_arm64 "$ctx/out/"
cp config-local-test.toml LICENSE "$ctx/"
cp -R funcd/licenses "$ctx/licenses"

args=(
    -f funcd/image/Dockerfile
    --build-arg "CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    --build-arg "VERSION=$tag"
    --build-arg "REVISION=$revision"
    -t "$image:$tag"
)
if $push; then
    # a multi-platform push needs a docker-container builder; it is named, not made the default
    $docker buildx inspect funcd-rauthy > /dev/null 2>&1 ||
        $docker buildx create --name funcd-rauthy --driver docker-container > /dev/null
    # ghcr.io links a multi-platform image to its repository from the index, not from the
    # per-platform labels; that link is what lets this repository's workflows push it
    $docker buildx build --builder funcd-rauthy --platform linux/amd64,linux/arm64 --push \
        --annotation "index:org.opencontainers.image.source=https://github.com/pyvvo/funcd-rauthy" \
        --annotation "index:org.opencontainers.image.description=rauthy with its user-facing pages and mails in funcd's look" \
        --annotation "index:org.opencontainers.image.licenses=Apache-2.0" \
        "${args[@]}" "$ctx"
else
    case "$(uname -m)" in
        x86_64 | amd64) platform=linux/amd64 ;;
        *) platform=linux/arm64 ;;
    esac
    $docker buildx build --platform "$platform" --load "${args[@]}" "$ctx"
fi
echo "== done: $image:$tag"
