# Linux dev image for the rauthy backend: rauthy does not build on macOS
# (tls-hot-reload uses the Linux-only inotify watcher). mold links the debug
# binary in a few GiB, where GNU ld runs out of memory in a 6 GiB VM.
FROM rust:1.95.0-bookworm
RUN apt-get update \
    && apt-get install -y --no-install-recommends clang mold libpam0g-dev libudev-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN printf '#!/bin/sh\nexec cc -fuse-ld=mold "$@"\n' > /usr/local/bin/cc-mold \
    && chmod +x /usr/local/bin/cc-mold
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=/usr/local/bin/cc-mold \
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/usr/local/bin/cc-mold
