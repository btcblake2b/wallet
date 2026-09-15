import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/onboarding/presentation/onboarding_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

Widget _wrap() {
  return const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: OnboardingScreen(),
  );
}

Future<void> _selectCountry(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  final Finder item = find.text(label);
  // PERCHÉ: con la lista mondiale il menu del dropdown è una lista lazy:
  // la voce scelta va scrollata in vista prima del tap (find.text(label).last
  // lancerebbe "No element" finché la voce non è costruita).
  await tester.scrollUntilVisible(
    item,
    200,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 300,
  );
  await tester.pumpAndSettle();
  await tester.tap(item.last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('step 1: progress bar + Next disabilitato senza paese',
      (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Step 1 of 4'), findsOneWidget);
    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(next.onPressed, isNull);

    await _selectCountry(tester, 'Austria (AT)');

    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('navigazione avanti/indietro preserva lo stato dei campi',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _selectCountry(tester, 'Austria (AT)');

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 4'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 4'), findsOneWidget);
    // Il dropdown conserva la selezione dopo il ritorno.
    expect(find.text('Austria (AT)'), findsOneWidget);
  });

  testWidgets(
      'step 2: Next disabilitato finché reverse solicitation non è spuntata',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _selectCountry(tester, 'Austria (AT)');
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(next.onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets(
      'step 4: Continue disabilitato finché termini e privacy non sono spuntati',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _selectCountry(tester, 'Austria (AT)');
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); // reverse
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); // età
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 4'), findsOneWidget);
    final cont = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(cont.onPressed, isNull);

    // // PERCHÉ: nello step 4 ci sono 2 checkbox (Termini, Privacy). Il tap va
    // sul Checkbox discendente, NON sulla tile: il titolo dei Termini contiene
    // un link inline (recognizer) che aprirebbe LegalInfoScreen.
    expect(find.byKey(const Key('onboarding_terms_check')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_privacy_check')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('onboarding_terms_check')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('onboarding_privacy_check')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('paese non-UE: selezione e avanzamento fino allo step 4',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await _selectCountry(tester, 'United States (US)');

    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(next.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); // reverse solicitation
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); // età
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 4'), findsOneWidget);
  });
}
