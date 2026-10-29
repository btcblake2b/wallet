/// Trasporto di una PSBT su **QR a più frame** (animati).
///
/// // PERCHÉ un formato nostro (P4/M2, 26/10): una PSBT P2WPKH con 2 input è
/// // ~800-1200 caratteri base64 — un QR singolo a quella densità non si
/// // scansiona in modo affidabile con le fotocamere dei telefoni. I formati
/// // standard (BC-UR, BBQR) servono a SeedSigner/Sparrow, che **non**
/// // conoscono SIGHASH_UNIFIED: il firmatario di questa PSBT è un'altra
/// // istanza di questa app, quindi il protocollo può essere semplice,
/// // versionato e verificabile da noi.
///
/// Formato di un frame:
///
///     PSBT1/<indice>/<totale>/<pezzo-base64>
///
/// - `indice` è **1-based**; `totale` è il numero di frame dell'insieme.
/// - il prefisso/versione rende riconoscibile un frame nostro in mezzo agli
///   altri QR (e permette di cambiare formato senza ambiguità: `PSBT2`).
/// - nessun checksum: il base64 è ricomposto in ordine e validato dal codec
///   BIP-174 (`Psbt.fromBase64`), che è la verifica che conta davvero.
library;

/// Prefisso/versione del protocollo QR.
const String kPsbtFramePrefix = 'PSBT1';

/// Lunghezza di ogni pezzo base64: ~180 caratteri → QR leggibile a schermo
/// anche su telefoni modesti, e al massimo ~8 frame per una PSBT a 2 input.
const int kPsbtFrameChunkLength = 180;

/// Spezza una PSBT (base64) nei frame QR da mostrare in sequenza.
///
/// [chunkLength] è esposto per i test; in app si usa il default.
List<String> encodePsbtFrames(
  String psbtBase64, {
  int chunkLength = kPsbtFrameChunkLength,
}) {
  if (chunkLength <= 0) {
    throw ArgumentError.value(chunkLength, 'chunkLength', 'deve essere > 0');
  }
  final payload = psbtBase64.trim().replaceAll(RegExp(r'\s'), '');
  if (payload.isEmpty) {
    throw ArgumentError.value(psbtBase64, 'psbtBase64', 'PSBT vuota');
  }
  final total = (payload.length + chunkLength - 1) ~/ chunkLength;
  return <String>[
    for (var i = 0; i < total; i++)
      '$kPsbtFramePrefix/${i + 1}/$total/'
          '${payload.substring(
            i * chunkLength,
            i * chunkLength + chunkLength > payload.length
                ? payload.length
                : i * chunkLength + chunkLength,
          )}',
  ];
}

/// True se la stringa sembra un frame del nostro protocollo.
bool isPsbtFrame(String raw) =>
    raw.trimLeft().startsWith('$kPsbtFramePrefix/');

/// Ricompone i frame letti dalla fotocamera, **fuori ordine e con ripetizioni**.
///
/// // PERCHÉ tollerante: chi scansiona insegue un QR che ruota — lo stesso
/// // frame viene letto più volte e gli altri arrivano in ordine casuale. Il
/// // compito dell'assembler è dire "manca ancora il frame 3", non fallire.
class PsbtFrameAssembler {
  final Map<int, String> _chunks = <int, String>{};
  int? _total;

  /// Frame raccolti finora.
  int get received => _chunks.length;

  /// Frame attesi, `null` finché non arriva il primo frame valido.
  int? get total => _total;

  /// True quando tutti i frame sono stati raccolti.
  bool get isComplete => _total != null && _chunks.length == _total;

  /// Aggiunge un frame. Restituisce la PSBT (base64) **appena** l'insieme è
  /// completo, altrimenti `null`. Un frame malformato viene ignorato (ritorna
  /// `null`) invece di interrompere la scansione.
  String? add(String raw) {
    final trimmed = raw.trim();
    if (!isPsbtFrame(trimmed)) return null;
    final parts = trimmed.split('/');
    if (parts.length != 4) return null;
    final index = int.tryParse(parts[1]);
    final total = int.tryParse(parts[2]);
    final chunk = parts[3];
    if (index == null || total == null) return null;
    if (total <= 0 || index < 1 || index > total || chunk.isEmpty) return null;

    // // PERCHÉ il reset: due PSBT diverse non devono mescolarsi. Un totale
    // // diverso (o il frame 1 di un giro nuovo) segnala un nuovo insieme.
    if (_total != null && _total != total) {
      reset();
    }
    if (index == 1 && _chunks.containsKey(1) && _chunks[1] != chunk) {
      reset();
    }
    _total = total;
    _chunks[index] = chunk;

    if (!isComplete) return null;
    final buffer = StringBuffer();
    for (var i = 1; i <= total; i++) {
      buffer.write(_chunks[i]);
    }
    return buffer.toString();
  }

  /// Dimentica i frame raccolti (nuova scansione).
  void reset() {
    _chunks.clear();
    _total = null;
  }
}
