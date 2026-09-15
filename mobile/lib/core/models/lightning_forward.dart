/// Forwarding del nodo (spec dln `list_forwards`).
///
/// ⚠️ Sul nodo di riferimento non è ancora passato un forward: i campi
/// dell'elemento sono quelli documentati da CLN (`status`, `fee_msat` solo per
/// i forward risolti) e il modello li tratta tutti come opzionali.
class LightningForward {
  const LightningForward({
    this.inChannel,
    this.outChannel,
    this.inMsat = 0,
    this.outMsat = 0,
    this.feeMsat,
    this.status = 'unknown',
    this.receivedTime,
    this.resolvedTime,
  });

  final String? inChannel;
  final String? outChannel;
  final int inMsat;
  final int outMsat;

  /// Fee guadagnata: presente solo quando il forward è risolto (settled).
  final int? feeMsat;

  /// `offered`, `settled`, `failed`, …
  final String status;
  final int? receivedTime;
  final int? resolvedTime;

  int get inSats => inMsat ~/ 1000;
  int? get feeSats => feeMsat == null ? null : feeMsat! ~/ 1000;
  bool get isSettled => status == 'settled';
  bool get isFailed => status == 'failed';

  factory LightningForward.fromJson(Map<String, dynamic> json) =>
      LightningForward(
        inChannel: json['in_channel']?.toString(),
        outChannel: json['out_channel']?.toString(),
        inMsat: (json['in_msat'] as num?)?.toInt() ?? 0,
        outMsat: (json['out_msat'] as num?)?.toInt() ?? 0,
        feeMsat: (json['fee_msat'] as num?)?.toInt(),
        status: '${json['status'] ?? 'unknown'}',
        receivedTime: (json['received_time'] as num?)?.toInt(),
        resolvedTime: (json['resolved_time'] as num?)?.toInt(),
      );
}
