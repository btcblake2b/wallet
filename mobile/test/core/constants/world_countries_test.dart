// PERCHÉ (C003): l'onboarding deve consentire la dichiarazione della
// residenza fiscale per QUALSIASI paese (250 voci: 249 ISO 3166-1 + XK),
// non solo UE/SEE — altrimenti gli utenti fuori UE restano bloccati.
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/constants/world_countries.dart';

/// Normalizzazione speculare a quella del generatore (scripts/):
/// minuscole, senza accenti — usata per verificare l'ordinamento.
String _fold(String value) {
  const accents = <String, String>{
    'å': 'a',
    'ã': 'a',
    'ç': 'c',
    'é': 'e',
    'í': 'i',
    'ô': 'o',
    'ü': 'u',
    '’': '',
  };
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}

void main() {
  test('contiene 250 voci: 249 ISO 3166-1 alpha-2 + XK', () {
    expect(kWorldCountries, hasLength(250));
  });

  test('codici univoci e in formato alpha-2 maiuscolo', () {
    final codes = kWorldCountries.map((entry) => entry.key).toList();
    expect(codes.toSet(), hasLength(codes.length));
    for (final code in codes) {
      expect(
        RegExp(r'^[A-Z]{2}$').hasMatch(code),
        isTrue,
        reason: 'Codice non valido: $code',
      );
    }
  });

  test('nomi non vuoti e senza spazi esterni', () {
    for (final entry in kWorldCountries) {
      expect(entry.value, isNotEmpty);
      expect(entry.value.trim(), entry.value);
    }
  });

  test('include paesi extra-UE e territori', () {
    final codes = kWorldCountries.map((entry) => entry.key).toSet();
    for (final code in <String>[
      'US',
      'BR',
      'CN',
      'JP',
      'IN',
      'NG',
      'AU',
      'RU',
      'ZA',
      'HK',
      'TW',
      'XK',
    ]) {
      expect(codes, contains(code), reason: 'Manca $code');
    }
  });

  test('include UE/SEE e Svizzera', () {
    final codes = kWorldCountries.map((entry) => entry.key).toSet();
    for (final code in <String>['IT', 'DE', 'FR', 'CH', 'NO', 'IS', 'LI']) {
      expect(codes, contains(code), reason: 'Manca $code');
    }
  });

  test('esclude aggregati e codici non-paese', () {
    final codes = kWorldCountries.map((entry) => entry.key).toSet();
    for (final code in <String>[
      'EU',
      'ZZ',
      'QO',
      'EZ',
      'UN',
      'XA',
      'XB',
      'AC',
      'CP',
      'DG',
      'EA',
      'IC',
      'TA',
      'CQ',
    ]) {
      expect(codes, isNot(contains(code)), reason: 'Non deve esserci $code');
    }
  });

  test('ordinamento alfabetico sul nome (accenti ignorati)', () {
    final names = kWorldCountries.map((entry) => _fold(entry.value)).toList();
    final sorted = [...names]..sort();
    expect(names, orderedEquals(sorted));
  });

  test('prima voce Afghanistan, ultima Zimbabwe', () {
    expect(kWorldCountries.first.value, 'Afghanistan');
    expect(kWorldCountries.last.value, 'Zimbabwe');
  });
}
