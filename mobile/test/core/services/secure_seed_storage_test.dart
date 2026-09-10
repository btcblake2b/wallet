import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/services/secure_seed_storage_io.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureSeedStorage', () {
    late MockFlutterSecureStorage mockFlutterSecureStorage;
    late SecureSeedStorage sut;

    setUp(() {
      mockFlutterSecureStorage = MockFlutterSecureStorage();
      sut = SecureSeedStorage(secureStorage: mockFlutterSecureStorage);
    });

    test('should instantiate', () {
      expect(sut, isNotNull);
    });

    // TODO: Implementa test per i metodi pubblici
    // test('loadWallets should ...', () { ... });
    // test('upsertWallet should ...', () { ... });
    // test('deleteWallet should ...', () { ... });
    // test('saveWallets should ...', () { ... });
  });
}
