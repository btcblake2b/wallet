import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/wallet_record.dart';

class SecureSeedStorage {
  SecureSeedStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _walletsKey = 'wallet_records_v1'; // Legacy key
  static const String _indexKey = 'wallet_index_v2';
  static const String _walletPrefix = 'wallet_record_v2_';

  final FlutterSecureStorage _secureStorage;

  Future<List<WalletRecord>> loadWallets() async {
    final indexRaw = await _secureStorage.read(key: _indexKey);
    if (indexRaw != null && indexRaw.isNotEmpty) {
      final ids = (jsonDecode(indexRaw) as List<dynamic>).cast<String>();
      final wallets = <WalletRecord>[];
      for (final id in ids) {
        final walletRaw = await _secureStorage.read(key: '$_walletPrefix$id');
        if (walletRaw != null) {
          wallets.add(
            WalletRecord.fromMap(
              jsonDecode(walletRaw) as Map<String, dynamic>,
            ),
          );
        }
      }
      return wallets;
    }

    // Migration from v1
    final oldRaw = await _secureStorage.read(key: _walletsKey);
    if (oldRaw != null && oldRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(oldRaw) as List<dynamic>;
        final wallets = decoded
            .map((item) => WalletRecord.fromMap(item as Map<String, dynamic>))
            .toList();

        final ids = <String>[];
        for (final w in wallets) {
          await _secureStorage.write(
            key: '$_walletPrefix${w.walletId}',
            value: jsonEncode(w.toMap()),
          );
          ids.add(w.walletId);
        }
        await _secureStorage.write(key: _indexKey, value: jsonEncode(ids));
        await _secureStorage.delete(key: _walletsKey);
        return wallets;
      } catch (e) {
        return <WalletRecord>[];
      }
    }

    return <WalletRecord>[];
  }

  Future<void> upsertWallet(WalletRecord wallet) async {
    // 1. Save the wallet record
    await _secureStorage.write(
      key: '$_walletPrefix${wallet.walletId}',
      value: jsonEncode(wallet.toMap()),
    );

    // 2. Update the index if not already present
    final indexRaw = await _secureStorage.read(key: _indexKey);
    final ids = indexRaw != null && indexRaw.isNotEmpty
        ? (jsonDecode(indexRaw) as List<dynamic>).cast<String>()
        : <String>[];

    if (!ids.contains(wallet.walletId)) {
      ids.add(wallet.walletId);
      await _secureStorage.write(key: _indexKey, value: jsonEncode(ids));
    }
  }

  Future<void> deleteWallet(String walletId) async {
    await _secureStorage.delete(key: '$_walletPrefix$walletId');

    final indexRaw = await _secureStorage.read(key: _indexKey);
    if (indexRaw != null && indexRaw.isNotEmpty) {
      final ids = (jsonDecode(indexRaw) as List<dynamic>).cast<String>();
      if (ids.remove(walletId)) {
        await _secureStorage.write(key: _indexKey, value: jsonEncode(ids));
      }
    }
  }

  // Not used anymore but kept for interface compatibility if needed by other services
  Future<void> saveWallets(List<WalletRecord> wallets) async {
    for (final wallet in wallets) {
      await upsertWallet(wallet);
    }
  }

  // ── Web password-protection hooks (audit F1) ────────────────────────────
  // Su native il keyring è protetto dall'OS (Android Keystore / iOS Keychain):
  // la protezione con password è un concetto solo-web, qui è no-op.

  /// Web-only: `true` se il vault è protetto da password (su native sempre false).
  Future<bool> isKeyProtectedAsync() async => false;

  /// Web-only: avvolge la chiave con la password (su native no-op).
  Future<void> enablePasswordProtection(String password) async {}

  /// Web-only: sblocca il vault con la password (su native no-op).
  Future<void> unlockWithPassword(String password) async {}

  /// Hardening 2.4: su native non esiste una cache di chiavi in RAM governata
  /// dall'app (le chiavi a riposo sono nel keyring OS) → no-op per parità di
  /// interfaccia con la variante web (auto-lock / blocco manuale).
  void lock() {}
}
