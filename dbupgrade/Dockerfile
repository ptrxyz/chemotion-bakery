FROM pgautoupgrade/pgautoupgrade:16-bookworm
COPY --chown=root:root --chmod=755 noop-if-empty.sh /usr/local/bin/docker-entrypoint-noop.sh

ENV PGAUTO_ONESHOT=yes \
    POSTGRES_PASSWORD=postgres \
    PGAUTO_REINDEX=yes

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint-noop.sh" ]
