import 'dart:async';
import 'dart:math';

import '../../models/lightning_balance.dart';
import '../../models/lightning_channel.dart';
import '../../models/lightning_channel_fees.dart';
import '../../models/lightning_connection.dart';
import '../../models/lightning_forward.dart';
import '../../models/lightning_htlc.dart';
import '../../models/lightning_invoice.dart';
import '../../models/lightning_invoice_record.dart';
import '../../models/lightning_keysend_result.dart';
import '../../models/lightning_movement.dart';
import '../../models/lightning_network_node.dart';
import '../../models/lightning_node_address.dart';
import '../../models/lightning_node_info.dart';
import '../../models/lightning_node_stats.dart';
import '../../models/lightning_onchain_fees.dart';
import '../../models/lightning_onchain_result.dart';
import '../../models/lightning_peer.dart';
import '../../models/lightning_payment_record.dart';
import '../../models/lightning_payment_result.dart';
import '../../models/lightning_route.dart';
import '../../models/lightning_utxo.dart';
import '../nostr/nostr_crypto.dart';
import 'lightning_service.dart';

/// Mock del servizio Lightning: stato in memoria, nessuna rete.
///
/// // PERCHÉ: permette di sviluppare e testare la UI (widget test, demo)
/// prima che il nodo blake2b sia disponibile — stessa interfaccia del client
/// reale, zero codice nativo.
class LightningServiceMock implements LightningService {
  LightningServiceMock({
    this.latency = const Duration(milliseconds: 20),
    this.supportedMethods,
    int channelCount = 1,
    int closedChannelCount = 0,
    int movementCount = 4,
    int forwardCount = 0,
    this.peerDisconnected = false,
    this.inboundOverrideMsat,
    this.onchainFeesOverride,
  }) {
    // PERCHÉ: canali e movimenti sono generati — i test delle liste lunghe
    // (e della paginazione) non devono dipendere da fixture duplicate a mano.
    _channels = List.generate(
      channelCount < 0 ? 0 : channelCount,
      _mockChannel,
    );
    // PERCHÉ (I4a): i test verificano che un canale CHIUSO non compaia in
    // lista né nei conteggi — è storia (v. Movimenti), non un canale.
    if (closedChannelCount > 0) {
      _channels.addAll(List.generate(closedChannelCount, _mockClosedChannel));
    }
    // PERCHÉ (I4a): peer REGISTRATO ma non connesso → `numPeersConnected`
    // resta 0 mentre `numPeers` resta 1 (semantica CLN).
    _peers = <LightningPeer>[
      LightningPeer(
        id: '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389',
        alias: 'mock-peer',
        connected: !peerDisconnected,
        numChannels: 1,
        addresses: const ['140.99.254.11:9735'],
      ),
    ];
    _movements = List.generate(
      movementCount < 0 ? 0 : movementCount,
      _mockMovement,
    );
    // PERCHÉ: il nodo di riferimento non ha ancora instradato nulla: il mock
    // parte vuoto e i test chiedono i forward esplicitamente.
    _forwards = List.generate(
      forwardCount < 0 ? 0 : forwardCount,
      _mockForward,
    );
  }

  /// Se valorizzato, forza la liquidità in entrata del primo canale (test).
  final int? inboundOverrideMsat;

  /// Se true, il peer del mock risulta registrato ma disconnesso (test I4a).
  final bool peerDisconnected;

  /// Se valorizzato, sostituisce le stime fee on-chain (test): serve a
  /// riprodurre il caso reale in cui più livelli hanno lo stesso sat/vB.
  final LightningOnchainFees? onchainFeesOverride;

  /// Latenza simulata per ogni operazione (per test/progress in UI).
  final Duration latency;

  /// Metodi dichiarati dal nodo finto (`get_info.methods`).
  /// null = nodo legacy senza elenco → la UI assume supporto (retrocompat).
  final List<String>? supportedMethods;

