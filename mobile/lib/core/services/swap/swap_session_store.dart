import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'swap_models.dart';

/// Registro locale delle sessioni swap dell'utente (P9).
///
/// // PERCHÉ: le sessioni devono sopravvivere al riavvio dell'app (il
/// // provider custodisce lo stato "vero", ma l'app deve sapere QUALI swap
/// // seguire, con che funding/vout e quale chiave di refund usare).
/// // Niente segreti: solo dati pubblici on-chain + indici di derivazione.
class SwapSessionStore {
  SwapSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'swap_sessions';

  /// Tutte le sessioni note (ordine: più recenti prima).
  Future<List<SwapSession>> all() async {
    final raw = await _readRaw();
    final sessions = <SwapSession>[];
    for (final json in raw) {
      try {
        sessions.add(SwapSession.fromJson(json));
      } catch (e) {
        debugPrint('[LoopEngineer] SwapSessionStore: sessione corrotta: $e');
      }
    }
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  Future<SwapSession?> byId(String swapId) async {
    for (final s in await all()) {
      if (s.swapId == swapId) return s;
    }
    return null;
  }

  /// Inserisce o aggiorna la sessione (match su [SwapSession.swapId]).
  Future<void> upsert(SwapSession session) async {
    final raw = await _readRaw();
    final out = <Map<String, dynamic>>[
      for (final json in raw)
        if ('${json['swap_id']}' != session.swapId) json,
      session.toJson(),
    ];
    await _writeRaw(out);
  }

  Future<void> remove(String swapId) async {
    final raw = await _readRaw();
    await _writeRaw([
      for (final json in raw)
        if ('${json['swap_id']}' != swapId) json,
    ]);
  }

  /// Prossimo indice libero per la chiave di refund (`m/84'/coin'/2'/0/x`).
  ///
  /// // PERCHÉ: ogni swap usa una chiave DIVERSA (mai riuso di chiave); max+1
  /// // evita collisioni anche dopo import di blob esterni.
  Future<int> nextRefundKeyIndex() async {
    var max = -1;
    for (final s in await all()) {
      if (s.refundKeyIndex > max) max = s.refundKeyIndex;
    }
    return max + 1;
  }

  Future<List<Map<String, dynamic>>> _readRaw() async {
    try {
      final stored = await _storage.read(key: _key);
      if (stored == null || stored.isEmpty) return [];
      final decoded = jsonDecode(stored);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
    } catch (e) {
      debugPrint('[LoopEngineer] SwapSessionStore: registro illeggibile: $e');
      return [];
    }
  }

  Future<void> _writeRaw(List<Map<String, dynamic>> sessions) async {
    await _storage.write(key: _key, value: jsonEncode(sessions));
  }
}
