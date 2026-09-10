import 'transaction_record.dart';
import 'utxo_info.dart';

/// WalletSnapshot — dati completi di un wallet in un'unica immagine immutabile.
///
/// PERCHÉ: fonte unica di verità condivisa tra Home e Detail. Evita la
/// desincronizzazione di variabili separate (saldo, UTXO, storico): ogni
/// schermata deriva tutto da un singolo snapshot presente in `BalanceCache`.
class WalletSnapshot {
  const WalletSnapshot({
    required this.balanceSats,
    required this.txCount,
    required this.fetchedAt,
    this.utxos,
    this.transactions,
  });

  /// Saldo spendibile in satoshi (Σ UTXO su entrambe le catene — fonte
  /// autorevole: esclude le coinbase orfane che non sono mai UTXO).
  final int balanceSats;

  /// Numero di transazioni nello storico (semantica della label "N transazioni").
  ///
  /// Nota: negli snapshot PARZIALI (Home all'avvio, storico non ancora
  /// caricato) vale il numero di UTXO come valore provvisorio.
  final int txCount;

  /// UTXO per il coin control (null = mai caricati).
  final List<UtxoInfo>? utxos;

  /// Storico transazioni (null = mai caricato).
  final List<TransactionRecord>? transactions;

  /// Momento del fetch: guida la strategia TTL (fresh vs stale).
  final DateTime fetchedAt;

  /// True se contiene sia UTXO che storico (riusabile dal Detail senza rete).
  bool get isComplete => utxos != null && transactions != null;

  /// True se lo snapshot è ancora "fresco" rispetto al TTL dato.
  bool isFresh(Duration ttl) =>
      DateTime.now().difference(fetchedAt).abs() < ttl;
}
