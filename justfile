set dotenv-load
REPO := env("DOCKER_REPO_BASE", "ptrxyz")
VERSION := env("VERSION")

@default:
    just --list

# Requires sudo, yq
setup:
    sudo systemctl stop docker
    sudo mkdir -p /ram
    sudo mount -t tmpfs -o size=48G tmpfs /ram
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    sudo yq -i '.["data-root"] = "/ram"' /etc/docker/daemon.json
    sudo systemctl start docker

teardown:
    sudo systemctl stop docker
    sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
    sudo umount /ram
    sudo rmdir /ram

_inhibit:
    export __BUILD=1 && systemd-inhibit --what="shutdown:sleep:idle" --why="Pushing images to registry" sleep infinity & disown

_release:
    kill $(pgrep --env __BUILD=1)

build *args: _inhibit && _release
    time docker compose -f docker-compose.build.yml build {{args}}

reset:
    docker compose -f docker-compose.yml down --remove-orphans
    docker volume rm -f chemotion_app chemotion_data chemotion_db chemotion_spectra

_tag arg:
    docker tag chemotion-build/base:{{VERSION}} {{REPO}}/{{arg}}:base-{{VERSION}}
    docker tag chemotion-build/eln:{{VERSION}} {{REPO}}/{{arg}}:eln-{{VERSION}}
    docker tag chemotion-build/db:{{VERSION}} {{REPO}}/{{arg}}:db-{{VERSION}}
    docker tag chemotion-build/dbupgrade:{{VERSION}} {{REPO}}/{{arg}}:dbupgrade-{{VERSION}}
    docker tag chemotion-build/converter:{{VERSION}} {{REPO}}/{{arg}}:converter-{{VERSION}}
    docker tag chemotion-build/spectra:{{VERSION}} {{REPO}}/{{arg}}:spectra-{{VERSION}}
    docker tag chemotion-build/msconvert:{{VERSION}} {{REPO}}/{{arg}}:msconvert-{{VERSION}}
    docker tag chemotion-build/ketchersvc:{{VERSION}} {{REPO}}/{{arg}}:ketchersvc-{{VERSION}}

_push arg: _inhibit && _release
    docker push {{REPO}}/{{arg}}:base-{{VERSION}}
    docker push {{REPO}}/{{arg}}:eln-{{VERSION}}
    docker push {{REPO}}/{{arg}}:db-{{VERSION}}
    docker push {{REPO}}/{{arg}}:dbupgrade-{{VERSION}}
    docker push {{REPO}}/{{arg}}:converter-{{VERSION}}
    docker push {{REPO}}/{{arg}}:spectra-{{VERSION}}
    docker push {{REPO}}/{{arg}}:msconvert-{{VERSION}}
    docker push {{REPO}}/{{arg}}:ketchersvc-{{VERSION}}

_publish arg:
    just _tag {{arg}}
    just _push {{arg}}

tag-internal: (_tag "internal")
push-internal: (_push "internal")
publish-internal: (_publish "internal")

tag-chemotion: (_tag "chemotion")
push-chemotion: (_push "chemotion")
publish-chemotion: (_publish "chemotion")

publish: publish-chemotion


test-fresh:
    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml down --remove-orphans -v
    docker volume rm -f pg13
    docker volume create pg13

    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml up dbupgrade db &
    sleep 10
    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml down
    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml up dbupgrade db &
    sleep 10
    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml down --remove-orphans -v

test-pg13-upgrade:
    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml down --remove-orphans -v
    docker volume rm -f pg13
    docker volume create pg13

    docker run --rm \
        -e POSTGRES_PASSWORD=postgres \
        -v pg13:/var/lib/postgresql/data \
        -u postgres \
        postgres:13 \
        bash -c "initdb -D /var/lib/postgresql/data && pg_ctl -D /var/lib/postgresql/data -w start && createdb -U postgres chemotion && pg_ctl -D /var/lib/postgresql/data -m fast stop"

    docker compose -f docker-compose.yml -f docker-compose.internal.yml -f docker-compose.testing.yml up dbupgrade
