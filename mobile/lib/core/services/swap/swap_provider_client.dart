import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../nostr/nostr_crypto.dart';
import '../nostr/nostr_event.dart';
import '../nostr/nostr_transport.dart';
import 'swap_consts.dart';
import 'swap_models.dart';
import 'swap_web_policy.dart';

/// Client del protocollo swap (P9): parla col provider via Nostr.
///
/// // FLOW: Pagamento LN via swap (P9) — app
/// // STEP: 1 quote → 2 create → 3 funding (tx on-chain firmata dall'app)
/// // STEP: 4 polling/notifiche di stato → claim del provider → completed
/// // (refund: percorso di recupero, vedi SwapSession + "Recupera fondi").
///
/// // PERCHÉ: stesso scheletro di [NwcLightningService] — transport
/// // iniettabile, eventi firmati/verificati, NIP-04, health check con
/// // riciclo del socket zombie — ma wire format dedicato (kind 23290-23292)
/// // per non interferire con il canale NWC/NCC.
class SwapProviderClient {
  SwapProviderClient({
    required NostrTransport transport,
    Duration requestTimeout = const Duration(seconds: 30),
    this.maxSocketAge = const Duration(minutes: 10),
  })  : _transport = transport,
        _requestTimeout = requestTimeout;

  final NostrTransport _transport;
  final Duration _requestTimeout;

  /// Età massima del socket prima del riciclo preventivo (zombie NAT/standby).
  final Duration maxSocketAge;

  SwapProvider? _provider;
  String _clientPrivHex = '';
  String _clientPubHex = '';
  String? _relayUrl;
  StreamSubscription<NostrEvent>? _sub;
  Timer? _healthTimer;
  bool _disposed = false;

  /// Richieste in attesa di risposta, indicizzate per id evento richiesta.
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  final StreamController<SwapStatus> _statusUpdates =
      StreamController<SwapStatus>.broadcast();

  SwapProvider? get provider => _provider;

  bool get isConnected => _provider != null && _transport.isConnected;

  /// Notifiche di stato push dal provider (kind 23292).
  Stream<SwapStatus> get statusUpdates => _statusUpdates.stream;

