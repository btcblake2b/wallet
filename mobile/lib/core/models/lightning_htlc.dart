/// HTLC del canale (spec dln `get_pending_htlcs` → CLN `listhtlcs`).
///
/// // PERCHÉ: `listhtlcs` sul nodo è uno storico (contiene anche HTLC risolti):
/// il flag [pending] (derivato dal bridge dallo state, assenza di
/// `ACK_REVOCATION`) è ciò che distingue "in corso" da "concluso".
class LightningHtlc {
  const LightningHtlc({
    required this.paymentHash,
    required this.amountMsat,
    required this.state,
    required this.pending,
    this.id,
    this.shortChannelId,
    this.direction,
    this.expiry,
  });

  final int? id;
  final String? shortChannelId;
  final String paymentHash;
  final int amountMsat;

  /// `in` | `out` (dal punto di vista del nodo).
  final String? direction;

  /// Stato grezzo del nodo (es. `RCVD_REMOVE_ACK_REVOCATION`).
  final String state;

  /// True se l'HTLC non ha ancora completato il ciclo (`ACK_REVOCATION`).
  final bool pending;

  /// Altezza di blocco di scadenza (time lock).
  final int? expiry;

  int get amountSats => amountMsat ~/ 1000;

  bool get isIncoming => direction == 'in';

  factory LightningHtlc.fromJson(Map<String, dynamic> json) => LightningHtlc(
        id: (json['id'] as num?)?.toInt(),
        shortChannelId: json['short_channel_id']?.toString(),
        paymentHash: '${json['payment_hash'] ?? ''}',
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        direction: json['direction']?.toString(),
        state: '${json['state'] ?? 'unknown'}',
        // PERCHÉ: se il bridge non manda il flag, lo derivo allo stesso modo
        // (un payload vecchio non deve far apparire "in corso" un HTLC chiuso).
        pending: (json['pending'] as bool?) ??
            !'${json['state'] ?? ''}'.contains('ACK_REVOCATION'),
        expiry: (json['expiry'] as num?)?.toInt(),
      );
}
