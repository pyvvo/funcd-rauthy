# Builder for the funcd-rauthy image: upstream's Dockerfile_builder, plus the C
# cross-compiler for whichever of amd64 and arm64 the build host is not, so one
# host builds both binaries (upstream only cross-builds arm64 from amd64).
# The build context is a folder holding node_setup_22.sh (funcd/image/build.sh).
FROM rust:1.95.0-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
    PKG_CONFIG_ALLOW_CROSS=1

COPY node_setup_22.sh /tmp/node_setup_22.sh

RUN set -eux; \
    bash /tmp/node_setup_22.sh; \
    rm /tmp/node_setup_22.sh; \
    case "$(dpkg --print-architecture)" in \
        amd64) cross="gcc-aarch64-linux-gnu g++-aarch64-linux-gnu" ;; \
        arm64) cross="gcc-x86-64-linux-gnu g++-x86-64-linux-gnu" ;; \
        *) echo "unsupported build host" >&2; exit 1 ;; \
    esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential clang $cross \
        libpam0g-dev libudev-dev nodejs; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; \
    cargo install --locked just wasm-pack

WORKDIR /work
