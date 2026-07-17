# Agent instructions

## Purpose and scope

This repo is a portable Home Assistant deployment: a `compose.yaml` running
Home Assistant as a rootless Podman container, plus the HA config directory
tracked in git. It is meant to become the first service in a small
multi-service home-lab stack (Ollama, Plex, etc. as siblings), but **do not
add other services, reverse proxies, or orchestration (Kubernetes/k3s)
unless explicitly asked** — the current scope is intentionally just Home
Assistant.

## Hard rules

- Never commit `homeassistant/config/secrets.yaml`, `.env`, or anything
  under `homeassistant/config/.storage/` — these hold credentials, tokens,
  and device pairings. Check `.gitignore` before adding new config-adjacent
  files and extend it if a new type of secret/runtime state shows up.
- Don't hardcode host-specific values (timezone, paths) into `compose.yaml`
  — route them through `.env` / `.env.example` so the repo stays portable
  across machines.
- Keep `network_mode: host` on the Home Assistant service — it's required
  for local device discovery (mDNS/SSDP, HomeKit, Bluetooth) and isn't a
  mistake to "fix" into a bridge network.
- Keep the `:Z` suffix on the config bind mount in `compose.yaml`. It's a
  no-op on non-SELinux hosts (Ubuntu, Arch/Manjaro) and required for the
  mount to work under SELinux-enforcing hosts (Fedora/RHEL) — don't remove
  it thinking it's Fedora-specific cruft.

## Adding a new service later

When Ollama, Plex, etc. are actually requested:
- Add a new service block to `compose.yaml` rather than a separate compose
  file, so `podman-compose up -d` continues to bring up the whole stack.
- Give each service its own config/data subdirectory at the repo root
  (mirroring `homeassistant/config/`), and extend `.gitignore` for any
  secrets/runtime state it introduces.
- Extend `install.sh` only if the new service needs additional host
  packages beyond Podman/podman-compose.

## Testing changes

There's no test suite — verification is running the stack:

```sh
podman-compose up -d
podman-compose logs -f homeassistant
curl -sSf http://localhost:8123
```
