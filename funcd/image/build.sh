#!/usr/bin/env bash
# Builds the funcd-rauthy image the way upstream's `just build` does: the UI and the
# release binaries in a builder container, then the distroless runtime image.
#
#   funcd/image/build.sh           load the build host's platform into docker
#   funcd/image/build.sh --push    push linux/amd64 and linux/arm64 under the tag
#
# ARCH builds one platform only (amd64 or arm64). --push pushes each platform's image by
# digest, then funcd/image/index.sh tags one index of both; with a single ARCH the tag is
# left to the caller, and DIGEST_DIR/<arch> receives the digest (the release workflow
# builds each platform on its own runner). DOCKER picks the docker command (e.g.
# "docker --context colima-funcd-build"), IMAGE the repository (default
# ghcr.io/pyvvo/funcd-rauthy), TAG the tag. The default tag is
# <rauthy version>-funcd.<commit>, so the tree must be committed; the release workflow
# passes the release version.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

docker=${DOCKER:-docker}
image=${IMAGE:-ghcr.io/pyvvo/funcd-rauthy}
push=false
[ "${1:-}" = "--push" ] && push=true
arches=${ARCH:-amd64 arm64}
triple() {
    case "$1" in
        amd64) echo x86_64-unknown-linux-gnu ;;
        arm64) echo aarch64-unknown-linux-gnu ;;
        *) echo "ARCH must be amd64 or arm64, not '$1'" >&2; return 1 ;;
    esac
}
for arch in $arches; do triple "$arch" > /dev/null; done
case "$(uname -m)" in
    x86_64 | amd64) host=amd64 ;;
    *) host=arm64 ;;
esac
if ! $push && [[ " $arches " != *" $host "* ]]; then
    echo "loading into docker needs the build host's platform ($host) in ARCH" >&2
    exit 1
fi

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

copy="mkdir -p out"
for arch in $arches; do
    echo "== release binary, $arch"
    if [ "$arch" = arm64 ]; then
        # as upstream's justfile: 64 KiB jemalloc pages, so it runs on arm64 hosts with large pages
        in_builder -e JEMALLOC_SYS_WITH_LG_PAGE=16 funcd-rauthy-builder \
            cargo build --release --target "$(triple "$arch")"
    else
        in_builder funcd-rauthy-builder cargo build --release --target "$(triple "$arch")"
    fi
    copy+=" && cp /target/$(triple "$arch")/release/rauthy out/rauthy_$arch"
done

echo "== runtime image $image:$tag"
mkdir -p "$ctx/out/empty"
in_builder funcd-rauthy-builder bash -c "$copy"
for arch in $arches; do cp "out/rauthy_$arch" "$ctx/out/"; done
cp config-local-test.toml LICENSE "$ctx/"
cp -R funcd/licenses "$ctx/licenses"

args=(
    -f funcd/image/Dockerfile
    --build-arg "CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    --build-arg "VERSION=$tag"
    --build-arg "REVISION=$revision"
)
if $push; then
    # pushing by digest needs a docker-container builder; it is named, not made the default
    $docker buildx inspect funcd-rauthy > /dev/null 2>&1 ||
        $docker buildx create --name funcd-rauthy --driver docker-container > /dev/null
    refs=()
    for arch in $arches; do
        $docker buildx build --builder funcd-rauthy --platform "linux/$arch" \
            --output "type=image,name=$image,push-by-digest=true,name-canonical=true,push=true" \
            --metadata-file "$ctx/metadata-$arch.json" "${args[@]}" "$ctx"
        digest=$(python3 -I -c 'import json, sys; print(json.load(open(sys.argv[1]))["containerimage.digest"])' \
            "$ctx/metadata-$arch.json")
        echo "== pushed linux/$arch: $image@$digest"
        refs+=("$image@$digest")
        if [ -n "${DIGEST_DIR:-}" ]; then
            mkdir -p "$DIGEST_DIR"
            echo "$digest" > "$DIGEST_DIR/$arch"
        fi
    done
    if [ "${#refs[@]}" -eq 2 ]; then
        DOCKER="$docker" funcd/image/index.sh "$image:$tag" "${refs[@]}"
    else
        echo "== done: one platform pushed by digest; funcd/image/index.sh tags the index"
    fi
else
    $docker buildx build --platform "linux/$host" --load -t "$image:$tag" "${args[@]}" "$ctx"
    echo "== done: $image:$tag"
fi
