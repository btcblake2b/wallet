/// Pagamento in uscita del nodo (spec dln `list_pays`).
class LightningPaymentRecord {
  const LightningPaymentRecord({
    required this.paymentHash,
    required this.amountMsat,
    required this.amountSentMsat,
    required this.status,
    this.destination,
    this.createdAt,
    this.completedAt,
    this.createdIndex,
  });

  final String paymentHash;

  /// Pubkey del nodo destinatario (quando il nodo la riporta).
  final String? destination;

  /// Importo richiesto dalla fattura (msat).
  final int amountMsat;

  /// Importo effettivamente inviato, fee inclusa (msat).
  final int amountSentMsat;

  /// Stato grezzo dal nodo (`complete`, `failed`, `pending`, …).
  final String status;

  final int? createdAt;
  final int? completedAt;
  final int? createdIndex;

  int get amountSats => amountMsat ~/ 1000;

  /// Fee pagata per il routing (differenza fra inviato e richiesto).
  int get feeSats => (amountSentMsat - amountMsat) ~/ 1000;

  bool get isComplete => status.toLowerCase() == 'complete';

  DateTime? get date {
    final ts = completedAt ?? createdAt;
    return ts == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal();
  }

  factory LightningPaymentRecord.fromJson(Map<String, dynamic> json) =>
      LightningPaymentRecord(
        paymentHash: '${json['payment_hash'] ?? ''}',
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        amountSentMsat: (json['amount_sent_msat'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? 'unknown'}',
        destination: json['destination']?.toString(),
        createdAt: (json['created_at'] as num?)?.toInt(),
        completedAt: (json['completed_at'] as num?)?.toInt(),
        createdIndex: (json['created_index'] as num?)?.toInt(),
      );
}
