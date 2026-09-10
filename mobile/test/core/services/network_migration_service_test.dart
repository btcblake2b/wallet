import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/network_migration_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('NetworkMigrationService', () {
    test('isMigrationNeeded false when stored network matches current',
        () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'mainnet');
      final service = NetworkMigrationService(storage: storage);
      expect(await service.isMigrationNeeded(), isFalse);
    });

    test('isMigrationNeeded true when stored network differs (testnet)',
        () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'testnet');
      final service = NetworkMigrationService(storage: storage);
      // PERCHÉ: i dati locali sono stati creati su testnet, la rete configurata
      // ora è mainnet → serve la migrazione (reset).
      expect(await service.isMigrationNeeded(), isTrue);
    });

    test('isMigrationNeeded false on first install (no stored network)',
        () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      final service = NetworkMigrationService(storage: storage);
      expect(await service.isMigrationNeeded(), isFalse);
    });

    test('getStoredNetwork returns the persisted value', () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'mainnet');
      final service = NetworkMigrationService(storage: storage);
      expect(await service.getStoredNetwork(), 'mainnet');
    });

    test('resetAllData clears storage and setStoredNetwork persists', () async {
      final storage = MockSecureStorage();
      when(() => storage.deleteAll()).thenAnswer((_) async {});
      when(
        () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});
      final service = NetworkMigrationService(storage: storage);

      await service.resetAllData();
      await service.setStoredNetwork(BitcoinNetworkConfig.current.name);

      verify(() => storage.deleteAll()).called(1);
      verify(() => storage.write(key: 'network_id', value: 'mainnet'))
          .called(1);
    });
  });
}
