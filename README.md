# Build scripts to containerize Chemotion ELN

## Requirements

- Docker and Docker Compose: obviously
- just: a simple command runner
- systemd-inhibit: to prevent the system from going to sleep while building/pushing
- (optional) sudo, yq: to alter docker's daemon.json in case you want to build in a ramdisk

## Usage

To build container images, simply adjust `.env` and run:

```bash
just build
```

Then, to test the release, run:

```bash
docker compose up
```

An ELN should now be available at `http://localhost:4000`.

To publish the containers, adjust the justfile to suit your repo (which defaults to "ptrxyz"); then use `just publish-internal` or `just publish` to tag and push the images to the respective repositories (REPO/internal and REPO/chemotion).
