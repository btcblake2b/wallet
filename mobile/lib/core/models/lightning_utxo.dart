/// Output on-chain del nodo (spec dln `list_utxos` → CLN `listfunds`).
///
/// // PERCHÉ (I3b): mostra su quali output poggia il saldo on-chain del nodo —
/// senza questo l'utente vede un saldo senza sapere come è composto.
class LightningUtxo {
  const LightningUtxo({
    required this.txid,
    required this.vout,
    required this.amountMsat,
    this.address,
    this.status = 'unknown',
    this.blockHeight,
    this.reserved = false,
  });

  final String txid;

  /// Indice dell'output nella transazione.
  final int vout;

  /// Importo in msat (unità del protocollo).
  final int amountMsat;

  final String? address;

  /// `confirmed` | `unconfirmed` (stringa grezza dal nodo).
  final String status;

  /// Altezza di inclusione (assente per gli output non confermati).
  final int? blockHeight;

  /// True se il nodo ha riservato l'output (es. spesa in corso).
  final bool reserved;

  /// Importo in satoshi per la UI.
  int get amountSats => amountMsat ~/ 1000;

  bool get isConfirmed => status.toLowerCase() == 'confirmed';

  /// Txid abbreviato: inizio + fine, la copia resta disponibile.
  String get shortTxid => txid.length <= 16
      ? txid
      : '${txid.substring(0, 8)}…${txid.substring(txid.length - 6)}';

  factory LightningUtxo.fromJson(Map<String, dynamic> json) => LightningUtxo(
        txid: '${json['txid'] ?? ''}',
        vout: (json['vout'] as num?)?.toInt() ?? 0,
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        address: json['address']?.toString(),
        status: '${json['status'] ?? 'unknown'}',
        blockHeight: (json['blockheight'] as num?)?.toInt(),
        reserved: json['reserved'] as bool? ?? false,
      );
}