  LightningConnection? _connection;
  LightningConnectionState _state = LightningConnectionState.disconnected;
  final StreamController<LightningConnectionState> _stateController =
      StreamController<LightningConnectionState>.broadcast();
  final StreamController<void> _notifications =
      StreamController<void>.broadcast();

  int _balanceMsat = 150000000; // 150k sat di prova
  int _onchainBalanceMsat = 25000000; // 25k sat on-chain di prova

  /// Indice dell'ultima chiave indirizzo generata (continua 1, 2, …).
  int _nextAddressIndex = 6;

  /// Indice dell'ultima fattura creata (label e created_index del mock).
  int _nextInvoiceIndex = 2;

  /// Indice dell'ultimo pagamento registrato (created_index del mock).
  int _nextPayIndex = 0;

  /// Policy di routing per canale (modificabile: i test verificano l'effetto).
  final Map<String, LightningChannelFees> _fees = {
    'mock_channel_1': const LightningChannelFees(
      id: 'mock_channel_1',
      shortChannelId: '1000x1x0',
      feeBaseMsat: 1000,
      feePpm: 10,
      htlcMinMsat: 1000,
      htlcMaxMsat: 150000000,
      cltvDelta: 34,
      ourReserveMsat: 1500000,
      theirReserveMsat: 1500000,
      toSelfDelay: 144,
    ),
  };

  /// Pagamenti in uscita del mock (il primo ha una fee di 2 sat).
  final List<LightningPaymentRecord> _pays = [
    LightningPaymentRecord(
      paymentHash: 'cc33${'55' * 30}',
      amountMsat: 2000000,
      amountSentMsat: 2002000,
      status: 'complete',
      destination: '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389',
      createdAt: 1789364186,
      completedAt: 1789364187,
      createdIndex: 1,
    ),
  ];

  /// Storico fatture del mock: la prima è già scaduta, la seconda in attesa.
  final List<LightningInvoiceRecord> _invoices = [
    LightningInvoiceRecord(
      paymentHash: 'aabbccdd${'11' * 24}',
      label: 'nwcb-mock-1',
      amountMsat: 21000000,
      status: 'unpaid',
      description: 'mock scaduta',
      expiresAt: DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
      createdIndex: 1,
    ),
    LightningInvoiceRecord(
      paymentHash: 'eeff0011${'22' * 24}',
      label: 'nwcb-mock-2',
      amountMsat: 5000000,
      status: 'unpaid',
      description: 'mock in attesa',
      expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      createdIndex: 2,
    ),
  ];

  /// Canali del mock (`channelCount`, default 1): il primo è il canale
  /// "storico" dei test I1/I2 (150k sat, 89k spendibili, 59k ricevibili).
  late final List<LightningChannel> _channels;

  /// Forwarding del mock (`forwardCount`, default 0 — come il nodo reale).
  late final List<LightningForward> _forwards;

  LightningChannel _mockChannel(int index) {
    final receivable = inboundOverrideMsat ?? (index == 0 ? 59000000 : 49000000);
    if (index == 0) {
      return LightningChannel(
        id: 'mock_channel_1',
        shortChannelId: '1000x1x0',
        peerPubkey: '02mock_peer_pubkey_000000000000000000000000000000',
        peerAlias: 'mock-peer',
        state: 'Usable',
        isPrivate: false,
        localBalance: 90000000,
        remoteBalance: 60000000,
        capacity: 150000000,
        confirmations: 6,
        feeBaseMsat: 1000,
        feePpm: 10,
        htlcCount: 0,
        spendableMsat: 89000000,
        receivableMsat: receivable,
        peerConnected: true,
      );
    }
    return LightningChannel(
      id: 'mock_channel_${index + 1}',
      shortChannelId: '1000x${index + 1}x0',
      peerPubkey: '02mock_peer_pubkey_${index}_0000000000000000000000',
      peerAlias: 'mock-peer-$index',
      state: 'Usable',
      isPrivate: true,
      localBalance: 50000000,
      remoteBalance: 50000000,
      capacity: 100000000,
      confirmations: 3,
      feeBaseMsat: 1000,
      feePpm: 10,
      htlcCount: 0,
      spendableMsat: 49000000,
      receivableMsat: receivable,
      peerConnected: true,
    );
  }

