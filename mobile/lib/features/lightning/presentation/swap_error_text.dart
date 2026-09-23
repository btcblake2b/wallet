import '../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Errori dello SWAP (P9) → messaggi localizzati
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ (ADR 2026-09-18): lo swap parla in codici (`SwapException.code`).
// Alcuni hanno un significato per l'utente e il messaggio tecnico non è
// comprensibile ("relay del provider non consentito dalla variante web").
// Si mappa il CODICE, mai il testo: cambiare una stringa di protocollo non deve
// rompere la UI, e i codici non mappati restano visibili come fallback tecnico
// (utile al supporto) invece di sparire.

/// Motivo localizzato per un codice di errore dello swap P9.
///
/// Ritorna `null` per i codici non mappati: il chiamante mostra il messaggio
/// tecnico originale (fallback esplicito, mai silenzioso).
String? swapErrorReason(AppLocalizations loc, String code) {
  switch (code) {
    case 'RELAY_NOT_ALLOWED_WEB':
      // PERCHÉ: sulla PWA la CSP consente solo i relay in allowlist — qui la
      // causa non è un guasto di rete ma una scelta di sicurezza.
      return loc.lightningSwapErrorRelayNotAllowed;
    case 'CONNECT_FAILED':
      return loc.lightningSwapErrorConnectFailed;
    case 'DISCONNECTED':
      return loc.lightningSwapErrorDisconnected;
    case 'NOT_CONNECTED':
      return loc.lightningSwapErrorNotConnected;
    default:
      return null;
  }
}
