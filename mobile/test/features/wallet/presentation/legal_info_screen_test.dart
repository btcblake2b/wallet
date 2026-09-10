import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/legal_info_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('LegalInfoScreen', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LegalInfoScreen(),
        ),
      );

      expect(find.byType(LegalInfoScreen), findsOneWidget);
    });

    testWidgets('should render Terms and Privacy sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LegalInfoScreen(),
        ),
      );

      // PERCHÉ: verifica che i documenti legali siano ora mostrati in-app.
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    // TODO: Aggiungi test per interazioni e comportamento
  });
}
