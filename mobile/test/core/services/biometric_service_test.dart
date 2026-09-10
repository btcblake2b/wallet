import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service_io.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  group('BiometricService', () {
    late MockLocalAuthentication mockLocalAuthentication;
    late BiometricService sut;

    setUp(() {
      mockLocalAuthentication = MockLocalAuthentication();
      sut = BiometricService(localAuthentication: mockLocalAuthentication);
    });

    test('should instantiate', () {
      expect(sut, isNotNull);
    });

    // TODO: Implementa test per i metodi pubblici
    // test('canAuthenticate should ...', () { ... });
    // test('authenticateForUnlock should ...', () { ... });
    // test('authenticateForSensitiveAction should ...', () { ... });
    // test('setPassword should ...', () { ... });
    // test('verifyPassword should ...', () { ... });
  });
}
