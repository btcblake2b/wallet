import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_receive_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LightningServiceMock service;

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  Widget wrap(LightningServiceMock lightningService) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningReceiveScreen(lightningService: lightningService),
      );

  testWidgets('invoice creata → QR e nessun badge di pagamento',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));

    await tester.enterText(find.byType(TextField).first, '1500');
    await tester.tap(find.text('Create invoice'));
    // PERCHÉ: niente pumpAndSettle — il QR genera un PNG con API async del
    // motore che non si "settla" sotto clock fake (come nel test deposito I1).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lightning invoice'), findsOneWidget);
    expect(find.text('Invoice paid'), findsNothing);
  });

  testWidgets('pagamento rilevato dal polling → badge "Invoice paid"',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));

    await tester.enterText(find.byType(TextField).first, '1500');
    await tester.tap(find.text('Create invoice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Il nodo registra il pagamento (come farebbe la notifica push).
    await tester.runAsync(() async {
      final invoices = await service.listInvoices(limit: 1);
      service.markInvoicePaid(invoices.first.paymentHash);
    });

    // Avanza il timer del polling e lascia arrivare la risposta del mock.
    await tester.pump(LightningReceiveScreen.pollInterval);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Invoice paid'), findsWidgets);
  });

  testWidgets('nodo senza canali → avviso «non puoi ricevere» prima del QR',
      (tester) async {
    service = LightningServiceMock(channelCount: 0);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You cannot receive yet'), findsOneWidget);
    expect(find.text('Get inbound liquidity'), findsOneWidget);
  });

  testWidgets('canale senza liquidità in entrata → avviso mostrato',
      (tester) async {
    service = LightningServiceMock(channelCount: 1, inboundOverrideMsat: 0);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You cannot receive yet'), findsOneWidget);
  });

  testWidgets('canale con liquidità in entrata → nessun avviso',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('You cannot receive yet'), findsNothing);
  });
}
