/// Esito di uno splice di canale (NCC `splice_channel`, estensione del bridge).
///
/// // PERCHÉ: lo splice ridimensiona un canale **senza chiuderlo** — l'utente
/// // resta online, paga una sola transazione on-chain e non perde liquidità.
/// // `amountSats` positivo = fondi aggiunti al canale (splice-in), negativo =
/// // fondi riportati sull'on-chain del nodo (splice-out).
class LightningSpliceResult {
  const LightningSpliceResult({
    required this.channelId,
    required this.amountSats,
    this.txid,
  });

  final String channelId;

  /// Sat aggiunti (positivo) o rimossi (negativo) dal canale.
  final int amountSats;

  /// Txid della transazione di splice, se il nodo lo espone subito.
  final String? txid;

  bool get isSpliceIn => amountSats > 0;
  int get amountAbsSats => amountSats.abs();

  factory LightningSpliceResult.fromJson(Map<String, dynamic> json) =>
      LightningSpliceResult(
        channelId: '${json['channel_id'] ?? ''}',
        amountSats: (json['amount_sats'] as num?)?.toInt() ?? 0,
        txid: json['txid']?.toString(),
      );
}

/// Stima della fee on-chain di uno splice-in (`estimate_splice`).
///
/// // PERCHÉ: l'utente deve vedere il costo PRIMA di confermare. `feeSats` è
/// // la parte on-chain (input/output scelti + resto); non include la fee della
/// // transazione di commitment, che il nodo paga secondo la sua policy.
class LightningSpliceEstimate {
  const LightningSpliceEstimate({
    required this.amountSats,
    required this.feerate,
    this.feeSats,
    this.estimatedWeight,
    this.feeratePerKw,
  });

  /// Sat che verrebbero aggiunti al canale.
  final int amountSats;

  /// Feerate richiesta (`urgent`, `normal`, `slow` o `<n>perkw`).
  final String feerate;

  /// Fee on-chain stimata in sat (null se il nodo non la espone).
  final int? feeSats;

  /// Peso stimato della transazione (weight units).
  final int? estimatedWeight;

  /// Feerate effettiva in sat/kW usata dal nodo.
  final int? feeratePerKw;

  factory LightningSpliceEstimate.fromJson(Map<String, dynamic> json) =>
      LightningSpliceEstimate(
        amountSats: (json['amount_sats'] as num?)?.toInt() ?? 0,
        feerate: '${json['feerate'] ?? 'normal'}',
        feeSats: (json['fee_sats'] as num?)?.toInt(),
        estimatedWeight: (json['estimated_weight'] as num?)?.toInt(),
        feeratePerKw: (json['feerate_per_kw'] as num?)?.toInt(),
      );
}
