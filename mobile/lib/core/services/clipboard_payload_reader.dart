import 'package:flutter/services.dart';

/// Esito della lettura degli appunti.
enum ClipboardPayloadStatus {
  /// Testo letto e riconosciuto come payload **utilizzabile subito**.
  ok,

  /// Formato riconosciuto ma non utilizzabile qui (LNURL, lightning address).
  ///
  /// // PERCHÉ non è `unsupported` (ADR 02/11-28 §3): l'utente ha incollato un
  /// // formato legittimo che l'app conosce ma non sa ancora pagare. Dire «non
  /// // riconosciuto» lo farebbe dubitare dell'app; «riconosciuto, arriverà» è
  /// // la verità.
  recognizedUnsupported,

  /// Appunti vuoti (o solo spazi).
  empty,

  /// Testo presente ma non riconosciuto come payload (nessuna azione).
  unsupported,

  /// Permesso negato o piattaforma senza lettura degli appunti.
  ///
  /// // PERCHÉ un esito dedicato (ADR 02/11-27 §3): su web `readText()` richiede
  /// // contesto sicuro e gesture; Firefox chiede un permesso esplicito e Safari
  /// // si comporta diversamente. Il caso «negato» deve diventare un messaggio,
  /// // non un'eccezione non gestita.
  unavailable,
}

/// Tipo di payload riconosciuto negli appunti.
enum ClipboardPayloadKind {
  bitcoinAddress,
  bolt11,
  bolt12,

  /// URI BIP21 (`bitcoin:…`). Il parsing di importo/label spetta al chiamante
  /// che già lo fa per gli altri percorsi: qui si classifica soltanto.
  bip21,

  /// LNURL bech32 (`lnurl1…`): riconosciuto, non pagabile in questa build.
  lnurl,

  /// Lightning address (`nome@dominio`): riconosciuto, non pagabile qui.
  lightningAddress,
}

/// Risultato della lettura degli appunti.
class ClipboardPayload {
  const ClipboardPayload({
    required this.status,
    this.kind,
    this.value = '',
    this.hasLightningFallback = false,
  });

  final ClipboardPayloadStatus status;
  final ClipboardPayloadKind? kind;

  /// Testo normalizzato (trim, senza prefisso `lightning:`).
  final String value;

  /// True se il BIP21 contiene anche un fallback Lightning (`lightning=…`).
  ///
  /// // PERCHÉ esiste (ADR 02/11-29 §4): un QR `bitcoin:…?lightning=lnbc…`
  /// // offre on-chain **e** Lightning. Il reader lo classifica `bip21` e la UI
  /// // segue on-chain-first, ma deve **sapere** che il fallback c'è: ignorarlo
  /// // in silenzio è la stessa ambiguità del vecchio kind `uri`.
  final bool hasLightningFallback;

  bool get isUsable => status == ClipboardPayloadStatus.ok;

  /// Riconosciuto ma non utilizzabile qui: serve un messaggio, non un errore.
  bool get isRecognizedButUnsupported =>
      status == ClipboardPayloadStatus.recognizedUnsupported;
}

/// Legge e classifica un payload dagli appunti.
///
/// // PERCHÉ separato dalla UI (ADR 02/11-27 §3): su web il paste è il caso
/// // d'uso dominante e ha più modi di fallire di quanto sembri. Qui il
/// // fallimento diventa un [ClipboardPayloadStatus], quindi la schermata deve
/// // gestire solo quattro esiti — gli stessi della scansione QR.
class ClipboardPayloadReader {
  const ClipboardPayloadReader();

  Future<ClipboardPayload> read() async {
    final String raw;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      raw = data?.text ?? '';
    } catch (_) {
      // Permesso negato / API assente: non è un errore dell'utente.
      return const ClipboardPayload(
        status: ClipboardPayloadStatus.unavailable,
      );
    }

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return const ClipboardPayload(status: ClipboardPayloadStatus.empty);
    }

    // `lightning:` è un prefisso URI: si toglie prima di classificare.
    var value = normalized;
    if (value.toLowerCase().startsWith('lightning:')) {
      value = value.substring('lightning:'.length).trim();
    }

    final lower = value.toLowerCase();
    if (lower.startsWith('lno1') && value.length >= 20) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.ok,
        kind: ClipboardPayloadKind.bolt12,
        value: value,
      );
    }
    if ((lower.startsWith('lnbc') || lower.startsWith('lntb')) &&
        value.length >= 20) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.ok,
        kind: ClipboardPayloadKind.bolt11,
        value: value,
      );
    }
    if (lower.startsWith('lightning:')) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.ok,
        kind: ClipboardPayloadKind.bip21,
        value: value,
      );
    }
    if (lower.startsWith('bitcoin:')) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.ok,
        kind: ClipboardPayloadKind.bip21,
        value: value,
        hasLightningFallback: lower.contains('lightning='),
      );
    }
    // Formati riconosciuti ma non pagabili in questa build (A3a li coprirà).
    if (lower.startsWith('lnurl1') && value.length >= 20) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.recognizedUnsupported,
        kind: ClipboardPayloadKind.lnurl,
        value: value,
      );
    }
    if (_looksLikeLightningAddress(lower)) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.recognizedUnsupported,
        kind: ClipboardPayloadKind.lightningAddress,
        value: value,
      );
    }
    // Indirizzo on-chain: forma bech32 (bc1…) o legacy (1…/3…).
    if (_looksLikeAddress(lower)) {
      return ClipboardPayload(
        status: ClipboardPayloadStatus.ok,
        kind: ClipboardPayloadKind.bitcoinAddress,
        value: value,
      );
    }

    return const ClipboardPayload(status: ClipboardPayloadStatus.unsupported);
  }

  static bool _looksLikeAddress(String value) {
    if (value.startsWith('bc1') || value.startsWith('tb1')) {
      return value.length >= 14 && value.length <= 90;
    }
    final legacy = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$');
    return legacy.hasMatch(value);
  }

  /// `nome@dominio.tld` — forma di una lightning address (LNURL-pay via DNS).
  static bool _looksLikeLightningAddress(String value) {
    final pattern = RegExp(
      r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(value);
  }
}
