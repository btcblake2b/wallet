import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/features/lock/presentation/app_lock_gate.dart';
import 'package:btc_blake2b_wallet/features/lock/presentation/app_lock_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockBiometricService extends Mock implements BiometricService {}

const _childKey = Key('gate-child');

Widget _wrap({
  required AppLockService service,
  required BiometricService biometricService,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppLockGate(
      service: service,
      biometricService: biometricService,
      child: const Scaffold(body: Text('HOME', key: _childKey)),
    ),
  );
}

void main() {
  group('AppLockGate', () {
    testWidgets('sbloccato: mostra il child, nessuna lock screen',
        (tester) async {
      final biometricService = MockBiometricService();
      final service = AppLockService.test(enabled: true);

      await tester.pumpWidget(
        _wrap(service: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_childKey), findsOneWidget);
      expect(find.byType(AppLockScreen), findsNothing);
    });

    testWidgets('bloccato: copre il child e tenta l\'unlock automatico',
        (tester) async {
      final biometricService = MockBiometricService();
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => false);
      when(() => biometricService.canAuthenticate())
          .thenAnswer((_) async => true);
      final service = AppLockService.test(enabled: true)..lock();

      await tester.pumpWidget(
        _wrap(service: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLockScreen), findsOneWidget);
      // Il child NON viene mai rimosso dall'albero (stato preservato).
      expect(find.byKey(_childKey), findsOneWidget);
      verify(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).called(1);
    });

    testWidgets('unlock riuscito: la lock screen sparisce', (tester) async {
      final biometricService = MockBiometricService();
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      final service = AppLockService.test(enabled: true)..lock();

      await tester.pumpWidget(
        _wrap(service: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(service.isLocked, isFalse);
      expect(find.byType(AppLockScreen), findsNothing);
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets('lifecycle paused → blocco; al rientro la lock screen copre',
        (tester) async {
      final biometricService = MockBiometricService();
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => false);
      when(() => biometricService.canAuthenticate())
          .thenAnswer((_) async => true);

      final service = AppLockService.test(enabled: true);
      await tester.pumpWidget(
        _wrap(service: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // PERCHÉ: in background i frame sono sospesi (framesEnabled = false):
      // lo stato si verifica sul service, la UI si controlla al rientro.
      expect(service.isLocked, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Al ritorno la lock screen è visibile e il blocco resta attivo
      // (l'auto-tentativo con esito negativo non sblocca).
      expect(service.isLocked, isTrue);
      expect(find.byType(AppLockScreen), findsOneWidget);
    });

    testWidgets('fail-safe: protezione telefono rimossa → avviso e sblocco',
        (tester) async {
      final biometricService = MockBiometricService();
      when(
        () => biometricService.authenticateForUnlock(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => false);
      when(() => biometricService.canAuthenticate())
          .thenAnswer((_) async => false);
      final service = AppLockService.test(enabled: true)..lock();

      await tester.pumpWidget(
        _wrap(service: service, biometricService: biometricService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(service.isEnabled, isFalse);
      expect(service.isLocked, isFalse);
      expect(find.byType(AppLockScreen), findsNothing);
    });
  });
}
