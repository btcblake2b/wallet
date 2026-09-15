/// Nodo della rete Lightning visto dal gossip (spec dln `get_node_info`).
///
/// // PERCHÉ: serve a dare un nome alla controparte (alias) prima di inviare
/// fondi e a mostrare indirizzi/ultimo annuncio nel dettaglio rete.
class LightningNetworkNode {
  const LightningNetworkNode({
    required this.nodeId,
    this.alias,
    this.colorHex,
    this.lastTimestamp,
    this.features,
    this.addresses = const [],
  });

  final String nodeId;

  /// Alias annunciato (spesso coincide con il troncamento del pubkey).
  final String? alias;

  /// Colore RGB esadecimale (es. `f56835`), senza `#`.
  final String? colorHex;

  /// Timestamp Unix dell'ultimo annuncio nel gossip.
  final int? lastTimestamp;
  final String? features;
  final List<LightningNodeEndpoint> addresses;

  String get shortNodeId =>
      nodeId.length <= 16 ? nodeId : '${nodeId.substring(0, 16)}…';

  /// Nome da mostrare: alias se c'è, altrimenti l'id troncato.
  String get displayName {
    final a = alias?.trim() ?? '';
    return a.isEmpty ? shortNodeId : a;
  }

  factory LightningNetworkNode.fromJson(Map<String, dynamic> json) =>
      LightningNetworkNode(
        nodeId: '${json['node_id'] ?? ''}',
        alias: json['alias']?.toString(),
        colorHex: json['color']?.toString(),
        lastTimestamp: (json['last_timestamp'] as num?)?.toInt(),
        features: json['features']?.toString(),
        addresses: [
          for (final a in (json['addresses'] as List? ?? const []))
            LightningNodeEndpoint.fromJson((a as Map).cast<String, dynamic>()),
        ],
      );
}

/// Indirizzo annunciato da un nodo nel gossip (ipv4, ipv6, torv3, dns…).
///
/// // PERCHÉ: il nome evita la collisione con `LightningNodeAddress` (l'indirizzo
/// di deposito del PROPRIO nodo): qui si parla di come raggiungere un TERZO.
class LightningNodeEndpoint {
  const LightningNodeEndpoint({
    required this.type,
    required this.address,
    this.port,
  });

  final String type;
  final String address;
  final int? port;

  /// Forma compatta per la UI: `140.99.254.11:9735`.
  String get label => port == null ? address : '$address:$port';

  factory LightningNodeEndpoint.fromJson(Map<String, dynamic> json) =>
      LightningNodeEndpoint(
        type: '${json['type'] ?? ''}',
        address: '${json['address'] ?? ''}',
        port: (json['port'] as num?)?.toInt(),
      );
}
