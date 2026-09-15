/// Esito di un pagamento Lightning (NIP-47 `pay_invoice`).
class LightningPaymentResult {
  const LightningPaymentResult({
    required this.preimage,
    this.feesPaidMsat,
  });

  /// Preimage del pagamento: la prova che il pagamento è avvenuto.
  final String preimage;
  final int? feesPaidMsat;

  factory LightningPaymentResult.fromJson(Map<String, dynamic> json) =>
      LightningPaymentResult(
        preimage: '${json['preimage'] ?? ''}',
        feesPaidMsat: (json['fees_paid'] as num?)?.toInt(),
      );
}
