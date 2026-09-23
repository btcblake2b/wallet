# Btc Blake2b Wallet

**Self-custodial** Bitcoin wallet for the **bitcoin-blake2b** network (mainnet), forked from `tr_loc_wal` without the wallet-transfer feature, without a Firebase backend and without locked/unlocked classification: every wallet is a regular Bitcoin wallet (BlueWallet-style), with a locally encrypted seed and a user-confirmed backup.

> ⚠️ **Experimental**: the bitcoin-blake2b network is a Bitcoin fork whose currency has an uncertain value. Use the app **only with amounts you can afford to lose**. Not affiliated with Bitcoin/bitcoin.org. This software is not financial advice.

## Features

- ✅ Create wallet (BIP39 + BIP32/BIP84, seed encrypted AES-GCM in secure storage)
- ✅ Import wallet from seed phrase
- ✅ Receive (QR + address) / Send (build & sign tx, fee estimate, broadcast)
- ✅ Balance and transactions (Esplora-compatible API: `mempool.guide`, with automatic failover to two community mirrors — `mempool.kilombino.com`, `mempool.maveth.ca`)
- ✅ Unlock with biometrics / password (web)
- ✅ Message signing and verification
- ✅ Lightning (experimental): control of a remote blake2b node via NWC/NCC — see the [main README](../README.md) for the connection string
- ✅ Seed backup with mandatory confirmation
- ✅ Local GDPR consent (no data on servers)
- ✅ 7 languages (EN, IT, DE, FR, ES, FI, ZH)
- ✅ Security: jailbreak/root detection, APK integrity, screen protection
- ❌ No wallet-transfer feature (removed from the fork)
- ❌ No Firebase backend (100% local wallet)

## Structure

```
mobile/
  lib/
    app/              → bootstrap, router, DI
    core/
      config/         → bitcoin_network_config (blake2b mainnet)
      models/         → WalletRecord, OnboardingData
      services/       → bitcoin, crypto, wallet_repository, consent, security...
      theme/          → AppTheme dark
      widgets/        → GlassContainer, AppBackground, ...
    features/
      wallet/         → home, detail, send, import, legal
      onboarding/     → splash, onboarding
      settings/       → about
      donate/         → donate
    l10n/             → ARB + generated
  ai-core/            → static analyzer (docs in ai-context/)
  test/               → test suite
```

## bitcoin-blake2b network (mainnet)

- **Addresses/keys/signatures unchanged** compared to Bitcoin: mainnet prefixes (`bc1...`, `xpub`, coin_type `0'`).
- **API**: `https://mempool.guide/api` (Esplora-compatible format).
- Configuration centralized in `lib/core/config/bitcoin_network_config.dart`.

## Setup

```bash
cd mobile
flutter pub get
# create .env from .env.example (APP_SIGNATURE empty for dev)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

## Test

```bash
cd mobile
flutter analyze   # 0 issues
flutter test      # full suite
```

## APK release (Android)

> ⚠️ **Golden rule**: after EVERY change to `.env`, re-run
> `dart run build_runner build` **before** building the release. Envied embeds
> the values into the generated `env.g.dart`: if the generated file is older
> than `.env`, the build uses the previous values. With an empty embedded
> `APP_SIGNATURE`, `verifyIntegrity()` blocks startup in release (fail-closed) —
> that is what blocked v0.1.0 (logo splash on a black screen), fixed in v0.1.1.

```bash
cd mobile
# 1) .env → env.g.dart (if the cache misses the change: `dart run build_runner clean`,
#    delete lib/core/config/env.g.dart and re-run)
dart run build_runner build
# 2) signed APK (requires android/key.properties + keystore)
flutter build apk --release
```

Verify signature and hash **before** publishing:

```powershell
$apksigner = "$env:LOCALAPPDATA\Android\sdk\build-tools\36.0.0\apksigner.bat"
& $apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
```

Then: `scripts/publish-release.ps1 -Version <x.y.z>` (one commit per release on the
public repo), GitHub Release with APK + checksum, `website/` update (file name + hash).

## Web build (PWA)

> ⚠️ The PWA is **experimental**: the browser threat model (active XSS, local
> storage) differs from the native one. Auto-lock removes keys from RAM after
> 10 min of inactivity and on a hidden page, but the browser remains a wider
> surface than an OS keyring: do not use it for meaningful amounts.

```bash
cd mobile
# HARDENED build: self-hosted assets (no third-party CDN) and no dynamic
# code generation (prerequisite for a strict CSP).
flutter build web --release --csp --no-web-resources-cdn
```

- `web/_headers` (copied into `build/web/`) applies CSP/HSTS/nosniff on
  Cloudflare Pages: **HTTPS is required** (the web vault refuses insecure contexts).
- `web/boot.js` is an external script: no inline scripts in the HTML.
- Outfit font bundled and licenses in `assets/legal/`: no requests to Google
  Fonts or raw.githubusercontent.com while using the app.
- Deploy: **not activated while the PWA is under development** — it is tested
  locally only. The planned dedicated origin is `app.btcblake2b.org`.

### Local testing (no deploy)

From the repo root (uses `wrangler`, already required for the showcase deploy):

```powershell
.\scripts\serve-pwa.ps1            # hardened build + local server on :8788
.\scripts\serve-pwa.ps1 -SkipBuild # serve the existing build/web
.\scripts\serve-pwa.ps1 -Clean     # clean caches first (stale plugin builds)
```

- The server is `wrangler pages dev`: it applies the real `web/_headers`
  (CSP/HSTS) locally, so the local test matches what Pages will serve.
  Nothing is published.
- Quick iterations without production headers: `flutter run -d chrome`.
- Use `http://localhost:8788` only: it is a secure context, so the web vault
  accepts it. `http://<LAN-IP>` is rejected (the vault requires a secure context).
- Current web limitations: on the web app Lightning payments work **only
  through a swap provider** (pay an invoice without owning a node) —
  connecting your own node (NWC/NCC) is not available there, because the
  connection key would carry node-admin powers in a weaker storage context
  than an OS keyring. The CSP allows only the allowlisted swap relay
  (`wss://relay.primal.net`, see `kWebAllowedSwapRelays` in
  `core/services/swap/swap_web_policy.dart`), not any `wss:` host.
- `mempool.guide` does not expose CORS to browsers, so reads and broadcasts
  fail over to the community mirror (`mempool.kilombino.com`) — keep the
  fallback-explorer setting ON (default) while testing.

## Security and privacy note

- The bitcoin-blake2b network is a **network separate from Bitcoin** with limited hashrate and **no replay protection**: transactions can be reorganized or not recognized. The fork's currency may have no market value. Use small amounts only.
- **Privacy**: no personal data is stored on author-operated servers (seed encrypted on the device only). For balance and fees the app queries a single third-party API (mempool.guide) to which the IP and the queried public address are transmitted. **No fiat countervalue**: the blake2b network has no recognized market price. Details in the in-app Privacy Policy (Legal Info screen).
