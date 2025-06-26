#!/bin/bash
PGDATA="${PGDATA:-"/var/lib/postgresql/data"}"
if [ "$(id -u)" -eq 0 ] && [ ! -s "$PGDATA/PG_VERSION" ] && [ "x${PGAUTO_ONESHOT}" = "xyes" ]; then
    # data directory considered empty, and we are in oneshot mode; so, nothing to do, exit immediately
    echo "[PGAUTOUPDATE] Data directory is empty and running in oneshot mode, exiting without doing anything."
    exit 0
else
    # data directory is not empty or we are not in oneshot mode, continue with the script
    echo "[PGAUTOUPDATE] Data directory is not empty or not running in oneshot mode, proceeding with the script."
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
