/// Riconoscimento della release del fork CLN blake2b a partire dalla stringa
/// di versione riportata da `getinfo` (es. `v26.06.7-blake2b.4`).
///
/// // PERCHÉ (P8): il "gate di peering" (feature bit 68 obbligatorio in `init`)
/// è una proprietà della RELEASE, non del singolo nodo. Il fork espone la
/// release nel version string — verificato il 2026-09-16 sul nodo di test
/// (`getinfo.version` = `v26.06.7-blake2b.4`) — quindi l'app può dirlo
/// all'utente senza configurazione manuale e senza toccare il bridge.
library;

/// Prima release del fork che richiede `option_blake2b` (bit 68) in `init`.
///
/// ⚠️ Valido al 2026-09-16: da riverificare se la community flippa il bit a
/// optional (`discord-forecast.md`, F-02) — in quel caso l'avviso in app va
/// aggiornato o rimosso.
const int kBit68FirstRelease = 4;

/// Esito del riconoscimento della release.
enum ClnPeeringGate {
  /// Release precedente al gate (peer più vecchi ancora ammessi).
  none,

  /// Release con `option_blake2b` (bit 68) obbligatorio: i peer su release
  /// precedenti vengono rifiutati durante l'handshake.
  bit68,

  /// Versione assente o non riconosciuta: nessuna conclusione (mai un avviso
  /// basato su un dato che non sappiamo leggere).
  unknown,
}

/// `blake2b.<numero>` — il suffisso che il fork aggiunge alla versione
/// (es. `v26.06.7-blake2b.4`, `v26.06.7-blake2b.10`).
final RegExp _blake2bReleasePattern = RegExp(r'blake2b\.(\d+)');

/// Riconosce il gate di peering dalla versione riportata dal nodo.
ClnPeeringGate parsePeeringGate(String? version) {
  if (version == null || version.isEmpty) return ClnPeeringGate.unknown;
  final match = _blake2bReleasePattern.firstMatch(version);
  if (match == null) return ClnPeeringGate.unknown;
  final release = int.tryParse(match.group(1) ?? '');
  if (release == null) return ClnPeeringGate.unknown;
  return release >= kBit68FirstRelease
      ? ClnPeeringGate.bit68
      : ClnPeeringGate.none;
}

/// True SOLO quando la versione è riconosciuta come release con gate attivo.
///
/// // PERCHÉ: `unknown` non è "gate assente" — è "non lo so". In quel caso non
/// si mostra nessun avviso, così una versione inattesa (nodo dln, futuro
/// cambio di schema) non produce un allarme falso.
bool clnRequiresBit68(String? version) =>
    parsePeeringGate(version) == ClnPeeringGate.bit68;
