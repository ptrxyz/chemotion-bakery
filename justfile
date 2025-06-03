set dotenv-load

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

build: _inhibit && _release
    time docker compose -f docker-compose.build.yml build

reset:
    docker compose -f docker-compose.yml down --remove-orphans
    docker volume rm -f chemotion_app chemotion_data chemotion_db chemotion_spectra

_tag arg:
    docker tag chemotion-build/base:${VERSION} ptrxyz/{{arg}}:base-${VERSION}
    docker tag chemotion-build/eln:${VERSION} ptrxyz/{{arg}}:eln-${VERSION}
    docker tag chemotion-build/db:${VERSION} ptrxyz/{{arg}}:db-${VERSION}
    docker tag chemotion-build/converter:${VERSION} ptrxyz/{{arg}}:converter-${VERSION}
    docker tag chemotion-build/spectra:${VERSION} ptrxyz/{{arg}}:spectra-${VERSION}
    docker tag chemotion-build/msconvert:${VERSION} ptrxyz/{{arg}}:msconvert-${VERSION}
    docker tag chemotion-build/ketchersvc:${VERSION} ptrxyz/{{arg}}:ketchersvc-${VERSION}

_push arg: _inhibit && _release
    docker push ptrxyz/{{arg}}:base-${VERSION}
    docker push ptrxyz/{{arg}}:eln-${VERSION}
    docker push ptrxyz/{{arg}}:db-${VERSION}
    docker push ptrxyz/{{arg}}:converter-${VERSION}
    docker push ptrxyz/{{arg}}:spectra-${VERSION}
    docker push ptrxyz/{{arg}}:msconvert-${VERSION}
    docker push ptrxyz/{{arg}}:ketchersvc-${VERSION}

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
