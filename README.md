# Btc Blake2b Wallet

> ⚠️ **Sperimentale — nessuna garanzia.** Wallet **self-custody** per la rete
> **bitcoin-blake2b** (fork di Bitcoin). Il software è fornito "così com'è":
> usalo a tuo rischio. Non custodiamo le tue chiavi: la seed resta solo sul
> tuo dispositivo.

Wallet Bitcoin **self-custodial** (open source, MIT) per la rete
**bitcoin-blake2b**. Nessun account, nessun KYC, nessun backend dell'autore:
le chiavi private e la seed phrase vengono generate e cifrate (AES-256-GCM)
**esclusivamente sul dispositivo**.

- 🔐 Self-custody al 100% — chiavi mai trasmesse
- 👛 Crea / importa wallet (BIP39 + BIP32/BIP84/BIP49/BIP44)
- 💸 Ricevi, invia, saldo e cronologia (API Esplora-compatibile)
- 🛡️ Consenso GDPR locale, screen protection, jailbreak/root detection
- 🌍 7 lingue

> **Non affiliato, sponsorizzato o approvato da Bitcoin, Bitcoin Core o
> bitcoin.org.**

## Repository

Il codice dell'app è in [`mobile/`](mobile/README.md) (Flutter/Dart).
Documentazione di progetto e memoria degli agenti AI in [`docs/`](docs/).

| File | Scopo |
|------|-------|
| [`LICENSE`](LICENSE) | Licenza MIT |
| [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md) | Attribuzioni dipendenze |
| [`SECURITY.md`](SECURITY.md) | Responsible disclosure |
| [`mobile/README.md`](mobile/README.md) | Setup e sviluppo |

## Licenza

[MIT](LICENSE) — Copyright (c) 2025-2026 Filippo Santagiuliana.
