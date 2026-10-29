import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_cross_chain_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_send_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pagamento cross-chain (P9): verifica del costo e conferma esplicita.
///
/// // PERCHÉ: il flusso muove denaro reale verso un servizio esterno — i test
/// // bloccano le due garanzie che contano: si vede la cifra PRIMA, e senza
/// // conferma non parte nulla.
void main() {
  late LightningServiceMock service;

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  const invoice =
      'lnbc50u1p3xyzabcdqsp5abcdefghijklmnopqrstuvwxyz0123456789abcdefghijk';

  Widget wrap() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningCrossChainScreen(lightningService: service),
      );

  Future<void> open(WidgetTester tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  testWidgets('verifica del costo mostra quanto si paga', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), invoice);
    await tester.tap(find.text('Check cost'));
    await tester.pumpAndSettle();

    expect(find.text('You pay: 5,110 sat'), findsOneWidget);
    expect(find.text('Invoice amount: 5,000 sat'), findsOneWidget);
    expect(find.text('Exchange rate: 1 XBT = 0.98 BTC'), findsOneWidget);
    expect(find.text('Bridge spread: 2%'), findsOneWidget);
    expect(find.text('Pay via bridge'), findsOneWidget);
  });

  testWidgets('senza conferma non parte alcun pagamento', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), invoice);
    await tester.tap(find.text('Check cost'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay via bridge'));
    await tester.pumpAndSettle();

    // Il dialog chiede conferma; annullando non succede nulla.
    expect(find.text('Pay through the bridge?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.lastCrossChainPay, isNull);
    expect(find.text('Payment completed'), findsNothing);
  });

  testWidgets('conferma → pagamento completato con preimage', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), invoice);
    await tester.tap(find.text('Check cost'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay via bridge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(service.lastCrossChainPay, invoice);
    expect(find.text('Payment completed'), findsOneWidget);
    expect(find.text('mock_preimage'), findsOneWidget);
  });

  group('voce in invio', () {
    Future<void> openSend(
      WidgetTester tester,
      List<String>? methods,
    ) async {
      service = LightningServiceMock(supportedMethods: methods);
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: LightningSendScreen(lightningService: service),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('nodo con i metodi cross-chain: voce visibile', (tester) async {
      await openSend(tester, const [
        'get_info',
        'cross_chain_check',
        'cross_chain_pay',
      ]);

      expect(find.text('Pay a BTC (SHA-256) invoice'), findsOneWidget);
    });

    testWidgets('nodo senza i metodi cross-chain: voce nascosta',
        (tester) async {
      await openSend(tester, const ['get_info', 'pay_invoice']);

      expect(find.text('Pay a BTC (SHA-256) invoice'), findsNothing);
    });

    testWidgets('nodo che elenca un solo metodo: voce nascosta',
        (tester) async {
      await openSend(tester, const ['get_info', 'cross_chain_check']);

      expect(find.text('Pay a BTC (SHA-256) invoice'), findsNothing);
    });
  });
}
