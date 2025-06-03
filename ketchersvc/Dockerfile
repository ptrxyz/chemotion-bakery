ARG VERSION
ARG KETCHERSVC_BUILD_TAG

# ------------------------------------------------------------------------------

FROM oven/bun:latest AS ketcher-base
ARG KETCHERSVC_BUILD_TAG

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
        git \
        ca-certificates

WORKDIR /app

# Use ADD for GitHub tag archive (keeping your preference)
ADD https://github.com/ptrxyz/chemotion-ketchersvc.git#${KETCHERSVC_BUILD_TAG} .

# Set build-related environment variables only for the build process
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_BROWSERS_PATH=/app/.browser-cache

RUN bun install && \
    bun add @playwright/test chromium-bidi@3 && \
    bun run build

# ------------------------------------------------------------------------------

FROM oven/bun:latest AS app
ARG VERSION

ENV PLAYWRIGHT_BROWSERS_PATH=/app/.browser-cache
EXPOSE 4000

WORKDIR /app

COPY --from=ketcher-base /app/dist /app

RUN bun add playwright@1.49.0 && bunx playwright install --with-deps chromium && \
    chown -R 1000:1000 /app

USER bun

HEALTHCHECK --interval=5s --timeout=1s --start-period=30s --retries=3 \
    CMD /bin/pidof bun || exit 1

LABEL \
    org.opencontainers.image.authors="Chemotion Team" \
    org.opencontainers.image.title="Chemotion KetcherSVC" \
    org.opencontainers.image.description="Image for Chemotion KetcherSVC" \
    org.opencontainers.image.version="${VERSION}" \
    chemotion.internal.service.id="ketchersvc"

CMD ["bun", "index.js"]
