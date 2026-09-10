/// Direzione di una transazione rispetto al wallet.
///
/// Determinata dal saldo netto: se il wallet ha ricevuto più di quanto ha
/// speso (Σ vout > Σ vin) la transazione è [incoming], altrimenti [outgoing].
enum TxDirection { incoming, outgoing }

/// Modello manuale di una transazione Bitcoin (formato Esplora/mempool API).
///
/// // PERCHÉ: nessun modello del progetto usa Freezed/JsonSerializable —
/// pattern canonico: const constructor, campi final, parsing esplicito.
/// I campi derivano dalla risposta di `GET /address/{addr}/txs` verificata
/// sull'API reale mempool.guide testnet4 (2026-08-27).
class TransactionRecord {
  const TransactionRecord({
    required this.txid,
    required this.direction,
    required this.amountSats,
    this.feeSats,
    this.confirmations = 0,
    this.blockHeight,
    this.timestamp,
    this.isOrphan = false,
    this.isEvicted = false,
  });

  final String txid;

  /// In entrata (ricevuti) o in uscita (spesi) rispetto al wallet.
  final TxDirection direction;

  /// Importo in satoshi, sempre positivo (il segno è dato da [direction]).
  final int amountSats;

  /// Fee della transazione in satoshi (null se non fornita dall'API).
  final int? feeSats;

  /// Numero di conferme; 0 = non ancora confermata (pending in mempool).
  final int confirmations;

  /// Altezza del blocco che la contiene (null se pending).
  final int? blockHeight;

  /// Timestamp del blocco (null se pending).
  final DateTime? timestamp;

  /// True se è una coinbase NON confermata → blocco orfano perso per
  /// riorganizzazione/competizione: non è in attesa, non si confermerà mai.
  final bool isOrphan;

  /// True se è una transazione INVIATA da questa app ed è stata ESPULSA o
  /// SOSTITUITA dal mempool (non più conosciuta dal nodo): non si confermerà
  /// mai e i fondi tornano disponibili. Stato di sessione (non persistito).
  final bool isEvicted;

  /// In attesa di conferma nel mempool (esclude coinbase orfane e tx espulse).
  bool get isPending => confirmations == 0 && !isOrphan && !isEvicted;

  /// Parsa una transazione Esplora e calcola direzione/importo rispetto
  /// all'insieme di indirizzi del wallet.
  ///
  /// Regola: netto = Σ vout verso [walletAddresses] − Σ vin (prevout) da
  /// [walletAddresses]. Se netto ≥ 0 → incoming (importo = netto), altrimenti
  /// outgoing (importo = −netto). Gestisce i casi misti (es. change) e le
  /// coinbase (`prevout == null`).
  ///
  /// [tipHeight] opzionale: se fornito calcola le conferme reali
  /// (tipHeight − blockHeight + 1); altrimenti 1 per le confermate.
  factory TransactionRecord.fromExplorerJson(
    Map<String, dynamic> json, {
    required Set<String> walletAddresses,
    int? tipHeight,
  }) {
    final txid = json['txid'] as String? ?? '';

    var received = 0;
    var sent = 0;

    // Σ vout verso i nostri indirizzi (ricevuti).
    // // PERCHÉ: `scriptpubkey_address` può essere vuoto (es. op_return) o
    // assente — va filtrato per non contare output non-spendibili.
    final vouts = json['vout'] as List<dynamic>? ?? const [];
    for (final rawVout in vouts) {
      final vout = rawVout as Map<String, dynamic>;
      final addr = vout['scriptpubkey_address'] as String?;
      if (addr != null && addr.isNotEmpty && walletAddresses.contains(addr)) {
        received += vout['value'] as int? ?? 0;
      }
    }

    // Σ vin (prevout) dai nostri indirizzi (spesi).
    final vins = json['vin'] as List<dynamic>? ?? const [];
    for (final rawVin in vins) {
      final vin = rawVin as Map<String, dynamic>;
      // // PERCHÉ: le coinbase hanno `prevout == null` e non rappresentano
      // una spesa del wallet — vanno saltate, non crashare.
      final prevout = vin['prevout'] as Map<String, dynamic>?;
      if (prevout == null) continue;
      final addr = prevout['scriptpubkey_address'] as String?;
      if (addr != null && addr.isNotEmpty && walletAddresses.contains(addr)) {
        sent += prevout['value'] as int? ?? 0;
      }
    }

    final net = received - sent;
    final direction = net >= 0 ? TxDirection.incoming : TxDirection.outgoing;
    final amountSats = net.abs();

    final status = json['status'] as Map<String, dynamic>? ?? const {};
    final confirmed = status['confirmed'] as bool? ?? false;
    final blockHeight = status['block_height'] as int?;
    final blockTime = status['block_time'] as int?;

    // PERCHÉ: una coinbase (tutti i vin con prevout null / is_coinbase) è
    // SEMPRE in un blocco. Se l'API la riporta non confermata è un blocco
    // ORFANO perso (riorg/competizione) → non è pending, non si confermerà
    // mai. Il saldo non deve includerla (non è un UTXO spendibile).
    final isCoinbase = vins.any((rawVin) {
      final vin = rawVin as Map<String, dynamic>;
      return vin['is_coinbase'] == true || vin['prevout'] == null;
    });
    final isOrphan = isCoinbase && !confirmed;

    // // PERCHÉ: l'API /address/{addr}/txs non restituisce il conteggio
    // conferme — serve l'altezza del blocco tip. Se non disponibile,
    // fallback onesto: 1 per le confermate.
    final int confirmations;
    if (!confirmed) {
      confirmations = 0;
    } else if (tipHeight != null && blockHeight != null) {
      confirmations = tipHeight - blockHeight + 1;
    } else {
      confirmations = 1;
    }

    return TransactionRecord(
      txid: txid,
      direction: direction,
      amountSats: amountSats,
      feeSats: json['fee'] as int?,
      confirmations: confirmations,
      blockHeight: blockHeight,
      timestamp: blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(blockTime * 1000)
          : null,
      isOrphan: isOrphan,
    );
  }
}
