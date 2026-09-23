import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../nostr/nostr_crypto.dart';
import 'swap_models.dart';

/// Persistenza del collegamento al provider swap (P9).
///
/// Salvaguardia due cose in secure storage:
/// - la URI del provider (`nostr+swap://…`) — pubblica, ma comoda da tenere;
/// - la chiave privata client (hex 64) — SEGRETO: genera l'identità Nostr
///   dell'app verso il provider, mai loggata.
///
/// // PERCHÉ storage iniettabile: stesso pattern di LightningConnectionStore,
/// // i test usano un mock in-memory.
class SwapProviderStore {
  SwapProviderStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _uriKey = 'swap_provider_uri';
  static const String _secretKey = 'swap_client_secret';
  static const String _urisKey = 'swap_provider_uris';

  /// Quante URI recenti tenere nel menu a tendina.
  static const int _maxKnownUris = 5;

  /// URI dei provider usati di recente (più recenti prima, max 5).
  ///
  /// // PERCHÉ: la URI è pubblica (pubkey + relay) e ridigitarla a mano è
  /// // error-prone: il menu a tendina riempie il campo al volo.
  Future<List<String>> knownUris() async {
    try {
      final stored = await _storage.read(key: _urisKey);
      if (stored == null || stored.isEmpty) return const [];
      final decoded = jsonDecode(stored);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .take(_maxKnownUris)
          .toList();
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProviderStore: storico URI corrotto: $e');
      return const [];
    }
  }

  /// Ricorda una URI (dedup, più recente in testa, cap a [_maxKnownUris]).
  Future<void> rememberUri(String uri) async {
    final current = await knownUris();
    final updated = <String>[
      uri,
      ...current.where((u) => u != uri),
    ].take(_maxKnownUris).toList();
    await _storage.write(key: _urisKey, value: jsonEncode(updated));
  }

  /// Salva provider + chiave client (chiamata dopo un connect riuscito).
  Future<void> save(SwapProvider provider, {required String clientSecretHex}) async {
    await _storage.write(key: _uriKey, value: provider.toUri());
    await _storage.write(key: _secretKey, value: clientSecretHex.toLowerCase());
  }

  /// Provider salvato, o null se l'app non è mai stata collegata.
  Future<SwapProvider?> loadProvider() async {
    try {
      final uri = await _storage.read(key: _uriKey);
      if (uri == null || uri.isEmpty) return null;
      return SwapProvider.fromUri(uri);
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProviderStore: URI corrotta ignorata: $e');
      return null;
    }
  }

  /// Chiave client esistente, o null.
  Future<String?> loadClientSecret() async {
    try {
      final secret = await _storage.read(key: _secretKey);
      return (secret == null || secret.isEmpty) ? null : secret;
    } catch (e) {
      debugPrint('[LoopEngineer] SwapProviderStore: secret illeggibile: $e');
      return null;
    }
  }

  /// Chiave client esistente o appena generata (e persistita).
  ///
  /// // PERCHÉ: l'identità Nostr del client deve essere STABILE — se
  /// // cambiasse, il provider non riconoscerebbe più le sessioni aperte
  /// // (clientPubkey è la chiave di ownership delle swap).
  Future<String> ensureClientSecret() async {
    final existing = await loadClientSecret();
    if (existing != null) return existing;
    final generated = NostrCrypto.randomHex32();
    await _storage.write(key: _secretKey, value: generated);
    debugPrint('[LoopEngineer] SwapProviderStore: nuova chiave client generata');
    return generated;
  }

  /// Rimuove collegamento e chiave (disconnessione completa).
  ///
  /// ⚠️ Le sessioni swap attive NON vengono toccate: restano recuperabili
  /// dal blob/registro sessioni.
  Future<void> clear() async {
    await _storage.delete(key: _uriKey);
    await _storage.delete(key: _secretKey);
  }
}
