import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_channel_detail_screen.dart';
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

  // Canale corrispondente alla policy del mock (`_fees['mock_channel_1']`).
  const channel = LightningChannel(
    id: 'mock_channel_1',
    shortChannelId: '1000x1x0',
    peerPubkey: '02mock_peer_pubkey_000000000000000000000000000000',
    peerAlias: 'mock-peer',
    state: 'Usable',
    isPrivate: false,
    localBalance: 90000000,
    remoteBalance: 60000000,
    capacity: 150000000,
    feeBaseMsat: 1000,
    feePpm: 10,
    htlcCount: 0,
    spendableMsat: 89000000,
    receivableMsat: 59000000,
    peerConnected: true,
  );

  Widget wrap(LightningServiceMock lightningService) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningChannelDetailScreen(
          channel: channel,
          lightningService: lightningService,
        ),
      );

  testWidgets('sezione fee: base, ppm, limiti HTLC, cltv e riserva',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Routing fees'), findsOneWidget);
    // La coppia base+ppm e il massimo HTLC appaiono anche nella card canale.
    expect(find.text('1 sat + 10 ppm'), findsNWidgets(2));
    expect(find.text('150,000 sat'), findsNWidgets(2));
    expect(find.text('34'), findsOneWidget); // CLTV delta
    expect(find.text('1,500 sat'), findsOneWidget); // nostra riserva
    expect(find.text('144'), findsOneWidget); // to-self delay
    expect(find.text('Edit fees'), findsOneWidget);
  });

  testWidgets('modifica fee: conferma prima/dopo e applicazione',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit fees'));
    await tester.pumpAndSettle();

    // Il primo campo è la fee base in sat (attuale: 1).
    await tester.enterText(find.byType(TextFormField).first, '2');
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    // Conferma forte con riepilogo prima → dopo.
    expect(find.text('Apply these routing fees?'), findsOneWidget);
    expect(find.textContaining('Current: 1 sat + 10 ppm'), findsOneWidget);
    expect(find.textContaining('New: 2 sat + 10 ppm'), findsOneWidget);
    expect(
      find.textContaining('network accepts only a few changes'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Confirm').last);
    await tester.pumpAndSettle();

    // Il mock applica la modifica: la sezione mostra i nuovi valori.
    expect(find.text('Fee policy updated'), findsOneWidget);
    expect(find.text('2 sat + 10 ppm'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('annullare la conferma NON cambia le fee', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit fees'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '9');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Nessuna seconda dialog e nessuna modifica: restano i valori iniziali.
    expect(find.text('Apply these routing fees?'), findsNothing);
    expect(find.text('1 sat + 10 ppm'), findsNWidgets(2));
    expect(find.text('9 sat + 10 ppm'), findsNothing);
  });
}
