# Btc Blake2b Wallet

> ⚠️ **Experimental — no warranty.** **Self-custody** wallet for the
> **bitcoin-blake2b** network (a Bitcoin fork). The software is provided "as
> is": use it at your own risk. We never hold your keys: the seed stays on
> your device only.

**Self-custodial** Bitcoin wallet (open source, MIT) for the
**bitcoin-blake2b** network. No accounts, no KYC, no author-operated backend:
private keys and the seed phrase are generated and encrypted (AES-256-GCM)
**on the device only**.

- 🔐 100% self-custody — keys never leave your device
- 👛 Create / import wallets (BIP39 + BIP32/BIP84/BIP49/BIP44)
- 💸 Receive, send, balance and history (Esplora-compatible API)
- 🛡️ Local GDPR consent, screen protection, jailbreak/root detection
- 🌍 7 languages

> **Not affiliated with, sponsored or endorsed by Bitcoin, Bitcoin Core or
> bitcoin.org.**

## Lightning (remote node, experimental)

Since **v0.2.0** the app can control a **remote blake2b Lightning node**
(NWC/NCC): the node and bridge run on **your** server, the app connects over
Nostr. Keys stay on the node — no custody, no author-operated service.

**What you need:**

1. **Install the node + bridge** with the assisted installer:
   <https://btcblake2b.org/node.html> · source:
   [`btcblake2b/control-plane`](https://github.com/btcblake2b/control-plane).
   You need an Ubuntu machine (22.04/24.04/26.04) with a blake2b full node
   reachable via RPC.
2. **Find the connection string** (NWC URI): the installer prints it at the
   end of the installation and stores it on the server in `~/bridge/uri.txt`:

   ```bash
   cat ~/bridge/uri.txt
   ```

   For **another device**: from the installed package directory,
   `./install.sh --gen-uri` authorizes a new client and prints a new
   string (local revocation with `--revoke-client <pubkey>`).
3. **Connect it in the app**: *Lightning → Connect* → paste the string.

**Example string** (fake values):

```
nostr+walletconnect://<bridge-pubkey-64-hex>?relay=wss://relay.primal.net&secret=<secret-64-hex>
```

⚠️ The string contains a **personal authorization secret**: treat it like a
password and never share it. Each device has its own string and it can be
revoked locally (on the bridge).

## Repository

The app code is in [`mobile/`](mobile/README.md) (Flutter/Dart); the public
site in [`website/`](website/).

| File | Purpose |
|------|---------|
| [`LICENSE`](LICENSE) | MIT license |
| [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md) | Dependency attributions |
| [`SECURITY.md`](SECURITY.md) | Responsible disclosure |
| [`mobile/README.md`](mobile/README.md) | Setup and development |

## License

[MIT](LICENSE) — Copyright (c) 2025-2026 Filippo Santagiuliana.
