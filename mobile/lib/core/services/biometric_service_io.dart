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

  Future<bool> authenticateForUnlock() async {
    final available = await canAuthenticate();
    if (!available) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: 'Authenticate to unlock this wallet',
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
}
