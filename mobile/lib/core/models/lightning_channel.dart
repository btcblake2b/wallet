/// Canale Lightning del nodo remoto (NCC `list_channels` → LdkChannelInfo).
///
/// Unità: il protocollo (spec dln) usa **msat** per saldi e capacità — i getter
/// `*Sats` fanno la conversione per la UI (÷1000), così l'unità resta unica e
/// il bug "msat mostrati come sat" non può ripetersi.
class LightningChannel {
  const LightningChannel({
    required this.id,
    this.shortChannelId,
    required this.peerPubkey,
    this.peerAlias,
    required this.state,
    required this.isPrivate,
    required this.localBalance,
    required this.remoteBalance,
    required this.capacity,
    this.fundingTxid,
    this.confirmations,
    this.feeBaseMsat,
    this.feePpm,
    this.htlcCount,
    this.spendableMsat,
    this.receivableMsat,
    this.peerConnected,
    this.status,
  });

  final String id;
  final String? shortChannelId;
  final String peerPubkey;

  /// Alias del peer, se il nodo lo espone (`listpeerchannels.alias`).
  final String? peerAlias;

  /// Stato ldk-node (es. `Usable`, `PendingOpen`, `Closed`…): stringa grezza.
  final String state;
  final bool isPrivate;

  /// Valori in msat (convenzione dln/NWC).
  final int localBalance;
  final int remoteBalance;
  final int capacity;
  final String? fundingTxid;
  final int? confirmations;

  /// Fee annunciate dal nostro lato (base + ppm).
  final int? feeBaseMsat;
  final int? feePpm;

  /// HTLC pending (numero).
  final int? htlcCount;

  /// Spendibile / ricevibile stimati dal nodo (msat).
  final int? spendableMsat;
  final int? receivableMsat;

  /// True se il peer è online.
  final bool? peerConnected;

  /// Righe di stato (`CHANNELD_NORMAL:Funding transaction locked…`).
  final List<String>? status;

  /// True se il canale è pronto all'uso (stato ldk-node `Usable`).
  bool get isUsable => state.toLowerCase() == 'usable';

  /// True se il canale è chiuso (stato ldk-node `Closed`): da I4a i chiusi
  /// NON contano come canali in UI — sono storia (v. Movimenti).
  bool get isClosed => state.toLowerCase() == 'closed';

  /// Valori in satoshi per la UI.
  int get capacitySats => capacity ~/ 1000;
  int get localBalanceSats => localBalance ~/ 1000;
  int get remoteBalanceSats => remoteBalance ~/ 1000;
  int? get feeBaseSats => feeBaseMsat == null ? null : feeBaseMsat! ~/ 1000;
  int? get spendableSats =>
      spendableMsat == null ? null : spendableMsat! ~/ 1000;
  int? get receivableSats =>
      receivableMsat == null ? null : receivableMsat! ~/ 1000;

  /// Etichetta del peer: alias se presente, altrimenti null.
  String? get peerLabel =>
      (peerAlias == null || peerAlias!.isEmpty) ? null : peerAlias;

  factory LightningChannel.fromJson(Map<String, dynamic> json) =>
      LightningChannel(
        id: '${json['id'] ?? ''}',
        shortChannelId: json['short_channel_id']?.toString(),
        peerPubkey: '${json['peer_pubkey'] ?? ''}',
        peerAlias: (json['alias']?.toString().isEmpty ?? true)
            ? null
            : json['alias']?.toString(),
        state: '${json['state'] ?? 'Unknown'}',
        isPrivate: json['is_private'] as bool? ?? false,
        localBalance: (json['local_balance'] as num?)?.toInt() ?? 0,
        remoteBalance: (json['remote_balance'] as num?)?.toInt() ?? 0,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        fundingTxid: json['funding_txid']?.toString(),
        confirmations: (json['confirmations'] as num?)?.toInt(),
        feeBaseMsat: (json['fee_base_msat'] as num?)?.toInt(),
        feePpm: (json['fee_proportional_millionths'] as num?)?.toInt(),
        htlcCount: (json['htlc_count'] as num?)?.toInt(),
        spendableMsat: (json['spendable_msat'] as num?)?.toInt(),
        receivableMsat: (json['receivable_msat'] as num?)?.toInt(),
        peerConnected: json['peer_connected'] as bool?,
        status: (json['status'] as List?)?.map((s) => '$s').toList(),
      );
}

/// Canali "vivi" (esclude i chiusi).
///
/// // PERCHÉ (I4a): `list_channels` continua a elencare il canale appena
/// chiuso (state `Closed`, con saldi congelati) finché il nodo non lo
/// dimentica: mostrarlo gonfierebbe conteggi e liquidità (spendibile/
/// ricevibile stantii). Il filtro vive nei punti di visualizzazione, così il
/// service resta fedele ai dati del nodo.
List<LightningChannel> openOnly(List<LightningChannel> channels) =>
    channels.where((c) => !c.isClosed).toList(growable: false);
