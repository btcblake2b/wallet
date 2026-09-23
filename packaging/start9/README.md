# NWC/NCC Bridge — StartOS package

StartOS wrapper for the **NWC/NCC ↔ Core Lightning bridge** of the
[btc-blake2b](https://btcblake2b.org) project: it exposes a Core Lightning node
over Nostr Wallet Connect (NIP-47) and NCC, so the wallet app can send/receive
on Lightning and manage channels **without** touching the node's console.

```
Wallet app ── NWC/NCC (Nostr) ──▶ Bridge ── clnrest ──▶ Core Lightning node
```

## What the package does

- runs the bridge container (image built from
  `packaging/docker/Dockerfile.bridge` in the main repository);
- exposes a **web page** (StartOS `UI` interface) with the connection string
  (NWC/NCC URI + QR) and the node settings;
- if the **Core Lightning** service is installed, the package connects to its
  `clnrest` interface automatically and reads the rune from its volume;
- otherwise the node is configured **from the page** (`clnrest` URL + rune),
  for example a remote node reached over LAN or Tailscale.

## Build

```sh
npm install
npm run check      # tsc --noEmit
make               # produces the .s9pk
```

## Tests run (2026-09-17)

- `npm run check` (`tsc --noEmit`) → **0 errors**; `prettier` clean; the `ncc`
bundle builds (2.6 MB).
- StartOS-like environment simulated in Docker: a **stub clnrest** reachable only
on an internal Docker network, plus the node volume mounted **read-only** at
`/mnt/cln` — the same shape as `mountDependency` + `getBridgeAddress`:
  - the bridge starts with the rune read from `.commando-env`, connects to the
    relay and prints the UI token in its log;
  - the page requires the token (401 without it) and shows the connection string
    and the QR code;
  - `config.json` and `uri.txt` persist in the package volume;
  - `bin/probe.dart` (the real client, through the production relay) →
    **PROBE_OK** with 14 methods;
  - if the rune is missing at startup (StartOS `Revoke Runes` deletes and re-mints
    `.commando-env`) the bridge no longer exits: it logs a warning, keeps serving
    the page and returns an explicit error to the app until the rune is back.
- **Not runnable here**: `make` → `.s9pk` (needs Linux + `start-cli`) and the
install test on a real StartOS server.

## Notes and requirements

- **Do not expose the UI interface** on untrusted networks: the page shows a
  connection string containing a device secret. When the bridge starts it logs
  the UI token to include in the URL (`http://<host>:<port>/?token=<token>`).
- Outbound: the bridge talks to a **Nostr relay over wss (port 443)** and to
  `clnrest`; no inbound port is needed.
- On StartOS with the upstream Core Lightning package, keep `btc-rpc-proxy`
  **>= 0.8.1** (older versions had a witness-commitment bug that stalled the
  index).
- Compatibility matrix (app ↔ bridge ↔ node) is maintained in the project's
  public documentation.
