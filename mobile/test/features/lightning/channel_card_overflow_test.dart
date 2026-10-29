import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_channel_detail_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/channel_card.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// Regressione (26/10): durante uno splice il nodo riporta stati lunghi
/// (`CHANNELD_AWAITING_SPLICE`) e la card sforava di pochi pixel a destra.
///
/// // PERCHÉ a 266 px: è la larghezza reale misurata sul device (constraint
/// // `0.0<=w<=266.0` nel log dell'overflow). Con uno stato corto non emerge.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 266, child: child),
          ),
        ),
      );

  LightningChannel channel({required String state, int? htlcCount}) =>
      LightningChannel(
        id: 'ff89ed8cbcac3df954deb8a10b8d32e7943f578f8d0fa9fd4ad495cd6454f735',
        shortChannelId: '975653x69x0',
        peerPubkey: '02aa',
        peerAlias: 'peer-one',
        state: state,
        isPrivate: false,
        localBalance: 9000000,
        remoteBalance: 7000000,
        capacity: 16000000,
        feeBaseMsat: 1000,
        feePpm: 10,
        htlcCount: htlcCount,
        spendableMsat: 8900000,
        receivableMsat: 6900000,
        peerConnected: true,
      );

  testWidgets('stato di splice + HTLC a 266 px: nessun overflow', (tester) async {
    await tester.pumpWidget(
      wrap(
        LightningChannelCard(
          channel: channel(state: 'CHANNELD_AWAITING_SPLICE', htlcCount: 3),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // L'id del canale resta comunque leggibile per intero.
    expect(find.text('975653x69x0'), findsOneWidget);
  });

  testWidgets('stato normale: layout invariato', (tester) async {
    await tester.pumpWidget(
      wrap(LightningChannelCard(channel: channel(state: 'CHANNELD_NORMAL'))),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('CHANNELD_NORMAL'), findsOneWidget);
    expect(find.text('975653x69x0'), findsOneWidget);
    expect(find.textContaining('peer-one'), findsOneWidget);
  });

  testWidgets('dettaglio canale: stato di splice a 266 px senza overflow',
      (tester) async {
    const connection = LightningConnection(
      walletPubkey:
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
      relays: ['wss://relay.test'],
      secretHex:
          'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
    );
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));

    await tester.pumpWidget(
      wrap(
        LightningChannelDetailScreen(
          channel: channel(state: 'CHANNELD_AWAITING_SPLICE', htlcCount: 1),
          lightningService: service,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CHANNELD_AWAITING_SPLICE'), findsOneWidget);
  });
}
