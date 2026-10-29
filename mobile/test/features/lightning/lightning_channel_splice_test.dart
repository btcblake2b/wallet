import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_splice.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_channel_detail_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock che rifiuta lo splice come un peer senza `option_unified_sigs`.
class _SpliceFailingMock extends LightningServiceMock {
  _SpliceFailingMock({super.onchainBalanceOverrideMsat});

  @override
  Future<LightningSpliceResult> spliceChannel({
    required String channelId,
    required int amountSats,
    List<String>? utxos,
    String? feerate,
  }) async =>
      throw const LightningException(
        'CHANNEL_FAILED',
        'Peer does not support splicing',
      );
}

/// Mock di un bridge più vecchio dell'app: non conosce lo splice.
class _SpliceUnknownMock extends LightningServiceMock {
  _SpliceUnknownMock({super.onchainBalanceOverrideMsat});

  @override
  Future<LightningSpliceResult> spliceChannel({
    required String channelId,
    required int amountSats,
    List<String>? utxos,
    String? feerate,
  }) async =>
      throw const LightningException(
        'NOT_IMPLEMENTED',
        'Metodo non supportato: splice_channel',
      );
}

/// Mock che risponde come CLN quando il wallet on-chain non copre l'importo.
class _InsufficientFundsMock extends LightningServiceMock {
  _InsufficientFundsMock({super.onchainBalanceOverrideMsat});

  @override
  Future<LightningSpliceResult> spliceChannel({
    required String channelId,
    required int amountSats,
    List<String>? utxos,
    String? feerate,
  }) async =>
      throw const LightningException(
        'INSUFFICIENT_BALANCE',
        'Could not afford 30000sat using all 1 available UTXOS: '
            '25298sat short',
      );
}

