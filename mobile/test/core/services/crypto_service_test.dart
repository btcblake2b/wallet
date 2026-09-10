import 'dart:convert';

import 'package:cryptography/cryptography.dart';
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

    test('signMutation produces valid signature format', () async {
      const walletId = 'wallet-test-123';
      const deviceId = 'test-device-001';
      const nonce = 'nonce-abc-123';
      const timestamp = 1712345678;

      final signature = await cryptoService.signMutation(
        walletId: walletId,
        deviceId: deviceId,
        nonce: nonce,
        timestamp: timestamp,
      );

      expect(signature, isNotEmpty);
      // La firma Ed25519 in base64 è lunga ~88 caratteri
      expect(signature.length, greaterThan(50));
    });

    test(
        'signTargetClaim produces valid signature verifiable with public key (F2)',
        () async {
      const walletId = 'wallet-test-123';
      const nonce = 'nonce-abc-123';
      const targetDeviceId = 'target-device-999';

      final signature = await cryptoService.signTargetClaim(
        walletId: walletId,
        nonce: nonce,
        targetDeviceId: targetDeviceId,
      );
      expect(signature, isNotEmpty);
      // La firma Ed25519 in base64 è lunga ~88 caratteri
      expect(signature.length, greaterThan(50));

      // Round-trip (F2): la firma deve essere verificabile con la chiave
      // pubblica del device, come farà il server in completeTransfer.
      final publicKeyBase64 = await cryptoService.getEd25519PublicKeyBase64();
      final publicKey = SimplePublicKey(
        base64Decode(publicKeyBase64),
        type: KeyPairType.ed25519,
      );

      final message = utf8.encode('$walletId|$nonce|$targetDeviceId');
      final isValid = await Ed25519().verify(
        message,
        signature: Signature(
          base64Decode(signature),
          publicKey: publicKey,
        ),
      );
      expect(isValid, isTrue);

      // La stessa firma NON deve verificare per un target diverso
      final wrongMessage = utf8.encode('$walletId|$nonce|altro-device');
      final isInvalid = await Ed25519().verify(
        wrongMessage,
        signature: Signature(
          base64Decode(signature),
          publicKey: publicKey,
        ),
      );
      expect(isInvalid, isFalse);
    });

    test('encryptSeedForTransit / decryptSeedForTransit roundtrip', () async {
      const seed =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const walletId = 'wallet-test-123';
      const nonce = 'transit-nonce-001';

      final encrypted = await cryptoService.encryptSeedForTransit(
        seedPhrase: seed,
        walletId: walletId,
        nonce: nonce,
      );

      expect(encrypted, isNotEmpty);

      final decrypted = await cryptoService.decryptSeedForTransit(
        encryptedSeed: encrypted,
        walletId: walletId,
        nonce: nonce,
      );

      expect(decrypted, equals(seed));
    });

    test('generateX25519KeyPair produces distinct key pairs', () async {
      final pairA = await cryptoService.generateX25519KeyPair();
      final pairB = await cryptoService.generateX25519KeyPair();

      final pubA = await pairA.extractPublicKey();
      final pubB = await pairB.extractPublicKey();

      expect(pubA.bytes, isNot(equals(pubB.bytes)));
      expect(pubA.bytes.length, greaterThan(0));
    });

    test('X25519 encrypt/decrypt roundtrip between two devices', () async {
      // PERCHÉ (P1.2): copre il flusso QR/WebRTC — A cifra il seed per B,
      // B lo decifra con la propria chiave privata (ECDH + AES-GCM).
      const plaintext = 'seed-segreto-da-trasferire';

      final keyA = await cryptoService.generateX25519KeyPair(); // mittente
      final keyB = await cryptoService.generateX25519KeyPair(); // ricevente
      final pubA = await keyA.extractPublicKey();
      final pubB = await keyB.extractPublicKey();

      final encrypted = await cryptoService.encryptWithX25519(
        plaintext: plaintext,
        ourKeyPair: keyA,
        remotePublicKeyBytes: pubB.bytes,
      );

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));

      final decrypted = await cryptoService.decryptWithX25519(
        encryptedPayload: encrypted,
        ourKeyPair: keyB,
        remotePublicKeyBytes: pubA.bytes,
      );

      expect(decrypted, equals(plaintext));
    });

    test('X25519 decrypt fails with wrong receiver key (attacker)', () async {
      const plaintext = 'dato-sensibile';
      final keyA = await cryptoService.generateX25519KeyPair();
      final keyB = await cryptoService.generateX25519KeyPair();
      final keyC = await cryptoService.generateX25519KeyPair(); // attaccante
      final pubA = await keyA.extractPublicKey();
      final pubB = await keyB.extractPublicKey();

      final encrypted = await cryptoService.encryptWithX25519(
        plaintext: plaintext,
        ourKeyPair: keyA,
        remotePublicKeyBytes: pubB.bytes,
      );

      // C prova a decifrare con la sua chiave → shared secret diverso →
      // la verifica AES-GCM fallisce.
      await expectLater(
        () => cryptoService.decryptWithX25519(
          encryptedPayload: encrypted,
          ourKeyPair: keyC,
          remotePublicKeyBytes: pubA.bytes,
        ),
        throwsA(anything),
      );
    });
  });
}
