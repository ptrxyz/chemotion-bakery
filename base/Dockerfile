ARG VERSION
ARG BASE=ubuntu:24.04

FROM ${BASE} AS raw
ARG TINI_VERSION="v0.19.0"
ARG TZ=Europe/Berlin

# Set timezone and locale configuration
ENV TZ=${TZ} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "LANG=${LANG}" > /etc/locale.conf && \
    echo "LC_ALL=${LANG}" >> /etc/locale.conf && \
    echo "${LANG} UTF-8" > /etc/locale.gen

# Locale and essential tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        locales curl ca-certificates && \
    locale-gen en_US.UTF-8

# Minimal tools: tini, yq
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 /bin/yq
RUN chmod +x /tini /bin/yq

# ------------------------------------------------------------------------------

FROM scratch AS squash
COPY --from=raw / /

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENTRYPOINT ["/tini", "--"]

# ------------------------------------------------------------------------------

FROM squash AS base
ARG VERSION

LABEL \
    org.opencontainers.image.authors="Chemotion Team" \
    org.opencontainers.image.title="Chemotion Converter" \
    org.opencontainers.image.description="Image for Chemotion Converter" \
    org.opencontainers.image.version="${VERSION}" \
    chemotion.internal.service.id="base"
