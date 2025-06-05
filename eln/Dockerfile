# GLOBALs that should be passed to this file
ARG VERSION
ARG CHEMOTION_BUILD_TAG
ARG KETCHER2_VERSION

# Derived values
ARG CHEMOTION_RELEASE=${VERSION}

# Private variables, not passed in from outside, but helpful for this file
ARG RUBY_VERSION=2.7.8
ARG NODE_VERSION=22.15.1
ARG BUNDLER_VERSION=2.4.22
ARG ASDF_VERSION=v0.17.0
ARG PANDOC_VERSION=3.7.0.1
ARG BUILD_REPO_CHEMOTION=https://github.com/ComPlat/chemotion_ELN


# ------------------------------------------------------------------------------
FROM chemotion-build/base:${VERSION} AS base

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c", "--"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --autoremove --fix-missing \
        git ca-certificates curl unzip


# ------------------------------------------------------------------------------
# Add ASDF, Ruby, Node, bundler and yarn
# ------------------------------------------------------------------------------
FROM base AS asdf-enabled

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --autoremove --fix-missing \
        build-essential \
        zlib1g-dev libreadline-dev patchelf

ARG ASDF_VERSION
ARG RUBY_VERSION
ARG NODE_VERSION
ARG BUNDLER_VERSION

ENV ASDF_DIR=/asdf \
    ASDF_DATA_DIR=/asdf \
    GEM_HOME=/cache/gems \
    ASDF_NODEJS_VERSION=${NODE_VERSION} \
    ASDF_RUBY_VERSION=${RUBY_VERSION}
ENV PATH="${ASDF_DIR}/shims:${GEM_HOME}/bin:${GEM_HOME}/gems/bin:${ASDF_DIR}:${PATH}"

# ASDF
RUN --mount=type=cache,target=/cache,sharing=locked \
    curl -sSL -o /cache/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-amd64.tar.gz" && \
    tar -xzf /cache/asdf.tar.gz --one-top-level=/asdf && \
    chmod +x /asdf/asdf

# NodeJS
RUN --mount=type=cache,target=/asdf/cache,sharing=locked \
    MAKEFLAGS="-j$(nproc)" && export MAKEFLAGS && \
    asdf plugin add nodejs && \
    asdf install nodejs "${NODE_VERSION}" && \
    npm install -g yarn

# Ruby
RUN --mount=type=cache,target=/asdf/cache,sharing=locked \
    MAKEFLAGS="-j$(nproc)" && export MAKEFLAGS && \
    asdf plugin add ruby && \
    asdf install ruby "${RUBY_VERSION}" && \
    rm -r /asdf/installs/ruby/2.7.8/lib/ruby/gems/2.7.0/gems/bundler-* && \
    rm /asdf/installs/ruby/**/lib/ruby/gems/**/specifications/default/bundler-*.gemspec && \
    gem install bundler -v "${BUNDLER_VERSION}"

# Ruby 2.7.8 comes with it's own openssl version, we have to copy it to the system
RUN SSL_PATH="$(asdf where ruby)" && \
    ln -s "${SSL_PATH}/openssl/lib/libcrypto.so.1.1" /lib/x86_64-linux-gnu/


# ------------------------------------------------------------------------------
FROM base AS raw-eln

ARG CHEMOTION_BUILD_TAG
ARG BUILD_REPO_CHEMOTION
ARG CHEMOTION_RELEASE
ARG VERSION
ARG KETCHER2_VERSION

WORKDIR /chemotion/app

ADD ${BUILD_REPO_CHEMOTION}.git#${CHEMOTION_BUILD_TAG} /chemotion/app

# Create release file
RUN echo "CHEMOTION_REF=$(git rev-parse --short HEAD || echo unknown)" >> /chemotion/app/.version && \
    echo "CHEMOTION_TAG=$(git describe --abbrev=0 --tags || echo untagged)" >> /chemotion/app/.version && \
    echo "RELEASE=${CHEMOTION_RELEASE}" >> /chemotion/app/.version && \
    echo "VERSION=${VERSION}" >> /chemotion/app/.version && \
    cat /chemotion/app/.version

# Clean up configs
RUN find ./config -type f -name '*.yml.example' -print | while read -r f; do \
    echo "$f to ${f%.example}"; \
    yq --input-format yaml -ojson < "$f" | \
    yq -oyaml -P 'del(.test, .development)' > "${f%.example}"; \
    done

