import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/settings/presentation/settings_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockBiometricService extends Mock implements BiometricService {}

class MockStorage extends Mock implements FlutterSecureStorage {}

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
    home: Builder(
      builder: (ctx) => Scaffold(
        // PERCHÉ: la nuova sezione "Interfaccia" spinge il contenuto oltre i 600px;
        // ingrandisco l'viewport del test per contenere tutto senza scroll.
        body: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: SettingsScreen(
              themeProvider: themeProvider,
              localeProvider: LocaleProvider(),
              appLockService: appLockService,
              biometricService: biometricService,
              walletRepository: MockWalletRepository(),
            ),
          ),
        ),
      ),
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

      // PERCHÉ: la nuova sezione "Interfaccia" spinge il contenuto oltre i 600px;
      // uso Scrollable.ensureVisible per far scorrre automaticamente ogni elemento.
      expect(find.text('Appearance'), findsOneWidget);
      await tester.ensureVisible(find.text('Tools'));
      await tester.pumpAndSettle();
      expect(find.text('Information'), findsOneWidget);
      await tester.ensureVisible(find.text('Explorer'));
      await tester.pumpAndSettle();
      expect(find.text('Legal Info'), findsOneWidget);
    });

    testWidgets('interruttore mirror Esplora: ON di default e disattivabile',
        (tester) async {
      // PERCHÉ: la preferenza è di processo → ogni test parte dal default ON
      // e non deve mai toccare lo storage reale.
      ExplorerMirrors.resetForTest();
      addTearDown(ExplorerMirrors.resetForTest);
      final storage = MockStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      ExplorerMirrors.instance = ExplorerMirrors(storage: storage);

      final biometricService = MockBiometricService();
      when(() => biometricService.hasEnrolledBiometrics())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(
        _wrap(
          appLockService: AppLockService.test(),
          biometricService: biometricService,
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Backup explorers',
      );
      // PERCHÉ: la sezione Mirror è sotto "Interfaccia" → scorri manualmente
      // per renderla visibile nel viewport di 600px del test.
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(ExplorerMirrors.instance.enabled, isFalse);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      // PERCHÉ: con i mirror disattivati resta il solo primario.
      expect(
        ExplorerMirrors.instance.readHosts,
        equals(['https://mempool.guide/api']),
      );
    });
  });
}
