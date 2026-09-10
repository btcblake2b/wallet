# Btc Blake2b Wallet

Wallet Bitcoin **self-custodial** per la rete **bitcoin-blake2b** (mainnet), fork da `tr_loc_wal` senza funzionalità di trasferimento wallet, senza backend Firebase e senza classificazione locked/unlocked: ogni wallet è un normale wallet Bitcoin (stile BlueWallet), con seed cifrata localmente e backup confermato dall'utente.

> ⚠️ **Sperimentale**: la rete bitcoin-blake2b è un fork di Bitcoin con valuta dal valore incerto. Usa l'app **solo con importi che puoi permetterti di perdere**. Non è affiliata a Bitcoin/bitcoin.org. Il software non è un consiglio finanziario.

## Funzionalità

- ✅ Crea wallet (BIP39 + BIP32/BIP84, seed cifrato AES-GCM su secure storage)
- ✅ Importa wallet da seed phrase
- ✅ Ricevi (QR + indirizzo) / Invia (build & sign tx, fee estimate, broadcast)
- ✅ Saldo e transazioni (API Esplora-compatibile: `mempool.guide`)
- ✅ Sblocco con biometria / password (web)
- ✅ Firma e verifica messaggi
- ✅ Backup seed con conferma obbligatoria
- ✅ Consenso GDPR locale (nessun dato su server)
- ✅ 8 lingue (EN, IT, DE, FR, ES, FI, ZH)
- ✅ Security: jailbreak/root detection, integrità APK, screen protection
- ❌ Nessuna funzionalità di trasferimento wallet (rimossa dal fork)
- ❌ Nessun backend Firebase (wallet 100% locale)

## Struttura

```
mobile/
  lib/
    app/              → bootstrap, router, DI
    core/
      config/         → bitcoin_network_config (rete blake2b mainnet)
      models/         → WalletRecord, OnboardingData
      services/       → bitcoin, crypto, wallet_repository, consent, security...
      theme/          → AppTheme dark
      widgets/        → GlassContainer, AppBackground, ...
    features/
      wallet/         → home, detail, send, import, legal
      onboarding/     → splash, onboarding
      settings/       → about
      donate/         → donate
    l10n/             → ARB + generati
  ai-core/            → analizzatore statico (docs in ai-context/)
  test/               → suite di test
```

## Rete bitcoin-blake2b (mainnet)

- **Indirizzi/chiavi/firme invariati** rispetto a Bitcoin: prefissi mainnet (`bc1...`, `xpub`, coin_type `0'`).
- **API**: `https://mempool.guide/api` (formato Esplora-compatibile).
- Config centralizzata in `lib/core/config/bitcoin_network_config.dart`.

## Setup

```bash
cd mobile
flutter pub get
# crea .env da .env.example (APP_SIGNATURE vuoto per dev)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

## Test

```bash
cd mobile
flutter analyze   # 0 errori
flutter test      # suite completa
```

## Release APK (Android)

> ⚠️ **Regola d'oro**: dopo OGNI modifica a `.env` riesegui
> `dart run build_runner build` **prima** di buildare la release. Envied incorpora
> i valori nel generato `env.g.dart`: se il generato è più vecchio del `.env`, la
> build usa i valori precedenti. Con `APP_SIGNATURE` incorporata vuota,
> `verifyIntegrity()` blocca l'avvio in release (fail-closed) — è ciò che ha
> bloccato la v0.1.0 (splash con logo su schermo nero), fixato in v0.1.1.

```bash
cd mobile
# 1) .env → env.g.dart (se la cache non rileva il cambio: `dart run build_runner clean`,
#    rimuovere lib/core/config/env.g.dart e rieseguire)
dart run build_runner build
# 2) APK firmato (richiede android/key.properties + keystore)
flutter build apk --release
```

Verifica firma e hash **prima** di pubblicare:

```powershell
$apksigner = "$env:LOCALAPPDATA\Android\sdk\build-tools\36.0.0\apksigner.bat"
& $apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
```

Poi: `scripts/publish-release.ps1 -Version <x.y.z>` (un commit per release sul repo
pubblico), GitHub Release con APK + checksum, aggiornamento `website/` (nome file + hash).

## Nota sicurezza e privacy

- La rete bitcoin-blake2b è una **minority chain** con hashrate limitato e **senza replay protection**: le transazioni possono essere riorganizzate o non riconosciute. La valuta del fork potrebbe non avere valore di mercato. Usa solo piccoli importi.
- **Privacy**: nessun dato personale è salvato su server dell'autore (seed cifrata solo sul dispositivo). Per saldo e fee l'app interroga una sola API di terze parti (mempool.guide) a cui vengono trasmessi IP e indirizzo pubblico interrogato. **Niente controvalore fiat**: la rete blake2b non ha un prezzo di mercato riconosciuto. Dettagli nella Privacy Policy in-app (schermata Info Legali).
