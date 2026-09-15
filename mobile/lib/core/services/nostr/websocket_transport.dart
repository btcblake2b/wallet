import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'nostr_event.dart';
import 'nostr_transport.dart';

/// Transport Nostr su WebSocket — MVP: un relay singolo (il primo della
/// lista nella URI di connessione).
///
/// // PERCHÉ: web_socket_channel è cross-platform (Android/iOS/web) e non
/// richiede servizi in background: la connessione vive solo mentre l'app
/// è in primo piano.
class WebSocketTransport implements NostrTransport {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final StreamController<NostrEvent> _events =
      StreamController<NostrEvent>.broadcast();
  int _subCounter = 0;
  bool _closing = false;
  DateTime? _connectedSince;

  @override
  bool get isConnected => _channel != null;

  /// Età del socket: uno "zombie" (NAT half-open) resta connesso ma sordo,
  /// quindi il service lo ricicla quando supera l'età massima.
  @override
  DateTime? get connectedSince => _connectedSince;

  @override
  Future<void> connect(String relayUrl) async {
    await close();
    final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
    await channel.ready;
    _channel = channel;
    _connectedSince = DateTime.now();
    _sub = channel.stream.listen(
      _onMessage,
      onError: (Object e) {
        // // PERCHÉ: segnare la caduta (isConnected→false) permette al
        // client NWC di riconnettere invece di restare appeso.
        _channel = null;
        _connectedSince = null;
        debugPrint('[LoopEngineer] NostrTransport: errore relay: $e');
      },
      onDone: () {
        _channel = null;
        _connectedSince = null;
        if (!_closing) {
          debugPrint('[LoopEngineer] NostrTransport: connessione chiusa');
        }
      },
    );
    debugPrint('[LoopEngineer] NostrTransport: connesso a $relayUrl');
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as List<dynamic>;
      final type = msg.isNotEmpty ? msg[0] as String : '';
      if (type == 'EVENT' && msg.length >= 3) {
        final event = NostrEvent.fromJson(
          (msg[2] as Map).cast<String, dynamic>(),
        );
        _events.add(event);
      } else if (type == 'NOTICE' && msg.length >= 2) {
        debugPrint(
          '[LoopEngineer] NostrTransport: NOTICE dal relay: ${msg[1]}',
        );
      }
      // EOSE/OK/CLOSED: ignorati nell'MVP.
    } catch (e) {
      debugPrint('[LoopEngineer] NostrTransport: messaggio non valido: $e');
    }
  }

  @override
  Future<void> publish(NostrEvent event) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Transport non connesso');
    }
    channel.sink.add(jsonEncode(['EVENT', event.toJson()]));
  }

  @override
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Transport non connesso');
    }
    final subId = 'nwc_${_subCounter++}';
    channel.sink.add(jsonEncode(['REQ', subId, ...filters]));
    return _events.stream;
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _sub?.cancel();
    _sub = null;
    final channel = _channel;
    _channel = null;
    _connectedSince = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _closing = false;
  }
}
