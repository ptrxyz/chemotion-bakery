ARG VERSION
ARG SPECTRA_BUILD_TAG

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
        libglib2.0-0 `# for pyOpenMS`

COPY --chmod=755 ./additives/spectra_config.py /app/instance/config.py
COPY --chmod=755 ./additives/fake-docker.py    /bin/docker

# Fetch dependencies and source code
ADD https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh /tmp/conda.sh
ADD https://github.com/ComPlat/chem-spectra-app.git#${SPECTRA_BUILD_TAG} /app

WORKDIR /app

# Install Conda and environment
RUN bash /tmp/conda.sh -p /anaconda3 -b && \
    echo "PATH=/anaconda3/condabin:$PATH" >> ~/.profile && \
    /anaconda3/condabin/conda update -y -n base -c defaults conda && \
    /anaconda3/condabin/conda env create -f environment.yml

# Switch to conda shell
SHELL ["/anaconda3/condabin/conda", "run", "--no-capture-output", "-n", "python-v38", "/bin/bash", "-c"]

# Finalize app setup
RUN mkdir -p /shared /app/instance && \
    ln -s /shared /app/chem_spectra/tmp && \
    pip install --no-cache-dir -r requirements.txt

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

ENTRYPOINT ["/tini", "--", "/anaconda3/condabin/conda", "run", "--no-capture-output", "-n", "python-v38"]
CMD ["gunicorn", "--timeout", "600", "-w", "4", "-b", "0.0.0.0:4000", "server:app"]

HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 \
    CMD curl --fail http://localhost:4000/ping || exit 1

LABEL \
    "org.opencontainers.image.authors"="Chemotion Team" \
    "org.opencontainers.image.title"="Chemotion Spectra" \
    "org.opencontainers.image.version"="${VERSION}" \
    "org.opencontainers.image.description"="Image for Chemotion Spectra" \
    "chemotion.internal.service.id"="spectra"