# Remove unnecessary files
RUN rm -rf ./**/*github* ./**/*gitlab* ./**/*travis* ./**/*.bak .vscode/ .devcontainer ./**/*git* || true

# Add application additives
COPY ./additives/chemotion/ /chemotion/app

# Create persistent volume directories:
# - move [app]/uploads to /chemotion/data
# - move [app]/public/images to /data
RUN mkdir -p /chemotion/data && \
    mv /chemotion/app/uploads /chemotion/data/ || mkdir -p /chemotion/data/uploads && \
    ln -s /chemotion/data/uploads/ /chemotion/app/uploads && \
    mkdir -p /chemotion/data/public/ && \
    mv /chemotion/app/public/images/ /chemotion/data/public/ || mkdir -p /chemotion/data/public/images && \
    ln -s /chemotion/data/public/images/ /chemotion/app/public/images && \
    mkdir -p /chemotion/data/public/ && \
    mv /chemotion/app/public/safety_sheets/ /chemotion/data/public || mkdir -p /chemotion/data/public/safety_sheets && \
    ln -s /chemotion/data/public/safety_sheets/ /chemotion/app/public/safety_sheets && \
    cp /chemotion/app/.version /chemotion/data/.version && \
    mkdir -p /chemotion/data/public/images/thumbnail

# Add Ketcher
ADD https://github.com/epam/ketcher/releases/download/v${KETCHER2_VERSION}/ketcher-standalone-${KETCHER2_VERSION}.zip /tmp/ketcher.zip
RUN mkdir -p /chemotion/app/public/editors/ketcher2 && \
    unzip -o /tmp/ketcher.zip -d /chemotion/app/public/editors/ketcher2 && \
    rm /tmp/ketcher.zip


# ------------------------------------------------------------------------------
FROM asdf-enabled AS yarn-installed

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c", "--"]

ENV NODE_ENV=production \
    NODE_PATH=/cache/node_modules/ \
    NODE_MODULES_PATH=/cache/node_modules/ \
    NODE_OPTIONS=--max_old_space_size=4096 \
    YARN_CACHE_FOLDER=/cache/yarn

WORKDIR /chemotion/app

COPY --from=raw-eln /chemotion/app/package.json /chemotion/app/
COPY --from=raw-eln /chemotion/app/yarn.lock    /chemotion/app/

RUN echo -e "--modules-folder ${NODE_PATH}\n--ignore-engines" > /chemotion/app/.yarnrc && \
    MAKEFLAGS="-j$(nproc)" && export MAKEFLAGS && \
    yarn install --modules-folder ${NODE_PATH} --ignore-engines --ignore-scripts 2>&1 | grep -v ^warning


# ------------------------------------------------------------------------------
FROM asdf-enabled AS bundle-installed

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c", "--"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --autoremove --fix-missing \
        build-essential cmake libpq-dev swig libmagickcore-dev

ENV BUNDLE_PATH=/cache/bundle \
    BUNDLE_CACHE_PATH=/cache/bundle/package-cache \
    BUNDLE_USER_HOME=/cache/bundle \
    BUNDLE_APP_CONFIG=/cache/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_CACHE_ALL=1 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    GEM_HOME=/cache/gems \
    RAILS_ENV=production \
    RAKE_ENV=production \
    THOR_SILENCE_DEPRECATION=1

WORKDIR /chemotion/app

COPY --from=raw-eln /chemotion/app/Gemfile      /chemotion/app/
COPY --from=raw-eln /chemotion/app/Gemfile.lock /chemotion/app/

RUN MAKEFLAGS="-j$(nproc)" && export MAKEFLAGS && \
    bundle install --jobs="$(nproc)" --retry=3 && \
    bundle clean --force


# ------------------------------------------------------------------------------
FROM base AS eln-ruby-node

ARG PANDOC_VERSION
ARG RUBY_VERSION
ARG NODE_VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt-lib \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --autoremove --fix-missing \
        postgresql-client inkscape imagemagick librsvg2-bin locales ghostscript \
        vim iproute2 sudo make git

COPY --from=asdf-enabled /asdf/ /asdf/
COPY --from=asdf-enabled /lib/x86_64-linux-gnu/libcrypto.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=raw-eln /chemotion /chemotion
COPY --from=bundle-installed /cache/bundle /cache/bundle
COPY --from=bundle-installed /cache/gems /cache/gems
COPY --from=yarn-installed /cache/node_modules/ /cache/node_modules/

