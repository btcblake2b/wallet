import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  CryptoService({
    AesGcm? algorithm,
    FlutterSecureStorage? storage,
  })  : _algorithm = algorithm ?? AesGcm.with256bits(),
        _storage = storage ?? const FlutterSecureStorage();

  static const int _nonceLength = 12;
  static const int _secretLength = 32;
  static const String _masterKeyAlias = 'app_master_key';
  static const String _ed25519PrivateKeyAlias = 'ed25519_private_key_v1';

  // ── Audit F1: password-based key-wrapping (solo web) ──
  // Su web flutter_secure_storage usa localStorage (chiave AES estraibile
  // salvata accanto ai dati): la master key e la chiave ED25519 vengono
  // quindi AVVOLTE con un KEK derivato dalla password (PBKDF2-SHA256 600k +
  // AES-256-GCM) e le versioni in chiaro eliminate.
  static const String _masterKeyWrappedAlias = 'app_master_key_wrapped_v1';
  static const String _ed25519WrappedAlias = 'ed25519_private_key_wrapped_v1';
  static const int _webWrapIterations = 600000;
  static const int _webWrapSaltLength = 16;

  final AesGcm _algorithm;
  final FlutterSecureStorage _storage;
  final Random _random = Random.secure();

  // Cache in memoria delle chiavi sbloccate (solo web, F1).
  SecretKey? _cachedWebMasterKey;
  Uint8List? _cachedWebEd25519Seed;

  /// Web (audit F1): `true` se master key o chiave ED25519 sono avvolte
  /// con password. Su native è sempre `false` (keyring OS).
  Future<bool> isWebKeyVaultProtected() async {
    if (!kIsWeb) return false;
    final masterWrapped = await _storage.read(key: _masterKeyWrappedAlias);
    final edWrapped = await _storage.read(key: _ed25519WrappedAlias);
    return (masterWrapped != null && masterWrapped.isNotEmpty) ||
        (edWrapped != null && edWrapped.isNotEmpty);
  }

  /// Web (audit F1): avvolge master key e chiave ED25519 con la password e
  /// rimuove le versioni in chiaro. Idempotente (no-op se già protetto).
  Future<void> enableWebPasswordProtection(String password) async {
    if (!kIsWeb || password.isEmpty) return;
    if (await isWebKeyVaultProtected()) return;

    // Master key (esistente o nuova): la chiave viene AVVOLTA, non rigenerata,
    // così i seed esistenti restano decifrabili.
    final masterKey = await _getOrCreateMasterKey();
    final masterBytes = await masterKey.extractBytes();
    final masterWrapped = await _wrapWithPassword(password, masterBytes);
    await _storage.write(key: _masterKeyWrappedAlias, value: masterWrapped);
    await _storage.delete(key: _masterKeyAlias);

    // Chiave ED25519 (esistente o nuova).
    final keyPair = await getOrCreateEd25519KeyPair();
    final keyPairData = await keyPair.extract();
    final edWrapped = await _wrapWithPassword(password, keyPairData.bytes);
    await _storage.write(key: _ed25519WrappedAlias, value: edWrapped);
    await _storage.delete(key: _ed25519PrivateKeyAlias);

    _cachedWebMasterKey = masterKey;
    _cachedWebEd25519Seed = Uint8List.fromList(keyPairData.bytes);
  }

  /// Web (audit F1): sblocca il vault chiavi con la password. Le chiavi
  /// restano SOLO in memoria ([_cachedWebMasterKey] / [_cachedWebEd25519Seed]).
  Future<void> unlockWebStorage(String password) async {
    if (!kIsWeb) return;
    if (_cachedWebMasterKey != null && _cachedWebEd25519Seed != null) return;

    final masterWrapped = await _storage.read(key: _masterKeyWrappedAlias);
    if (masterWrapped != null && masterWrapped.isNotEmpty) {
      final masterBytes = await _unwrapWithPassword(password, masterWrapped);
      _cachedWebMasterKey = SecretKey(masterBytes);
    }
    final edWrapped = await _storage.read(key: _ed25519WrappedAlias);
    if (edWrapped != null && edWrapped.isNotEmpty) {
      _cachedWebEd25519Seed = await _unwrapWithPassword(password, edWrapped);
    }
  }

  /// Web (audit F1 + hardening 2.4): rimuove le chiavi dalla memoria
  /// (lock/logout/auto-lock per inattività o pagina nascosta).
  void lockWebStorage() {
    // PERCHÉ (hardening 2.4): best-effort wipe dei buffer prima del drop —
    // Dart non garantisce lo zeroing della memoria, ma azzerare riduce la
    // finestra in cui il seed ED25519 resta leggibile in un heap dump.
    final edSeed = _cachedWebEd25519Seed;
    if (edSeed != null) {
      edSeed.fillRange(0, edSeed.length, 0);
    }
    // NOTA: SecretKey incapsula i byte e le String Dart sono immutabili:
    // non azzerabili — l'unica opzione è eliminare il riferimento.
    _cachedWebMasterKey = null;
    _cachedWebEd25519Seed = null;
  }

  /// Deriva il KEK (256 bit) dalla password: PBKDF2-HMAC-SHA256 via WebCrypto
  /// (package cryptography: su web usa automaticamente Web Crypto API).
  Future<SecretKey> _deriveWebKek(
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Avvolge [plaintext] con AES-256-GCM usando il KEK derivato dalla password.
  Future<String> _wrapWithPassword(
    String password,
    List<int> plaintext,
  ) async {
    final salt = _randomBytes(_webWrapSaltLength);
    final kek = await _deriveWebKek(password, salt, _webWrapIterations);
    final nonce = _randomBytes(_nonceLength);
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: kek,
      nonce: nonce,
    );
    return jsonEncode(<String, dynamic>{
      'iterations': _webWrapIterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// Sblocca [blob] con AES-256-GCM usando il KEK derivato dalla password.
  Future<Uint8List> _unwrapWithPassword(String password, String blob) async {
    final payload = jsonDecode(blob) as Map<String, dynamic>;
    final iterations = payload['iterations'] as int;
    final salt = base64Decode(payload['salt'] as String);
    final kek = await _deriveWebKek(password, salt, iterations);
    final box = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );
    final clear = await _algorithm.decrypt(box, secretKey: kek);
    return Uint8List.fromList(clear);
  }

  /// Gets or creates a master key stored in secure storage.
  Future<SecretKey> _getOrCreateMasterKey() async {
    // Web (audit F1): usa la chiave sbloccata in memoria, altrimenti se il
    // vault è protetto da password l'accesso è negato (fail-closed).
    if (kIsWeb) {
      if (_cachedWebMasterKey != null) return _cachedWebMasterKey!;
      final wrapped = await _storage.read(key: _masterKeyWrappedAlias);
      if (wrapped != null && wrapped.isNotEmpty) {
        throw StateError(
          'CryptoService (web): master key protetta da password. '
          'Chiamare unlockWebStorage().',
        );
      }
    }

    String? storedKey = await _storage.read(key: _masterKeyAlias);
    if (storedKey == null) {
      final newKeyBytes = _randomBytes(_secretLength);
      storedKey = base64Encode(newKeyBytes);
      await _storage.write(key: _masterKeyAlias, value: storedKey);
    }
    final masterKey = SecretKey(base64Decode(storedKey));
    if (kIsWeb) _cachedWebMasterKey = masterKey;
    return masterKey;
  }

  static const String _transferableEncryptionSaltV2 = 'transferable_seed_v2';

  Future<String> encryptSeed({
    required String seedPhrase,
    required String deviceId,
  }) async {
    // Versione 2: encryption NON legata al deviceId, così il seed può essere
    // trasferito/importato su un altro telefono.
    final masterKey = await _getOrCreateMasterKey();
    final encryptionKey =
        await _deriveKey(masterKey, _transferableEncryptionSaltV2);

    final nonce = _randomBytes(_nonceLength);

    final encStartTime = DateTime.now().millisecondsSinceEpoch;
    final secretBox = kIsWeb
        ? await _algorithm.encrypt(
            utf8.encode(seedPhrase),
            secretKey: encryptionKey,
            nonce: nonce,
          )
        : await compute(
            (data) async {
              return data.algorithm.encrypt(
                data.data,
                secretKey: data.secretKey,
                nonce: data.nonce,
              );
            },
            _EncryptData(
              _algorithm,
              utf8.encode(seedPhrase),
              encryptionKey,
              nonce,
            ),
          );
    final encEndTime = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('encryptSeed dt=${encEndTime - encStartTime}ms');

    return jsonEncode(<String, dynamic>{
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
      // Nota: non serve salvare versioni nel payload perché la decryptSeed fa fallback.
    });
  }

  Future<String> decryptSeed({
    required String encryptedSeed,
    required String deviceId,
  }) async {
    final payload = jsonDecode(encryptedSeed) as Map<String, dynamic>;
    final masterKey = await _getOrCreateMasterKey();

    final secretBox = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    // 1) Prova decrittografia v2 (transferable)
    final decryptionKeyV2 =
        await _deriveKey(masterKey, _transferableEncryptionSaltV2);
    try {
      final decStart = DateTime.now().millisecondsSinceEpoch;
      final clearBytesV2 = kIsWeb
          ? await _algorithm.decrypt(
              secretBox,
              secretKey: decryptionKeyV2,
            )
          : await compute(
              (data) async {
                return data.algorithm.decrypt(
                  data.secretBox,
                  secretKey: data.secretKey,
                );
              },
              _DecryptData(_algorithm, secretBox, decryptionKeyV2),
            );
      final decEnd = DateTime.now().millisecondsSinceEpoch;
      if (kDebugMode) debugPrint('decryptSeed v2 dt=${decEnd - decStart}ms');
      return utf8.decode(clearBytesV2);
    } catch (_) {
      // 2) Fallback: decrypt seed legacy legato al deviceId (v1)
    }

    final decryptionKeyV1 = await _deriveKey(masterKey, deviceId);
    final decV1Start = DateTime.now().millisecondsSinceEpoch;
    final clearBytesV1 = kIsWeb
        ? await _algorithm.decrypt(
            secretBox,
            secretKey: decryptionKeyV1,
          )
        : await compute(
            (data) async {
              return data.algorithm.decrypt(
                data.secretBox,
                secretKey: data.secretKey,
              );
            },
            _DecryptData(_algorithm, secretBox, decryptionKeyV1),
          );
    final decV1End = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('decryptSeed v1 dt=${decV1End - decV1Start}ms');
    return utf8.decode(clearBytesV1);
  }

  /// Gets or creates the device's ED25519 key pair.
  /// The private key is stored persistently in FlutterSecureStorage.
  Future<SimpleKeyPair> getOrCreateEd25519KeyPair() async {
    // Web (audit F1): usa il seed sbloccato in memoria; se il vault è protetto
    // da password l'accesso è negato (fail-closed).
    if (kIsWeb) {
      if (_cachedWebEd25519Seed != null) {
        return Ed25519().newKeyPairFromSeed(_cachedWebEd25519Seed!);
      }
      final wrapped = await _storage.read(key: _ed25519WrappedAlias);
      if (wrapped != null && wrapped.isNotEmpty) {
        throw StateError(
          'CryptoService (web): chiave ED25519 protetta da password. '
          'Chiamare unlockWebStorage().',
        );
      }
    }

    final storedPrivateKey = await _storage.read(key: _ed25519PrivateKeyAlias);
    if (storedPrivateKey != null && storedPrivateKey.isNotEmpty) {
      final seed = base64Decode(storedPrivateKey);
      if (kIsWeb) _cachedWebEd25519Seed = seed;
      return Ed25519().newKeyPairFromSeed(seed);
    }

    // Generate new ED25519 key pair
    final keyPair = await Ed25519().newKeyPair();
    final keyPairData = await keyPair.extract();

    // Store private key (seed bytes)
    final privateKeyBase64 = base64Encode(keyPairData.bytes);
    await _storage.write(key: _ed25519PrivateKeyAlias, value: privateKeyBase64);
    if (kIsWeb) {
      _cachedWebEd25519Seed = Uint8List.fromList(keyPairData.bytes);
    }

    // Cache public key for quick access
    final publicKeyBase64 = base64Encode(keyPairData.publicKey.bytes);
    await _storage.write(
      key: '${_ed25519PrivateKeyAlias}_pub',
      value: publicKeyBase64,
    );

    return keyPair;
  }

  /// Returns the base64-encoded ED25519 public key for this device.
  Future<String> getEd25519PublicKeyBase64() async {
    final storedPublicKey = await _storage.read(
      key: '${_ed25519PrivateKeyAlias}_pub',
    );
    if (storedPublicKey != null && storedPublicKey.isNotEmpty) {
      return storedPublicKey;
    }

    // Derive from private key
    final keyPair = await getOrCreateEd25519KeyPair();
    final keyPairData = await keyPair.extract();
    final publicKeyBase64 = base64Encode(keyPairData.publicKey.bytes);

    await _storage.write(
      key: '${_ed25519PrivateKeyAlias}_pub',
      value: publicKeyBase64,
    );
    return publicKeyBase64;
  }

  /// Signs a mutation message using the device's ED25519 private key.
  /// Replaces the old HMAC-SHA256 scheme with asymmetric ED25519 signatures.
  Future<String> signMutation({
    required String walletId,
    required String deviceId,
    String? targetDeviceId,
    required String nonce,
    required int timestamp,
  }) async {
    final target = targetDeviceId ?? '';
    final message = utf8.encode(
      '$walletId|$deviceId|$target|$nonce|$timestamp',
    );

    final keyPair = await getOrCreateEd25519KeyPair();

    final signature = await Ed25519().sign(
      message,
      keyPair: keyPair,
    );

    return base64Encode(signature.bytes);
  }

  /// F2 — Firma la claim del ricevente: prova il possesso della chiave privata
  /// del device verso il server (challenge-response su completeTransfer).
  Future<String> signTargetClaim({
    required String walletId,
    required String nonce,
    required String targetDeviceId,
  }) async {
    final message = utf8.encode('$walletId|$nonce|$targetDeviceId');
    final keyPair = await getOrCreateEd25519KeyPair();
    final signature = await Ed25519().sign(message, keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  Future<SecretKey> _deriveTransitKey(String walletId, String nonce) async {
    final saltBytes = utf8.encode('$walletId|$nonce|transfer_transit_salt');
    final hash = await Sha256().hash(saltBytes);
    return SecretKey(hash.bytes.sublist(0, 32));
  }

  Future<String> encryptSeedForTransit({
    required String seedPhrase,
    required String walletId,
    required String nonce,
  }) async {
    final encryptionKey = await _deriveTransitKey(walletId, nonce);
    final aesNonce = _randomBytes(_nonceLength);
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final secretBox = kIsWeb
        ? await _algorithm.encrypt(
            utf8.encode(seedPhrase),
            secretKey: encryptionKey,
            nonce: aesNonce,
          )
        : await compute(
            (data) async {
              return data.algorithm.encrypt(
                data.data,
                secretKey: data.secretKey,
                nonce: data.nonce,
              );
            },
            _EncryptData(
              _algorithm,
              utf8.encode(seedPhrase),
              encryptionKey,
              aesNonce,
            ),
          );
    final t1 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('encryptSeedForTransit dt=${t1 - t0}ms');

    return jsonEncode(<String, dynamic>{
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<String> decryptSeedForTransit({
    required String encryptedSeed,
    required String walletId,
    required String nonce,
  }) async {
    final payload = jsonDecode(encryptedSeed) as Map<String, dynamic>;
    final decryptionKey = await _deriveTransitKey(walletId, nonce);

    final secretBox = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    final t0 = DateTime.now().millisecondsSinceEpoch;
    final clearBytes = kIsWeb
        ? await _algorithm.decrypt(
            secretBox,
            secretKey: decryptionKey,
          )
        : await compute(
            (data) async {
              return data.algorithm.decrypt(
                data.secretBox,
                secretKey: data.secretKey,
              );
            },
            _DecryptData(_algorithm, secretBox, decryptionKey),
          );
    final t1 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('decryptSeedForTransit dt=${t1 - t0}ms');

    return utf8.decode(clearBytes);
  }

  static const String _x25519KdfInfo = 'tlw_x25519_aes_key_v1';

  /// Generates an ephemeral X25519 key pair.
  Future<SimpleKeyPair> generateX25519KeyPair() async {
    return X25519().newKeyPair();
  }

  /// Encrypts a plaintext string using a shared secret derived from our private key and the remote public key.
  ///
  /// v2: Usa HKDF-SHA256 per derivare la chiave AES dallo shared secret X25519
  /// (invece di usare i raw bytes). Il payload include 'kdf': 'hkdf-sha256'
  /// per permettere il fallback del decrypt ai payload legacy v1.
  Future<String> encryptWithX25519({
    required String plaintext,
    required SimpleKeyPair ourKeyPair,
    required List<int> remotePublicKeyBytes,
  }) async {
    final remotePublicKey = SimplePublicKey(
      remotePublicKeyBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: ourKeyPair,
      remotePublicKey: remotePublicKey,
    );

    // PERCHÉ: X25519 raw shared secret non è uniformemente distribuito.
    // HKDF-SHA256 lo trasforma in una chiave AES-256 crittograficamente solida
    // (NIST SP 800-56A Rev. 3, OWASP Cryptographic Storage Cheat Sheet).
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );
    final encryptionKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode(_x25519KdfInfo),
    );

    final nonce = _randomBytes(_nonceLength);
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: encryptionKey,
      nonce: nonce,
    );

    return jsonEncode(<String, dynamic>{
      'kdf': 'hkdf-sha256',
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  /// Decrypts an encrypted payload string using a shared secret derived from our private key and the remote public key.
  ///
  /// Supporta sia payload v2 (HKDF-SHA256, campo 'kdf') che payload legacy v1
  /// (raw shared secret, senza campo 'kdf'). Il fallback v1 verrà rimosso
  /// in una release futura dopo che tutti i transfer in volo saranno completati.
  Future<String> decryptWithX25519({
    required String encryptedPayload,
    required SimpleKeyPair ourKeyPair,
    required List<int> remotePublicKeyBytes,
  }) async {
    final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    final remotePublicKey = SimplePublicKey(
      remotePublicKeyBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: ourKeyPair,
      remotePublicKey: remotePublicKey,
    );

    final isV2 = payload['kdf'] == 'hkdf-sha256';
    final SecretKey decryptionKey;
    if (isV2) {
      // PERCHÉ: v2 usa HKDF-SHA256 per derivare la chiave AES dallo shared
      // secret X25519, conforme a NIST SP 800-56A Rev. 3.
      final hkdf = Hkdf(
        hmac: Hmac.sha256(),
        outputLength: 32,
      );
      decryptionKey = await hkdf.deriveKey(
        secretKey: sharedSecret,
        info: utf8.encode(_x25519KdfInfo),
      );
      debugPrint(
        'decryptWithX25519: usando HKDF-SHA256 (v2)',
      );
    } else {
      // PERCHÉ: Fallback per payload legacy v1 che usavano raw shared secret.
      // Questi payload sono generati da versioni precedenti dell'app.
      // Il fallback verrà rimosso dopo 1 release.
      final sharedSecretBytes = await sharedSecret.extractBytes();
      decryptionKey = SecretKey(sharedSecretBytes.sublist(0, 32));
      debugPrint(
        'decryptWithX25519: usando raw shared secret (legacy v1)',
      );
    }

    final secretBox = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: decryptionKey,
    );

    return utf8.decode(clearBytes);
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  /// Derives a sub-key from the master key and a salt (like deviceId or context string).
  Future<SecretKey> _deriveKey(SecretKey masterKey, String salt) async {
    final saltBytes = utf8.encode(salt);

    // Using HMAC-SHA256 as a simple KDF to derive a sub-key
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      saltBytes,
      secretKey: masterKey,
    );

    return SecretKey(mac.bytes.take(_secretLength).toList());
  }
}

class _EncryptData {
  final AesGcm algorithm;
  final List<int> data;
  final SecretKey secretKey;
  final Uint8List nonce;

  _EncryptData(this.algorithm, this.data, this.secretKey, this.nonce);
}

class _DecryptData {
  final AesGcm algorithm;
  final SecretBox secretBox;
  final SecretKey secretKey;

  _DecryptData(this.algorithm, this.secretBox, this.secretKey);
}
