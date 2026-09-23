import 'dart:convert';
import 'dart:io';

import 'swap_models.dart';

/// Store persistente delle sessioni swap + cache idempotenza.
///
/// PERCHÉ (Blueprint §2.7): il provider deve riprendere dopo un riavvio e
/// rispondere in modo identico a una richiesta ripetuta (stesso `request_id`).
/// Scrittura ATOMICA (file temporaneo + rename): un crash a metà scrittura non
/// deve corrompere lo stato — qui ci sono fondi in volo.
class SwapStore {
  SwapStore(this.path, {this.idempotencyTtlSeconds = 86400});

  final String path;
  final int idempotencyTtlSeconds;
  final Map<String, SwapSession> _sessions = {};
  final Map<String, _IdempotencyEntry> _idempotency = {};

  List<SwapSession> all() => _sessions.values.toList();

  SwapSession? byId(String id) => _sessions[id];

  /// Sessione (anche chiusa male) che blocca un nuovo swap sullo stesso hash.
  SwapSession? blockingByPaymentHash(String paymentHashHex) {
    for (final s in _sessions.values) {
      if (s.paymentHashHex == paymentHashHex && s.state.blocksPaymentHash) {
        return s;
      }
    }
    return null;
  }

  /// Sessioni "vive" (il provider ci sta lavorando).
  List<SwapSession> active() =>
      _sessions.values.where((s) => s.state.isActive).toList();

  Future<void> load() async {
    final file = File(path);
    if (!file.existsSync()) return;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return;
    final json = decoded.cast<String, dynamic>();

    final sessions = json['sessions'];
    if (sessions is List) {
      for (final raw in sessions) {
        if (raw is! Map) continue;
        try {
          final s = SwapSession.fromJson(raw.cast<String, dynamic>());
          _sessions[s.id] = s;
        } on FormatException {
          // PERCHÉ: una entry corrotta non deve impedire il load delle altre
          // (i fondi delle sessioni valide restano gestibili).
          continue;
        }
      }
    }

    final idem = json['idempotency'];
    if (idem is Map) {
      final cutoff = _nowSec() - idempotencyTtlSeconds;
      idem.forEach((key, value) {
        if (value is! Map) return;
        final ts = (value['ts'] as num?)?.toInt();
        final response = value['response'];
        if (ts == null || ts < cutoff || response is! Map) return;
        _idempotency['$key'] = _IdempotencyEntry(
          ts: ts,
          response: response.cast<String, dynamic>(),
        );
      });
    }
  }

  /// Risposta già prodotta per [key] (idempotenza), se non scaduta.
  Map<String, dynamic>? idempotentResponse(String key) {
    final entry = _idempotency[key];
    if (entry == null) return null;
    if (entry.ts + idempotencyTtlSeconds < _nowSec()) {
      _idempotency.remove(key);
      return null;
    }
    return entry.response;
  }

  Future<void> rememberResponse(
    String key,
    Map<String, dynamic> response,
  ) async {
    _idempotency[key] = _IdempotencyEntry(ts: _nowSec(), response: response);
    await save();
  }

  Future<void> upsert(SwapSession session) async {
    _sessions[session.id] = session;
    await save();
  }

  Future<void> save() async {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final tmp = File('$path.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'sessions': [for (final s in _sessions.values) s.toJson()],
        'idempotency': {
          for (final e in _idempotency.entries)
            e.key: {'ts': e.value.ts, 'response': e.value.response},
        },
      }),
      flush: true,
    );
    // PERCHÉ: rename sostituisce atomicamente il file precedente — se il
    // processo muore prima, resta la versione precedente (mai un file a metà).
    await tmp.rename(path);
  }

  int _nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

class _IdempotencyEntry {
  _IdempotencyEntry({required this.ts, required this.response});

  final int ts;
  final Map<String, dynamic> response;
}
