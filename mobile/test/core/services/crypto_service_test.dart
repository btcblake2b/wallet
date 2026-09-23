import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFlutterSecureStorage mockStorage;
  late CryptoService cryptoService;
  // In-memory store per simulare FlutterSecureStorage
  final store = <String, String>{};

  setUp(() {
    store.clear();
    mockStorage = MockFlutterSecureStorage();
    // Simula lettura: restituisce il valore salvato in memoria
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return store[key];
    });
    // Simula scrittura: salva in memoria
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String;
      store[key] = value;
    });
    cryptoService = CryptoService(storage: mockStorage);
  });

  group('CryptoService', () {
    test('encryptSeed / decryptSeed roundtrip', () async {
      const seed =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const deviceId = 'test-device-001';

      final encrypted = await cryptoService.encryptSeed(
        seedPhrase: seed,
        deviceId: deviceId,
      );

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(seed)); // Non deve essere in chiaro

      final decrypted = await cryptoService.decryptSeed(
        encryptedSeed: encrypted,
        deviceId: deviceId,
      );

      expect(decrypted, equals(seed));
    });

    test('decryptSeed succeeds with any deviceId (v2 transferable encryption)',
        () async {
      const seed =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const deviceId1 = 'test-device-001';
      const deviceId2 = 'test-device-002';

      final encrypted = await cryptoService.encryptSeed(
        seedPhrase: seed,
        deviceId: deviceId1,
      );

      // V2: la cifratura NON è legata al deviceId (è transferable)
      final decrypted = await cryptoService.decryptSeed(
        encryptedSeed: encrypted,
        deviceId: deviceId2,
      );
      expect(decrypted, equals(seed));
    });

    test('encryptSeed produces different ciphertext each time', () async {
      const seed =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const deviceId = 'test-device-001';

      final encrypted1 = await cryptoService.encryptSeed(
        seedPhrase: seed,
        deviceId: deviceId,
      );
      final encrypted2 = await cryptoService.encryptSeed(
        seedPhrase: seed,
        deviceId: deviceId,
      );

      // Due cifrature della stessa seed devono produrre output diversi (IV random)
      expect(encrypted1, isNot(equals(encrypted2)));
    });
  });
}