  /// Canale chiuso del mock: stato `Closed` con saldi congelati (come il nodo
  /// reale dopo il mutual close, finché non lo dimentica).
  LightningChannel _mockClosedChannel(int index) => LightningChannel(
        id: 'mock_channel_closed_$index',
        shortChannelId: '1000x9${index + 1}x0',
        peerPubkey: '02mock_closed_peer_${index}_000000000000000000000000',
        peerAlias: 'mock-closed-$index',
        state: 'Closed',
        isPrivate: false,
        localBalance: 15000000,
        remoteBalance: 1000000,
        capacity: 16000000,
        confirmations: 1,
        htlcCount: 0,
        spendableMsat: 10148000,
        receivableMsat: 454000,
        peerConnected: false,
        status: const ['ONCHAIN:Tracking mutual close transaction'],
      );

  late final List<LightningPeer> _peers;

  /// Movimenti del mock (`movementCount`, default 4), dal più recente.
  late final List<LightningMovement> _movements;

  LightningMovement _mockMovement(int index) {
    const types = [
      LightningMovementType.invoice,
      LightningMovementType.deposit,
      LightningMovementType.onchainFee,
      LightningMovementType.channelOpen,
    ];
    final type = types[index % types.length];
    return LightningMovement(
      id: 'mock-mov-$index',
      type: type,
      // Solo il deposito è in entrata: copre entrambi i colori/segni della tile.
      isIncoming: type == LightningMovementType.deposit,
      amountMsat: 1000000 + index * 1000,
      timestamp: 1789364186 - index * 3600,
      blockHeight: type == LightningMovementType.onchainFee ? 971913 : null,
    );
  }

  @override
  LightningConnectionState get connectionState => _state;

  @override
  bool get isConnected => _state == LightningConnectionState.connected;

  @override
  Stream<LightningConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<void> get notifications => _notifications.stream;

  @override
  LightningConnection? get connection => _connection;

  @override
  Future<void> connect(LightningConnection connection) async {
    _setState(LightningConnectionState.connecting);
    await Future<void>.delayed(latency);
    _connection = connection;
    _setState(LightningConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    await Future<void>.delayed(latency);
    _connection = null;
    _setState(LightningConnectionState.disconnected);
  }

  @override
  Future<LightningNodeInfo> getInfo() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    return LightningNodeInfo(
      alias: 'mock-dln-node',
      network: 'bitcoin',
      methods: supportedMethods,
      // PERCHÉ (I3): la dashboard "Gestione nodo" legge identità e contatori
      // dalla stessa chiamata — il mock deve esporli come il bridge reale.
      pubkey:
          '02043a9147488f237fc446daf17fca2a9fb0b4cf7ae7c952427aef8f20d97b0436',
      color: '0203a0',
      version: 'v26.06.7-blake2b.2',
      blockHeight: 971913,
      numPeers: _peers.length,
      // I4a: contatori "significativi" come nel bridge nuovo.
      numPeersConnected: _peers.where((p) => p.connected).length,
      numActiveChannels: _channels.where((c) => !c.isClosed).length,
      numPendingChannels: 0,
    );
  }

