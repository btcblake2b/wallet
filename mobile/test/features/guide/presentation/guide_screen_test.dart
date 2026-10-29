import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/guide/presentation/guide_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:btc_blake2b_wallet/l10n/info_hints_l10n.dart';

Widget _wrap({
  Locale locale = const Locale('it'),
  Future<void> Function(Uri uri)? openUrl,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GuideScreen(openUrl: openUrl),
  );
}

void main() {
  group('GuideScreen — dati', () {
    // PERCHÉ: la guida è il posto dove un principiante cerca TUTTO; se si
    // aggiunge un InfoHintId senza inserirlo nei capitoli, resta invisibile.
    test('ogni InfoHintId compare esattamente una volta nei capitoli', () {
      final ids = <InfoHintId>[
        for (final section in GuideSection.values)
          ...guideTopicsOf(section).map((t) => t.id),
      ];
      expect(ids.length, InfoHintId.values.length);
      expect(ids.toSet(), InfoHintId.values.toSet());
    });

    test('nessun capitolo è vuoto', () {
      for (final section in GuideSection.values) {
        expect(guideTopicsOf(section), isNotEmpty, reason: section.name);
      }
    });

    test('URL della guida lunga per lingua', () {
      expect(GuideScreen.learnUrlFor('it'), GuideScreen.learnUrlIt);
      expect(GuideScreen.learnUrlFor('en'), GuideScreen.learnUrlEn);
      expect(GuideScreen.learnUrlFor('de'), GuideScreen.learnUrlEn);
    });
  });

  group('GuideScreen — UI', () {
    testWidgets('mostra introduzione e capitoli', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final loc = await AppLocalizations.delegate.load(const Locale('it'));

      expect(find.text('Come funziona'), findsWidgets);
      // PERCHÉ: la ListView costruisce solo ciò che è a schermo → ogni
      // capitolo va cercato scorrendo, come farebbe l'utente.
      for (final section in GuideSection.values) {
        final title = find.text(loc.guideSectionTitle(section));
        await tester.scrollUntilVisible(title, 300);
        expect(title, findsOneWidget, reason: section.name);
      }
    });

    testWidgets('espande un argomento e mostra il corpo', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final loc = await AppLocalizations.delegate.load(const Locale('it'));

      final title = loc.infoTitle(InfoHintId.whatIsWallet);
      expect(find.text(title), findsOneWidget);
      expect(find.text(loc.infoBody(InfoHintId.whatIsWallet)), findsNothing);

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(loc.infoBody(InfoHintId.whatIsWallet)), findsOneWidget);
    });

    testWidgets('"Apri la guida" usa la URL italiana', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        _wrap(openUrl: (uri) async => opened.add(uri)),
      );
      await tester.pumpAndSettle();

      final button = find.text('Apri la guida');
      await tester.scrollUntilVisible(button, 200);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(opened, [Uri.parse(GuideScreen.learnUrlIt)]);
    });

    testWidgets('in inglese apre la URL inglese', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          openUrl: (uri) async => opened.add(uri),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.text('Open the guide');
      await tester.scrollUntilVisible(button, 200);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(opened, [Uri.parse(GuideScreen.learnUrlEn)]);
    });
  });
}
