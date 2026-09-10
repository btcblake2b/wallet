import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/features/donate/presentation/donate_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('DonateScreen', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DonateScreen(),
        ),
      );

      expect(find.byType(DonateScreen), findsOneWidget);
    });

    // TODO: Aggiungi test per interazioni e comportamento
  });
}
