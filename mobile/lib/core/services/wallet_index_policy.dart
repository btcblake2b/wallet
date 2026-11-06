import '../models/wallet_record.dart';

/// Comportamento di risoluzione dell'indirizzo di ricezione.
///
/// // PERCHÉ (ADR 30/10-7 §2): feature flag e stato del record sono due
/// // dimensioni indipendenti. Se la tabella vivesse in due `if` sparsi, il
/// // kill switch potrebbe spegnere per errore il fail-closed e reintrodurre
/// // l'address reuse dal retro. Qui la tabella è una funzione pura e testabile.
enum ReceiveAddressMode {
  /// Flag spento + record legacy: si usa `publicAddress` (= `/0/0`), nessuna
  /// scrittura. È il comportamento storico.
  legacyPublicAddress,

  /// Flag spento + record con indici: si legge `/0/N` dal record e **non** si
  /// avanza — il flag spegne la rotazione automatica, non riscrive la storia.
  readOnlyIndex,

  /// Flag acceso + record legacy: serve un'adozione esplicita dell'utente
  /// prima di derivare da un indice persistito.
  needsAdoption,

  /// Flag acceso + record valido: write-ahead compare-and-set.
  rotate,

  /// Record `corrupt` o `anomalous`: fail-closed **qualunque** sia il flag.
  blocked,
}

/// Tabella di verità flag × stato (ADR 30/10-7 §2, confermata in ADR 30/10-11).
class WalletIndexPolicy {
  const WalletIndexPolicy._();

  /// Lo stato del record vince sempre sul flag: la corruzione non si aggira
  /// spegnendo la feature.
  static ReceiveAddressMode resolve({
    required bool rotationEnabled,
    required IndicesState state,
  }) {
    if (state == IndicesState.corrupt || state == IndicesState.anomalous) {
      return ReceiveAddressMode.blocked;
    }
    if (!rotationEnabled) {
      return state == IndicesState.legacyUninitialized
          ? ReceiveAddressMode.legacyPublicAddress
          : ReceiveAddressMode.readOnlyIndex;
    }
    return state == IndicesState.legacyUninitialized
        ? ReceiveAddressMode.needsAdoption
        : ReceiveAddressMode.rotate;
  }

  /// Perché il blocco: `corrupt` e `anomalous` hanno **uscite diverse** (per il
  /// corrotto anche «riparti da 0», per l'anomalo no).
  ///
  /// // PERCHÉ serve una funzione (ADR 30/10-12): `blocked` da solo non basta
  /// // alla UI — se ogni schermata re-interpretasse lo stato per conto proprio,
  /// // metà dei punti mostrerebbe il messaggio generico e metà quello giusto.
  static IndicesState? blockedState(IndicesState state) {
    return switch (state) {
      IndicesState.corrupt => IndicesState.corrupt,
      IndicesState.anomalous => IndicesState.anomalous,
      _ => null,
    };
  }

  /// Indice di ricezione autoritativo dopo un restore (ADR 30/10-12 §3).
  ///
  /// // PERCHÉ `max`: il record persistito è un floor, simmetrico al resto.
  /// // Se il gap-scan trova più usage del record, i fondi sono più avanti; se
  /// // ne trova meno (indirizzi derivati ma mai mostrati prima di un crash) il
  /// // record non deve scendere, altrimenti si riusa un indirizzo già derivato.
  static int resolveRestoredReceiveIndex({
    required int persisted,
    required int scanned,
  }) {
    final safePersisted = persisted < 0 ? 0 : persisted;
    final safeScanned = scanned < 0 ? 0 : scanned;
    return safePersisted > safeScanned ? safePersisted : safeScanned;
  }

  /// Come [resolveRestoredReceiveIndex], ma su un record: **fail-closed** se lo
  /// stato non è utilizzabile.
  ///
  /// // PERCHÉ (ADR 30/10-13): il restore è il percorso di recupero — su un
  /// // record corrotto/anomalo non si «risolve» nulla: si lancia l'eccezione
  /// // dedicata, altrimenti si fisserebbe come autoritativo un indice che non
  /// // si conosce.
  static int resolveRestoredReceiveIndexFor({
    required WalletRecord record,
    required int scanned,
  }) {
    switch (record.indicesState) {
      case IndicesState.corrupt:
        throw CorruptWalletIndicesException(record.walletId);
      case IndicesState.anomalous:
        throw AnomalousWalletIndexException(
          record.walletId,
          record.requireNextReceiveIndex(),
        );
      case IndicesState.legacyUninitialized:
      case IndicesState.valid:
        return resolveRestoredReceiveIndex(
          persisted: record.requireNextReceiveIndex(),
          scanned: scanned,
        );
    }
  }
}
