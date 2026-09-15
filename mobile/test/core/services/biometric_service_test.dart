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

    test('hasEnrolledBiometrics: true con biometrie registrate', () async {
      when(() => mockLocalAuthentication.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      expect(await sut.hasEnrolledBiometrics(), isTrue);
    });

    test('hasEnrolledBiometrics: false senza biometrie', () async {
      when(() => mockLocalAuthentication.getAvailableBiometrics())
          .thenAnswer((_) async => []);

      expect(await sut.hasEnrolledBiometrics(), isFalse);
    });

    test('hasEnrolledBiometrics: false su eccezione (fail-safe)', () async {
      when(() => mockLocalAuthentication.getAvailableBiometrics())
          .thenThrow(Exception('plugin error'));

      expect(await sut.hasEnrolledBiometrics(), isFalse);
    });

    test('authenticateForUnlock inoltra la reason localizzata', () async {
      when(() => mockLocalAuthentication.canCheckBiometrics)
          .thenAnswer((_) async => true);
      when(() => mockLocalAuthentication.isDeviceSupported())
          .thenAnswer((_) async => true);
      when(
        () => mockLocalAuthentication.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);

      final result =
          await sut.authenticateForUnlock(reason: 'Sblocca il wallet');

      expect(result, isTrue);
      verify(
        () => mockLocalAuthentication.authenticate(
          localizedReason: 'Sblocca il wallet',
        ),
      ).called(1);
    });
  });
}
