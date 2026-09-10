// PERCHÉ (Step 2, audit test): OnboardingService persiste i dati legali in
// flutter_secure_storage. Il flag 'completed' è separato dai dati per letture
// veloci; i test verificano lettura, scrittura e gestione JSON corrotto.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/models/onboarding_data.dart';
import 'package:btc_blake2b_wallet/core/services/onboarding_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('OnboardingService', () {
    late MockFlutterSecureStorage mockStorage;
    late OnboardingService sut;

    const completedKey = 'onboarding_completed';
    const dataKey = 'onboarding_data';

    // PERCHÉ: DateTime.utc non è un costruttore const, quindi 'final'
    // invece di 'const' per il sample.
    final sample = OnboardingData(
      residenzaFiscale: 'IT',
      reverseSolicitationAccepted: DateTime.utc(2026, 8, 1, 10),
      termsAccepted: DateTime.utc(2026, 8, 1, 10, 5),
      privacyPolicyAccepted: DateTime.utc(2026, 8, 1, 10, 10),
      ageConfirmed: true,
    );

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      sut = OnboardingService(storage: mockStorage);
    });

    test('isCompleted → true quando il flag salvato è "true"', () async {
      when(() => mockStorage.read(key: completedKey))
          .thenAnswer((_) async => 'true');

      expect(await sut.isCompleted(), isTrue);
      verify(() => mockStorage.read(key: completedKey)).called(1);
    });

    test('isCompleted → false quando il flag è assente o diverso', () async {
      when(() => mockStorage.read(key: completedKey))
          .thenAnswer((_) async => null);

      expect(await sut.isCompleted(), isFalse);

      when(() => mockStorage.read(key: completedKey))
          .thenAnswer((_) async => 'false');

      expect(await sut.isCompleted(), isFalse);
    });

    test('complete scrive flag "true" e JSON dei dati', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await sut.complete(sample);

      verify(() => mockStorage.write(key: completedKey, value: 'true'))
          .called(1);
      verify(
        () => mockStorage.write(
          key: dataKey,
          value: jsonEncode(sample.toJson()),
        ),
      ).called(1);
    });

    test('getData restituisce OnboardingData su JSON valido', () async {
      when(() => mockStorage.read(key: dataKey))
          .thenAnswer((_) async => jsonEncode(sample.toJson()));

      final data = await sut.getData();

      expect(data, isNotNull);
      expect(data!.residenzaFiscale, 'IT');
      expect(data.ageConfirmed, isTrue);
    });

    test('getData restituisce null su chiave assente', () async {
      when(() => mockStorage.read(key: dataKey)).thenAnswer((_) async => null);

      expect(await sut.getData(), isNull);
    });

    test('getData restituisce null (non throws) su JSON corrotto', () async {
      when(() => mockStorage.read(key: dataKey))
          .thenAnswer((_) async => '{non-json-valido');

      expect(await sut.getData(), isNull);
    });
  });
}
