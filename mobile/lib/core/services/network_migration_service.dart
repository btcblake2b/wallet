import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/bitcoin_network_config.dart';

/// Gestisce il reset dei dati locali quando cambia la rete Bitcoin configurata.
///
/// PERCHÉ: un wallet creato su testnet ha indirizzi `tb1...` e path
/// `m/84'/1'/0'`; su mainnet la derivazione cambia (`bc1...`, `m/84'/0'/0'`),
/// quindi gli stessi dati diventerebbero inutilizzabili o mostrerebbero saldi
/// errati. Al passaggio testnet → mainnet (2026-08-31) i dati testnet vanno
/// eliminati e l'utente riparte dall'onboarding.
class NetworkMigrationService {
  NetworkMigrationService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kNetworkKey = 'network_id';

  /// Rete con cui sono stati creati i dati locali (null = prima installazione).
  Future<String?> getStoredNetwork() => _storage.read(key: _kNetworkKey);

  /// Registra la rete corrente come quella dei dati locali.
  Future<void> setStoredNetwork(String network) =>
      _storage.write(key: _kNetworkKey, value: network);

  /// True se i dati locali appartengono a una rete diversa da quella configurata.
  /// PERCHÉ: se non c'è rete salvata (prima installazione) non serve migrare.
  Future<bool> isMigrationNeeded() async {
    final stored = await getStoredNetwork();
    return stored != null && stored != BitcoinNetworkConfig.current.name;
  }

  /// Cancella TUTTI i dati locali (wallet, seed, onboarding, consent, chiavi).
  /// PERCHÉ (mainnet): i wallet testnet vanno eliminati per ripartire puliti —
  /// l'utente ha confermato che i tBTC su testnet non hanno valore.
  Future<void> resetAllData() async {
    await _storage.deleteAll();
    // DEBUG: traccia il reset per diagnosi post-deploy
    debugPrint(
      '[NetworkMigrationService] reset dati: rete=${BitcoinNetworkConfig.current.name}',
    );
  }
}
