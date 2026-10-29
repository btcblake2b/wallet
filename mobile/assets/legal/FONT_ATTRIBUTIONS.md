# Attribuzioni dei font inclusi

> Auto-contenuto e leggibile offline: sta in `assets/legal/` come gli altri
> documenti legali mostrati nella schermata *Informazioni*.

| Font | Uso | Licenza | Testo della licenza |
|---|---|---|---|
| **Outfit** (variable) | Font dell'interfaccia (`fontFamily: Outfit`) | SIL Open Font License 1.1 | [`OUTFIT_OFL.txt`](OUTFIT_OFL.txt) |
| **Roboto** (regular/medium/bold) | Font di fallback del Material, richiesto dal motore Flutter su web | Apache License 2.0 | [`ROBOTO_LICENSE.txt`](ROBOTO_LICENSE.txt) |

## Perché Roboto è nel bundle (27/10/2026)

Su web il motore Flutter chiedeva Roboto a `fonts.gstatic.com`. La CSP lo
bloccava — quindi **nessun IP usciva dal browser** — ma la console mostrava
errori e la privacy dipendeva da una direttiva CSP. Con i file negli asset il
font arriva dal bundle: nessuna richiesta a terzi, nessun errore e la garanzia
di privacy non è più "in prestito" alla CSP.

I file provengono dalla cache del Flutter SDK (`bin/cache/artifacts/material_fonts`)
e non sono stati modificati.
