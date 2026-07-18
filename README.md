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
`scenes.yaml`, `custom_sentences/`, and similar config files you edit
directly.

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

## Voice Assist / Shopping List

`make run` also brings up `whisper` and `piper` containers (local
speech-to-text and text-to-speech via the
[Wyoming protocol](https://www.home-assistant.io/integrations/wyoming/)),
so you can add items to — and ask what's on — your Home Assistant shopping
list by voice from the companion app, with the answer spoken back.
`shopping_list`, `conversation`, and `assist_pipeline` are already enabled
via `default_config:`; Whisper and Piper fill in the missing speech-to-text
and text-to-speech pieces.

Confirm they're healthy with `podman-compose logs -f whisper piper` — on
first run each downloads the model set by `WHISPER_MODEL`/`PIPER_VOICE` in
`.env`.

**One-time setup in the HA UI** (this lives in `.storage/`, so it isn't
tracked in git and has to be repeated per instance):

1. Settings → Devices & Services → Add Integration → **Wyoming Protocol** →
   host `localhost`, port `10300`. Repeat for port `10200`. This creates a
   Whisper speech-to-text entity and a Piper text-to-speech entity.
2. Settings → Voice assistants → **Assist** → edit the "Home Assistant"
   pipeline → set **Speech-to-text** to the Whisper entity and
   **Text-to-speech** to the Piper entity → Save. Leave the conversation
   agent as the built-in "Home Assistant" agent — it already understands
   shopping-list phrasing (e.g. "add eggs to the shopping list") out of the
   box.

**Reading the list back:** the shopping-list integration has a built-in
handler that reads back the top items, but this HA version doesn't ship a
trigger phrase for it by default. `homeassistant/config/custom_sentences/en/shopping_list.yaml`
adds one, so phrases like "what's on my shopping list" or "read my
shopping list" work — no automation or template needed, it just points
existing phrases at the existing handler. Add more phrasings there if the
ones that ship don't match how you naturally ask.

**Using it from your phone:**

1. Open the Home Assistant companion app and make sure it's logged into
   this instance.
2. Tap the Assist icon (chat bubble) and grant microphone permission when
   prompted.
3. Tap the mic and say "Add milk to the shopping list," or "what's on my
   shopping list?" to hear it read back.
4. Optional: Android supports an Assist quick-settings tile/home-screen
   widget for one-tap voice access; iOS can trigger Assist via a Siri
   Shortcut.

## Boot persistence

Rootless Podman containers don't survive a reboot unless the user session
persists. Enable that with:

```sh
loginctl enable-linger $USER
```

Combined with `restart: unless-stopped` in `compose.yaml`, the container
will come back up after a reboot.
