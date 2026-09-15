import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_channel_detail_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_peers_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LightningServiceMock service;

  // Valori pubblici di test (vettori BIP340), come negli altri test Lightning.
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  const channel = LightningChannel(
    id: 'ch1',
    shortChannelId: '1000x1x0',
    peerPubkey: '02aa',
    peerAlias: 'peer-one',
    state: 'Usable',
    isPrivate: false,
    localBalance: 9000000,
    remoteBalance: 7000000,
    capacity: 16000000,
    feeBaseMsat: 1000,
    feePpm: 10,
    htlcCount: 1,
    spendableMsat: 8900000,
    receivableMsat: 6900000,
    peerConnected: true,
    status: ['CHANNELD_NORMAL:Funding transaction locked.'],
  );

  setUp(() => service = LightningServiceMock());

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      );

  testWidgets('lista peer: alias, stato, indirizzi e canali', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(
      wrap(LightningPeersScreen(lightningService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peers'), findsOneWidget);
    expect(find.text('mock-peer'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('Addresses:'), findsOneWidget);
    expect(find.text('Channels: 1'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });

  testWidgets('connetti peer: pubkey@host:porta viene separata nei campi',
      (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(
      wrap(LightningPeersScreen(lightningService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect peer'));
    await tester.pumpAndSettle();

    // Forma compatta incollata in un colpo solo: il campo host resta vuoto.
    final pubkey = '02${'dd' * 32}';
    await tester.enterText(find.byType(TextField).first, '$pubkey@1.2.3.4:9735');
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    // Il peer compare in lista con l'indirizzo estratto dalla stringa.
    expect(find.textContaining('1.2.3.4:9735'), findsWidgets);
  });

  testWidgets('disconnetti peer: conferma → badge Disconnected', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(
      wrap(LightningPeersScreen(lightningService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(
      find.text('Disconnect this peer? Open channels stay active.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Disconnected'), findsOneWidget);
  });

  testWidgets('stringa peer non valida → errore, nessun connect', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(
      wrap(LightningPeersScreen(lightningService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect peer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'non-una-pubkey');
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid node ID or host (66 hex, host:port)'),
      findsWidgets,
    );
  });

  testWidgets('dettaglio canale: sat, fee, HTLC e chiusura cooperativa',
      (tester) async {
    await tester.runAsync(() => service.connect(connection));
    bool? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => LightningChannelDetailScreen(
                        channel: channel,
                        lightningService: service,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Channel details'), findsOneWidget);
    // 16.000.000 msat = 16.000 sat (unità convertite) e 1000 msat = 1 sat.
    expect(find.text('16,000 sat'), findsWidgets);
    expect(find.text('1 sat + 10 ppm'), findsOneWidget);
    expect(find.text('peer-one'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // HTLC pending

    await tester.tap(find.text('Close channel'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    // La schermata torna indietro con esito positivo → la view rifà il refresh.
    expect(result, isTrue);
    expect(find.text('open'), findsOneWidget);
  });
}
