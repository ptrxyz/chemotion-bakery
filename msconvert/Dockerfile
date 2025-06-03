ARG VERSION

# Stage 0: Base with required binaries
FROM chemotion-build/base:${VERSION} AS chemotion-build-base

# Stage 1: Prepare ProteoWizard environment
FROM proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses AS prebuild

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-flask \
        python3-gevent \
        curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Stage 2: Copy required files and configure the container
FROM scratch AS msconvert

COPY --from=prebuild / /
COPY --from=chemotion-build-base /tini /tini
COPY ./mscrunner.py /app/mscrunner.py

RUN mkdir -p /shared && \
    rm -rf /data && \
    ln -s /shared /data

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    CONTAINER_GITHUB="https://github.com/ProteoWizard/container" \
    WINEDISTRO="devel" \
    WINEVERSION="7.8~focal-1" \
    WINEDEBUG="-all" \
    WINEPREFIX="/wineprefix64" \
    WINEPATH="C:\\pwiz;C:\\pwiz\\skyline"

# Stage 3: Final runtime container
FROM msconvert AS app
ARG VERSION

ENV FLASK_ENV="production" \
    FLASK_DEBUG=0 \
    MSC_PORT=4000

EXPOSE 4000
WORKDIR /app

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash", "-c", "wine msconvert &>/dev/null; exec python3 -u mscrunner.py"]

HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
    CMD curl --fail http://localhost:4000/ping || exit 1

LABEL \
    "org.opencontainers.image.authors"="Chemotion Team" \
    "org.opencontainers.image.title"="Chemotion MSConvert" \
    "org.opencontainers.image.description"="Image for the Chemotion Spectra-MSConvert sidecar container" \
    "org.opencontainers.image.version"="${VERSION}" \
    "chemotion.internal.service.id"="msconvert"
