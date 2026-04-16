ARG VERSION
ARG KETCHERSVC_BUILD_TAG

# ------------------------------------------------------------------------------

FROM oven/bun:latest AS ketcher-base
ARG KETCHERSVC_BUILD_TAG
ARG VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
        git \
        ca-certificates fonts-liberation \
        libnss3 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdrm2 \
        libxkbcommon0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libasound2 \
        libpangocairo-1.0-0 \
        libpango-1.0-0 \
        libcairo2 \
        libatspi2.0-0 \
        libgtk-3-0 \
        libxshmfence1 \
        fonts-unifont

# Use ADD for GitHub tag archive (keeping your preference)
ADD --chown=1000:1000 https://github.com/ptrxyz/chemotion-ketchersvc.git#${KETCHERSVC_BUILD_TAG} /app

USER bun
WORKDIR /app

# Set build-related environment variables only for the build process
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_BROWSERS_PATH=/app/.browser-cache

RUN bun install && \
    bunx playwright install chromium

# ------------------------------------------------------------------------------


EXPOSE 4000

HEALTHCHECK --interval=5s --timeout=1s --start-period=30s --retries=3 \
    CMD /bin/pidof bun || exit 1

LABEL \
    org.opencontainers.image.authors="Chemotion Team" \
    org.opencontainers.image.title="Chemotion KetcherSVC" \
    org.opencontainers.image.description="Image for Chemotion KetcherSVC" \
    org.opencontainers.image.version="${VERSION}" \
    chemotion.internal.service.id="ketchersvc"

CMD ["bun", "src/index.ts"]