  /// Si collega al provider: apre il primo relay raggiungibile e si
  /// sottoscrive ai kind di risposta/notifica indirizzati alla nostra pubkey.
  Future<void> connect(
    SwapProvider provider, {
    required String clientSecretHex,
  }) async {
    await disconnect();
    _clientPrivHex = clientSecretHex.toLowerCase();
    _clientPubHex = NostrCrypto.derivePublicKey(_clientPrivHex);
    // PERCHÉ (PWA 2026-09-18): sulla variante web la CSP consente solo i relay
    // in allowlist (swap_web_policy.dart ↔ mobile/web/_headers): filtrarli qui
    // evita tentativi che fallirebbero con un errore di rete generico.
    final relayCandidates = filterRelaysForPlatform(provider.relays);
    if (relayCandidates.isEmpty) {
      _clientPrivHex = '';
      _clientPubHex = '';
      // PERCHÉ: su web l'unica causa possibile è la CSP (allowlist relay);
      // fuori dal web la lista non viene filtrata e `SwapProvider.fromUri`
      // garantisce già almeno un relay.
      throw SwapException(
        'RELAY_NOT_ALLOWED_WEB',
        'relay del provider non consentito dalla variante web: '
            '${provider.relays.join(', ')}',
      );
    }
    Object? lastError;
    for (final relay in relayCandidates) {
      try {
        await _transport.connect(relay);
        _relayUrl = relay;
        break;
      } catch (e) {
        lastError = e;
      }
    }
    if (_relayUrl == null) {
      _clientPrivHex = '';
      _clientPubHex = '';
      throw SwapException('CONNECT_FAILED', 'nessun relay raggiungibile: $lastError');
    }
    _provider = provider;
    await _subscribe();
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_ensureConnected()),
    );
    debugPrint(
      '[LoopEngineer] SwapProvider: connesso (relay=$_relayUrl, '
      'provider=${provider.providerPubkey})',
    );
  }

  Future<void> _subscribe() async {
    await _sub?.cancel();
    _sub = _transport.subscribe([
      {
        'kinds': [SwapConsts.responseKind, SwapConsts.notificationKind],
        '#p': [_clientPubHex],
      },
    ]).listen(_onEvent);
  }

  /// Riconnette se il socket è caduto o troppo vecchio (prima di ogni invio
  /// e dal health check periodico).
  Future<void> _ensureConnected() async {
    if (_provider == null) return;
    final since = _transport.connectedSince;
    final tooOld =
        since != null && DateTime.now().difference(since) > maxSocketAge;
    if (_transport.isConnected && !tooOld) return;
    if (_transport.isConnected) {
      debugPrint('[LoopEngineer] SwapProvider: socket vecchio, riciclo…');
    } else {
      debugPrint('[LoopEngineer] SwapProvider: relay caduto, riconnessione…');
    }
    try {
      await _transport.connect(_relayUrl!);
      await _subscribe();
      debugPrint('[LoopEngineer] SwapProvider: relay riconnesso');
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProvider: riconnessione fallita: $e');
    }
  }

  /// Chiude il collegamento. Le richieste in volo falliscono con DISCONNECTED.
  Future<void> disconnect() async {
    _healthTimer?.cancel();
    _healthTimer = null;
    await _sub?.cancel();
    _sub = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const SwapException('DISCONNECTED', 'collegamento chiuso.'),
        );
      }
    }
    _pending.clear();
    await _transport.close();
    _provider = null;
    _relayUrl = null;
    _clientPrivHex = '';
    _clientPubHex = '';
  }

  /// Rilascia anche gli stream (uso nei dispose di test/servizi).
  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _statusUpdates.close();
  }

  // ── API di protocollo ──────────────────────────────────────────────────────

  /// Chiede una quote per pagare [invoice]; [refundPubkeyHex] è la chiave
  /// pubblica compressa (33B) dell'account refund dell'utente.
  Future<SwapQuote> quote({
    required String invoice,
    required String refundPubkeyHex,
    String? requestId,
  }) async {
    final result = await _request(
      method: 'swap_quote',
      params: {
        'invoice': invoice,
        'refund_pubkey': refundPubkeyHex,
      },
      requestId: requestId,
    );
    return SwapQuote.fromJson(result);
  }

  /// Crea la sessione dalla quote (idempotente per [requestId]).
  Future<SwapStatus> create({
    required String quoteId,
    String? requestId,
  }) async {
    final result = await _request(
      method: 'swap_create',
      params: {'quote_id': quoteId},
      requestId: requestId,
    );
    return SwapStatus.fromJson(result);
  }

  /// Annuncia la tx di funding (idempotente per [requestId]).
  Future<SwapStatus> funding({
    required String swapId,
    required String fundingTxid,
    String? requestId,
  }) async {
    final result = await _request(
      method: 'swap_funding',
      params: {
        'swap_id': swapId,
        'funding_txid': fundingTxid,
      },
      requestId: requestId,
    );
    return SwapStatus.fromJson(result);
  }

  /// Stato corrente della sessione (con conteggio conferme, se nota).
  Future<SwapStatus> status({required String swapId}) async {
    final result = await _request(
      method: 'swap_status',
      params: {'swap_id': swapId},
    );
    return SwapStatus.fromJson(result);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// true per i metodi senza effetti collaterali: gli unici che possono
  /// essere ritentati dopo un timeout (create/funding sono idempotenti lato
  /// provider ma un retry cieco consuma una richiesta in più: qui si evita).
  static bool _isReadOnly(String method) =>
      method == 'swap_quote' || method == 'swap_status';

  Future<Map<String, dynamic>> _request({
    required String method,
    required Map<String, dynamic> params,
    String? requestId,
  }) async {
    final provider = _provider;
    if (provider == null) {
      throw const SwapException('NOT_CONNECTED', 'provider non collegato.');
    }
    final attempts = _isReadOnly(method) ? 2 : 1;
    for (var i = 0; i < attempts; i++) {
      await _ensureConnected();
      try {
        return await _send(
          provider,
          method: method,
          params: params,
          requestId: requestId ?? NostrCrypto.randomHex32(),
        );
      } on SwapException catch (e) {
        final isLast = i == attempts - 1;
        // // PERCHÉ: retry SOLO su timeout dei metodi read-only — per
        // // create/funding il client deve vedere l'esito reale (l'idempotenza
        // // del provider copre il caso di risposta persa, ma qui non
        // // rischiamo di spendere due richieste se non serve).
        if (isLast || e.code != 'TIMEOUT') rethrow;
        debugPrint('[LoopEngineer] SwapProvider: $method in timeout, ritento…');
      }
    }
    throw StateError('unreachable');
  }

  Future<Map<String, dynamic>> _send(
    SwapProvider provider, {
    required String method,
    required Map<String, dynamic> params,
    required String requestId,
  }) async {
    final payload = jsonEncode({
      'v': SwapConsts.protocolVersion,
      'id': requestId,
      'method': method,
      'params': params,
    });
    final content = NostrCrypto.nip04Encrypt(
      privkeyHex: _clientPrivHex,
      pubkeyHex: provider.providerPubkey,
      plaintext: payload,
    );
    final event = NostrEvent.unsigned(
      pubkey: _clientPubHex,
      kind: SwapConsts.requestKind,
      tags: [
        ['p', provider.providerPubkey],
      ],
      content: content,
    ).sign(_clientPrivHex);

    final completer = Completer<Map<String, dynamic>>();
    _pending[event.id] = completer;
    try {
      await _transport.publish(event);
    } catch (e) {
      _pending.remove(event.id);
      throw SwapException('PUBLISH_FAILED', '$e');
    }
    return completer.future.timeout(
      _requestTimeout,
      onTimeout: () {
        _pending.remove(event.id);
        throw const SwapException(
          'TIMEOUT',
          'nessuna risposta dal provider entro il timeout.',
        );
      },
    );
  }

  void _onEvent(NostrEvent event) {
    final provider = _provider;
    if (provider == null || _disposed) return;
    // Solo il provider atteso, con firma e id verificati (anti-spoof/tamper).
    if (event.pubkey != provider.providerPubkey) return;
    if (!event.verify()) {
      debugPrint('[LoopEngineer] SwapProvider: evento con firma non valida');
      return;
    }
    String plaintext;
    try {
      plaintext = NostrCrypto.nip04Decrypt(
        privkeyHex: _clientPrivHex,
        pubkeyHex: provider.providerPubkey,
        payload: event.content,
      );
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProvider: payload non decifrabile: $e');
      return;
    }
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProvider: payload JSON non valido: $e');
      return;
    }
    if (event.kind == SwapConsts.responseKind) {
      final requestEventId = event.firstTagValue('e');
      if (requestEventId == null) return;
      final completer = _pending.remove(requestEventId);
      if (completer == null || completer.isCompleted) return;
      final error = decoded['error'];
      if (error is Map) {
        completer.completeError(
          SwapException(
            '${error['code'] ?? 'ERROR'}',
            '${error['message'] ?? ''}',
          ),
        );
        return;
      }
      final result = decoded['result'];
      completer.complete(
        result is Map<String, dynamic> ? result : <String, dynamic>{},
      );
      return;
    }
    if (event.kind == SwapConsts.notificationKind) {
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) return;
      try {
        _statusUpdates.add(SwapStatus.fromJson(result));
      } catch (e) {
        debugPrint('[LoopEngineer] SwapProvider: notifica malformata: $e');
      }
    }
  }
}
