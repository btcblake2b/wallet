import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_node_management_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Widget wrap(LightningServiceMock lightningService) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningNodeManagementScreen(lightningService: lightningService),
      );

  testWidgets('identità del nodo: alias, pubkey, versione e contatori',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Node management'), findsOneWidget);
    expect(find.text('mock-dln-node'), findsOneWidget);
    expect(find.textContaining('Public key: 02043a91'), findsOneWidget);
    expect(find.text('Version: v26.06.7-blake2b.2'), findsOneWidget);
    expect(find.text('Peers: 1 · Active channels: 1'), findsOneWidget);
    // Contatori assenti quando non ci sono canali in attesa.
    expect(find.textContaining('Pending channels'), findsNothing);
  });

  testWidgets('I4a: canale chiuso e peer disconnesso non contano',
      (tester) async {
    service = LightningServiceMock(
      channelCount: 0,
      closedChannelCount: 1,
      peerDisconnected: true,
    );
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    // Peer: si contano i CONNESSI (0), non i registrati (il mock ne ha 1).
    expect(find.text('Peers: 0 · Active channels: 0'), findsOneWidget);
    // Il canale chiuso non è in elenco né nei conteggi.
    await tester.scrollUntilVisible(find.text('All channels (0)'), 300);
    expect(find.text('All channels (0)'), findsOneWidget);
    expect(find.textContaining('mock-closed'), findsNothing);
  });

  testWidgets('copia della pubkey → snackbar di conferma', (tester) async {
    // PERCHÉ: nei widget test il canale di piattaforma degli appunti non ha
    // handler: senza mock la Future non si completa e la snackbar non appare.
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Copied'), findsOneWidget);
    expect(
      calls.any(
        (c) =>
            c.method == 'Clipboard.setData' &&
            '${(c.arguments as Map)['text']}'.startsWith('02043a91'),
      ),
      isTrue,
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('liquidità: capacità, uscita, entrata (in sat)', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Liquidity'), findsOneWidget);
    expect(find.text('150,000 sat'), findsWidgets); // capacità totale
    expect(find.text('89,000 sat'), findsOneWidget); // outbound
    expect(find.text('59,000 sat'), findsOneWidget); // inbound
    expect(find.textContaining('No inbound liquidity'), findsNothing);
  });

  testWidgets('liquidità: senza inbound appare l avviso', (tester) async {
    service = LightningServiceMock(inboundOverrideMsat: 0);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('0 sat'), findsOneWidget);
    expect(find.textContaining('No inbound liquidity'), findsOneWidget);
  });

  testWidgets('movimenti: anteprima + ingresso allo storico completo',
      (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Movements'), findsOneWidget);
    expect(find.text('Lightning payment'), findsOneWidget);
    expect(find.text('-1,000 sat'), findsOneWidget);
    expect(find.text('On-chain deposit'), findsOneWidget);
    expect(find.text('+1,001 sat'), findsOneWidget);

    // La riga di ingresso sta in fondo alla ListView (lazy): va portata in vista
    // e centrata, altrimenti il tap cade fuori dalla viewport del test.
    await tester.scrollUntilVisible(find.text('All movements'), 300);
    await tester.ensureVisible(find.text('All movements'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All movements'));
    await tester.pumpAndSettle();

    // Nello storico completo la riga di ingresso non esiste più.
    expect(find.text('All movements'), findsNothing);
    expect(find.text('Lightning payment'), findsOneWidget);
    expect(find.text('Load more'), findsNothing); // 4 movimenti: una pagina
  });

  testWidgets('righe operative: canali e peer', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    // Le righe operative stanno in fondo: la ListView è lazy.
    await tester.scrollUntilVisible(find.text('All channels (1)'), 300);
    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('All channels (1)'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Peers'), 300);
    await tester.ensureVisible(find.text('Peers'));
    await tester.pumpAndSettle();
    expect(find.text('Peers'), findsOneWidget);

    await tester.tap(find.text('Peers'));
    await tester.pumpAndSettle();
    expect(find.text('Connect peer'), findsOneWidget);
  });

  testWidgets('riga On-chain del nodo con saldo e navigazione', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Node on-chain'), 300);
    await tester.ensureVisible(find.text('Node on-chain'));
    await tester.pumpAndSettle();

    // Il sottotitolo porta il saldo on-chain reale (mock: 25.000 sat).
    expect(find.text('25,000 sat'), findsWidgets);

    await tester.tap(find.text('Node on-chain'));
    await tester.pumpAndSettle();
    expect(find.text('On-chain balance'), findsOneWidget);
    expect(find.text('Node addresses'), findsOneWidget);
  });
}
