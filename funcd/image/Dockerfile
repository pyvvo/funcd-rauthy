# The funcd-rauthy runtime image: upstream's Dockerfile with funcd's labels.
# funcd/image/build.sh puts the binaries in out/rauthy_<arch> of a small build
# context, next to config-local-test.toml.
FROM gcr.io/distroless/cc-debian12:nonroot

ARG TARGETARCH
ARG TARGET_USER="10001:10001"
ARG CREATED
ARG VERSION
ARG REVISION

LABEL org.opencontainers.image.authors="The funcd Authors"
LABEL org.opencontainers.image.base.name="gcr.io/distroless/cc-debian12:nonroot"
LABEL org.opencontainers.image.created="$CREATED"
LABEL org.opencontainers.image.description="rauthy with its user-facing pages and mails in funcd's look"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.revision="$REVISION"
LABEL org.opencontainers.image.source="https://github.com/pyvvo/funcd-rauthy"
LABEL org.opencontainers.image.title="funcd-rauthy"
LABEL org.opencontainers.image.version="$VERSION"

USER $TARGET_USER

# upstream's jemalloc tuning
ENV MALLOC_CONF="abort_conf:true,narenas:8,tcache_max:4096,dirty_decay_ms:5000,muzzy_decay_ms:5000"

WORKDIR /app

COPY --chown=$TARGET_USER ./out/rauthy_$TARGETARCH ./rauthy
COPY --chown=$TARGET_USER ./config-local-test.toml ./config-local-test.toml

# rauthy's licence, and the licences of what the fork adds (the binary embeds the Roboto fonts)
COPY --chown=$TARGET_USER ./LICENSE ./LICENSE
COPY --chown=$TARGET_USER ./licenses/ ./licenses/

# empty dirs copied upfront for the right owner
COPY --chown=$TARGET_USER ./out/empty/ ./data
COPY --chown=$TARGET_USER ./out/empty/ ./tls

ENTRYPOINT ["/app/rauthy"]
CMD ["serve"]
