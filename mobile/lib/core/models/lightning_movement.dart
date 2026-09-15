/// Tipo di movimento del nodo Lightning.
///
/// // PERCHÉ: il bridge normalizza i tag di `bkpr` in categorie stabili; la UI
/// traduce solo queste, senza conoscere la contabilità del nodo. Tutto ciò che
/// non è riconosciuto ricade in `other` (mai un errore a schermo).
enum LightningMovementType {
  deposit('deposit'),
  withdrawal('withdrawal'),
  channelOpen('channel_open'),
  channelClose('channel_close'),
  invoice('invoice'),
  onchainFee('onchain_fee'),
  forward('forward'),
  other('other');

  const LightningMovementType(this.value);

  /// Valore scambiato sul filo (snake_case, come lo invia il bridge).
  final String value;

  static LightningMovementType fromValue(String value) =>
      LightningMovementType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => LightningMovementType.other,
      );
}

/// Movimento del nodo: on-chain e Lightning in un'unica lista.
///
/// Unità: importo in **msat** (convenzione protocollo) con getter `amountSats`
/// per la UI; il verso è dato da [isIncoming], non dal segno dell'importo.
class LightningMovement {
  const LightningMovement({
    required this.id,
    required this.type,
    required this.isIncoming,
    required this.amountMsat,
    required this.timestamp,
    this.blockHeight,
    this.outpoint,
    this.description,
  });

  final String id;
  final LightningMovementType type;

  /// True se i fondi sono entrati nel nodo (credit), false se sono usciti.
  final bool isIncoming;

  /// Importo assoluto in msat.
  final int amountMsat;

  /// Secondi epoch (UTC) del movimento.
  final int timestamp;
  final int? blockHeight;
  final String? outpoint;
  final String? description;

  /// Importo in satoshi per la UI.
  int get amountSats => amountMsat ~/ 1000;

  /// Data locale del movimento (il protocollo porta secondi epoch UTC).
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true,
      ).toLocal();

  factory LightningMovement.fromJson(Map<String, dynamic> json) =>
      LightningMovement(
        id: '${json['id'] ?? ''}',
        type: LightningMovementType.fromValue('${json['type'] ?? ''}'),
        // PERCHÉ: default "in" — il bridge è esplicito, ma un payload senza
        // `direction` non deve trasformare un accredito in un addebito.
        isIncoming: '${json['direction'] ?? 'in'}' != 'out',
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        blockHeight: (json['blockheight'] as num?)?.toInt(),
        outpoint: json['outpoint']?.toString(),
        description: json['description']?.toString(),
      );
}
