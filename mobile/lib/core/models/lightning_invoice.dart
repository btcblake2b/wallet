/// Invoice Lightning generata dal nodo (NIP-47 `make_invoice`).
class LightningInvoice {
  const LightningInvoice({
    required this.bolt11,
    required this.paymentHash,
    this.amountMsat,
    this.description,
    this.expiresAt,
  });

  /// Invoice BOLT11 (stringa `lnbc…`).
  final String bolt11;
  final String paymentHash;
  final int? amountMsat;
  final String? description;
  final DateTime? expiresAt;

  factory LightningInvoice.fromJson(Map<String, dynamic> json) =>
      LightningInvoice(
        bolt11: '${json['invoice'] ?? ''}',
        paymentHash: '${json['payment_hash'] ?? ''}',
        amountMsat: (json['amount'] as num?)?.toInt(),
        description: json['description']?.toString(),
        expiresAt: (json['expires_at'] as num?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                ((json['expires_at'] as num).toInt()) * 1000,
              ),
      );
}
