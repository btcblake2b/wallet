/// Stime fee on-chain del nodo (spec dln `estimate_onchain_fees`).
///
/// Shape provvisoria (sat/vB): dln dichiara il metodo ma non l'ha ancora
/// implementato; il bridge lo espone con tre livelli.
class LightningOnchainFees {
  const LightningOnchainFees({
    this.minSatVb,
    this.economicalSatVb,
    this.prioritySatVb,
  });

  final int? minSatVb;
  final int? economicalSatVb;
  final int? prioritySatVb;

  /// True se il nodo non fornisce alcun livello utilizzabile.
  bool get isEmpty =>
      minSatVb == null && economicalSatVb == null && prioritySatVb == null;

  factory LightningOnchainFees.fromJson(Map<String, dynamic> json) =>
      LightningOnchainFees(
        minSatVb: (json['min'] as num?)?.toInt(),
        economicalSatVb: (json['economical'] as num?)?.toInt(),
        prioritySatVb: (json['priority'] as num?)?.toInt(),
      );
}
