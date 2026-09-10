import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';

void main() {
  group('WalletRecord', () {
    test('should instantiate', () {
      final sut = WalletRecord(
        walletId: 'test_wallet_id',
        encryptedSeed: 'test_encrypted_seed',
        publicAddress: 'test_public_address',
        deviceId: 'test_device_id',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(sut, isNotNull);
      expect(sut.walletId, 'test_wallet_id');
    });

    test('fromMap migra i record legacy ignorando il campo state', () {
      // PERCHÉ: i record salvati prima della rimozione di locked/unlocked
      // contengono 'state' — fromMap deve ignorarlo senza errori.
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'tb1qlegacy',
        'state': 'locked',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.walletId, 'legacy_id');
      expect(sut.publicAddress, 'tb1qlegacy');
    });

    test('default kind hot e accountXpub null per i wallet seed', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );

      // PERCHÉ: default hot = zero breaking su tutti i wallet esistenti.
      expect(sut.kind, WalletKind.hot);
      expect(sut.accountXpub, isNull);
    });

    test('fromMap senza kind migra a hot (record pre-watch-only)', () {
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.kind, WalletKind.hot);
      expect(sut.accountXpub, isNull);
    });

    test('round-trip toMap/fromMap preserva kind watchOnly e accountXpub', () {
      final sut = WalletRecord(
        walletId: 'wo_id',
        encryptedSeed: '',
        publicAddress: 'bc1qwatch',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        kind: WalletKind.watchOnly,
        accountXpub: 'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz',
      );

      final restored = WalletRecord.fromMap(sut.toMap());

      expect(restored.kind, WalletKind.watchOnly);
      expect(restored.accountXpub, sut.accountXpub);
      expect(restored.encryptedSeed, '');
    });

    test('copyWith cambia kind/accountXpub e clearAccountXpub azzera', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );

      final asWatch = sut.copyWith(
        kind: WalletKind.watchOnly,
        accountXpub: 'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz',
      );
      expect(asWatch.kind, WalletKind.watchOnly);
      expect(asWatch.accountXpub, isNotNull);

      final cleared = asWatch.copyWith(clearAccountXpub: true);
      expect(cleared.kind, WalletKind.watchOnly);
      expect(cleared.accountXpub, isNull);
    });
  });
}
