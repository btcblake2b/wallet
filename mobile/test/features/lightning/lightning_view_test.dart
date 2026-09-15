import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_connection_store.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_view.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/channel_card.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LightningServiceMock service;
  late LightningConnectionStore store;

  // Valori pubblici di test (vettori BIP340).
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  setUp(() {
    service = LightningServiceMock();
    // Nei test lo storage sicuro non è disponibile: load() → null (feature
    // resta disconnessa) — comportamento atteso e gestito dal servizio.
    store = LightningConnectionStore();
  });

  Widget buildView() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LightningView(
            lightningService: service,
            connectionStore: store,
          ),
        ),
      );

  testWidgets('disconnesso: CTA di connessione visibile', (tester) async {
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.text('No Lightning node connected'), findsOneWidget);
    expect(find.text('Connect node'), findsOneWidget);
  });

  testWidgets('connesso (mock): saldo, azioni e canali', (tester) async {
    // PERCHÉ runAsync: le Future.delayed del mock usano il clock fake —
    // fuori da un pump il tempo non avanza e l'await resterebbe appeso.
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.textContaining('sat'), findsWidgets);
    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    // Il canale mock è in stato Usable.
    expect(find.text('Usable'), findsOneWidget);
  });

  testWidgets('nessun canale: empty state', (tester) async {
    await tester.runAsync(() async {
      await service.connect(connection);
      final channels = await service.listChannels();
      await service.closeChannel(channelId: channels.first.id);
    });
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.text('No open channels'), findsOneWidget);
  });

  testWidgets('disconnect dal mock torna alla CTA', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    // PERCHÉ: con la card on-chain la lista è cresciuta — il bottone
    // Disconnect può essere fuori viewport (ListView lazy).
    await tester.scrollUntilVisible(find.text('Disconnect'), 300);
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(find.text('No Lightning node connected'), findsOneWidget);
  });

  testWidgets('connesso: card on-chain visibile con azioni', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.text('Node on-chain'), findsOneWidget);
    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('Send on-chain'), findsOneWidget);
  });

  testWidgets('tap Deposita → schermata con indirizzo', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deposit'));
    // PERCHÉ: niente pumpAndSettle qui — il QR (SafeQrImage) genera un PNG
    // con API async del motore che non si "settla" sotto clock fake.
    // Pompiamo transizione + caricamento del mock (latenza 20ms) a step.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('On-chain deposit'), findsOneWidget);
    expect(find.textContaining('bc1qmock'), findsOneWidget);
  });

  testWidgets('nodo senza metodi on-chain: card nascosta', (tester) async {
    final legacy = LightningServiceMock(supportedMethods: const ['get_info']);
    await tester.runAsync(() => legacy.connect(connection));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LightningView(
            lightningService: legacy,
            connectionStore: store,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Node on-chain'), findsNothing);
  });

  testWidgets('nodo solo in uscita: deposito non disponibile', (tester) async {
    final withdrawOnly = LightningServiceMock(
      supportedMethods: const ['get_info', 'pay_onchain'],
    );
    await tester.runAsync(() => withdrawOnly.connect(connection));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: LightningView(
            lightningService: withdrawOnly,
            connectionStore: store,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Node on-chain'), findsOneWidget);
    expect(find.text('Deposit'), findsNothing);
    expect(find.text('Send on-chain'), findsOneWidget);
  });

  testWidgets('card canale in sat con alias del peer (I2)', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    // 89.000.000 msat = 89.000 sat: se ricomparisse il bug delle unità
    // (msat mostrati come sat) il testo atteso non si troverebbe più.
    await tester.scrollUntilVisible(find.text('89,000 sat'), 200);
    expect(find.text('89,000 sat'), findsOneWidget);
    expect(find.text('59,000 sat'), findsOneWidget);
    expect(find.text('89,000,000 sat'), findsNothing);
    expect(find.textContaining('mock-peer'), findsWidgets);
    expect(find.text('Spendable'), findsOneWidget);
    expect(find.text('Receivable'), findsOneWidget);
  });

  testWidgets('tap sulla card canale → dettaglio canale', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    // Tap sulla card del canale (bersaglio robusto: il valore testuale può
    // restare al bordo del viewport dopo lo scroll).
    final card = find.byType(LightningChannelCard);
    await tester.scrollUntilVisible(card, 200);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Channel details'), findsOneWidget);
    // «Fee» compare due volte (card canale + sezione fee): uso il titolo.
    expect(find.text('Routing fees'), findsOneWidget);
    // La sezione fee allunga il dettaglio: il pulsante è sotto la piega.
    await tester.scrollUntilVisible(find.text('Close channel'), 200);
    expect(find.text('Close channel'), findsOneWidget);
  });

  testWidgets('notifica dal nodo → avviso di attività + refresh',
      (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    service.emitNotification();
    await tester.pump(); // consegna lo stream
    await tester.pump(const Duration(milliseconds: 300)); // animazione snackbar

    expect(find.text('Node activity detected'), findsOneWidget);

    // Lascia scadere la snackbar per non lasciare timer pendenti.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('riga Gestione nodo al posto dei peer (I3a)', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.text('Node management'), findsOneWidget);
    // Il sottotitolo porta i contatori reali del nodo (mock: 1 peer, 1 canale).
    expect(find.text('1 peers · 1 channels'), findsOneWidget);
    // I peer non sono più un ingresso diretto dalla principale.
    expect(find.text('Peers'), findsNothing);

    await tester.tap(find.text('Node management'));
    await tester.pumpAndSettle();
    expect(find.text('Node identity'), findsOneWidget);
  });

  testWidgets('I4a: canale chiuso escluso da card e contatori', (tester) async {
    service = LightningServiceMock(channelCount: 0, closedChannelCount: 1);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    // Il canale chiuso non è un "canale": niente card/alias, empty state.
    expect(find.textContaining('mock-closed'), findsNothing);
    expect(find.text('No open channels'), findsOneWidget);
    // Il sottotitolo conta i peer CONNESSI (1) e i canali attivi (0).
    expect(find.text('1 peers · 0 channels'), findsOneWidget);
  });

  testWidgets('canali compatti: 2 card + rimando all elenco completo',
      (tester) async {
    service = LightningServiceMock(channelCount: 3);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('All channels (3)'), 300);
    expect(find.text('All channels (3)'), findsOneWidget);
    // Il terzo canale non è renderizzato nella principale.
    expect(find.textContaining('mock-peer-2'), findsNothing);

    await tester.tap(find.text('All channels (3)'));
    await tester.pumpAndSettle();
    expect(find.byType(LightningChannelCard), findsNWidgets(3));
  });
}
