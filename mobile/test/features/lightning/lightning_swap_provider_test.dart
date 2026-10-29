import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/config/swap_defaults.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_session_store.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_swap_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockSwapService extends Mock implements SwapService {}

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockStorage extends Mock implements FlutterSecureStorage {}

/// Pagamento senza nodo: il NOSTRO nodo è già nel menu, i limiti di invio
/// arrivano dalla liquidità del provider e il destinatario viene verificato.
///
/// // PERCHÉ (27/10/2026): un utente senza nodo non sa procurarsi una URI di
/// // provider e non sa quanto può inviare — questi test bloccano la
/// // regressione su entrambe le cose.
void main() {
  const providerPubkey = '91d1fca1a250bfd426b3276fa1a40018d4a0b'
      'f3fb46b8e748c5892066d18b296';

  const limits = SwapProviderInfo(
    minSats: 5000,
    maxSats: 250000,
    minSendableSats: 4750,
    maxSendableSats: 23750,
    availableSats: 24000,
  );

  final wallet = WalletRecord(
    walletId: 'w1',
    encryptedSeed: 'enc',
    publicAddress: 'bc1qexamplewalletaddress000000000000000000000',
    deviceId: 'device-1',
    createdAt: DateTime.utc(2026, 1, 1),
    name: 'Wallet 1',
  );

  setUpAll(() {
    registerFallbackValue('');
    // mocktail: serve un valore reale per i matcher `any()` su SwapSession.
    registerFallbackValue(
      SwapSession(
        swapId: 'x',
        invoice: 'lnbc1',
        paymentHashHex:
            'abababababababababababababababababababababababababababababababab',
        fundingAmountSats: 1,
        cltvHeight: 1,
        fundingDeadlineHeight: 1,
        claimPubkeyHex: '02${'11' * 32}',
        refundPubkeyHex: '02${'22' * 32}',
        refundKeyIndex: 0,
        htlcAddress: 'bc1q',
        witnessScriptHex: '00',
        providerPubkey: 'cd' * 32,
        relays: const [],
        state: SwapClientState.completed,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  Future<MockSwapService> buildService({
    required bool defaultNodeAlive,
    required SwapProviderInfo? withInvoice,
  }) async {
    final storage = MockStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    final service = MockSwapService();
    when(() => service.sessions).thenReturn(SwapSessionStore(storage: storage));
    when(() => service.restoreConnection()).thenAnswer((_) async => null);
    when(() => service.knownProviderUris()).thenAnswer((_) async => const []);
    when(() => service.probeProvider(any()))
        .thenAnswer((_) async => defaultNodeAlive);
    when(() => service.connect(any())).thenAnswer(
      (_) async => const SwapProvider(
        providerPubkey: providerPubkey,
        relays: ['wss://relay.primal.net'],
      ),
    );
    // Un solo stub: mocktail registra i parametri named anche quando omessi,
    // quindi due stub separate si sovrascriverebbero a vicenda.
    when(() => service.providerInfo(invoice: any(named: 'invoice'))).thenAnswer(
      (invocation) async =>
          invocation.namedArguments[#invoice] == null ? limits : withInvoice,
    );
    when(() => service.exportRecoveryBlob(any())).thenReturn('swaprecover1.x');
    return service;
  }

  Future<void> pumpScreen(WidgetTester tester, SwapService service) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningSwapScreen(
          swapService: service,
          wallets: [wallet],
          walletRepository: MockWalletRepository(),
          bitcoinService: MockBitcoinService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('il nodo predefinito è già nel menu e preselezionato',
      (tester) async {
    final service = await buildService(
      defaultNodeAlive: true,
      withInvoice: null,
    );
    await pumpScreen(tester, service);

    // Etichetta leggibile del nodo nostro nel menu a tendina…
    expect(
      find.text('btcblake2b node (recommended)'),
      findsWidgets,
    );
    // …e il campo URI è già compilato: basta un tocco per collegarsi.
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, SwapDefaults.providerUri);
    expect(find.text('Default node reachable'), findsOneWidget);
  });

  testWidgets('provider collegato: limiti di invio dalla liquidità',
      (tester) async {
    final service = await buildService(
      defaultNodeAlive: true,
      withInvoice: null,
    );
    await pumpScreen(tester, service);

    await tester.tap(find.text('Connect provider'));
    await tester.pumpAndSettle();

    expect(
      find.text('Right now you can send between 4,750 and 23,750 sat'),
      findsOneWidget,
    );
    expect(find.text('Liquidity available now: 24,000 sat'), findsOneWidget);
    expect(find.text('Check recipient'), findsOneWidget);
  });

  testWidgets('destinatario non raggiungibile: verdetto mostrato in chiaro',
      (tester) async {
    const unreachable = SwapProviderInfo(
      minSats: 5000,
      maxSats: 250000,
      minSendableSats: 4750,
      maxSendableSats: 23750,
      availableSats: 24000,
      check: SwapPeerCheck(
        valid: true,
        reachable: false,
        amountSats: 5000,
        reason: 'PEER_UNREACHABLE',
        message: 'nessuna rotta trovata verso il destinatario.',
      ),
    );
    final service = await buildService(
      defaultNodeAlive: true,
      withInvoice: unreachable,
    );
    await pumpScreen(tester, service);

    await tester.tap(find.text('Connect provider'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'lnbc50u1p3xyz',
    );
    await tester.tap(find.text('Check recipient'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not reachable from the provider'),
      findsOneWidget,
    );
  });
}
