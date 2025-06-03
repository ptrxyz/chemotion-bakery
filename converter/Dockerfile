ARG VERSION
ARG CONVERTER_BUILD_TAG

# ------------------------------------------------------------------------------

FROM chemotion-build/base:${VERSION} AS converter-base

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
        python3-pip \
        python3-venv \
        libmagic1 \
        curl \
        git \
        build-essential

# ------------------------------------------------------------------------------

FROM converter-base AS converter
ARG CONVERTER_BUILD_TAG

WORKDIR /srv/chemotion

# Keep using ADD with remote GitHub URL as per your requirements
ADD https://github.com/ComPlat/chemotion-converter-app.git#${CONVERTER_BUILD_TAG} .

RUN python3 -m venv env && \
    env/bin/pip install --no-cache-dir --upgrade pip setuptools wheel pybind11 && \
    env/bin/pip install --no-cache-dir \
        --config-settings="cmake.args=-DFETCH_ZLIB_NG=ON" \
        -r requirements/common.txt && \
    if [ -f .env.prod ]; then mv .env.prod .env; fi && \
    mkdir -p /var/log/chemotion-converter && \
    chmod a+wrx /var/log/chemotion-converter

COPY --chmod=755 pass /bin/genpass
RUN /bin/genpass chemotion chemotion > htpasswd

ENV PATH=/srv/chemotion/env/bin:$PATH \
    VIRTUAL_ENV=/srv/chemotion/env \
    MAX_CONTENT_LENGTH=250M \
    GUNICORN_TIMEOUT=180 \
    PROFILES_DIR=/srv/chemotion/profiles \
    DATASETS_DIR=/srv/chemotion/datasets \
    HTPASSWD_PATH=/srv/chemotion/htpasswd

# ------------------------------------------------------------------------------

FROM converter AS app
ARG VERSION

LABEL \
    org.opencontainers.image.authors="Chemotion Team" \
    org.opencontainers.image.title="Chemotion Converter" \
    org.opencontainers.image.description="Image for Chemotion Converter" \
    org.opencontainers.image.version="${VERSION}" \
    chemotion.internal.service.id="converter"

WORKDIR /srv/chemotion
EXPOSE 4000

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:4000/ || exit 1

CMD ["gunicorn", "--bind=0.0.0.0:4000", "--preload", "converter_app.app:create_app()"]
