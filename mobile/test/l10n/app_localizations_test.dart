import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations_en.dart';

void main() {
  group('AppLocalizations', () {
    test('english localizations should be available', () {
      final sut = AppLocalizationsEn();
      expect(sut, isNotNull);
      expect(sut.appTitle, isNotEmpty);
    });

    // TODO: Implementa test per i metodi pubblici
  });
}
