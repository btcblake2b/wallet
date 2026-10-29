/// Pagamento cross-chain: una fattura della chain SHA-256 pagata con i fondi
/// della chain BLAKE2b, tramite un bridge esterno non-custodial.
///
/// // PERCHÉ (P9): il bridge risponde con una **hold invoice** sulla nostra
/// // chain con lo stesso payment hash. Paghiamo quella: i fondi restano in
/// // sospeso e il bridge li incassa solo presentando la preimage, cioè dopo
/// // aver pagato davvero la fattura SHA-256. Se non ci riesce, la hold invoice
/// // scade e i sat tornano indietro da soli.
class LightningCrossChainEstimate {
  const LightningCrossChainEstimate({
    required this.amountSats,
    this.costSats,
    this.rate,
    this.spread,
    this.waitSeconds,
    this.paymentHash,
  });

  /// Importo della fattura SHA-256, in sat.
  final int amountSats;

  /// Quanto costa pagarla in sat della nostra chain (include fee e spread).
  final int? costSats;

  /// Cambio usato dal bridge.
  final double? rate;

  /// Spread applicato dal bridge (0.02 = 2%).
  final double? spread;

  /// Attesa stimata prima che il bridge paghi.
  final int? waitSeconds;

  final String? paymentHash;

  factory LightningCrossChainEstimate.fromJson(Map<String, dynamic> json) =>
      LightningCrossChainEstimate(
        amountSats: (json['sat'] as num?)?.toInt() ?? 0,
        costSats: (json['cost_sats'] as num?)?.toInt(),
        rate: (json['rate'] as num?)?.toDouble(),
        spread: (json['spread'] as num?)?.toDouble(),
        waitSeconds: (json['wait_seconds'] as num?)?.toInt(),
        paymentHash: json['payment_hash']?.toString(),
      );
}

/// Esito di un pagamento cross-chain.
class LightningCrossChainResult {
  const LightningCrossChainResult({
    required this.state,
    required this.preimage,
    required this.paymentHash,
    this.amountMsat,
    this.feesPaid = 0,
    this.paySats,
  });

  /// `settled` = il bridge ha pagato la fattura SHA-256 e noi la hold invoice.
  final String state;

  /// Prova del pagamento sulla nostra chain.
  final String preimage;
  final String paymentHash;

  /// Importo (msat) della hold invoice, se il nodo lo riporta.
  final int? amountMsat;

  /// Fee di routing pagate in msat.
  final int feesPaid;

  /// Sat addebitati dal bridge (quanto è costato il pagamento).
  final int? paySats;

  bool get isSettled => state == 'settled';

  factory LightningCrossChainResult.fromJson(Map<String, dynamic> json) =>
      LightningCrossChainResult(
        state: '${json['state'] ?? ''}',
        preimage: '${json['preimage'] ?? ''}',
        paymentHash: '${json['payment_hash'] ?? ''}',
        amountMsat: (json['amount_msat'] as num?)?.toInt(),
        feesPaid: (json['fees_paid'] as num?)?.toInt() ?? 0,
        paySats: (json['pay_sats'] as num?)?.toInt(),
      );
}
