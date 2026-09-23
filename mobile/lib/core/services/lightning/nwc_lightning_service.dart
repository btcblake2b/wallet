import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
import '../nostr/nostr_event.dart';
import '../nostr/nostr_transport.dart';
import 'lightning_service.dart';

/// Client Lightning per nodo remoto: pagamenti via **NWC (NIP-47)**,
/// canali via **NNC/NCC** (spec Nostr Node Control: kind 23198/23199,
/// payload `{"method","params"}` / `{"result_type","result","error"}`).
///
/// // PERCHÉ (NIP-XX): nomi metodo, nomi parametro e unità (`_sats`) sono
/// quelli canonici della spec — il bridge accetta anche gli alias storici,
/// così app e bridge possono essere aggiornati in momenti diversi.
///
/// // PERCHÉ: tutto il protocollo è implementato e testato contro un
/// transport iniettabile — quando il nodo blake2b sarà buildabile basta
/// incollare la URI di connessione, senza modifiche al codice.
class NwcLightningService implements LightningService {
  NwcLightningService({
    required NostrTransport transport,
    Duration requestTimeout = const Duration(seconds: 30),
    this.maxSocketAge = const Duration(minutes: 10),
  })  : _transport = transport,
        _requestTimeout = requestTimeout;

  final NostrTransport _transport;
  final Duration _requestTimeout;

  /// Età massima del socket prima del riciclo preventivo.
  ///
  /// // PERCHÉ: su mobile il WebSocket può diventare "zombie" (standby,
  /// cambio rete, NAT): resta isConnected=true ma le richieste si perdono.
  /// Riciclarlo a intervalli garantiti evita che l'app resti appesa.
  final Duration maxSocketAge;

  // Kind del protocollo (dal sorgente del nodo dln-node-knots).
  static const int nwcRequestKind = 23194;
  static const int nwcResponseKind = 23195;
  static const int nwcNotificationKind = 23196;
  static const int nwcNotificationNip44Kind = 23197;
  static const int nccRequestKind = 23198;
  static const int nccResponseKind = 23199;
  static const int nccNotificationKind = 23200;

  LightningConnection? _connection;
  String _clientPrivHex = '';
  String _clientPubHex = '';
  StreamSubscription<NostrEvent>? _sub;
  Timer? _healthTimer;

  LightningConnectionState _state = LightningConnectionState.disconnected;
  final StreamController<LightningConnectionState> _stateController =
      StreamController<LightningConnectionState>.broadcast();
  final StreamController<void> _notifications =
      StreamController<void>.broadcast();

