import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_movements_screen.dart';
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
        home: LightningMovementsScreen(lightningService: lightningService),
      );

  testWidgets('prima pagina di 50 movimenti → "Carica altri" disponibile',
      (tester) async {
    // 60 movimenti: la seconda pagina esiste (10 elementi).
    service = LightningServiceMock(movementCount: 60);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    // La lista è lunga: il pulsante sta in fondo alla ListView (lazy).
    await tester.scrollUntilVisible(find.text('Load more'), 600);
    expect(find.text('Load more'), findsOneWidget);
    expect(find.text('No movements yet'), findsNothing);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    // Dopo l'append la seconda pagina è arrivata (10 < 50 → niente altro).
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('storico vuoto → empty state', (tester) async {
    service = LightningServiceMock(movementCount: 0);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('No movements yet'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('movimenti misti: entrate con + e uscite con -', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('-1,000 sat'), findsOneWidget); // invoice in uscita
    expect(find.text('+1,001 sat'), findsOneWidget); // deposito in entrata
    expect(find.text('On-chain fee'), findsOneWidget);
    expect(find.text('Channel opening'), findsOneWidget);
  });
}