COPY ./additives/various/fontfix.conf /etc/fonts/conf.d/99-chemotion-fontfix.conf
COPY ./additives/various/policy.xml   /etc/ImageMagick-6/policy.xml
COPY ./additives/embed/               /embed/

RUN curl -L -o /tmp/pandoc.deb "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    dpkg -i /tmp/pandoc.deb && rm /tmp/pandoc.deb && \
    ln -s /embed/bin/chemotion /bin/chemotion && \
    cp /chemotion/app/.version /.version && \
    chmod +x /embed/bin/*

ENV ASDF_DIR=/asdf \
    ASDF_DATA_DIR=/asdf \
    ASDF_NODEJS_VERSION=${NODE_VERSION} \
    ASDF_RUBY_VERSION=${RUBY_VERSION} \
    BUNDLE_PATH=/cache/bundle \
    BUNDLE_CACHE_PATH=/cache/bundle/package-cache \
    BUNDLE_USER_HOME=/cache/bundle \
    BUNDLE_APP_CONFIG=/cache/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_CACHE_ALL=1 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    GEM_HOME=/cache/gems \
    RAILS_ENV=production \
    RAKE_ENV=production \
    NODE_ENV=production \
    NODE_PATH=/cache/node_modules/ \
    NODE_MODULES_PATH=/cache/node_modules/ \
    NODE_OPTIONS=--max_old_space_size=4096 \
    YARN_CACHE_FOLDER=/cache/yarn \
    TERM=xterm-256color \
    THOR_SILENCE_DEPRECATION=1 \
    RAILS_LOG_TO_STDOUT=1 \
    PASSENGER_DOWNLOAD_NATIVE_SUPPORT_BINARY=0 \
    CONFIG_PIDFILE=/chemotion/app/tmp/eln.pid
ENV PATH="${ASDF_DIR}/shims:${GEM_HOME}/bin:${GEM_HOME}/gems/bin:${ASDF_DIR}:${PATH}"

WORKDIR /chemotion/app

RUN ln -s ${NODE_PATH} /chemotion/app/node_modules && \
    bash package_postinstall.sh

RUN MAKEFLAGS="-j$(nproc)" && export MAKEFLAGS && \
    bundle install --jobs="$(nproc)" --retry=3

RUN export SECRET_KEY_BASE="build" && \
    KETCHER_PATH=$(bundle info --path ketcherails) && \
    UIFILE_PATH="${KETCHER_PATH}/app/assets/javascripts/ketcherails/ui/ui.js.erb" && \
    rm /chemotion/app/config/scifinder_n.yml && \
    cp "${UIFILE_PATH}" /tmp/ui.js.bak && \
    sed -i 's/Ketcherails::TemplateCategory.with_approved_templates.pluck(:id)/[]/g' "${UIFILE_PATH}" && \
    bundle exec rake DISABLE_DATABASE_ENVIRONMENT_CHECK=1 DATABASE_URL=nulldb://user:pass@127.0.0.1/dbname shakapacker:compile 2>&1 | grep -v ^warning && \
    bundle exec rake DISABLE_DATABASE_ENVIRONMENT_CHECK=1 DATABASE_URL=nulldb://user:pass@127.0.0.1/dbname assets:precompile 2>&1 | grep -v ^warning && \
    mv /tmp/ui.js.bak "${UIFILE_PATH}" && \
    rm -rf /tmp/* /var/tmp/* && \
    git init . && \
    git config user.name "Chemotion ELN Builder" && \
    git config user.email "chemotion@kit.edu" && \
    git add . && git commit -m "Init commit" --allow-empty && \
    git tag -a "v${VERSION}" -m "Chemotion ELN version ${VERSION}"

RUN env && touch /chemotion/app/.env && bundle exec dotenv erb /chemotion/app/config/secrets.yml


# ------------------------------------------------------------------------------
# Final stage
# ------------------------------------------------------------------------------
FROM eln-ruby-node AS app

ARG VERSION

EXPOSE 4000

WORKDIR /chemotion/app

CMD ["/embed/run.sh"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD /embed/health.sh || exit 1

VOLUME [ "/chemotion/app", "/chemotion/data" ]

LABEL \
    "org.opencontainers.image.authors"="Chemotion Team" \
    "org.opencontainers.image.title"="Chemotion ELN" \
    "org.opencontainers.image.description"="Image for Chemotion ELN" \
    "org.opencontainers.image.version"="${VERSION}" \
    "chemotion.internal.service.id"="eln"
