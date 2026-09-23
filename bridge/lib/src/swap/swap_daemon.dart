import 'dart:async';
import 'dart:convert';

import '../logger.dart';
import '../nostr/nostr_crypto.dart';
import '../nostr/nostr_event.dart';
import '../nostr/nostr_transport.dart';
import '../protocol.dart';
import 'swap_config.dart';
import 'swap_consts.dart';
import 'swap_handlers.dart';
import 'swap_models.dart';
import 'swap_service.dart';
import 'swap_store.dart';

/// Daemon del provider swap (P9) — lato server del protocollo 23290-23292.
///
/// // FLOW: Pagamento LN via swap (P9) — provider
/// app → relay Nostr → [daemon] → SwapHandlers → SwapService → CLN/chain
/// La risposta ripercorre il cammino inverso, cifrata NIP-04 e firmata.
/// Ogni tick riconcilia le sessioni e NOTIFICA i cambi di stato al client
/// proprietario (kind 23292), così l'app non deve dipendere dal solo polling.
///
/// // PERCHÉ: un daemon dedicato (invece di riusare BridgeService) separa
/// // identità, kind e policy dello swap dal canale NWC/NCC: due servizi
/// // distinti sullo stesso nodo, nessuna allowlist condivisa.
class SwapDaemon {
  SwapDaemon({
    required NostrTransport transport,
    required SwapService service,
    required SwapHandlers handlers,
    required SwapStore store,
    required SwapConfig config,
    required String providerKeyHex,
    Logger? logger,
    Duration maxSocketAge = const Duration(minutes: 10),
  })  : _transport = transport,
        _service = service,
        _handlers = handlers,
        _store = store,
        _config = config,
        _privHex = providerKeyHex.toLowerCase(),
        _logger = logger ?? Logger(),
        _maxSocketAge = maxSocketAge;

  final NostrTransport _transport;
  final SwapService _service;
  final SwapHandlers _handlers;
  final SwapStore _store;
  final SwapConfig _config;
  final String _privHex;
  final Logger _logger;
  final Duration _maxSocketAge;

  late final String _pubHex = NostrCrypto.derivePublicKey(_privHex);

  /// Id evento già processati (i relay possono ripetere gli eventi).
  final Set<String> _processed = <String>{};

  /// Ultimo stato osservato per sessione (per notificare solo i CAMBI).
  final Map<String, SwapState> _lastStates = <String, SwapState>{};

  StreamSubscription<NostrEvent>? _sub;
  Timer? _tickTimer;
  Timer? _healthTimer;
  bool _stopped = false;
  String? _activeRelay;

  /// Pubkey Nostr del provider (quella nella URI `nostr+swap://` per l'app).
  String get publicKey => _pubHex;

  /// Relay su cui il daemon è (o sarà) in ascolto.
  String? get activeRelay => _activeRelay;

