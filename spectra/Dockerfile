ARG VERSION
ARG SPECTRA_BUILD_TAG

FROM scratch as cache
ADD https://github.com/ComPlat/chem-spectra-app.git#${SPECTRA_BUILD_TAG} /raw


# Stage 1: Build and install the ChemSpectra app
FROM chemotion-build/base:${VERSION} AS spectra
ARG SPECTRA_BUILD_TAG

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        curl \
        gcc \
        g++ \
        libxrender1 \
        libxext-dev \
        pkg-config \
        libfreetype6-dev `# for matplotlib` \
        libglib2.0-0 `# for pyOpenMS` \
        python3 python3-pip python3-venv

COPY --chmod=755 ./additives/spectra_config.py /app/instance/config.py
COPY --chmod=755 ./additives/fake-docker.py    /bin/docker

WORKDIR /app
ENV PIP_CACHE_DIR=/var/cache/pip \
    PIP_ROOT_USER_ACTION=ignore \
    PATH="/app/venv/bin:$PATH"

COPY --from=cache /raw/pyproject.toml /app/
RUN --mount=type=cache,target=/var/cache/pip,sharing=locked,id=pip-cache \
    python3 -m venv /app/venv && pip install .

COPY --from=cache /raw/chem_spectra /app/chem_spectra
COPY --from=cache /raw/server.py /app/server.py

# Finalize app setup
RUN mkdir -p /shared /app/instance && \
    ln -s /shared /app/chem_spectra/tmp

# Stage 2: Final container
FROM spectra AS app
ARG VERSION

ENV FLASK_ENV=production \
    FLASK_DEBUG=0 \
    MSC_HOST=msconvert \
    MSC_PORT=4000 \
    MSC_VALIDATE=true \
    SPECTRA_PORT=4000

EXPOSE 4000
WORKDIR /app

ENTRYPOINT ["/tini", "--"]
CMD ["gunicorn", "--timeout", "600", "-w", "4", "-b", "0.0.0.0:4000", "server:app"]

HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 \
    CMD curl --fail http://localhost:4000/ping || exit 1

LABEL \
    "org.opencontainers.image.authors"="Chemotion Team" \
    "org.opencontainers.image.title"="Chemotion Spectra" \
    "org.opencontainers.image.version"="${VERSION}" \
    "org.opencontainers.image.description"="Image for Chemotion Spectra" \
    "chemotion.internal.service.id"="spectra"
