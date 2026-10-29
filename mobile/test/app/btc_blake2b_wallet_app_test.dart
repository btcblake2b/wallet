import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/app/app.dart';
import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockAppServices extends Mock implements AppServices {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  group('BtcBlake2bWalletApp', () {
    testWidgets('should render', (tester) async {
      // PERCHÉ: lo splash decide il routing leggendo flutter_secure_storage e
      // ha un timeout di sicurezza; senza un handler il read resta appeso e il
      // test finisce con un timer pendente.
      const storageChannel =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (call) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(storageChannel, null);
      });

      final services = MockAppServices();
      when(() => services.appLockService).thenReturn(AppLockService.test());
      when(() => services.biometricService).thenReturn(MockBiometricService());
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
