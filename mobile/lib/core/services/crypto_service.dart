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
  // salvata accanto ai dati): la master key viene quindi AVVOLTA con un KEK
  // derivato dalla password (PBKDF2-SHA256 600k + AES-256-GCM) e la versione
  // in chiaro eliminata.
  // Audit SEC-02: gli alias ED25519 qui sotto restano SOLO per la pulizia
  // dei blob legacy del vecchio trasferimento (feature rimossa dal fork).
  static const String _masterKeyWrappedAlias = 'app_master_key_wrapped_v1';
  static const String _ed25519WrappedAlias = 'ed25519_private_key_wrapped_v1';
  static const int _webWrapIterations = 600000;
  static const int _webWrapSaltLength = 16;

  final AesGcm _algorithm;
  final FlutterSecureStorage _storage;
  final Random _random = Random.secure();

  // Cache in memoria della master key sbloccata (solo web, F1).
  // Audit SEC-02: la cache del seed ED25519 è stata rimossa insieme al
  // codice del vecchio trasferimento.
  SecretKey? _cachedWebMasterKey;

  /// Web (audit F1): `true` se la master key è avvolta con password.
  /// Su native è sempre `false` (keyring OS).
  Future<bool> isWebKeyVaultProtected() async {
    if (!kIsWeb) return false;
    // Audit SEC-02: conta solo la master key — la chiave ED25519 del vecchio
    // trasferimento non esiste più (eventuali blob residui sono ignorati).
    final masterWrapped = await _storage.read(key: _masterKeyWrappedAlias);
    return masterWrapped != null && masterWrapped.isNotEmpty;
  }

  /// Web (audit F1): avvolge la master key con la password e rimuove la
  /// versione in chiaro. Idempotente (no-op se già protetto).
  Future<void> enableWebPasswordProtection(String password) async {
    if (!kIsWeb || password.isEmpty) return;
    // Audit SEC-02: pulisce i blob ED25519 del vecchio trasferimento.
    await _cleanupLegacyEd25519Keys();
    if (await isWebKeyVaultProtected()) return;

    // Master key (esistente o nuova): la chiave viene AVVOLTA, non rigenerata,
    // così i seed esistenti restano decifrabili.
    final masterKey = await _getOrCreateMasterKey();
    final masterBytes = await masterKey.extractBytes();
    final masterWrapped = await _wrapWithPassword(password, masterBytes);
    await _storage.write(key: _masterKeyWrappedAlias, value: masterWrapped);
    await _storage.delete(key: _masterKeyAlias);

    _cachedWebMasterKey = masterKey;
  }

  /// Web (audit F1): sblocca il vault chiavi con la password. La chiave
  /// resta SOLO in memoria ([_cachedWebMasterKey]).
  Future<void> unlockWebStorage(String password) async {
    if (!kIsWeb) return;
    if (_cachedWebMasterKey != null) return;

    final masterWrapped = await _storage.read(key: _masterKeyWrappedAlias);
    if (masterWrapped != null && masterWrapped.isNotEmpty) {
      final masterBytes = await _unwrapWithPassword(password, masterWrapped);
      _cachedWebMasterKey = SecretKey(masterBytes);
    }
  }

  /// Web (audit F1 + hardening 2.4): rimuove la chiave dalla memoria
  /// (lock/logout/auto-lock per inattività o pagina nascosta).
  void lockWebStorage() {
    // PERCHÉ (hardening 2.4): best-effort wipe — Dart non garantisce lo
    // zeroing della memoria.
    // NOTA: SecretKey incapsula i byte (le String Dart sono immutabili):
    // l'unica opzione è eliminare il riferimento.
    _cachedWebMasterKey = null;
  }

  /// Audit SEC-02: elimina i blob della chiave ED25519 del vecchio
  /// trasferimento (feature rimossa dal fork). Best-effort: i residui erano
  /// innocui, ma eliminarli riduce la superficie dello storage.
  Future<void> _cleanupLegacyEd25519Keys() async {
    try {
      await _storage.delete(key: _ed25519PrivateKeyAlias);
      await _storage.delete(key: '${_ed25519PrivateKeyAlias}_pub');
      await _storage.delete(key: _ed25519WrappedAlias);
    } catch (_) {
      // best-effort: la pulizia non deve mai bloccare il flusso chiavi
    }
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
      // 2) Fallback: decrypt seed legacy legato al deviceId (v1).
      // SEC-14 (audit): mantenuto per retro-compatibilità dei wallet creati
      // con lo schema v1 — rimozione dopo la migrazione completa.
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