  /// Richieste in attesa di risposta, indicizzate per id evento richiesta.
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

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
    await disconnect();
    _setState(LightningConnectionState.connecting);
    try {
      await _transport.connect(connection.relays.first);
      _connection = connection;
      _clientPrivHex = connection.secretHex;
      _clientPubHex = NostrCrypto.derivePublicKey(connection.secretHex);
      await _subscribe();
      _setState(LightningConnectionState.connected);
      // // PERCHÉ: su mobile il WebSocket cade spesso (standby, cambio rete):
      // un health check periodico riconnette e ri-sottoscrive da solo.
      _healthTimer?.cancel();
      _healthTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(_ensureConnected()),
      );
      debugPrint(
        '[LoopEngineer] NwcLightning: connesso (relay=${connection.relays.first})',
      );
    } catch (e) {
      _setState(LightningConnectionState.disconnected);
      throw LightningException('CONNECT_FAILED', '$e');
    }
  }

  Future<void> _subscribe() async {
    await _sub?.cancel();
    _sub = _transport.subscribe([
      {
        'kinds': [nwcResponseKind, nccResponseKind],
        '#p': [_clientPubHex],
      },
      {
        'kinds': [
          nwcNotificationKind,
          nwcNotificationNip44Kind,
          nccNotificationKind,
        ],
        '#p': [_clientPubHex],
      },
    ]).listen(_onEvent);
  }

  /// Riconnette il relay se il WebSocket è caduto o è troppo vecchio
  /// (health check periodico + controllo prima di ogni invio).
  Future<void> _ensureConnected() async {
    final conn = _connection;
    if (conn == null || _state != LightningConnectionState.connected) {
      return;
    }
    final since = _transport.connectedSince;
    final tooOld =
        since != null && DateTime.now().difference(since) > maxSocketAge;
    if (_transport.isConnected && !tooOld) {
      return;
    }
    if (_transport.isConnected) {
      // // PERCHÉ: socket vecchio = possibile zombie: lo sostituisco prima
      // che una richiesta finisca persa in timeout.
      debugPrint(
        '[LoopEngineer] NwcLightning: socket vecchio, riciclo preventivo…',
      );
    } else {
      debugPrint('[LoopEngineer] NwcLightning: relay caduto, riconnessione…');
    }
    await _reconnect(conn);
  }

  /// Chiude (anche un eventuale socket zombie) e riapre ri-sottoscrivendo.
  Future<void> _reconnect(LightningConnection conn) async {
    try {
      await _transport.connect(conn.relays.first);
      await _subscribe();
      debugPrint('[LoopEngineer] NwcLightning: relay riconnesso');
    } catch (e) {
      debugPrint('[LoopEngineer] NwcLightning: riconnessione fallita: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _healthTimer?.cancel();
    _healthTimer = null;
    await _sub?.cancel();
    _sub = null;
    _pending.clear();
    await _transport.close();
    _connection = null;
    _clientPrivHex = '';
    _clientPubHex = '';
    _setState(LightningConnectionState.disconnected);
  }

  // ── API pubbliche (protocollo) ──────────────────────────────────────────────

  @override
  Future<LightningNodeInfo> getInfo() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'get_info',
    );
    return LightningNodeInfo.fromJson(result);
  }

  @override
  Future<int> getBalanceMsat() async {
    final balance = await getBalance();
    return balance.balanceMsat;
  }

  @override
  Future<LightningBalance> getBalance() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'get_balance',
    );
    return LightningBalance.fromJson(result);
  }

  @override
  Future<LightningInvoice> makeInvoice({
    required int amountMsat,
    String? description,
  }) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'make_invoice',
      params: {
        'amount': amountMsat,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return LightningInvoice.fromJson(result);
  }

  @override
  Future<LightningPaymentResult> payInvoice(String bolt11) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'pay_invoice',
      params: {'invoice': bolt11},
    );
    return LightningPaymentResult.fromJson(result);
  }

  @override
  Future<LightningNodeAddress> makeNewAddress({String? addressType}) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'make_new_address',
      // PERCHÉ (NIP-XX): il campo spec è `type`; il bridge accetta anche
      // `address_type` per retro-compatibilità.
      params: {if (addressType != null) 'type': addressType},
    );
    return LightningNodeAddress.fromJson(result);
  }

  @override
  Future<LightningOnchainFees> estimateOnchainFees() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'estimate_onchain_fees',
    );
    return LightningOnchainFees.fromJson(result);
  }

  @override
  Future<LightningOnchainResult> payOnchain({
    required String address,
    required int amountSats,
    int? feeRateSatVb,
  }) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'pay_onchain',
      params: {
        'address': address,
        // PERCHÉ (NIP-XX nwc-units): `amount_sats` è il nome spec.
        'amount_sats': amountSats,
        // PERCHÉ (NIP-XX nwc-onchain): `feerate` in sat/vB; la conversione
        // perkw per CLN è responsabilità del bridge (l'app non conosce CLN).
        if (feeRateSatVb != null) 'feerate': feeRateSatVb,
      },
    );
    return LightningOnchainResult.fromJson(result);
  }

  @override
  Future<List<LightningNodeAddress>> listAddresses() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'list_addresses',
    );
    final list = (result['addresses'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningNodeAddress.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<List<LightningUtxo>> listUtxos() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'list_utxos',
    );
    final list = (result['utxos'] as List?) ?? const [];
    return list
        .map((e) => LightningUtxo.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<LightningInvoiceRecord>> listInvoices({
    int limit = 25,
    int offset = 0,
  }) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'list_invoices',
      params: {'limit': limit, 'offset': offset},
    );
    final list = (result['invoices'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningInvoiceRecord.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<LightningInvoiceRecord> lookupInvoice({
    String? paymentHash,
    String? label,
  }) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'lookup_invoice',
      params: {
        if (paymentHash != null) 'payment_hash': paymentHash,
        if (paymentHash == null && label != null) 'label': label,
      },
    );
    return LightningInvoiceRecord.fromJson(result);
  }

  @override
  Future<void> deleteInvoice({String? paymentHash, String? label}) async {
    // Scrittura: NESSUN retry automatico (una doppia cancellazione non è
    // pericolosa, ma la semantica di `_request` resta uniforme per i write).
    await _request(
      kind: nwcRequestKind,
      method: 'delete_invoice',
      params: {
        if (paymentHash != null) 'payment_hash': paymentHash,
        if (paymentHash == null && label != null) 'label': label,
      },
    );
  }

  @override
  Future<List<LightningPaymentRecord>> listPays({
    int limit = 25,
    int offset = 0,
  }) async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'list_pays',
      params: {'limit': limit, 'offset': offset},
    );
    final list = (result['pays'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningPaymentRecord.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<List<LightningHtlc>> listPendingHtlcs() async {
    final result = await _request(
      kind: nwcRequestKind,
      method: 'get_pending_htlcs',
    );
    final list = (result['htlcs'] as List?) ?? const [];
    return list
        .map((e) => LightningHtlc.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<LightningChannelFees> getChannelFees({
    required String channelId,
  }) async {
    // PERCHÉ: la policy di canale è un comando NCC (kind 23198).
    final result = await _request(
      kind: nccRequestKind,
      method: 'get_channel_fees',
      params: {'id': channelId},
    );
    return LightningChannelFees.fromJson(result);
  }

  @override
  Future<LightningChannelFees> setChannelFees({
    required String channelId,
    int? baseMsat,
    int? ppm,
    int? htlcMinMsat,
    int? htlcMaxMsat,
  }) async {
    final result = await _request(
      kind: nccRequestKind,
      method: 'set_channel_fees',
      params: {
        'id': channelId,
        if (baseMsat != null) 'base_msat': baseMsat,
        if (ppm != null) 'ppm': ppm,
        if (htlcMinMsat != null) 'htlc_min_msat': htlcMinMsat,
        if (htlcMaxMsat != null) 'htlc_max_msat': htlcMaxMsat,
      },
    );
    return LightningChannelFees.fromJson(result);
  }

  @override
  Future<LightningNodeStats> getNodeStats() async {
    // PERCHÉ: economia e plugin sono dati di nodo (kind 23198).
    final result = await _request(
      kind: nccRequestKind,
      method: 'get_node_stats',
    );
    return LightningNodeStats.fromJson(result);
  }

  @override
  Future<List<LightningForward>> listForwards({
    int limit = 25,
    int offset = 0,
  }) async {
    final result = await _request(
      kind: nccRequestKind,
      method: 'get_forwarding_history',
      params: {'limit': limit, 'offset': offset},
    );
    final list = (result['forwards'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningForward.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<LightningNetworkNode> getNodeInfo(String nodeId) async {
    // PERCHÉ (NIP-XX get_network_node): `pubkey` è il nome spec del parametro.
    final result = await _request(
      kind: nccRequestKind,
      method: 'get_network_node',
      params: {'pubkey': nodeId},
    );
    return LightningNetworkNode.fromJson(result);
  }

  @override
  Future<LightningRoute> getRoute({
    required String destination,
    required int amountMsat,
    int? riskFactor,
  }) async {
    final result = await _request(
      kind: nccRequestKind,
      method: 'query_routes',
      // PERCHÉ (NIP-XX nwc-units): `amount` è il nome spec (msat, senza
      // suffisso); `risk_factor` resta un extra accettato dal bridge.
      params: {
        'destination': destination,
        'amount': amountMsat,
        if (riskFactor != null) 'risk_factor': riskFactor,
      },
    );
    return LightningRoute.fromJson(result);
  }

  @override
  Future<LightningKeysendResult> sendKeysend({
    required String destination,
    required int amountSats,
    int? maxFeeMsat,
    int? retryForSeconds,
  }) async {
    // PERCHÉ: scrittura che muove fondi → NWC (kind 23194) e MAI ritentata su
    // timeout: un doppio invio sarebbe irreversibile.
    final result = await _request(
      kind: nwcRequestKind,
      method: 'keysend',
      params: {
        'destination': destination,
        'amount_msat': amountSats * 1000,
        if (maxFeeMsat != null) 'maxfee_msat': maxFeeMsat,
        if (retryForSeconds != null) 'retry_for': retryForSeconds,
      },
    );
    return LightningKeysendResult.fromJson(result);
  }

  @override
  Future<List<LightningPeer>> listPeers() async {
    final result = await _request(
      kind: nccRequestKind,
      method: 'list_peers',
    );
    final list = (result['peers'] as List?) ?? const [];
    return list
        .map((e) => LightningPeer.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<LightningMovement>> listTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    // PERCHÉ: i movimenti sono un metodo NWC della spec dln (dati di nodo),
    // non NCC: la richiesta viaggia sul kind 23194.
    final result = await _request(
      kind: nwcRequestKind,
      method: 'list_transactions',
      params: {'limit': limit, 'offset': offset},
    );
    final list = (result['transactions'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningMovement.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<void> connectPeer({required String nodeId, String? host}) async {
    await _request(
      kind: nccRequestKind,
      method: 'connect_peer',
      params: {
        'id': nodeId,
        if (host != null && host.isNotEmpty) 'host': host,
      },
    );
  }

  @override
  Future<void> disconnectPeer({
    required String nodeId,
    bool force = false,
  }) async {
    await _request(
      kind: nccRequestKind,
      method: 'disconnect_peer',
      params: {'id': nodeId, 'force': force},
    );
  }

  @override
  Future<List<LightningChannel>> listChannels() async {
    final result = await _request(
      kind: nccRequestKind,
      method: 'list_channels',
    );
    final list = (result['channels'] as List?) ?? const [];
    return list
        .map(
          (e) => LightningChannel.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<void> openChannel({
    required String nodeId,
    required int amountSats,
    String? host,
    bool isPrivate = false,
  }) async {
    await _request(
      kind: nccRequestKind,
      method: 'open_channel',
      params: {
        'pubkey': nodeId,
        // PERCHÉ (NIP-XX nwc-units): `amount_sats` è il nome spec.
        'amount_sats': amountSats,
        if (host != null && host.isNotEmpty) 'host': host,
        if (isPrivate) 'private': true,
      },
    );
  }

  @override
  Future<void> closeChannel({
    required String channelId,
    bool force = false,
  }) async {
    await _request(
      kind: nccRequestKind,
      method: 'close_channel',
      params: {
        'id': channelId,
        'force': force,
      },
    );
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  /// Invia una richiesta cifrata (NIP-04) e attende la risposta correlata
  /// (tag `e` = id richiesta). Lancia [LightningException] su errore del nodo
  /// o timeout.
  ///
  /// // PERCHÉ: sulle sole letture un timeout è recuperabile (la risposta è
  /// andata persa): riciclo la connessione e ritento una volta.
  Future<Map<String, dynamic>> _request({
    required int kind,
    required String method,
    Map<String, dynamic>? params,
  }) async {
    final conn = _connection;
    if (conn == null || !isConnected) {
      throw const LightningException(
        'NOT_CONNECTED',
        'Nessun nodo Lightning connesso',
      );
    }

    // // PERCHÉ: se il socket è caduto o è troppo vecchio (zombie), la
    // richiesta andrebbe persa in silenzio: riciclo prima di inviare.
    await _ensureConnected();
    if (!_transport.isConnected) {
      throw const LightningException(
        'CONNECT_FAILED',
        'Relay non raggiungibile: riconnessione in corso, riprova tra qualche secondo',
      );
    }

    try {
      return await _send(kind: kind, method: method, params: params);
    } on LightningException catch (e) {
      // // PERCHÉ: sui comandi con effetti (pay_invoice, make_invoice, …) NON
      // ritento: si rischierebbero duplicati.
      if (e.code == 'TIMEOUT' && _isReadOnly(method)) {
        debugPrint(
          '[LoopEngineer] NwcLightning: $method in timeout, riciclo e ritento…',
        );
        await _reconnect(conn);
        if (!_transport.isConnected) {
          throw const LightningException(
            'CONNECT_FAILED',
            'Relay non raggiungibile: riconnessione in corso, riprova tra qualche secondo',
          );
        }
        return _send(kind: kind, method: method, params: params);
      }
      rethrow;
    }
  }

  /// Metodi di sola lettura: ritentarli è sicuro (nessun effetto collaterale).
  ///
  /// // PERCHÉ (I1): stime e indirizzi sono letture — un timeout non deve
  /// lasciare la UI appesa. `make_new_address` NO (genera un indirizzo nuovo),
  /// `pay_onchain` NO (muove fondi).
  static bool _isReadOnly(String method) =>
      method == 'get_info' ||
      method == 'get_balance' ||
      method == 'list_channels' ||
      method == 'estimate_onchain_fees' ||
      method == 'list_addresses' ||
      method == 'list_utxos' ||
      method == 'list_invoices' ||
      method == 'lookup_invoice' ||
      method == 'list_pays' ||
      method == 'get_pending_htlcs' ||
      method == 'list_transactions' ||
      method == 'list_peers' ||
      method == 'get_channel_fees' ||
      // I3e: letture di rete/diagnostica. `keysend` NON è qui: muove fondi.
      method == 'get_node_stats' ||
      // PERCHÉ (NIP-XX): nomi canonici + alias storici — un bridge non ancora
      // aggiornato risponde `NOT_IMPLEMENTED` al nome nuovo, non un timeout.
      method == 'get_forwarding_history' ||
      method == 'list_forwards' ||
      method == 'get_network_node' ||
      method == 'get_node_info' ||
      method == 'query_routes' ||
      method == 'get_route';

  /// Invia una singola richiesta cifrata e attende la risposta correlata
  /// (tag `e` = id richiesta).
  Future<Map<String, dynamic>> _send({
    required int kind,
    required String method,
    Map<String, dynamic>? params,
  }) async {
    final conn = _connection!;
    final payload = jsonEncode({
      'method': method,
      if (params != null) 'params': params,
    });
    final encrypted = NostrCrypto.nip04Encrypt(
      privkeyHex: _clientPrivHex,
      pubkeyHex: conn.walletPubkey,
      plaintext: payload,
    );
    final event = NostrEvent.unsigned(
      pubkey: _clientPubHex,
      kind: kind,
      tags: [
        ['p', conn.walletPubkey],
      ],
      content: encrypted,
    ).sign(_clientPrivHex);

    final completer = Completer<Map<String, dynamic>>();
    _pending[event.id] = completer;

    try {
      await _transport.publish(event);
      debugPrint('[LoopEngineer] NwcLightning: $method inviato (${event.id})');
      final response = await completer.future.timeout(
        _requestTimeout,
        onTimeout: () => throw LightningException(
          'TIMEOUT',
          'Il nodo non ha risposto a $method',
        ),
      );

      final error = response['error'];
      if (error is Map && error.isNotEmpty) {
        throw LightningException(
          '${error['code'] ?? 'OTHER'}',
          '${error['message'] ?? 'errore dal nodo'}',
        );
      }
      final result = response['result'];
      return result is Map ? result.cast<String, dynamic>() : const {};
    } finally {
      _pending.remove(event.id);
    }
  }

  void _onEvent(NostrEvent event) {
    final conn = _connection;
    if (conn == null) return;

    // // PERCHÉ (sicurezza): accetta solo eventi firmati dal nodo atteso —
    // un relay malevolo non può iniettare risposte.
    if (event.pubkey != conn.walletPubkey || !event.verify()) {
      return;
    }

    if (event.kind == nwcResponseKind || event.kind == nccResponseKind) {
      final requestId = event.firstTagValue('e');
      if (requestId == null) return;
      final completer = _pending.remove(requestId);
      if (completer == null || completer.isCompleted) return;
      try {
        final decrypted = NostrCrypto.nip04Decrypt(
          privkeyHex: _clientPrivHex,
          pubkeyHex: event.pubkey,
          payload: event.content,
        );
        final json = (jsonDecode(decrypted) as Map).cast<String, dynamic>();
        completer.complete(json);
      } catch (e) {
        completer.completeError(LightningException('BAD_RESPONSE', '$e'));
      }
      return;
    }

    // Notifiche (payment_received / channel_opened / …): segnale di refresh.
    if (event.kind == nwcNotificationKind ||
        event.kind == nwcNotificationNip44Kind ||
        event.kind == nccNotificationKind) {
      _notifications.add(null);
    }
  }

  void _setState(LightningConnectionState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
