import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:btc_blake2b_wallet/l10n/info_hints_l10n.dart';

void main() {
  group('InfoHintL10n', () {
    // PERCHÉ: ogni locale deve avere titolo e corpo non vuoti per TUTTI gli
    // InfoHintId. Se un ARB manca una chiave, questo test fallisce con un
    // messaggio chiaro che indica quale lingua e quale id sono problematici.
    final locales = [
      const Locale('en'),
      const Locale('it'),
      const Locale('de'),
      const Locale('fr'),
      const Locale('es'),
      const Locale('fi'),
      const Locale('zh'),
    ];

    for (final locale in locales) {
      for (final id in InfoHintId.values) {
        test('$locale → ${id.name} ha titolo e corpo non vuoti', () async {
          final loc = await AppLocalizations.delegate.load(locale);
          final title = loc.infoTitle(id);
          final body = loc.infoBody(id);
          expect(
            title.trim(),
            isNotEmpty,
            reason: '$locale → ${id.name}.title è vuoto',
          );
          expect(
            body.trim(),
            isNotEmpty,
            reason: '$locale → ${id.name}.body è vuoto',
          );
          // Il titolo non deve essere uguale alla chiave ARB (garantisce traduzione reale).
          expect(
            title,
            isNot(equals('info${id.name.toString().replaceAll('_', '')}Title')),
            reason: '$locale → ${id.name} sembra una chiave non tradotta',
          );
        });
      }
    }
  });
}
