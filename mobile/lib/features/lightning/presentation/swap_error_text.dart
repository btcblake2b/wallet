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
    // PERCHÉ (07/10/2026): dopo un `paymentFailed` l'utente non capiva se il
    // pagamento fosse avvenuto (il messaggio grezzo del nodo era troncato e
    // incomprensibile) — il codice del provider ora ha un testo che spiega che
    // i fondi restano nell'HTLC e si recuperano col refund.
    case 'PAYMENT_FAILED':
      return loc.lightningSwapErrorPaymentFailed;
    case 'PROVIDER_UNAVAILABLE':
      return loc.lightningSwapErrorProviderUnavailable;
    // PERCHÉ (27/10/2026): `swap_info` distingue "il nodo non può pagare" da
    // "il DESTINATARIO non è raggiungibile" — due cause, due azioni diverse.
    case 'PEER_UNREACHABLE':
      return loc.lightningSwapErrorPeerUnreachable;
    case 'RATE_LIMITED':
      return loc.lightningSwapErrorRateLimited;
    case 'DUPLICATE_SWAP':
      return loc.lightningSwapErrorDuplicateSwap;
    case 'QUOTE_EXPIRED':
      return loc.lightningSwapErrorQuoteExpired;
    case 'INVOICE_INVALID':
      return loc.lightningSwapErrorInvoiceInvalid;
    case 'INVOICE_EXPIRED':
      return loc.lightningSwapErrorInvoiceExpired;
    case 'AMOUNT_TOO_SMALL':
    case 'AMOUNT_TOO_LARGE':
      return loc.lightningSwapErrorAmountOutOfRange;
    case 'FUNDING_TIMEOUT':
      return loc.lightningSwapErrorFundingTimeout;
    case 'TOO_LATE':
      return loc.lightningSwapErrorTooLate;
    default:
      return null;
  }
}
