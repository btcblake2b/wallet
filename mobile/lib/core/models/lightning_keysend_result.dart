/// Esito di un pagamento keysend (spec dln `keysend`).
///
/// // PERCHÉ: separato da `LightningPaymentResult` (che copre solo preimage e
/// fee di `pay_invoice`) perché qui servono anche destinazione, hash e stato —
/// e la preimage può mancare finché il nodo non chiude il pagamento.
class LightningKeysendResult {
  const LightningKeysendResult({
    required this.destination,
    required this.paymentHash,
    this.preimage,
    this.status = 'unknown',
    this.amountMsat = 0,
    this.feeMsat,
    this.createdAt,
  });

  final String destination;
  final String paymentHash;

  /// Prova del pagamento: presente solo a pagamento completato.
  final String? preimage;

  /// `complete`, `failed`, `pending`, …
  final String status;
  final int amountMsat;
  final int? feeMsat;
  final int? createdAt;

  bool get isComplete => status == 'complete';
  int get amountSats => amountMsat ~/ 1000;
  int? get feeSats => feeMsat == null ? null : feeMsat! ~/ 1000;

  String get shortDestination => destination.length <= 16
      ? destination
      : '${destination.substring(0, 16)}…';

  factory LightningKeysendResult.fromJson(Map<String, dynamic> json) =>
      LightningKeysendResult(
        destination: '${json['destination'] ?? ''}',
        paymentHash: '${json['payment_hash'] ?? ''}',
        preimage: json['payment_preimage']?.toString(),
        status: '${json['status'] ?? 'unknown'}',
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        feeMsat: (json['fee_msat'] as num?)?.toInt(),
        createdAt: (json['created_at'] as num?)?.toInt(),
      );
}
