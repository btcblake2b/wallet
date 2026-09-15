import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/lightning_connection.dart';

/// Persistenza della connessione Lightning (URI NIP-47).
///
/// // PERCHÉ secure storage: la URI contiene il `secret` client (chiave
/// privata di sessione) — mai in chiaro, mai nei log.
class LightningConnectionStore {
  LightningConnectionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'lightning_nwc_uri';

  final FlutterSecureStorage _storage;

  Future<void> save(LightningConnection connection) =>
      _storage.write(key: _key, value: connection.toUri());

  Future<LightningConnection?> load() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null || value.isEmpty) return null;
      return LightningConnection.fromUri(value);
    } catch (e) {
      // PERCHÉ: URI corrotta/incompatibile → si riparte da zero, senza crash.
      debugPrint('[LoopEngineer] LightningConnectionStore: load fallito');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      // PERCHÉ: storage non disponibile (test/piattaforme senza keyring) →
      // il clear è best-effort e non deve far fallire il flusso di disconnect.
      debugPrint('[LoopEngineer] LightningConnectionStore: clear fallito');
    }
  }
}
