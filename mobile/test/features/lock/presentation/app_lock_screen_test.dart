import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/lock/presentation/app_lock_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  group('AppLockScreen', () {
    testWidgets('mostra titolo e bottone di sblocco', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppLockScreen(onUnlock: () => taps++, busy: false)),
      );

      expect(find.text('App locked'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      expect(taps, 1);
    });

    testWidgets('busy: bottone disabilitato e spinner visibile',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppLockScreen(onUnlock: () => taps++, busy: true)),
      );

      await tester.tap(find.text('Unlock'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('notice fail-safe: messaggio + bottone Continua',
        (tester) async {
      var continued = 0;
      await tester.pumpWidget(
        _wrap(
          AppLockScreen(
            onUnlock: () {},
            busy: false,
            notice: 'Device protection removed',
            onNoticeContinue: () => continued++,
          ),
        ),
      );

      expect(find.text('Device protection removed'), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);
      await tester.tap(find.text('Continue'));
      expect(continued, 1);
    });
  });
}
