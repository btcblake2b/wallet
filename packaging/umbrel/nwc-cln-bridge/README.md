# NWC/NCC Bridge — Umbrel package

Umbrel package for the **NWC/NCC ↔ Core Lightning bridge** of the
[btc-blake2b](https://btcblake2b.org) project.

## Files

```
nwc-cln-bridge/
  umbrel-app.yml        manifest (id, port 3477, no app dependencies)
  docker-compose.yml    app_proxy + bridge container
  data/.gitkeep         host-side bind-mount source for ${APP_DATA_DIR}/data
  README.md             this file
```

## How it works on Umbrel

- The container exposes its **status/setup page** (`BRIDGE_UI_PORT=3000`) behind
  `app_proxy`: umbrelOS handles authentication (login + 2FA), so the bridge runs
  with `BRIDGE_UI_TOKEN=none`.
- The node is configured **from the page** (clnrest URL + rune) and applied at
  runtime — nothing to edit in the compose file. This works with a node on the
  same Umbrel (if `clnrest` is reachable) or a remote node over LAN/VPN.
- State lives in `${APP_DATA_DIR}/data` (config, Nostr key, generated URI).

## Tests run (2026-09-17)

umbrelOS-like environment simulated in Docker (same env as this compose, data
bind-mounted under a host directory):

- fresh start with **no node configured** → the page opens (200) without a token
  (`BRIDGE_UI_TOKEN=none`, umbrelOS auth is provided by `app_proxy`); the node is
  then configured **from the page** (`POST /api/config`) and applied at runtime;
- **container restart** → `config.json`, `rune.txt` (600) and `uri.txt` survive in
  the bind-mounted data dir and the node stays configured;
- Docker `HEALTHCHECK` → `healthy` once the node answers;
- `bin/probe.dart` (the real client, through the production Nostr relay) →
  **PROBE_OK** with 14 methods.

Official linter (`npm run lint:apps -- nwc-cln-bridge` on a clone of
`getumbrel/umbrel-apps`): **0 warnings** and 3 errors, all publish-time artefacts
rather than package defects — `manifest.submission` empty (needs the PR URL, ×2)
and `image.pinned` (needs `@sha256:<digest>` once the image is on ghcr). Port
`3477`, `app_proxy` wiring, persistence paths and manifest shape pass.

## Before submitting to the App Store

1. Publish the multi-arch image to `ghcr.io/btcblake2b/nwc-cln-bridge:0.1.0`
   (Dockerfile: `packaging/docker/Dockerfile.bridge` in the main repo, built with
   `docker buildx build --platform linux/amd64,linux/arm64`).
2. Pin the image with the **manifest-list digest** and verify both architectures:
   `docker buildx imagetools inspect ghcr.io/btcblake2b/nwc-cln-bridge:0.1.0`.
3. Clone `getumbrel/umbrel-apps` and run:
   `npm run lint:apps -- nwc-cln-bridge --check-images`.
4. Test the install through umbrelOS (the package is not ready until it installs,
   opens in the browser, saves the node config, restarts and keeps the data).
5. Open the PR: the Umbrel team adds gallery images and the icon (do not commit
   them here), and `submission:` gets the PR URL.

## Notes

- No app dependencies: the bridge does not require the Core Lightning app, which
  on Umbrel is the upstream node (Bitcoin mainnet). The btc-blake2b wallet needs
  a node on the blake2b chain, so the node is normally remote/self-hosted.
- The `port: 3477` value is the host-facing app_proxy port and must be unique in
  the App Store: confirm with the official linter.
