import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_channels_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/channel_card.dart';
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
        home: LightningChannelsScreen(lightningService: lightningService),
      );

  testWidgets('mostra tutti i canali del nodo', (tester) async {
    service = LightningServiceMock(channelCount: 3);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.byType(LightningChannelCard), findsNWidgets(3));
    expect(find.textContaining('mock-peer'), findsWidgets);
  });

  testWidgets('tap sulla card → dettaglio canale', (tester) async {
    service = LightningServiceMock(channelCount: 2);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LightningChannelCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Channel details'), findsOneWidget);
    // La sezione fee allunga il dettaglio: il pulsante è sotto la piega.
    await tester.scrollUntilVisible(find.text('Close channel'), 200);
    expect(find.text('Close channel'), findsOneWidget);
  });

  testWidgets('nessun canale → empty state', (tester) async {
    service = LightningServiceMock(channelCount: 0);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('No open channels'), findsOneWidget);
  });
}
