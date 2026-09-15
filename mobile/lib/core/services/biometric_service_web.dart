// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import '../utils/unlock_backoff.dart';

// ──────────────────────────────────────────────────────────────
// JS interop bindings per Web Crypto API (NON usare `dynamic` o
// `dart:html`._SubtleCrypto perché minificano i nomi dei metodi).
// ──────────────────────────────────────────────────────────────

@JS('crypto.subtle.importKey')
external JSPromise<JSObject> _jsImportKeyPbkdf2(
  JSString format,
  JSArrayBuffer keyData,
  JSObject algorithm,
  JSBoolean extractable,
  JSArray<JSString> keyUsages,
);

@JS('crypto.subtle.deriveBits')
external JSPromise<JSArrayBuffer> _jsDeriveBits(
  JSObject algorithm,
  JSObject key,
  JSNumber length,
);

@JS('crypto.subtle.digest')
external JSPromise<JSArrayBuffer> _jsDigest(
  JSString algorithm,
  JSUint8Array data,
);

/// [BiometricService] per PWA con hardening password via PBKDF2.
///
/// v2: la password viene derivata con PBKDF2-SHA256 (100.000 iterazioni)
/// e un salt random di 16 byte. Il formato di storage è:
///   `pwa_wallet_password_v2:<iterations>:<salt_b64>:<derived_key_b64>`
/// Migrazione automatica dal vecchio formato SHA256 semplice (v1).
class BiometricService {
  BiometricService();

  static const String _passwordKeyV2 = 'pwa_wallet_password_v2';
  static const String _passwordKeyV1 = 'pwa_wallet_password_hash_v1';
  // PERCHÉ (audit F5): OWASP Password Storage Cheat Sheet 2023 raccomanda
  // >= 600.000 iterazioni per PBKDF2-HMAC-SHA256. Le entry esistenti
  // mantengono le proprie iterazioni salvate nel formato v2 (migrazione sicura).
  static const int _pbkdf2Iterations = 600000;
  static const int _minPasswordLength = 8;
  static const int _saltLength = 16;
  static const int _derivedKeyLength = 32;

  String? _cachedDerivedKeyBase64;

  /// Chiave localStorage del contatore tentativi falliti (backoff, 2.4).
  static const String _failuresKey = 'pwa_unlock_failures_v1';

  Future<bool> canAuthenticate() async {
    final storage = html.window.localStorage;
    if (_cachedDerivedKeyBase64 != null) return true;
    return storage.containsKey(_passwordKeyV2) ||
        storage.containsKey(_passwordKeyV1);
  }

  /// Sul web non esistono biometrie native → sempre false.
  /// (Il blocco app è una feature native; sul web resta il vault con password.)
  Future<bool> hasEnrolledBiometrics() async => false;

  Future<bool> authenticateForUnlock({String? reason}) async {
    return authenticateForSensitiveAction(
      reason: reason ?? 'Unlock wallet (enter password)',
    );
  }

  Future<bool> authenticateForSensitiveAction({required String reason}) async {
    final storage = html.window.localStorage;
    if (!storage.containsKey(_passwordKeyV2) &&
        !storage.containsKey(_passwordKeyV1)) {
      return false;
    }
    return false;
  }

  /// Hardening 2.4: rimuove la chiave derivata dalla memoria (auto-lock).
  /// La prossima verifica richiederà di nuovo la password.
  void lockCache() {
    _cachedDerivedKeyBase64 = null;
  }

  Future<bool> setPassword(String password) async {
    if (password.length < _minPasswordLength) return false;

    // Genera salt random
    final random = Random.secure();
    final salt = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }

    // Deriva chiave con PBKDF2 via Web Crypto API
    final derivedKey = await _deriveKeyWithPbkdf2(password, salt);
    final derivedKeyBase64 = base64Encode(derivedKey);
    final saltBase64 = base64Encode(salt);

    // Formato v2: iterations:salt:derived_key
    html.window.localStorage[_passwordKeyV2] =
        '$_pbkdf2Iterations:$saltBase64:$derivedKeyBase64';
    _cachedDerivedKeyBase64 = derivedKeyBase64;

    // Rimuovi vecchio formato v1 (SHA256 semplice)
    html.window.localStorage.remove(_passwordKeyV1);

    // PERCHÉ (hardening 2.4): password impostata → contatore tentativi azzerato.
    _resetFailures();

