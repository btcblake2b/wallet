// PERCHÉ (Step 2, audit test): il modello OnboardingData è il contratto di
// serializzazione dei dati legali conservati localmente (zero-knowledge).
// Un errore in toJson/fromJson corromperebbe i dati di conformità.
import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/onboarding_data.dart';

void main() {
  group('OnboardingData', () {
    // PERCHÉ: DateTime.utc non è un costruttore const, quindi 'final'
    // invece di 'const' per il sample.
    final sample = OnboardingData(
      residenzaFiscale: 'IT',
      reverseSolicitationAccepted: DateTime.utc(2026, 8, 1, 10),
      termsAccepted: DateTime.utc(2026, 8, 1, 10, 5),
      privacyPolicyAccepted: DateTime.utc(2026, 8, 1, 10, 10),
      ageConfirmed: true,
    );

    test('roundtrip toJson → fromJson restituisce dati identici', () {
      final decoded = OnboardingData.fromJson(sample.toJson());

      expect(decoded.residenzaFiscale, 'IT');
      expect(
        decoded.reverseSolicitationAccepted,
        sample.reverseSolicitationAccepted,
      );
      expect(decoded.termsAccepted, sample.termsAccepted);
      expect(decoded.privacyPolicyAccepted, sample.privacyPolicyAccepted);
      expect(decoded.ageConfirmed, true);
    });

    test('toJson produce le chiavi attese con date ISO8601', () {
      final json = sample.toJson();

      expect(json['residenzaFiscale'], 'IT');
      expect(json['reverseSolicitationAccepted'], '2026-08-01T10:00:00.000Z');
      expect(json['termsAccepted'], '2026-08-01T10:05:00.000Z');
      expect(json['privacyPolicyAccepted'], '2026-08-01T10:10:00.000Z');
      expect(json['ageConfirmed'], true);
    });

    test('fromJson su JSON mancante di un campo → throws', () {
      expect(
        () => OnboardingData.fromJson({
          'residenzaFiscale': 'IT',
          'reverseSolicitationAccepted': '2026-08-01T10:00:00.000Z',
          'termsAccepted': '2026-08-01T10:05:00.000Z',
          'privacyPolicyAccepted': '2026-08-01T10:10:00.000Z',
          // ageConfirmed mancante
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson su campo data non valido → throws', () {
      expect(
        () => OnboardingData.fromJson({
          'residenzaFiscale': 'IT',
          'reverseSolicitationAccepted': 'non-una-data',
          'termsAccepted': '2026-08-01T10:05:00.000Z',
          'privacyPolicyAccepted': '2026-08-01T10:10:00.000Z',
          'ageConfirmed': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
