import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/info_hints.dart';
import 'package:btc_blake2b_wallet/core/widgets/info_dot.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:btc_blake2b_wallet/l10n/info_hints_l10n.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

Widget _wrap({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('InfoDot', () {
    setUp(() {
      InfoHints.resetForTest();
    });

    testWidgets('ON → icona presente', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const InfoDot(id: InfoHintId.coinControl)),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('OFF → SizedBox.shrink (nessuna icona)', (tester) async {
      final storage = MockStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      // PERCHÉ: parto da OFF prima di pump → il ListenableBuilder vede subito
      // enabled=false e restituisce SizedBox.shrink().
      InfoHints.instance = InfoHints(storage: storage);
      await InfoHints.instance.setEnabled(false);
      await tester.pumpWidget(
        _wrap(child: const InfoDot(id: InfoHintId.coinControl)),
      );
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('tap → AlertDialog con titolo e corpo', (tester) async {
      await tester.pumpWidget(
        _wrap(child: const InfoDot(id: InfoHintId.coinControl)),
      );
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // Il titolo è generato da infoTitle(coinControl)
      expect(find.text('Coin control (UTXO selection)'), findsOneWidget);
      // Il corpo è generato da infoBody(coinControl)
      expect(find.textContaining('Your balance is made of UTXOs'), findsOneWidget);
    });
  });
}
