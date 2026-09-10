import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/env.dart';
import 'package:btc_blake2b_wallet/core/services/security_service.dart';

void main() {
  group('evaluateIntegrity (logica pura)', () {
    test('config vuota ⇒ false (fail-closed)', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'ABC',
          configuredSignatures: '',
        ),
        isFalse,
      );
    });

    test('match esatto ⇒ true', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'abc123',
          configuredSignatures: 'abc123',
        ),
        isTrue,
      );
    });

    test('confronto case-insensitive (Android può variare)', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'ABCdef',
          configuredSignatures: 'abcdef',
        ),
        isTrue,
      );
    });

    test('lista multi-firma: almeno una corrispondenza ⇒ true', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'SIG2',
          configuredSignatures: 'SIG1, SIG2',
        ),
        isTrue,
      );
    });

    test('nessuna corrispondenza ⇒ false', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'SIG3',
          configuredSignatures: 'SIG1, SIG2',
        ),
        isFalse,
      );
    });

    test('spazi e separatori vuoti vengono ignorati', () {
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'DEF',
          configuredSignatures: '  abc ,  def  ',
        ),
        isTrue,
      );
      // Edge storico: solo separatori ⇒ nessuna firma attesa ⇒ true.
      expect(
        SecurityService.evaluateIntegrity(
          currentSignature: 'ABC',
          configuredSignatures: ',',
        ),
        isTrue,
      );
    });
  });

  group('verifyIntegrity', () {
    test('default (debug/web) ⇒ true senza chiamare la piattaforma', () async {
      final svc = SecurityService.test(
        getSignature: () async => throw StateError('non deve chiamare'),
      );
      expect(await svc.verifyIntegrity(), isTrue);
    });

    test('native: delega la decisione a evaluateIntegrity', () async {
      final svc = SecurityService.test(
        emulateNative: true,
        getSignature: () async => 'MySig',
      );
      final result = await svc.verifyIntegrity();
      expect(
        result,
        SecurityService.evaluateIntegrity(
          currentSignature: 'MySig',
          configuredSignatures: Env.appSignature,
        ),
      );
    });

    test(
      'native fail-closed: APP_SIGNATURE vuota ⇒ false',
      () async {
        final svc = SecurityService.test(
          emulateNative: true,
          getSignature: () async => 'MySig',
        );
        expect(await svc.verifyIntegrity(), isFalse);
      },
      skip: Env.appSignature.isNotEmpty
          ? 'APP_SIGNATURE configurata: fail-closed non applicabile'
          : false,
    );

    test(
      'native fail-secure: errore nel recupero firma ⇒ false',
      () async {
        final svc = SecurityService.test(
          emulateNative: true,
          getSignature: () async => throw Exception('channel down'),
        );
        expect(await svc.verifyIntegrity(), isFalse);
      },
      skip: Env.appSignature.isEmpty
          ? 'richiede APP_SIGNATURE configurata per esercitare il ramo catch'
          : false,
    );
  });

  group('init (protezione globale)', () {
    test('default (debug/web): nessuna chiamata al plugin', () async {
      var onCalls = 0;
      final svc = SecurityService.test(screenshotOn: () async => onCalls++);
      await svc.init();
      expect(onCalls, 0);
    });

    test('native: idempotente e la protezione globale non si spegne mai',
        () async {
      var onCalls = 0;
      var offCalls = 0;
      final svc = SecurityService.test(
        emulateNative: true,
        screenshotOn: () async => onCalls++,
        screenshotOff: () async => offCalls++,
      );
      await svc.init();
      await svc.init(); // seconda chiamata: early-return
      expect(onCalls, 1);

      // Con la protezione globale attiva, protectScreen(false) non spegne mai.
      await svc.protectScreen(true);
      await svc.protectScreen(false);
      expect(offCalls, 0);
    });
  });

  group('protectScreen (reference counting)', () {
    test('default (debug/web): no-op, contatore invariato', () async {
      var onCalls = 0;
      var offCalls = 0;
      final svc = SecurityService.test(
        screenshotOn: () async => onCalls++,
        screenshotOff: () async => offCalls++,
      );
      await svc.protectScreen(true);
      await svc.protectScreen(true);
      await svc.protectScreen(false);
      expect(onCalls, 0);
      expect(offCalls, 0);
    });

    test('native: screenshot-on solo alla prima schermata protetta', () async {
      var onCalls = 0;
      var offCalls = 0;
      final svc = SecurityService.test(
        emulateNative: true,
        screenshotOn: () async => onCalls++,
        screenshotOff: () async => offCalls++,
      );
      await svc.protectScreen(true); // 0→1: on
      await svc.protectScreen(true); // 1→2: nessuna chiamata extra
      expect(onCalls, 1);

      await svc.protectScreen(false); // 2→1: resta attiva
      expect(offCalls, 0);

      await svc.protectScreen(false); // 1→0: off
      expect(offCalls, 1);
    });

    test('native: release ridondante a contatore 0 ⇒ off idempotente (nessun '
        'crash), ma mai off con protezione globale attiva', () async {
      var offCalls = 0;
      final svc = SecurityService.test(
        emulateNative: true,
        screenshotOff: () async => offCalls++,
      );
      // Contratto reale del codice: senza protezione globale un release a 0
      // riapplica screenshot-off (innocuo/idempotente).
      await svc.protectScreen(false);
      expect(offCalls, 1);

      // Con la protezione globale attiva, nemmeno un release a 0 spegne.
      var offCallsGlobal = 0;
      final svcGlobal = SecurityService.test(
        emulateNative: true,
        screenshotOn: () async {},
        screenshotOff: () async => offCallsGlobal++,
      );
      await svcGlobal.init();
      await svcGlobal.protectScreen(false);
      await svcGlobal.protectScreen(false);
      expect(offCallsGlobal, 0);
    });
  });

  group('isDeviceSecure', () {
    test('default (debug/web) ⇒ true', () async {
      final svc = SecurityService.test(isJailbroken: () async => true);
      expect(await svc.isDeviceSecure(), isTrue);
    });

    test('native: dispositivo jailbroken ⇒ false', () async {
      final svc = SecurityService.test(
        emulateNative: true,
        isJailbroken: () async => true,
      );
      expect(await svc.isDeviceSecure(), isFalse);
    });

    test('native: dispositivo pulito ⇒ true', () async {
      final svc = SecurityService.test(
        emulateNative: true,
        isJailbroken: () async => false,
      );
      expect(await svc.isDeviceSecure(), isTrue);
    });
  });

  group('enforceDeviceSecurity', () {
    test('dispositivo sicuro ⇒ true, nessun kill', () async {
      var killed = false;
      final svc = SecurityService.test(
        emulateNative: true,
        isJailbroken: () async => false,
        onForceKill: () => killed = true,
      );
      expect(await svc.enforceDeviceSecurity(), isTrue);
      expect(killed, isFalse);
    });

    test('jailbroken senza context ⇒ kill diretto e false', () async {
      var killed = false;
      final svc = SecurityService.test(
        emulateNative: true,
        isJailbroken: () async => true,
        onForceKill: () => killed = true,
      );
      expect(await svc.enforceDeviceSecurity(), isFalse);
      expect(killed, isTrue);
    });

    testWidgets('jailbroken con context ⇒ dialog non dismissable + Esci ⇒ kill',
        (tester) async {
      var killed = false;
      final svc = SecurityService.test(
        emulateNative: true,
        isJailbroken: () async => true,
        onForceKill: () => killed = true,
      );
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      final future = svc.enforceDeviceSecurity(context: ctx);
      await tester.pumpAndSettle();
      expect(find.text('Dispositivo non sicuro'), findsOneWidget);

      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      expect(await future, isFalse);
      expect(killed, isTrue);
    });
  });
}
