import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_payments_screen.dart';
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
        home: LightningPaymentsScreen(lightningService: lightningService),
      );

  testWidgets('storico fatture: scaduta e in attesa con importi',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('21,000 sat'), findsOneWidget); // scaduta
    expect(find.text('5,000 sat'), findsOneWidget); // in attesa
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Waiting for payment'), findsOneWidget);
    expect(find.text('No invoices yet'), findsNothing);
  });

  testWidgets('cancella fattura: icona solo su non pagate + conferma',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    // Due fatture non pagate (scaduta + in attesa) → due icone cancella.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete this invoice?'), findsOneWidget);

    await tester.tap(find.text('Yes, delete'));
    await tester.pumpAndSettle();

    // Una è stata rimossa dal nodo (mock) → resta una sola icona.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(1));
    expect(find.text('Invoice deleted'), findsOneWidget);
  });

  testWidgets('fattura pagata: stato verde e data di pagamento',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() async {
      await service.connect(connection);
      final invoice = await service.makeInvoice(amountMsat: 7000000);
      service.markInvoicePaid(invoice.paymentHash);
    });
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('7,000 sat'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.textContaining('Paid on'), findsOneWidget);
  });

  testWidgets('paginazione: 25 per pagina + "Load more"', (tester) async {
    service = LightningServiceMock();
    // PERCHÉ: le fatture vanno create PRIMA di montare la schermata — il primo
    // caricamento avviene in initState.
    await tester.runAsync(() async {
      await service.connect(connection);
      // 26 fatture nuove + 2 storiche = 28 → la seconda pagina esiste.
      for (var i = 0; i < 26; i++) {
        await service.makeInvoice(amountMsat: 1000000 + i);
      }
    });
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Load more'), 400);
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    // 28 totali: dopo l'append la pagina è completa (3 < 25) → niente altro.
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('selettore: pagamenti inviati con fee e stato', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sent payments'));
    await tester.pumpAndSettle();

    expect(find.text('-2,000 sat'), findsOneWidget);
    expect(find.text('Fee: 2 sat'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    // Le fatture non sono più in vista.
    expect(find.text('Expired'), findsNothing);
  });

  testWidgets('selettore: HTLC con badge in volo e stato grezzo',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HTLCs'));
    await tester.pumpAndSettle();

    expect(find.text('1,500 sat'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('SENT_ADD_HTLC'), findsOneWidget);
    // L'HTLC concluso resta visibile con il suo stato reale.
    expect(find.text('RCVD_REMOVE_ACK_REVOCATION'), findsOneWidget);
    expect(find.text('Outgoing'), findsOneWidget);
    expect(find.text('Incoming'), findsOneWidget);
  });
}
