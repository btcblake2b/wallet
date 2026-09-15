/// Policy di routing di un canale (spec dln `get_channel_fees`).
///
/// // PERCHÉ: base/ppm sono le fee che il canale annuncia alla rete, `htlcMin`/
/// `htlcMax` limitano cosa il canale accetta di instradare, `cltvDelta` è il
/// delta di scadenza pubblicato. `cltvDelta` è **solo lettura**: `setchannel`
/// non ha un parametro per modificarlo.
class LightningChannelFees {
  const LightningChannelFees({
    required this.id,
    this.shortChannelId,
    this.feeBaseMsat = 0,
    this.feePpm = 0,
    this.htlcMinMsat,
    this.htlcMaxMsat,
    this.cltvDelta,
    this.ourReserveMsat,
    this.theirReserveMsat,
    this.toSelfDelay,
    this.warning,
  });

  final String id;
  final String? shortChannelId;

  /// Fee fissa in msat (protocollo); la UI mostra i sat.
  final int feeBaseMsat;

  /// Fee proporzionale in ppm.
  final int feePpm;

  final int? htlcMinMsat;
  final int? htlcMaxMsat;

  /// Delta di scadenza CLTV pubblicato (solo lettura).
  final int? cltvDelta;

  /// Riserve dei due lati (msat) e delay di auto-risoluzione.
  final int? ourReserveMsat;
  final int? theirReserveMsat;
  final int? toSelfDelay;

  /// Avviso restituito dal nodo dopo una modifica (es. limite alzato dal peer).
  final String? warning;

  int get feeBaseSats => feeBaseMsat ~/ 1000;
  int? get htlcMinSats => htlcMinMsat == null ? null : htlcMinMsat! ~/ 1000;
  int? get htlcMaxSats => htlcMaxMsat == null ? null : htlcMaxMsat! ~/ 1000;
  int? get reserveSats =>
      ourReserveMsat == null ? null : ourReserveMsat! ~/ 1000;

  factory LightningChannelFees.fromJson(Map<String, dynamic> json) =>
      LightningChannelFees(
        id: '${json['id'] ?? ''}',
        shortChannelId: json['short_channel_id']?.toString(),
        feeBaseMsat: (json['fee_base_msat'] as num?)?.toInt() ?? 0,
        feePpm: (json['fee_proportional_millionths'] as num?)?.toInt() ?? 0,
        htlcMinMsat: (json['htlc_min_msat'] as num?)?.toInt(),
        htlcMaxMsat: (json['htlc_max_msat'] as num?)?.toInt(),
        cltvDelta: (json['cltv_delta'] as num?)?.toInt(),
        ourReserveMsat: (json['our_reserve_msat'] as num?)?.toInt(),
        theirReserveMsat: (json['their_reserve_msat'] as num?)?.toInt(),
        toSelfDelay: (json['to_self_delay'] as num?)?.toInt(),
        warning: json['warning']?.toString(),
      );
}
