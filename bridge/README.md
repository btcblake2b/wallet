# NWC/NCC ↔ CLN Bridge

Dart service that exposes a **Core Lightning** node (blake2b fork) over
**Nostr Wallet Connect (NIP-47)** and **NCC** — so the project's Flutter app
(NWC/NCC client already implemented) can manage the node's payments and
channels without modifying the node itself.

```
App (Flutter) ── NWC/NCC over Nostr ──▶ Bridge ── CLNRest ──▶ CLN node
      ▲                                    │
      └───────── encrypted response ───────┘
```

## Requirements

- CLN node with **clnrest** enabled + a dedicated **rune**
  (on the current server: `clnrest-port=3001`, loopback)
- Dart SDK 3.3+
- A reachable Nostr relay (e.g. `wss://relay.damus.io`)

## Setup

```bash
cd bridge
dart pub get

# 1) bridge Nostr key
dart run bin/bridge.dart --genkey           # → privkeyHex for config.json

# 2) config
cp config.example.json config.json          # then fill in the fields

# 3) dedicated rune on the node (once)
lightning-cli createrune                    # → save in ~/.lightning/bridge-rune
                                            #   format: LIGHTNING_RUNE="<rune>"

# 4) URI for the app (registers the client allowlist)
dart run bin/bridge.dart --genuri           # → paste the URI into the app

# 5) start
dart run bin/bridge.dart
```

### Persistent start on the server (example)

```bash
cd ~/bridge && nohup dart run bin/bridge.dart > bridge.log 2>&1 &
```

### Deploying an update (script)

WHY: complex commands over SSH suffer PowerShell→bash quoting —
use a script copied with `scp` (same lesson as the RTL setup).

```powershell
# from the PC (repo): upload the modified sources + the script, then run the deploy
scp bridge\lib\src\protocol.dart bridge\lib\src\handlers.dart "<user>@<server>:~/bridge/lib/src/"
scp scripts\deploy-bridge.sh "<user>@<server>:~/bridge/deploy-bridge.sh"
ssh <user>@<server> "sed -i 's/\r$//' ~/bridge/deploy-bridge.sh; bash ~/bridge/deploy-bridge.sh"
```

The script: backups the binary with a timestamp → **stops the process** (on Linux
you cannot overwrite a running executable) → `dart compile exe` →
`run.sh start` → probes `bin/probe.dart` (if compilation fails it immediately
restarts the previous binary). If `dart` is not in the non-interactive PATH it
searches common locations (`~/dart-sdk`, `~/dart`) or pass it explicitly:
`DART=/path/dart bash deploy-bridge.sh`.

## Supported methods

Capabilities: **15 NWC / 12 NCC** methods.

| Method | Type | CLN command | Notes |
|---|---|---|---|
| `get_info` | NWC | `getinfo` + `listpeers` | `network: "blake2b"`; additive `num_peers_connected` (CONNECTED peers, not registered; I4a) |
| `get_balance` | NWC | `listfunds` + `listpeerchannels` | active-channel balance + on-chain |
| `make_invoice` | NWC | `invoice` | amount in **msat** |
| `pay_invoice` | NWC | `pay` | returns preimage + fee |
| `make_new_address` | NWC | `newaddr` | on-chain address (P2WPKH `bech32`) |
| `pay_onchain` | NWC | `withdraw` | `amount_sat` (or `all`), optional `feerate` |
| `estimate_onchain_fees` | NWC | `feerates` | `{min, economical, priority}` in sat/vB |
| `list_addresses` | NWC | `listaddresses` | falls back to `listfunds` if the command is missing |
| `list_utxos` | NWC | `listfunds` | UTXOs of the node |
| `list_invoices` | NWC | `listinvoices` | paginated invoice history |
| `lookup_invoice` | NWC | `listinvoices` | single invoice by `payment_hash` |
| `list_pays` | NWC | `listpays` | outgoing payments |
| `get_pending_htlcs` | NWC | `listhtlcs` | in-flight HTLCs |
| `list_transactions` | NWC | derived | unified history (on-chain + invoices + pays) |
| `keysend` | NWC | `keysend` | **SPENDS funds**; `maxfee` overrides `maxfeepercent`; never retried on timeout |
| `list_channels` | NCC | `listpeerchannels` | mapped to the app model (**msat**) |
| `open_channel` | NCC | `connect` + `fundchannel` | optional `host` |
| `close_channel` | NCC | `close` | `force` → unilateral close |
| `connect_peer` | NCC | `connect` | accepts `pubkey@host:port` |
| `disconnect_peer` | NCC | `disconnect` | |
| `list_peers` | NCC | `listpeers` | shows registered vs connected (see `get_info` note) |
| `get_channel_fees` | NCC | `listpeerchannels` | base/ppm/HTLC limits/cltv/reserve |
| `set_channel_fees` | NCC | `setchannel` | msat values, `feeppm` dimensionless |
| `get_node_stats` | NCC | `bkpr-listincome` + `plugin list` | economy by tag + plugins + forward count |
| `list_forwards` | NCC | `listforwards` | paginated |
| `get_node_info` | NCC | `listnodes` | alias/color/features/addresses |
| `get_route` | NCC | `getroute` | `fee_msat` = first-hop amount − requested (0 toward a direct peer) |

## Security

- **Allowlist**: only pubkeys in `allowedClientPubkeys` can send
  requests; without an allowlist the bridge accepts nothing (fail-safe).
  Every `--genuri` automatically registers the new client pubkey.
- **Dedicated rune** (clnrest loopback only): the bridge has no access to the
  node beyond what the rune grants — use a rune separate from the RTL one.
- The bridge **never logs** plaintext, event content, runes or keys.
- The secret in the URI is the **client's** private key: keep it as a
  secret (it goes into the app, not the repo).

## MVP limitations

- A single relay (the first in the config).
- No push notifications (kind 23196/23200): the app refreshes periodically.
- `pay_invoice`/`open_channel` are synchronous: if the node takes longer than
  the client timeout (30 s) the response arrives late and the client times out.
- Balances in **msat** (NWC/LDK convention).

## CLN fork compatibility — `.4` release (2026-09-15)

- Since the fork's **`.4`** release the node announces `option_blake2b` (**bit 68 mandatory** in
  `init`): it does NOT peer with older nodes → via the bridge, `connect_peer`/`open_channel`
  toward `.2/.3`-line peers fail until they upgrade (a **node** gate; the bridge is unchanged).
- The bridge **rune** derives from `hsm_secret` and **survives** node upgrades → no
  regeneration; the probe (`bin/probe.dart`) remains the end-to-end check. With a node without
  usable channels the probe **skips `get_route`** (the route cannot exist) instead of reporting a
  false failure.
