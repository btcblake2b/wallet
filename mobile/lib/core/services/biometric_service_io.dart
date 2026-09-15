import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> canAuthenticate() async {
    final canCheck = await _localAuthentication.canCheckBiometrics;
    final isSupported = await _localAuthentication.isDeviceSupported();
    return canCheck || isSupported;
  }

  /// True SOLO se la biometria è presente e REGISTRATA sul dispositivo.
  ///
  /// PERCHÉ (vincolo blocco app 2026-09-11): `canAuthenticate()` include anche
  /// il solo PIN di sistema; il blocco app va proposto/attivato SOLO quando
  /// esiste una biometria registrata (il PIN resta il fallback di sblocco).
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _localAuthentication.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      debugPrint('[LoopEngineer] hasEnrolledBiometrics error: $e');
      return false;
    }
  }

  Future<bool> authenticateForUnlock({String? reason}) async {
    final available = await canAuthenticate();
    if (!available) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: reason ?? 'Authenticate to unlock this wallet',
    );
  }

  Future<bool> authenticateForSensitiveAction({required String reason}) async {
    final available = await canAuthenticate();
    if (!available) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: reason,
    );
  }

  // Desktop/mobile implementation does not manage local password; stubs
  Future<bool> setPassword(String password) async {
    return false;
  }

  Future<bool> verifyPassword(String password) async {
    return false;
  }

  /// Hardening 2.4: su native non esiste una cache di chiavi derivata dalla
  /// password (la gestisce il keyring OS) → no-op per parità di interfaccia
  /// con la variante web (auto-lock / blocco manuale).
  void lockCache() {}
}
