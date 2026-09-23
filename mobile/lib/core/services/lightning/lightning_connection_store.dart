import 'dart:convert';

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

  /// Chiave dello storico dei nodi usati (lista JSON di URI, più recente primo).
  static const String _historyKey = 'lightning_nwc_history';

  /// Tetto dello storico: oltre non serve e lo storage va tenuto piccolo.
  static const int historyMax = 10;

  final FlutterSecureStorage _storage;

  /// Salva la connessione ATTIVA e la registra nello storico.
  ///
  /// // PERCHÉ (18/09/2026): "salvata" = "usata" → lo storico resta sempre
  /// // coerente coi nodi a cui l'utente si è collegato, senza chiamate
  /// // aggiuntive da ricordare in ogni chiamante.
  Future<void> save(LightningConnection connection) async {
    await _storage.write(key: _key, value: connection.toUri());
    await remember(connection);
  }

  /// Storico dei nodi collegati (più recente per primo).
  ///
  /// // PERCHÉ secure storage: ogni voce è una URI col `secret` di sessione —
  /// // mai in chiaro altrove, mai nei log. Best-effort: una voce corrotta viene
  /// // ignorata e su errore si torna lista vuota (la UI mostra solo il campo).
  Future<List<LightningConnection>> history() async {
    try {
      final raw = await _storage.read(key: _historyKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <LightningConnection>[];
      for (final entry in decoded) {
        try {
          out.add(LightningConnection.fromUri('$entry'));
        } on FormatException {
          continue;
        }
      }
      return out;
    } catch (e) {
      debugPrint('[LoopEngineer] LightningConnectionStore: storico illeggibile');
      return const [];
    }
  }

  /// Mette [connection] in testa allo storico (dedup per nodo, tetto
  /// [historyMax]).
  ///
  /// // PERCHÉ dedup per walletPubkey: il nodo è l'identità e il `secret` può
  /// // cambiare → resta una sola voce, aggiornata con l'URI più recente.
  Future<void> remember(LightningConnection connection) async {
    try {
      final current = await history();
      final merged = <LightningConnection>[
        connection,
        ...current.where((c) => c.walletPubkey != connection.walletPubkey),
      ];
      await _storage.write(
        key: _historyKey,
        value: jsonEncode([
          for (final c in merged.take(historyMax)) c.toUri(),
        ]),
      );
    } catch (e) {
      debugPrint('[LoopEngineer] LightningConnectionStore: remember fallito');
    }
  }

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
