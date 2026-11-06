import '../utils/coinbase_maturity.dart';
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
    this.blockedUtxos = const [],
    this.transactions,
  });

  /// Saldo SPENDIBILE in satoshi: Σ degli UTXO propagabili dalla rete
  /// (fonte autorevole: esclude le coinbase orfane e i payout di mining in
  /// periodo di attesa, accantonati in [blockedUtxos]).
  final int balanceSats;

  /// Numero di transazioni nello storico (semantica della label "N transazioni").
  ///
  /// Nota: negli snapshot PARZIALI (Home all'avvio, storico non ancora
  /// caricato) vale il numero di UTXO come valore provvisorio.
  final int txCount;

  /// UTXO per il coin control (null = mai caricati) — solo SPENDIBILI.
  final List<UtxoInfo>? utxos;

  /// UTXO non spendibili perché payout di mining (coinbase) in periodo di
  /// attesa: la rete non ne propaga la spesa prima della maturity della loro
  /// epoca (25.920 blocchi per le coinbase dal 979.919, sblocco comune a
  /// 979.919 per quelle del 973.440-979.918).
  ///
  /// PERCHÉ: NON concorrono a [balanceSats] — la UI li mostra a parte
  /// (badge + blocchi mancanti) e non devono essere selezionabili.
  final List<UtxoInfo> blockedUtxos;

  /// Storico transazioni (null = mai caricato).
  final List<TransactionRecord>? transactions;

  /// Momento del fetch: guida la strategia TTL (fresh vs stale).
  final DateTime fetchedAt;

  /// Satoshi in periodo di attesa (fuori dal saldo spendibile).
  int get blockedCoinbaseSats => sumUtxoSats(blockedUtxos);

  /// True se lo snapshot contiene fondi non ancora spendibili.
  bool get hasBlockedCoinbase => blockedUtxos.isNotEmpty;

  /// Blocchi mancanti al primo sblocco (null = conferme ignote).
  int? get blockedRemainingBlocks => minRemainingRelayBlocks(blockedUtxos);

  /// True se contiene sia UTXO che storico (riusabile dal Detail senza rete).
  bool get isComplete => utxos != null && transactions != null;

  /// True se lo snapshot è ancora "fresco" rispetto al TTL dato.
  bool isFresh(Duration ttl) =>
      DateTime.now().difference(fetchedAt).abs() < ttl;
}
