/// Saldo del nodo Lightning (NIP-47 `get_balance`).
///
/// `onchainMsat`/`lightningMsat` = breakdown additivo (estensione I1 del
/// bridge): se assenti la UI usa il totale `balanceMsat`.
class LightningBalance {
  const LightningBalance({
    required this.balanceMsat,
    this.onchainMsat,
    this.lightningMsat,
  });

  /// Saldo totale in millisatoshi (unità NIP-47).
  final int balanceMsat;

  /// Parte on-chain (msat) — null se il nodo non la espone.
  final int? onchainMsat;

  /// Parte Lightning (msat) — null se il nodo non la espone.
  final int? lightningMsat;

  factory LightningBalance.fromJson(Map<String, dynamic> json) =>
      LightningBalance(
        balanceMsat: (json['balance'] as num?)?.toInt() ?? 0,
        onchainMsat: (json['onchain'] as num?)?.toInt(),
        lightningMsat: (json['lightning'] as num?)?.toInt(),
      );

  /// Equivalente in satoshi (arrotondato per difetto).
  int get balanceSats => balanceMsat ~/ 1000;

  /// Saldo Lightning in satoshi (fallback sul totale).
  int get lightningSats => (lightningMsat ?? balanceMsat) ~/ 1000;

  /// Saldo on-chain in satoshi — null se non esposto dal nodo.
  int? get onchainSats => onchainMsat == null ? null : onchainMsat! ~/ 1000;
}
