import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_keysend_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Pubkey valida (66 esadecimali): il flusso non si ferma alla validazione.
  const pubkey =
      '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389';

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  Widget wrap(LightningServiceMock service) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningKeysendScreen(lightningService: service),
      );

  testWidgets('pubkey non valida → errore e nessun invio', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'non-una-pubkey');
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();

    expect(find.text('Invalid node pubkey'), findsOneWidget);
    expect(find.text('Send this keysend payment?'), findsNothing);
  });

  testWidgets('importo mancante → errore', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, pubkey);
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });

  testWidgets('conferma con destinazione e importo, poi invio', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), pubkey);
    await tester.enterText(find.byType(TextField).at(1), '21');
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    // Latenza del mock + risoluzione alias.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Conferma forte: destinazione, importo e avviso di irreversibilità.
    expect(find.text('Send this keysend payment?'), findsOneWidget);
    expect(find.textContaining('Destination:'), findsWidgets);
    expect(find.textContaining('21 sat'), findsOneWidget);
    // L'avviso compare due volte: nella pagina e nel dialog.
    expect(
      find.textContaining('cannot be reversed'),
      findsNWidgets(2),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Esito: la snackbar riporta anche la fee.
    expect(find.text('Keysend sent: 21 sat (+1 sat)'), findsOneWidget);

    // Il pagamento è nello storico del nodo (mock): era davvero un invio.
    final pays = await tester.runAsync(() => service.listPays());
    expect(pays!.first.destination, pubkey);
    expect(pays.first.amountMsat, 21000);
  });

  testWidgets('annullare la conferma NON invia nulla', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), pubkey);
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Keysend sent'), findsNothing);
    final pays = await tester.runAsync(() => service.listPays());
    expect(pays, hasLength(1)); // solo il pagamento preesistente del mock
  });
}
