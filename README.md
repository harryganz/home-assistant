# Home Assistant (Portable Podman Container)

A portable Home Assistant instance, run as a rootless Podman container via
`podman-compose`. Designed to be cloned onto any Linux machine and brought
up with minimal setup. This is the first service in what's intended to
become a small home-lab stack (Ollama, Plex, etc. may be added as sibling
services in `compose.yaml` later).

## Prerequisites

- A Linux host
- `git`
- `sudo` access (used by `install.sh` to install packages)

## Quick start

```sh
git clone <this-repo-url>
cd home-assistant
make install                  # installs Podman + podman-compose + make, creates .env
$EDITOR .env                  # set TZ and, if needed, HA_CONFIG_DIR
make run                      # podman-compose up -d
podman-compose logs -f homeassistant   # watch it come up
```

Then open `http://<this-host>:8123` and complete the Home Assistant
onboarding wizard.

Run `make help` to see all available tasks.

## Moving to another device

This repo *is* the portable unit. On the new device:

```sh
git clone <this-repo-url>
cd home-assistant
make install
$EDITOR .env
make run
```

Your automations, scripts, scenes, and `configuration.yaml` come along via
git. Device pairings, auth tokens, and history do not (see below) — those
are local to each running instance by design.

## What's tracked vs. gitignored

Home Assistant's config directory (`homeassistant/config/`) mixes
human-authored YAML with runtime state. Only the YAML is committed:

**Tracked:** `configuration.yaml`, `automations.yaml`, `scripts.yaml`,
`scenes.yaml`, and similar config files you edit directly.

**Gitignored** (local/secret, regenerated per instance):
`secrets.yaml`, `.storage/` (auth tokens, device pairings), the SQLite
history database, logs, `tts/`, `deps/`, `image/`, and `.env`.

If `configuration.yaml` references `!secret some_key`, create
`homeassistant/config/secrets.yaml` locally on each host — it's never
committed.

## Common operations

```sh
podman-compose logs -f homeassistant   # tail logs
podman-compose restart homeassistant   # restart
podman-compose pull && podman-compose up -d   # update to latest image
podman-compose down                    # stop and remove the container
```

## Networking

The container uses `network_mode: host` so Home Assistant can discover
devices on the local network (mDNS/SSDP, HomeKit, Bluetooth, etc.) the same
way it would running directly on the host.

## Boot persistence

Rootless Podman containers don't survive a reboot unless the user session
persists. Enable that with:

```sh
loginctl enable-linger $USER
```

Combined with `restart: unless-stopped` in `compose.yaml`, the container
will come back up after a reboot.