  Future<void> start() async {
    _stopped = false;
    await _connect();
    _logger.info('swapd: in ascolto su $_activeRelay');
    _logger.info('swapd: pubkey provider: $_pubHex');
    _tickTimer = Timer.periodic(
      Duration(seconds: _config.timeouts.tickSec),
      (_) => unawaited(tick()),
    );
    // PERCHÉ: i relay chiudono le connessioni inattive (NAT/standby): senza
    // un health check il daemon resterebbe "sordo" senza accorgersene —
    // con fondi in attesa di claim/refund non è un rischio accettabile.
    _healthTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(ensureConnected()),
    );
  }

  Future<void> stop() async {
    _stopped = true;
    _tickTimer?.cancel();
    _tickTimer = null;
    _healthTimer?.cancel();
    _healthTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _transport.close();
  }

  /// Riconnette il relay se caduto o più vecchio di [maxSocketAge].
  Future<void> ensureConnected() async {
    if (_stopped) return;
    if (_transport.isConnected) {
      final since = _transport.connectedSince;
      final tooOld =
          since != null && DateTime.now().difference(since) > _maxSocketAge;
      if (!tooOld) return;
      _logger.info('swapd: riciclo preventivo del socket');
    } else {
      _logger.warn('swapd: relay disconnesso, riconnessione…');
    }
    try {
      await _sub?.cancel();
      _sub = null;
      await _connect();
      _logger.info('swapd: relay riconnesso ($_activeRelay)');
    } catch (e) {
      _logger.warn('swapd: riconnessione fallita: $e');
    }
  }

  /// Un passo di riconciliazione + notifica dei cambi di stato.
  ///
  /// Pubblico: il timer lo chiama in automatico, i test in modo deterministico.
  Future<void> tick() async {
    if (_stopped) return;
    try {
      await _service.tick();
    } catch (e) {
      _logger.warn('swapd: tick fallito: $e');
    }
    await _notifyChanges();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    Object? lastError;
    // PERCHÉ: il transport è single-relay (MVP): si sceglie il primo
    // raggiungibile all'avvio; la URI per l'app elenca TUTTI i relay, così
    // il client ha comunque margine di failover lato suo.
    for (final relay in _config.relays) {
      try {
        await _transport.connect(relay);
        _activeRelay = relay;
        break;
      } catch (e) {
        lastError = e;
      }
    }
    if (_activeRelay == null) {
      throw StateError('nessun relay raggiungibile: $lastError');
    }
    _sub = _transport.subscribe([
      {
        'kinds': [SwapConsts.requestKind],
        '#p': [_pubHex],
      },
    ]).listen(_onEvent);
  }

  void _onEvent(NostrEvent event) {
    if (event.kind != SwapConsts.requestKind) return;
    // PERCHÉ: dedup — lo stesso evento può arrivare più volte dal relay.
    if (!_processed.add(event.id)) return;
    unawaited(_handle(event));
  }

  Future<void> _handle(NostrEvent event) async {
    if (!event.verify()) {
      _logger.warn('swapd: richiesta con firma non valida ignorata (${event.id})');
      return;
    }
    final allowed = _config.allowedClientPubkeys;
    if (allowed.isNotEmpty && !allowed.contains(event.pubkey)) {
      _logger.warn('swapd: client non autorizzato ignorato: ${event.pubkey}');
      return;
    }
    var requestId = '';
    Map<String, dynamic> body;
    try {
      final decrypted = NostrCrypto.nip04Decrypt(
        privkeyHex: _privHex,
        pubkeyHex: event.pubkey,
        payload: event.content,
      );
      final request = (jsonDecode(decrypted) as Map).cast<String, dynamic>();
      requestId = '${request['id'] ?? ''}';
      final version =
          (request['v'] as num?)?.toInt() ?? SwapConsts.protocolVersion;
      if (version != SwapConsts.protocolVersion) {
        throw RpcError(
          'BAD_REQUEST',
          'versione protocollo $version non supportata.',
        );
      }
      final method = '${request['method'] ?? ''}';
      final params =
          ((request['params'] as Map?) ?? const {}).cast<String, dynamic>();
      _logger.info(
        'swapd: $method (client=${_short(event.pubkey)}, id=$requestId)',
      );
      final result = await _handlers.handle(
        method: method,
        params: params,
        requestId: requestId,
        clientPubkey: event.pubkey,
      );
      body = {
        'v': SwapConsts.protocolVersion,
        'id': requestId,
        'result': result,
      };
    } on RpcError catch (e) {
      _logger.warn('swapd: errore ${e.code} — ${e.message}');
      body = {
        'v': SwapConsts.protocolVersion,
        'id': requestId,
        'error': {'code': e.code, 'message': e.message},
      };
    } catch (e) {
      _logger.error('swapd: errore interno: $e');
      body = {
        'v': SwapConsts.protocolVersion,
        'id': requestId,
        'error': {'code': 'INTERNAL', 'message': '$e'},
      };
    }
    await _publishTo(
      clientPub: event.pubkey,
      kind: SwapConsts.responseKind,
      body: body,
      tagsExtra: [
        ['e', event.id],
      ],
    );
  }

  /// Confronta (e memorizza) gli stati delle sessioni: ogni CAMBIO osservato
  /// viene notificato al client proprietario.
  Future<void> _notifyChanges() async {
    for (final session in _store.all()) {
      final previous = _lastStates[session.id];
      _lastStates[session.id] = session.state;
      if (previous == null || previous == session.state) continue;
      _logger.info(
        'swapd: notifica ${session.state.wireName} → '
        '${_short(session.clientPubkey)}',
      );
      await _publishTo(
        clientPub: session.clientPubkey,
        kind: SwapConsts.notificationKind,
        body: {
          'v': SwapConsts.protocolVersion,
          'id': session.id,
          'result': _service.statusPayload(session),
        },
      );
    }
  }

  Future<void> _publishTo({
    required String clientPub,
    required int kind,
    required Map<String, dynamic> body,
    List<List<String>> tagsExtra = const [],
  }) async {
    try {
      final encrypted = NostrCrypto.nip04Encrypt(
        privkeyHex: _privHex,
        pubkeyHex: clientPub,
        plaintext: jsonEncode(body),
      );
      final event = NostrEvent.unsigned(
        pubkey: _pubHex,
        kind: kind,
        tags: [
          ...tagsExtra,
          ['p', clientPub],
        ],
        content: encrypted,
      ).sign(_privHex);
      await _transport.publish(event);
    } catch (e) {
      _logger.error('swapd: pubblicazione kind $kind fallita: $e');
    }
  }

  static String _short(String hex) =>
      hex.length > 8 ? '${hex.substring(0, 8)}…' : hex;
}
