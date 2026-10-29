/// Riconoscimento della release del fork CLN blake2b a partire dalla stringa
/// di versione riportata da `getinfo` (es. `v26.06.7-blake2b.4`).
///
/// // PERCHÉ (P8): il "gate di peering" (feature bit 68 obbligatorio in `init`)
/// è una proprietà della RELEASE, non del singolo nodo. Il fork espone la
/// release nel version string — verificato il 2026-09-16 sul nodo di test
/// (`getinfo.version` = `v26.06.7-blake2b.4`) — quindi l'app può dirlo
/// all'utente senza configurazione manuale e senza toccare il bridge.
library;

/// Prima release del fork con gate di peering: `option_blake2b` (bit 68)
/// obbligatorio in `init` → i peer su release precedenti sono rifiutati.
const int kBit68FirstRelease = 4;

/// Prima release del fork con i feature bit **definitivi** (proposti per BOLT 9):
/// `option_blake2b` **512** e `option_unified_sigs` **514**. Da qui il nodo non
/// si connette più con `.4` e precedenti — «the feature bits moved», release
/// notes `v26.06.8-blake2b.5` (28/09/2026), `ecosystem-watch.md` `W-66`.
const int kNewBitsFirstRelease = 5;

/// Esito del riconoscimento della release.
enum ClnPeeringGate {
  /// Release precedente a ogni gate (peer più vecchi ancora ammessi).
  none,

  /// Release `.4`: `option_blake2b` (bit 68) in `init` → rifiuta i peer su
  /// release `.3` e precedenti.
  bit68,

  /// Release `.5` e successive: feature bit **512** (`option_blake2b`) e
  /// **514** (`option_unified_sigs`) → rifiuta i peer su `.4` e precedenti.
  newBits,

  /// Versione assente o non riconosciuta: nessuna conclusione (mai un avviso
  /// basato su un dato che non sappiamo leggere).
  unknown,
}

/// `blake2b.<numero>` — il suffisso che il fork aggiunge alla versione
/// (es. `v26.06.7-blake2b.4`, `v26.06.7-blake2b.10`).
final RegExp _blake2bReleasePattern = RegExp(r'blake2b\.(\d+)');

/// Numero di release del fork (`blake2b.<n>`), `null` se non riconoscibile.
///
/// // PERCHÉ: gate di peering e supporto dello splice leggono lo stesso dato da
/// angolazioni diverse — un solo parser evita che i due divergano (es. `.10`
/// letto come `1`).
int? clnReleaseNumber(String? version) {
  if (version == null || version.isEmpty) return null;
  final match = _blake2bReleasePattern.firstMatch(version);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

/// Riconosce il gate di peering dalla versione riportata dal nodo.
ClnPeeringGate parsePeeringGate(String? version) {
  final release = clnReleaseNumber(version);
  if (release == null) return ClnPeeringGate.unknown;
  // PERCHÉ l'ordine: il gate è cumulativo, non alternativo — `.5` è più stretto
  // di `.4` (non peerа nemmeno con `.4`), quindi per `.5+` prevale la
  // numerazione nuova; il numero cresce anche a più cifre (`.10` > `.5`).
  if (release >= kNewBitsFirstRelease) return ClnPeeringGate.newBits;
  return release >= kBit68FirstRelease
      ? ClnPeeringGate.bit68
      : ClnPeeringGate.none;
}

/// True quando la versione è riconosciuta come release con gate ATTIVO
/// (bit 68 oppure bit 512/514).
///
/// // PERCHÉ: `unknown` non è "gate assente" — è "non lo so". In quel caso non
/// si mostra nessun avviso, così una versione inattesa (nodo dln, futuro
/// cambio di schema) non produce un allarme falso.
bool clnHasPeeringGate(String? version) {
  final gate = parsePeeringGate(version);
  return gate == ClnPeeringGate.bit68 || gate == ClnPeeringGate.newBits;
}

/// Prima release del fork con lo **splice** utilizzabile.
///
/// // PERCHÉ (26/10): `splice_init`/`splice_signed` esistono in CLN dalla 23.08,
/// ma sul fork `.6` è la prima release che applica la feerate negoziata,
/// mantiene l'hash type unificato sulle firme HTLC dopo il lock e impedisce lo
/// splice dei canali senza `option_unified_sigs` (`docs/node-cln-upgrade.md`).
const int kSpliceFirstRelease = 6;

/// Prima release con i **fix di sicurezza dello splice**.
///
/// // PERCHÉ (26/10): `.8` chiude i buchi per cui un peer poteva portare il nodo
/// a **perdere i fondi del canale** (abort di uno splice già firmato, witness
/// del peer non verificati) e `.9` completa il quadro — `ecosystem-watch.md`
/// `W-98`/`W-99`. Sotto questa soglia lo splice funziona ma non è sicuro.
const int kSpliceSafeRelease = 9;

/// Stato dello splice rispetto alla release del nodo.
enum ClnSpliceSupport {
  /// Versione assente o non riconosciuta: nessuna conclusione (mai un avviso
  /// basato su un dato che non sappiamo leggere).
  unknown,

  /// Release precedente a `.6`: il nodo non sa fare lo splice.
  unavailable,

  /// Release `.6`…`.8`: splice possibile, senza i fix di sicurezza.
  outdated,

  /// Release `.9` e successive: splice supportato e corretto.
  safe,
}

/// Riconosce il supporto dello splice dalla versione riportata dal nodo.
ClnSpliceSupport parseSpliceSupport(String? version) {
  final release = clnReleaseNumber(version);
  if (release == null) return ClnSpliceSupport.unknown;
  if (release >= kSpliceSafeRelease) return ClnSpliceSupport.safe;
  if (release >= kSpliceFirstRelease) return ClnSpliceSupport.outdated;
  return ClnSpliceSupport.unavailable;
}
