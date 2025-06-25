#!/bin/bash
PGDATA="${PGDATA:-"/var/lib/postgresql/data"}"
if [ ! -s "$PGDATA/PG_VERSION" ] && [ "x${PGAUTO_ONESHOT}" = "xyes" ]; then
    # data directory considered empty, and we are in oneshot mode; so, nothing to do, exit immediately
    exit 0
fi
exec /usr/local/bin/docker-entrypoint.sh "$@"