    return true;
  }

  Future<bool> verifyPassword(String password) async {
    // PERCHÉ (hardening 2.4): backoff crescente e PERSISTENTE sui tentativi
    // falliti (sopravvive al reload della pagina): alza il costo di un attacco
    // dizionario senza introdurre una UI di lockout. Limite dichiarato: chi può
    // cancellare localStorage azzera il contatore — è attrito, non un muro.
    await Future<void>.delayed(unlockBackoffDelay(_readFailures()));

    // Prova formato v2 (PBKDF2)
    final storedV2 = html.window.localStorage[_passwordKeyV2];
    if (storedV2 != null && storedV2.isNotEmpty) {
      try {
        final parts = storedV2.split(':');
        if (parts.length == 3) {
          final iterations = int.parse(parts[0]);
          final salt = base64Decode(parts[1]);
          final expectedKeyBase64 = parts[2];

          final derivedKey = await _deriveKeyWithPbkdf2(
            password,
            Uint8List.fromList(salt),
            iterations: iterations,
          );
          final derivedKeyBase64 = base64Encode(derivedKey);

          // PERCHÉ (audit F5): confronto constant-time sul derived key
          // per evitare timing side-channel sulla verifica password.
          final ok = _constantTimeEquals(derivedKeyBase64, expectedKeyBase64);
          if (ok) {
            _cachedDerivedKeyBase64 = derivedKeyBase64;
            _resetFailures();
          } else {
            _registerFailure();
          }
          return ok;
        }
      } catch (_) {
        // Fallback a v1
      }
    }

    // Fallback: vecchio formato v1 (SHA256 semplice)
    final ok = await _verifyLegacyV1(password);
    if (ok) {
      // Migra a v2 automaticamente
      await setPassword(password);
    } else {
      _registerFailure();
    }
    return ok;
  }

  /// Deriva una chiave crittografica dalla password usando PBKDF2-SHA256.
  Future<Uint8List> _deriveKeyWithPbkdf2(
    String password,
    Uint8List salt, {
    int iterations = _pbkdf2Iterations,
  }) async {
    // Crea copie per garantire buffer con dimensione esatta
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final saltCopy = Uint8List.fromList(salt);
    // Chiamata JS interop @JS('crypto.subtle.importKey')
    final keyMaterial = await _jsImportKeyPbkdf2(
      'raw'.toJS,
      passwordBytes.buffer.toJS,
      ({'name': 'PBKDF2'.toJS}).jsify() as JSObject,
      false.toJS,
      ['deriveBits'.toJS].toJS,
    ).toDart;

    // Chiamata JS interop @JS('crypto.subtle.deriveBits')
    final derivedBits = await _jsDeriveBits(
      ({
        'name': 'PBKDF2'.toJS,
        'salt': saltCopy.toJS,
        'iterations': iterations.toJS,
        'hash': 'SHA-256'.toJS,
      }).jsify() as JSObject,
      keyMaterial,
      (_derivedKeyLength * 8).toJS,
    ).toDart;

    return derivedBits.toDart.asUint8List();
  }

  /// Verifica password v1 (SHA256) per migrazione. Usa Web Crypto API async.
  Future<String> _sha256(String input) async {
    final dataCopy = Uint8List.fromList(utf8.encode(input));
    // Chiamata JS interop @JS('crypto.subtle.digest')
    final hashBuffer = await _jsDigest(
      'SHA-256'.toJS,
      dataCopy.toJS,
    ).toDart;
    final hashBytes = hashBuffer.toDart.asUint8List();
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Async wrapper per verifica v1 (SHA256) usato nel fallback
  Future<bool> _verifyLegacyV1(String password) async {
    final storedV1 = html.window.localStorage[_passwordKeyV1];
    if (storedV1 == null || storedV1.isEmpty) return false;
    final hash = await _sha256(password);
    return _constantTimeEquals(hash, storedV1);
  }

  // ── Backoff tentativi falliti (hardening 2.4) ───────────────────────────

  int _readFailures() {
    final raw = html.window.localStorage[_failuresKey];
    return int.tryParse(raw ?? '') ?? 0;
  }

  void _registerFailure() {
    html.window.localStorage[_failuresKey] = '${_readFailures() + 1}';
  }

  void _resetFailures() {
    html.window.localStorage.remove(_failuresKey);
  }

  /// Confronto stringhe in tempo costante (XOR cumulativo) per evitare
  /// timing side-channel sulla verifica della password.
  static bool _constantTimeEquals(String a, String b) {
    final aBytes = a.codeUnits;
    final bBytes = b.codeUnits;
    if (aBytes.length != bBytes.length) {
      // Consuma comunque un tempo proporzionale alla lunghezza per
      // non rivelare la lunghezza confrontata.
      var diff = aBytes.length ^ bBytes.length;
      final maxLen =
          aBytes.length > bBytes.length ? aBytes.length : bBytes.length;
      for (var i = 0; i < maxLen; i++) {
        final av = i < aBytes.length ? aBytes[i] : 0;
        final bv = i < bBytes.length ? bBytes[i] : 0;
        diff |= av ^ bv;
      }
      return diff == 0;
    }
    var diff = 0;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }
}