  @override
  Future<int> getBalanceMsat() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    return _balanceMsat;
  }

  @override
  Future<LightningInvoice> makeInvoice({
    required int amountMsat,
    String? description,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    final invoice = LightningInvoice(
      bolt11: 'lnbcrt1mock${DateTime.now().millisecondsSinceEpoch}',
      paymentHash: NostrCrypto.randomHex32(),
      amountMsat: amountMsat,
      description: description,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    // PERCHÉ: la fattura appena creata entra nello storico, così il flusso
    // Ricevi può interrogarla con lookup_invoice (come sul nodo vero).
    _nextInvoiceIndex++;
    _invoices.insert(
      0,
      LightningInvoiceRecord(
        paymentHash: invoice.paymentHash,
        label: 'nwcb-mock-$_nextInvoiceIndex',
        amountMsat: amountMsat,
        status: 'unpaid',
        description: description,
        expiresAt: invoice.expiresAt == null
            ? null
            : invoice.expiresAt!.millisecondsSinceEpoch ~/ 1000,
        createdIndex: _nextInvoiceIndex,
      ),
    );
    return invoice;
  }

  @override
  Future<List<LightningInvoiceRecord>> listInvoices({
    int limit = 25,
    int offset = 0,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    if (offset >= _invoices.length) return const [];
    return List.unmodifiable(_invoices.skip(offset).take(limit));
  }

  @override
  Future<LightningInvoiceRecord> lookupInvoice({
    String? paymentHash,
    String? label,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    for (final i in _invoices) {
      if (paymentHash != null && i.paymentHash == paymentHash) return i;
      if (paymentHash == null && label != null && i.label == label) return i;
    }
    throw const LightningException('OTHER', 'fattura non trovata (mock)');
  }

  /// Segna pagata una fattura del mock (usata dai widget test del flusso Ricevi).
  void markInvoicePaid(String paymentHash) {
    final index = _invoices.indexWhere((i) => i.paymentHash == paymentHash);
    if (index < 0) return;
    final invoice = _invoices[index];
    _invoices[index] = LightningInvoiceRecord(
      paymentHash: invoice.paymentHash,
      label: invoice.label,
      amountMsat: invoice.amountMsat,
      status: 'paid',
      description: invoice.description,
      expiresAt: invoice.expiresAt,
      createdIndex: invoice.createdIndex,
      paidAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      amountReceivedMsat: invoice.amountMsat,
    );
    _notifications.add(null);
  }

  @override
  Future<LightningPaymentResult> payInvoice(String bolt11) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    if (bolt11.contains('fail')) {
      throw const LightningException('OTHER', 'pagamento rifiutato (mock)');
    }
    _balanceMsat = max(0, _balanceMsat - 1000000);
    // PERCHÉ: il pagamento entra anche nello storico in uscita (fee 1 sat),
    // così la schermata Pagamenti mostra dati coerenti col saldo.
    _nextPayIndex++;
    _pays.insert(
      0,
      LightningPaymentRecord(
        paymentHash: NostrCrypto.randomHex32(),
        amountMsat: 1000000,
        amountSentMsat: 1001000,
        status: 'complete',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        completedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        createdIndex: _nextPayIndex,
      ),
    );
    _notifications.add(null);
    return LightningPaymentResult(
      preimage: NostrCrypto.randomHex32(),
      feesPaidMsat: 1000,
    );
  }

  @override
  Future<LightningChannelFees> getChannelFees({
    required String channelId,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    final fees = _fees[channelId];
    if (fees == null) {
      throw const LightningException('OTHER', 'canale non trovato (mock)');
    }
    return fees;
  }

  @override
  Future<LightningChannelFees> setChannelFees({
    required String channelId,
    int? baseMsat,
    int? ppm,
    int? htlcMinMsat,
    int? htlcMaxMsat,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    final current = _fees[channelId];
    if (current == null) {
      throw const LightningException('OTHER', 'canale non trovato (mock)');
    }
    // PERCHÉ: il mock applica davvero la modifica — i widget test verificano
    // che la UI mostri i NUOVI valori dopo il salvataggio.
    final updated = LightningChannelFees(
      id: current.id,
      shortChannelId: current.shortChannelId,
      feeBaseMsat: baseMsat ?? current.feeBaseMsat,
      feePpm: ppm ?? current.feePpm,
      htlcMinMsat: htlcMinMsat ?? current.htlcMinMsat,
      htlcMaxMsat: htlcMaxMsat ?? current.htlcMaxMsat,
      cltvDelta: current.cltvDelta,
      ourReserveMsat: current.ourReserveMsat,
      theirReserveMsat: current.theirReserveMsat,
      toSelfDelay: current.toSelfDelay,
    );
    _fees[channelId] = updated;
    _notifications.add(null);
    return updated;
  }

  @override
  Future<List<LightningPaymentRecord>> listPays({
    int limit = 25,
    int offset = 0,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    if (offset >= _pays.length) return const [];
    return List.unmodifiable(_pays.skip(offset).take(limit));
  }

  @override
  Future<LightningNodeStats> getNodeStats() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: valori allineati al nodo reale (15/09/2026) — netto = saldo.
    const tags = [
      LightningIncomeTag(tag: 'deposit', creditsMsat: 35606000, entries: 2),
      LightningIncomeTag(tag: 'invoice', debitsMsat: 1000000, entries: 1),
      LightningIncomeTag(tag: 'onchain_fee', debitsMsat: 224000, entries: 1),
    ];
    final credits = tags.fold(0, (sum, t) => sum + t.creditsMsat);
    final debits = tags.fold(0, (sum, t) => sum + t.debitsMsat);
    return LightningNodeStats(
      netMsat: credits - debits,
      creditsMsat: credits,
      debitsMsat: debits,
      tags: tags,
      // liquidity-ads assente di proposito (scelta 15/09).
      plugins: const [
        LightningPluginInfo(name: 'keysend', active: true),
        LightningPluginInfo(name: 'bookkeeper', active: true),
        LightningPluginInfo(name: 'clnrest', active: true, isDynamic: true),
      ],
      forwardCount: _forwards.length,
    );
  }

  @override
  Future<List<LightningForward>> listForwards({
    int limit = 25,
    int offset = 0,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    if (offset >= _forwards.length) return const [];
    return List.unmodifiable(_forwards.skip(offset).take(limit));
  }

  @override
  Future<LightningNetworkNode> getNodeInfo(String nodeId) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: il mock risponde come il gossip — alias noto per i peer dei
    // canali, nome vuoto per gli sconosciuti (la UI ripiega sull'id corto).
    final channel = _channels.cast<LightningChannel?>().firstWhere(
          (c) => c?.peerPubkey == nodeId,
          orElse: () => null,
        );
    return LightningNetworkNode(
      nodeId: nodeId,
      alias: channel?.peerAlias,
      colorHex: '3399ff',
      lastTimestamp:
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - const Duration(hours: 1).inSeconds,
      addresses: const [
        LightningNodeEndpoint(
          type: 'ipv4',
          address: '203.0.113.7',
          port: 9735,
        ),
      ],
    );
  }

  @override
  Future<LightningRoute> getRoute({
    required String destination,
    required int amountMsat,
    int? riskFactor,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: un hop solo (peer diretto) con la fee della policy del canale.
    final fees = _fees.values.first;
    final fee = fees.feeBaseMsat + (amountMsat * fees.feePpm ~/ 1000000);
    return LightningRoute(
      hops: [
        LightningRouteHop(
          id: destination,
          channel: fees.shortChannelId,
          direction: 0,
          amountMsat: amountMsat + fee,
          delay: 9,
          style: 'tlv',
        ),
      ],
      feeMsat: fee,
      totalDelay: 9,
    );
  }

  @override
  Future<LightningKeysendResult> sendKeysend({
    required String destination,
    required int amountSats,
    int? maxFeeMsat,
    int? retryForSeconds,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: replica la validazione del nodo (pubkey di 33 byte = 66 hex).
    if (destination.length != 66) {
      throw const LightningException('OTHER', 'pubkey non valida (mock)');
    }
    final amountMsat = amountSats * 1000;
    // Fee simulata di 1 sat, mai oltre il massimo scelto dall'utente.
    final feeMsat = maxFeeMsat == null ? 1000 : min(1000, maxFeeMsat);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hash = NostrCrypto.randomHex32();
    _nextPayIndex++;
    // PERCHÉ: il keysend entra nello storico in uscita, come sul nodo vero.
    _pays.insert(
      0,
      LightningPaymentRecord(
        paymentHash: hash,
        amountMsat: amountMsat,
        amountSentMsat: amountMsat + feeMsat,
        status: 'complete',
        destination: destination,
        createdAt: now,
        completedAt: now,
        createdIndex: _nextPayIndex,
      ),
    );
    _balanceMsat = max(0, _balanceMsat - amountMsat - feeMsat);
    _notifications.add(null);
    return LightningKeysendResult(
      destination: destination,
      paymentHash: hash,
      preimage: NostrCrypto.randomHex32(),
      status: 'complete',
      amountMsat: amountMsat,
      feeMsat: feeMsat,
      createdAt: now,
    );
  }

  /// Forwarding finto: settled, con fee di 1 sat.
  LightningForward _mockForward(int index) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return LightningForward(
      inChannel: '1000x1x0',
      outChannel: '1001x2x0',
      inMsat: 2000000 + index * 100000,
      outMsat: 1999000 + index * 100000,
      feeMsat: 1000,
      status: 'settled',
      receivedTime: now - (index + 1) * 3600,
      resolvedTime: now - (index + 1) * 3600 + 1,
    );
  }

  @override
  Future<List<LightningHtlc>> listPendingHtlcs() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: un HTLC in corso e uno concluso coprono le due rese della UI
    // (badge "In progress" e stato grezzo).
    return [
      LightningHtlc(
        paymentHash: 'aa11${'33' * 30}',
        amountMsat: 1500000,
        state: 'SENT_ADD_HTLC',
        pending: true,
        id: 1,
        shortChannelId: '1000x1x0',
        direction: 'out',
        expiry: 972200,
      ),
      LightningHtlc(
        paymentHash: 'bb22${'44' * 30}',
        amountMsat: 1000000,
        state: 'RCVD_REMOVE_ACK_REVOCATION',
        pending: false,
        id: 0,
        shortChannelId: '1000x1x0',
        direction: 'in',
        expiry: 972026,
      ),
    ];
  }

  @override
  Future<LightningBalance> getBalance() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ (mock): espone il breakdown come il bridge I1 — così widget test
    // e demo coprono il percorso "saldi separati".
    return LightningBalance(
      balanceMsat: _balanceMsat + _onchainBalanceMsat,
      onchainMsat: _onchainBalanceMsat,
      lightningMsat: _balanceMsat,
    );
  }

  @override
  Future<LightningNodeAddress> makeNewAddress({String? addressType}) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: il tipo richiesto cambia il prefisso (taproot `bc1p`, bech32
    // `bc1q`) — i widget test verificano la scelta del dialog.
    final type = addressType == 'p2tr' ? 'p2tr' : 'bech32';
    _nextAddressIndex++;
    return LightningNodeAddress(
      address: type == 'p2tr'
          ? 'bc1pmock${NostrCrypto.randomHex32().substring(0, 20)}'
          : 'bc1qmock${NostrCrypto.randomHex32().substring(0, 20)}',
      type: type,
      keyIndex: _nextAddressIndex,
    );
  }

  @override
  Future<LightningOnchainFees> estimateOnchainFees() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    return onchainFeesOverride ??
        const LightningOnchainFees(
          minSatVb: 1,
          economicalSatVb: 2,
          prioritySatVb: 4,
        );
  }

  @override
  Future<LightningOnchainResult> payOnchain({
    required String address,
    required int amountSats,
    int? feeRateSatVb,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    if (amountSats > _onchainBalanceMsat ~/ 1000) {
      throw const LightningException(
        'OTHER',
        'fondi on-chain insufficienti (mock)',
      );
    }
    _onchainBalanceMsat -= amountSats * 1000;
    _notifications.add(null);
    return LightningOnchainResult(txid: NostrCrypto.randomHex32());
  }

  @override
  Future<List<LightningNodeAddress>> listAddresses() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // Due indirizzi: il primo con fondi (badge "con saldo"), il secondo vuoto.
    return [
      LightningNodeAddress(
        address: 'bc1qmock${NostrCrypto.randomHex32().substring(0, 20)}',
        type: 'bech32',
        keyIndex: 1,
        hasFunds: true,
        amountMsat: _onchainBalanceMsat,
      ),
      LightningNodeAddress(
        address: 'bc1pmock${NostrCrypto.randomHex32().substring(0, 20)}',
        type: 'p2tr',
        keyIndex: 2,
        hasFunds: false,
      ),
    ];
  }

  @override
  Future<List<LightningUtxo>> listUtxos() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: un confermato e uno in attesa (riservato) coprono i due stati
    // della UI senza fixture duplicate nei test.
    return [
      LightningUtxo(
        txid: 'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6',
        vout: 0,
        amountMsat: _onchainBalanceMsat - 5000000,
        address: 'bc1qmockutxo1',
        status: 'confirmed',
        blockHeight: 971913,
      ),
      const LightningUtxo(
        txid: 'aa11bb22cc33dd44ee55ff66aa77bb88cc99dd00ee11ff22aa33bb44cc55dd66',
        vout: 1,
        amountMsat: 5000000,
        address: 'bc1qmockutxo2',
        status: 'unconfirmed',
        reserved: true,
      ),
    ];
  }

  @override
  Future<List<LightningPeer>> listPeers() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    return List.unmodifiable(_peers);
  }

  @override
  Future<List<LightningMovement>> listTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    // PERCHÉ: la paginazione è reale anche nel mock — i widget test del
    // "Carica altri" devono poter verificare l'append della seconda pagina.
    if (offset >= _movements.length) return const [];
    return List.unmodifiable(_movements.skip(offset).take(limit));
  }

  @override
  Future<void> connectPeer({required String nodeId, String? host}) async {
    _peers.add(
      LightningPeer(
        id: nodeId,
        connected: true,
        numChannels: 0,
        addresses: [if (host != null && host.isNotEmpty) host],
      ),
    );
    _notifications.add(null);
  }

  @override
  Future<void> disconnectPeer({
    required String nodeId,
    bool force = false,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    final i = _peers.indexWhere((p) => p.id == nodeId);
    if (i < 0) return;
    final p = _peers[i];
    _peers[i] = LightningPeer(
      id: p.id,
      alias: p.alias,
      connected: false,
      numChannels: p.numChannels,
      addresses: p.addresses,
      remoteAddr: p.remoteAddr,
    );
    _notifications.add(null);
  }

  /// Simula una notifica del nodo (usata dai widget test).
  void emitNotification() => _notifications.add(null);

  @override
  Future<List<LightningChannel>> listChannels() async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    return List.unmodifiable(_channels);
  }

  @override
  Future<void> openChannel({
    required String nodeId,
    required int amountSats,
    String? host,
    bool isPrivate = false,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    _channels.add(
      LightningChannel(
        id: 'mock_channel_${_channels.length + 1}',
        peerPubkey: nodeId,
        state: 'PendingOpen',
        isPrivate: isPrivate,
        localBalance: amountSats * 1000,
        remoteBalance: 0,
        capacity: amountSats * 1000,
      ),
    );
    _notifications.add(null);
  }

  @override
  Future<void> closeChannel({
    required String channelId,
    bool force = false,
  }) async {
    _ensureConnected();
    await Future<void>.delayed(latency);
    _channels.removeWhere((c) => c.id == channelId);
    _notifications.add(null);
  }

  void _ensureConnected() {
    if (!isConnected) {
      throw const LightningException(
        'NOT_CONNECTED',
        'Nessun nodo Lightning connesso',
      );
    }
  }

  void _setState(LightningConnectionState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
