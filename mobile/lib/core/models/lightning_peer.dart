/// Peer del nodo Lightning (spec dln NCC `list_peers`).
class LightningPeer {
  const LightningPeer({
    required this.id,
    this.alias,
    required this.connected,
    required this.numChannels,
    this.addresses = const [],
    this.remoteAddr,
  });

  final String id;
  final String? alias;
  final bool connected;
  final int numChannels;

  /// Indirizzi annunciati dal peer (es. `140.99.254.11:9735`).
  final List<String> addresses;

  /// Da dove è connesso ora (es. `1.2.3.4:1691`), presente solo se connesso.
  final String? remoteAddr;

  /// Etichetta da mostrare: alias se disponibile, altrimenti la pubkey.
  String get label => (alias == null || alias!.isEmpty) ? id : alias!;

  factory LightningPeer.fromJson(Map<String, dynamic> json) => LightningPeer(
        id: '${json['id'] ?? ''}',
        alias: (json['alias']?.toString().isEmpty ?? true)
            ? null
            : json['alias']?.toString(),
        connected: json['connected'] as bool? ?? false,
        numChannels: (json['num_channels'] as num?)?.toInt() ?? 0,
        addresses:
            (json['addresses'] as List? ?? const []).map((a) => '$a').toList(),
        remoteAddr: json['remote_addr']?.toString(),
      );
}
