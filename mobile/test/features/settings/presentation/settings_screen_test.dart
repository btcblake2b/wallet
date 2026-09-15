import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/settings/presentation/settings_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockBiometricService extends Mock implements BiometricService {}

class MockThemeProvider extends Mock implements ThemeProvider {}

class MockWalletRepository extends Mock implements WalletRepository {}

Widget _wrap({
  required AppLockService appLockService,
  required BiometricService biometricService,
  ThemeProvider? themeProvider,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SettingsScreen(
      themeProvider: themeProvider,
      localeProvider: LocaleProvider(),
      appLockService: appLockService,
      biometricService: biometricService,
      walletRepository: MockWalletRepository(),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('senza biometria: toggle disabilitato + spiegazione',
        (tester) async {
      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => false);
      final service = AppLockService.test();

      await tester.pumpWidget(
        _wrap(appLockService: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security'), findsOneWidget);
      expect(
        find.text('No biometrics enrolled on this device'),
        findsOneWidget,
      );

      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'App lock'),
      );
      expect(switchTile.onChanged, isNull);
    });

    testWidgets('enable con biometria ok → blocco attivato', (tester) async {
      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => true);
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      final service = AppLockService.test();

      await tester.pumpWidget(
        _wrap(appLockService: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();

      expect(service.isEnabled, isTrue);
      expect(find.text('App lock enabled'), findsOneWidget);
    });

    testWidgets('enable con verifica fallita → blocco NON attivato',
        (tester) async {
      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => true);
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => false);
      final service = AppLockService.test();

      await tester.pumpWidget(
        _wrap(appLockService: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();

      expect(service.isEnabled, isFalse);
      expect(
        find.text('Verification failed: app lock not enabled'),
        findsOneWidget,
      );
    });

    testWidgets('disattivazione: toggle off → blocco disattivato',
        (tester) async {
      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => true);
      final service = AppLockService.test(enabled: true);

      await tester.pumpWidget(
        _wrap(appLockService: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();

      expect(service.isEnabled, isFalse);
      expect(find.text('App lock disabled'), findsOneWidget);
    });

    testWidgets('sezioni principali presenti (aspetto, strumenti, info)',
        (tester) async {
      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => true);
      final service = AppLockService.test();

      await tester.pumpWidget(
        _wrap(appLockService: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Legal Info'), findsOneWidget);
    });
  });
}
