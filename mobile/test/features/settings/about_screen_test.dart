import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/settings/presentation/about_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('AboutScreen', () {
    testWidgets('le licenze si aprono DALL\'ASSET locale (offline-first)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AboutScreen(),
        ),
      );

      // La tile "Licenze Terze Parti" è presente.
      expect(find.byIcon(Icons.description), findsOneWidget);

      await tester.tap(find.byIcon(Icons.description));
      await tester.pumpAndSettle();

      // PERCHÉ (fix 2.6): il contenuto arriva dall'asset, non dalla rete —
      // nessuna chiamata a raw.githubusercontent.com per consultare le
      // attribuzioni.
      final selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectable.data, contains('THIRD PARTY LICENSES'));
    });
  });
}
