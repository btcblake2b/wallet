import 'package:btc_blake2b_wallet/core/services/balance_display.dart';
import 'package:btc_blake2b_wallet/core/services/fiat_price.dart';
import 'package:btc_blake2b_wallet/core/widgets/tappable_balance.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  setUp(() {
    FiatPrice.instance = FiatPrice.inMemory();
    BalanceDisplay.instance = BalanceDisplay.inMemory();
  });

  tearDown(() {
    FiatPrice.instance = FiatPrice.inMemory();
    BalanceDisplay.resetForTest();
  });

  testWidgets('controllo spento → saldo in XBT e NON toccabile',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const TappableBalance(unitKey: 'w1', sats: 100000)),
    );

    expect(find.text('0.00100000 BTC'), findsOneWidget);

    await tester.tap(find.text('0.00100000 BTC'));
    await tester.pumpAndSettle();

    // Nessun ciclo: l'unità resta XBT.
    expect(BalanceDisplay.instance.unitFor('w1'), BalanceUnit.xbt);
  });

  testWidgets('controllo acceso → tocco: XBT → sats → dollari → XBT',
      (tester) async {
    FiatPrice.instance = FiatPrice.inMemory(
      enabled: true,
      usdCentsPerXbt: 30000,
    );

    await tester.pumpWidget(
      _wrap(const TappableBalance(unitKey: 'w1', sats: 100000)),
    );

    expect(find.text('0.00100000 BTC'), findsOneWidget);

    await tester.tap(find.text('0.00100000 BTC'));
    await tester.pumpAndSettle();
    expect(find.text('100 000 sats'), findsOneWidget);

    await tester.tap(find.text('100 000 sats'));
    await tester.pumpAndSettle();
    expect(find.text('0.30 \$'), findsOneWidget);

    await tester.tap(find.text('0.30 \$'));
    await tester.pumpAndSettle();
    expect(find.text('0.00100000 BTC'), findsOneWidget);
  });

  testWidgets('stessa chiave = stessa unità fra due widget (home e detail)',
      (tester) async {
    FiatPrice.instance = FiatPrice.inMemory(
      enabled: true,
      usdCentsPerXbt: 30000,
    );

    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TappableBalance(unitKey: 'w1', sats: 100000),
            TappableBalance(unitKey: 'w2', sats: 200000),
          ],
        ),
      ),
    );

    // Tocca il primo (w1): solo lui cambia unità.
    await tester.tap(find.text('0.00100000 BTC'));
    await tester.pumpAndSettle();

    expect(find.text('100 000 sats'), findsOneWidget);
    // w2 resta in XBT: 0,002 BTC.
    expect(find.text('0.00200000 BTC'), findsOneWidget);
  });
}
