/// Informazioni sul nodo Lightning (NIP-47 `get_info`, estesa dln).
class LightningNodeInfo {
  const LightningNodeInfo({
    this.alias,
    this.pubkey,
    this.network,
    this.methods,
    this.blockHeight,
    this.color,
    this.version,
    this.numPeers,
    this.numPeersConnected,
    this.numActiveChannels,
    this.numPendingChannels,
  });

  final String? alias;
  final String? pubkey;
  final String? network;

  /// Metodi supportati dichiarati dal nodo (capabilities).
  final List<String>? methods;

  /// Altezza di blocco del nodo (per il dashboard).
  final int? blockHeight;

  /// Colore identificativo del nodo (hex, es. `0203a0`).
  final String? color;

  /// Versione del nodo (es. `v26.06.7-blake2b.2`).
  final String? version;

  /// Peer connessi, canali attivi e in attesa (contatori da `getinfo`).
  ///
  /// NB: `numPeers` è il conteggio CLN dei peer REGISTRATI (peer table, anche
  /// disconnessi); `numPeersConnected` (I4a, campo additivo del bridge) è il
  /// valore da mostrare in UI.
  final int? numPeers;
  final int? numPeersConnected;
  final int? numActiveChannels;
  final int? numPendingChannels;

  factory LightningNodeInfo.fromJson(Map<String, dynamic> json) =>
      LightningNodeInfo(
        alias: json['alias']?.toString(),
        pubkey: json['pubkey']?.toString(),
        network: json['network']?.toString(),
        methods: (json['methods'] as List?)?.map((m) => '$m').toList(),
        // PERCHÉ: accetto sia `block_height` (spec dln/NIP-47) sia
        // `blockheight` (payload storici del bridge).
        blockHeight: (json['block_height'] as num?)?.toInt() ??
            (json['blockheight'] as num?)?.toInt(),
        color: json['color']?.toString(),
        version: json['version']?.toString(),
        numPeers: (json['num_peers'] as num?)?.toInt(),
        numPeersConnected: (json['num_peers_connected'] as num?)?.toInt(),
        numActiveChannels: (json['num_active_channels'] as num?)?.toInt(),
        numPendingChannels: (json['num_pending_channels'] as num?)?.toInt(),
      );
}
