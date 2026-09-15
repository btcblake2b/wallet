/// Percorso verso una destinazione Lightning (spec dln `get_route`).
///
/// // PERCHÉ: è uno strumento di diagnosi — risponde alla domanda "se pagassi
/// adesso, da dove passerebbe e quanto costerebbe?" senza muovere fondi.
class LightningRoute {
  const LightningRoute({
    this.hops = const [],
    this.feeMsat = 0,
    this.totalDelay,
  });

  final List<LightningRouteHop> hops;

  /// Fee totali della rotta (dal primo hop, che porta l'importo maggiorato).
  final int feeMsat;

  /// CLTV chiesto al primo hop.
  final int? totalDelay;

  int get feeSats => feeMsat ~/ 1000;
  bool get isEmpty => hops.isEmpty;

  factory LightningRoute.fromJson(Map<String, dynamic> json) =>
      LightningRoute(
        hops: [
          for (final h in (json['route'] as List? ?? const []))
            LightningRouteHop.fromJson((h as Map).cast<String, dynamic>()),
        ],
        feeMsat: (json['fee_msat'] as num?)?.toInt() ?? 0,
        totalDelay: (json['total_delay'] as num?)?.toInt(),
      );
}

/// Singolo hop di una rotta.
class LightningRouteHop {
  const LightningRouteHop({
    required this.id,
    this.channel,
    this.direction,
    this.amountMsat = 0,
    this.delay,
    this.style,
  });

  final String id;
  final String? channel;
  final int? direction;

  /// Importo da consegnare a questo hop (il primo include le fee di rotta).
  final int amountMsat;
  final int? delay;
  final String? style;

  int get amountSats => amountMsat ~/ 1000;
  String get shortId => id.length <= 16 ? id : '${id.substring(0, 16)}…';

  factory LightningRouteHop.fromJson(Map<String, dynamic> json) =>
      LightningRouteHop(
        id: '${json['id'] ?? ''}',
        channel: json['channel']?.toString(),
        direction: (json['direction'] as num?)?.toInt(),
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        delay: (json['delay'] as num?)?.toInt(),
        style: json['style']?.toString(),
      );
}
