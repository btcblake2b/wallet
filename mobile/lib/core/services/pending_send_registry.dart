import 'package:flutter/foundation.dart';

/// Stato di una transazione inviata da questa app nella sessione corrente.
enum PendingSendState { pending, confirmed, evicted }

/// Registro IN-MEMORIA (solo sessione) delle transazioni inviate dall'app.
///
/// PERCHÉ (audit P1-c): senza un "ricordo" delle tx inviate, una transazione
/// espulsa dal mempool (eviction) o sostituita (RBF/doppia spesa) sparirebbe
/// SILENZIOSAMENTE dallo storico a ogni refresh. Il registro consente al
/// servizio di riconciliare a ogni refresh interrogando `txStatus(txid)`.
///
/// MAI persistito e MAI contenente dati sensibili: solo txid + importo (per la
/// riga sintetica in UI). Pattern statico coerente con [BalanceCache] (nessun
/// DB, reset nei test). Scope v1: le informazioni si perdono al riavvio (una
/// persistenza reale richiederebbe uno storage locale → fuori scope).
class PendingSendRegistry {
  PendingSendRegistry._();

  static final Map<String, _PendingSend> _txs = {};

  @visibleForTesting
  static void resetForTest() => _txs.clear();

  /// Registra una transazione appena broadcastata (outgoing).
  static void register(String txid, {required int amountSats}) {
    if (txid.isEmpty) return;
    _txs[txid] = _PendingSend(amountSats: amountSats);
  }

  /// Txid ancora da riconciliare (pending o evicted).
  static List<String> get activeTxids => _txs.keys.toList();

  static bool contains(String txid) => _txs.containsKey(txid);

  static bool isEvicted(String txid) =>
      _txs[txid]?.state == PendingSendState.evicted;

  static int amountOf(String txid) => _txs[txid]?.amountSats ?? 0;

  /// La tx è confermata: smette di essere tracciata (rimozione, niente leak).
  static void markConfirmed(String txid) => _txs.remove(txid);

  static void markEvicted(String txid) {
    final t = _txs[txid];
    if (t != null) t.state = PendingSendState.evicted;
  }
}

class _PendingSend {
  _PendingSend({required this.amountSats});
  final int amountSats;
  PendingSendState state = PendingSendState.pending;
}
