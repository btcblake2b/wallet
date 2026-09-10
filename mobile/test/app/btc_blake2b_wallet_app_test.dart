import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/app/app.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockAppServices extends Mock implements AppServices {}

void main() {
  group('BtcBlake2bWalletApp', () {
    testWidgets('should render', (tester) async {
      final services = MockAppServices();
      final localeProvider = LocaleProvider();
      final themeProvider = ThemeProvider();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BtcBlake2bWalletApp(
            services: services,
            localeProvider: localeProvider,
            themeProvider: themeProvider,
          ),
        ),
      );

      expect(find.byType(BtcBlake2bWalletApp), findsOneWidget);
    });

    // TODO: Aggiungi test per interazioni e comportamento
  });
}
