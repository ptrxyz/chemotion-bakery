#!/bin/bash

set -euo pipefail

mapfile -t list < <(docker volume ls -q | grep chemotion_db)
choice=$(printf "%s\n" "${list[@]}" | fzf --no-multi)
echo "You chose: $choice"

if [ -z "$choice" ]; then
  echo "No volume selected. Exiting."
  exit 1
fi

to="$choice"
from="db-backup"

echo "Creating volume."

docker volume rm -f ${to} &>/dev/null || true
docker volume create ${to} &>/dev/null

echo "Cloning volume ${from} to ${to}..."
docker run --rm \
  -v ${from}:/from \
  -v ${to}:/to \
  alpine \
  sh -c "cd /from && cp -a . /to"

echo "Volume cloned successfully from ${from} to ${to}."
