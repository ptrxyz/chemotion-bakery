ARG VERSION
ARG KETCHERSVC_BUILD_TAG

# ------------------------------------------------------------------------------
# Build stage
FROM oven/bun:latest AS build
ARG KETCHERSVC_BUILD_TAG
ARG VERSION

WORKDIR /app

ADD --chown=1000:1000 https://github.com/ptrxyz/chemotion-ketchersvc.git#${KETCHERSVC_BUILD_TAG} /app

RUN export ELECTRON_SKIP_BINARY_DOWNLOAD=1; \
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1; \
    bun install --frozen-lockfile

RUN bun run build


# ------------------------------------------------------------------------------
# Finalize the image
FROM oven/bun:latest

WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/package.json /app/bun.lockb /app/
RUN export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1; \
    bun install --frozen-lockfile --production

RUN bunx playwright install --with-deps chromium
COPY --from=build /app/dist /app

CMD ["bun", "index.js"]

EXPOSE 4000

HEALTHCHECK --interval=5s --timeout=1s --start-period=30s --retries=3 \
    CMD /bin/pidof bun || exit 1

LABEL \
    org.opencontainers.image.authors="Chemotion Team" \
    org.opencontainers.image.title="Chemotion KetcherSVC" \
    org.opencontainers.image.description="Image for Chemotion KetcherSVC" \
    org.opencontainers.image.version="${VERSION}" \
    chemotion.internal.service.id="ketchersvc"