/// Splice dal dettaglio canale: ridimensiona senza chiudere.
///
/// // PERCHÉ: la feature tocca denaro (una transazione on-chain) — i test
/// // verificano che l'importo arrivi con il SEGNO giusto (splice-in positivo,
/// // splice-out negativo) e che la stima delle fee sia chiesta solo per
/// // l'aggiunta di fondi.
void main() {
  late LightningServiceMock service;

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  /// Canale del mock con stato/peer sovrascrivibili (casi "splice bloccato").
  LightningChannel buildChannel({
    String state = 'Usable',
    bool? peerConnected = true,
  }) =>
      LightningChannel(
        id: 'mock_channel_1',
        shortChannelId: '1000x1x0',
        peerPubkey: '02mock_peer_pubkey_000000000000000000000000000000',
        peerAlias: 'mock-peer',
        state: state,
        isPrivate: false,
        localBalance: 90000000,
        remoteBalance: 60000000,
        capacity: 150000000,
        feeBaseMsat: 1000,
        feePpm: 10,
        htlcCount: 0,
        spendableMsat: 89000000,
        receivableMsat: 59000000,
        peerConnected: peerConnected,
      );

  Widget wrap(
    LightningServiceMock lightningService,
    LightningChannel channel,
  ) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        // PERCHÉ: il dettaglio canale deve stare SOPRA una rotta — dopo uno
        // splice la schermata fa pop per far ricaricare la lista canali, e una
        // rotta radice non si può chiudere.
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => LightningChannelDetailScreen(
                      channel: channel,
                      lightningService: lightningService,
                    ),
                  ),
                ),
                child: const Text('open-detail'),
              ),
            ),
          ),
        ),
      );

  Future<void> openDetail(
    WidgetTester tester, {
    LightningChannel? channel,
    LightningServiceMock? mock,
    String version = 'v26.06.9-blake2b.9',
  }) async {
    service = mock ?? LightningServiceMock();
    // PERCHÉ (26/10): il pulsante di splice dipende dalla release del nodo
    // (splice da `.6`, sicuro da `.9`). Questi test riguardano il FLUSSO, non il
    // gate, quindi si parte da una release aggiornata; il gate ha i suoi test.
    service.versionOverride = version;
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service, channel ?? buildChannel()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-detail'));
    await tester.pumpAndSettle();
  }

  /// Porta in vista il pulsante "Ridimensiona canale" (lista lazy).
  Future<void> scrollToSplice(WidgetTester tester) async {
    final button = find.text('Resize channel');
    await tester.scrollUntilVisible(button, 300);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
  }

  Future<void> openSpliceDialog(
    WidgetTester tester, {
    LightningChannel? channel,
    LightningServiceMock? mock,
    String version = 'v26.06.9-blake2b.9',
  }) async {
    await openDetail(tester, channel: channel, mock: mock, version: version);
    await scrollToSplice(tester);
    await tester.tap(find.text('Resize channel'));
    await tester.pumpAndSettle();
  }

  testWidgets('nodo .7 → il dialog avvisa di aggiornare a .9', (tester) async {
    await openSpliceDialog(tester, version: 'v26.06.9-blake2b.7');

    expect(find.textContaining('release before .9'), findsOneWidget);
  });

  testWidgets('nodo .9 → nessun avviso di aggiornamento', (tester) async {
    await openSpliceDialog(tester);

    expect(find.textContaining('release before .9'), findsNothing);
  });

  testWidgets('il pulsante apre il dialog con le due direzioni',
      (tester) async {
    await openSpliceDialog(tester);

    expect(find.text('Resize channel without closing it'), findsOneWidget);
    expect(find.text('Add funds'), findsOneWidget);
    expect(find.text('Withdraw funds'), findsOneWidget);
    expect(find.text('Amount (sat)'), findsOneWidget);
  });

  testWidgets('stima la fee solo per aggiungere fondi', (tester) async {
    await openSpliceDialog(tester);

    await tester.enterText(find.byType(TextField), '100000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estimate on-chain fee'));
    await tester.pumpAndSettle();

    expect(find.text('On-chain fee: about 1,600 sat'), findsOneWidget);
  });

  testWidgets('conferma splice-in → importo positivo al servizio',
      (tester) async {
    // On-chain del nodo capiente: il preflight non deve bloccare.
    await openSpliceDialog(
      tester,
      mock: LightningServiceMock(onchainBalanceOverrideMsat: 200000000),
    );

    await tester.enterText(find.byType(TextField), '100000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(service.lastSplice, isNotNull);
    expect(service.lastSplice!.channelId, 'mock_channel_1');
    expect(service.lastSplice!.amountSats, 100000);
    expect(find.text('Channel resized'), findsOneWidget);
  });

  testWidgets('conferma splice-out → importo negativo al servizio',
      (tester) async {
    await openSpliceDialog(tester);

    await tester.tap(find.text('Withdraw funds'));
    await tester.pumpAndSettle();
    // La stima non ha senso in uscita: il pulsante sparisce.
    expect(find.text('Estimate on-chain fee'), findsNothing);

    await tester.enterText(find.byType(TextField), '40000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(service.lastSplice!.amountSats, -40000);
  });

  testWidgets('importo non valido → nessuna chiamata al nodo', (tester) async {
    await openSpliceDialog(tester);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(service.lastSplice, isNull);
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });

  group('splice bloccato', () {
    testWidgets('canale non utilizzabile → pulsante disabilitato',
        (tester) async {
      await openDetail(tester, channel: buildChannel(state: 'PendingOpen'));
      await scrollToSplice(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Resize channel'),
      );
      expect(button.onPressed, isNull);
      expect(
        find.text(
          'Resizing is available only on usable channels '
          'with the peer online.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('peer disconnesso → pulsante disabilitato', (tester) async {
      await openDetail(
        tester,
        channel: buildChannel(peerConnected: false),
      );
      await scrollToSplice(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Resize channel'),
      );
      expect(button.onPressed, isNull);
      expect(
        find.text(
          'Resizing is available only on usable channels '
          'with the peer online.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('CHANNEL_FAILED → spiega che il peer non supporta lo splice',
        (tester) async {
      await openSpliceDialog(
        tester,
        mock: _SpliceFailingMock(onchainBalanceOverrideMsat: 200000000),
      );

      await tester.enterText(find.byType(TextField), '100000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('the peer may not support it'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Peer does not support splicing'),
        findsOneWidget,
      );
      expect(find.text('Channel resized'), findsNothing);
    });

    testWidgets('bridge vecchio (NOT_IMPLEMENTED) → invita ad aggiornarlo',
        (tester) async {
      await openSpliceDialog(
        tester,
        mock: _SpliceUnknownMock(onchainBalanceOverrideMsat: 200000000),
      );

      await tester.enterText(find.byType(TextField), '100000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('does not expose channel resizing yet'),
        findsOneWidget,
      );
      expect(find.text('Channel resized'), findsNothing);
    });

    testWidgets('on-chain insufficiente → mostra i fondi e blocca la conferma',
        (tester) async {
      // Il mock ha 25.000 sat on-chain: 100.000 non sono finanziabili.
      await openSpliceDialog(tester);

      expect(find.text('Node on-chain funds: 25,000 sat'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '100000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Not enough on-chain funds on the node'),
        // Compare due volte: avviso nel dialog + snackbar alla conferma.
        findsWidgets,
      );
      expect(service.lastSplice, isNull);
      // Il dialog resta aperto: non si è confermato nulla.
      expect(find.text('Resize the channel without closing it'), findsNothing);
    });

    testWidgets('INSUFFICIENT_BALANCE dal nodo → spiega e riporta il testo',
        (tester) async {
      // Preflight capiente: l'errore arriva dal nodo al momento dello splice.
      await openSpliceDialog(
        tester,
        mock: _InsufficientFundsMock(onchainBalanceOverrideMsat: 200000000),
      );

      await tester.enterText(find.byType(TextField), '30000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Not enough on-chain funds on the node'),
        findsOneWidget,
      );
      expect(find.textContaining('25298sat short'), findsOneWidget);
    });
  });
}
