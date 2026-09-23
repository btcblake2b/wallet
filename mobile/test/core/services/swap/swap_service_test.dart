import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_provider_client.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_provider_store.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_script.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_service.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_swap_provider.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}
class MockBitcoinService extends Mock implements BitcoinService {}

/// Script HTLC coerente coi parametri delle risposte fake (la guardia di
/// `startSwap` confronta byte per byte: il vettore deve essere vero).
String scriptHexForQuote() => SwapScripts.witnessScript(
      SwapScriptParams(
        paymentHashHex: 'ab' * 32,
        claimPubkeyHex: '02${'11' * 32}',
        refundPubkeyHex: '02${'22' * 32}',
        cltvHeight: 972144,
      ),
    ).toHex();

SwapSession persistedSession({
  SwapClientState state = SwapClientState.awaitingFunding,
  String? fundingTxid,
  int? fundingVout,
}) =>
    SwapSession(
      swapId: 'aa' * 16,
      invoice: 'lnbc50u1ptest',
      paymentHashHex: 'ab' * 32,
      fundingAmountSats: 5250,
      cltvHeight: 972144,
      fundingDeadlineHeight: 971998,
      claimPubkeyHex: '02${'11' * 32}',
      refundPubkeyHex: '02${'22' * 32}',
      refundKeyIndex: 2,
      htlcAddress: 'bc1qexample',
      witnessScriptHex: scriptHexForQuote(),
      providerPubkey: 'cd' * 32,
      relays: const ['wss://relay.test'],
      state: state,
      createdAt: 1758100000,
      updatedAt: 1758100010,
      fundingTxid: fundingTxid,
      fundingVout: fundingVout,
    );

void main() {
  late FakeSwapProvider fake;
  late Map<String, String> data;
  late SwapSessionStore sessionStore;
  late SwapProviderStore providerStore;
  late SwapProviderClient client;
  late MockBitcoinService bitcoinService;
  late SwapService service;

  setUpAll(() {
    registerFallbackValue(<UtxoInfo>[]);
  });

  setUp(() {
    fake = FakeSwapProvider();
    data = <String, String>{};
    final storage = MockStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((inv) async => data[inv.namedArguments[#key] as String]);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      data[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((inv) async => data.remove(inv.namedArguments[#key]));
    bitcoinService = MockBitcoinService();
    client = SwapProviderClient(
      transport: fake,
      requestTimeout: const Duration(milliseconds: 300),
    );
    sessionStore = SwapSessionStore(storage: storage);
    providerStore = SwapProviderStore(storage: storage);
    service = SwapService(
      client: client,
      providerStore: providerStore,
      sessionStore: sessionStore,
      bitcoinService: bitcoinService,
    );
  });

  tearDown(() async {
    await client.dispose();
  });

  Future<void> connectProvider() => service.connect(
        'nostr+swap://${fake.providerPubHex}'
        '?v=1&network=blake2b&relay=wss%3A%2F%2Frelay.test',
      );

  group('refund', () {
    SwapSession refundableSession() => persistedSession(
          state: SwapClientState.paymentFailed,
          fundingTxid: 'aa' * 32,
          fundingVout: 0,
        );

    SwapService serviceWithTip(int tip) => SwapService(
          client: client,
          providerStore: providerStore,
          sessionStore: sessionStore,
          bitcoinService: bitcoinService,
          tipHeightProvider: () async => tip,
        );

    test('prima del CLTV: REFUND_TOO_EARLY e nessun broadcast', () async {
      // cltvHeight della sessione di test = 972144 → 972000 è troppo presto.
      service = serviceWithTip(972000);
      await expectLater(
        service.refund(
          session: refundableSession(),
          mnemonic: 'abandon abandon abandon',
          destinationAddress: 'bc1qexample',
          feeRateSatVb: 2,
        ),
        throwsA(
          isA<SwapException>()
              .having((e) => e.code, 'code', 'REFUND_TOO_EARLY'),
        ),
      );
      verifyNever(() => bitcoinService.broadcastTransaction(any()));
    });

    test('dal CLTV in poi: il refund viene firmato e trasmesso', () async {
      service = serviceWithTip(972200);
      when(
        () => bitcoinService.buildSignedRefundTx(
          mnemonic: any(named: 'mnemonic'),
          refundDerivationPath: any(named: 'refundDerivationPath'),
          paymentHashHex: any(named: 'paymentHashHex'),
          claimPubkeyHex: any(named: 'claimPubkeyHex'),
          refundPubkeyHex: any(named: 'refundPubkeyHex'),
          cltvHeight: any(named: 'cltvHeight'),
          witnessScriptHex: any(named: 'witnessScriptHex'),
          fundingTxid: any(named: 'fundingTxid'),
          fundingVout: any(named: 'fundingVout'),
          fundingAmountSats: any(named: 'fundingAmountSats'),
          destinationAddress: any(named: 'destinationAddress'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
        ),
      ).thenAnswer((_) async => 'deadbeef');
      when(() => bitcoinService.broadcastTransaction(any()))
          .thenAnswer((_) async => 'cd' * 32);

      final txid = await service.refund(
        session: refundableSession(),
        mnemonic: 'abandon abandon abandon',
        destinationAddress: 'bc1qexample',
        feeRateSatVb: 2,
      );
      expect(txid, 'cd' * 32);
    });
  });

  group('probeProvider', () {
    String uriFor() => 'nostr+swap://${fake.providerPubHex}'
        '?v=1&network=blake2b&relay=wss%3A%2F%2Frelay.test';

    test('provider vivo (SWAP_NOT_FOUND) → disponibile, sonda chiusa', () async {
      fake.responder = (method, params) => {
            'error': {'code': 'SWAP_NOT_FOUND', 'message': 'id sconosciuto'},
          };
      expect(await service.probeProvider(uriFor()), isTrue);
      expect(fake.receivedRequests.single['method'], 'swap_status');
      // PERCHÉ: la sonda non deve lasciare il collegamento aperto.
      expect(client.isConnected, isFalse);
    });

    test('provider muto (timeout) → non disponibile', () async {
      fake.silent = true;
      expect(await service.probeProvider(uriFor()), isFalse);
      expect(client.isConnected, isFalse);
    });

    test('relay irraggiungibile → non disponibile', () async {
      fake.failConnect = true;
      expect(await service.probeProvider(uriFor()), isFalse);
    });

    test('URI malformata → non disponibile (nessuna eccezione)', () async {
      expect(await service.probeProvider('non-una-uri'), isFalse);
    });
  });

  group('startSwap', () {
    test('quote → create → sessione persistita nel registro', () async {
      fake.responder = (method, params) {
        if (method == 'swap_quote') {
          return {'result': quoteResult(witnessScriptHex: scriptHexForQuote())};
        }
        if (method == 'swap_create') {
          return {'result': statusResult()};
        }
        return {'error': {'code': 'NOT_IMPLEMENTED', 'message': 'test'}};
      };
      await connectProvider();
      final session = await service.startSwap(
        invoice: 'lnbc50u1ptest',
        refundPubkeyHex: '02${'22' * 32}',
        refundKeyIndex: 2,
        walletId: 'wid-1',
        walletName: 'Test Wallet',
      );
      expect(session.swapId, 'aa' * 16);
      expect(session.walletId, 'wid-1');
      expect(session.walletName, 'Test Wallet');
      expect(session.fundingAmountSats, 5250);
      expect(session.cltvHeight, 972144);
      expect(session.refundKeyIndex, 2);
      expect(session.providerPubkey, fake.providerPubHex);
      expect(
        fake.receivedRequests.map((r) => r['method']),
        ['swap_quote', 'swap_create'],
      );
      final stored = await sessionStore.byId('aa' * 16);
      expect(stored, isNotNull);
      expect(stored!.state, SwapClientState.awaitingFunding);
    });

    test('QUOTE_MISMATCH: witnessScript incoerente coi parametri', () async {
      fake.responder = (method, params) => {
            'result': quoteResult(), // witness_script_hex: '00' (falso)
          };
      await connectProvider();
      await expectLater(
        service.startSwap(
          invoice: 'lnbc50u1ptest',
          refundPubkeyHex: '02${'22' * 32}',
          refundKeyIndex: 0,
        ),
        throwsA(
          isA<SwapException>().having((e) => e.code, 'code', 'QUOTE_MISMATCH'),
        ),
      );
    });

    test('NOT_CONNECTED: senza collegamento al provider', () async {
      await expectLater(
        service.startSwap(
          invoice: 'lnbc50u1ptest',
          refundPubkeyHex: '02${'22' * 32}',
          refundKeyIndex: 0,
        ),
        throwsA(
          isA<SwapException>().having((e) => e.code, 'code', 'NOT_CONNECTED'),
        ),
      );
    });
  });

  group('fund', () {
    late SwapSession session;

    setUp(() async {
      await connectProvider();
      session = persistedSession();
      await sessionStore.upsert(session);
    });

    test('tx on-chain verso l\'HTLC + annuncio + stato confirming', () async {
      when(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
          enableRBF: any(named: 'enableRBF'),
        ),
      ).thenAnswer((_) async => SendResult(txid: 'ff' * 32, feePaid: 300));
      fake.responder = (method, params) {
        if (method == 'swap_funding') {
          return {
            'result': statusResult(
              state: 'confirming',
              fundingTxid: params['funding_txid'] as String,
            ),
          };
        }
        return {'error': {'code': 'NOT_IMPLEMENTED', 'message': 'test'}};
      };

      final result = await service.fund(
        session: session,
        mnemonic: 'test mnemonic',
        accountDerivationPath: "m/84'/1'/0'",
        utxos: const [],
        feeRateSatVb: 2,
      );
      expect(result.txid, 'ff' * 32);
      // La tx va ESATTAMENTE all'HTLC per l'importo da lockare.
      verify(
        () => bitcoinService.buildSignAndSend(
          mnemonic: 'test mnemonic',
          toAddress: 'bc1qexample',
          amountSats: 5250,
          feeRateSatVb: 2,
          utxos: const [],
          derivationPath: "m/84'/1'/0'",
          enableRBF: true,
        ),
      ).called(1);
      final stored = (await sessionStore.byId(session.swapId))!;
      expect(stored.fundingTxid, 'ff' * 32);
      expect(stored.state, SwapClientState.confirming);
    });

    test('annuncio in errore: il txid viene salvato lo stesso', () async {
      when(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
          enableRBF: any(named: 'enableRBF'),
        ),
      ).thenAnswer((_) async => SendResult(txid: 'ee' * 32, feePaid: 300));
      fake.responder = (method, params) => {
            'error': {
              'code': 'FUNDING_TX_UNKNOWN',
              'message': 'tx sconosciuta alla chain',
            },
          };

      await service.fund(
        session: session,
        mnemonic: 'test mnemonic',
        accountDerivationPath: "m/84'/1'/0'",
        utxos: const [],
        feeRateSatVb: 2,
      );
      final stored = (await sessionStore.byId(session.swapId))!;
      expect(stored.fundingTxid, 'ee' * 32);
      // Lo stato resta awaitingFunding: `refresh` riproverà l'annuncio.
      expect(stored.state, SwapClientState.awaitingFunding);
    });
  });

  group('refresh', () {
    test('ri-annuncia il funding poi legge lo stato (completed)', () async {
      await connectProvider();
      final session = persistedSession(
        fundingTxid: 'ff' * 32,
      );
      await sessionStore.upsert(session);
      fake.responder = (method, params) {
        if (method == 'swap_funding') {
          return {'result': statusResult(state: 'confirming')};
        }
        if (method == 'swap_status') {
          return {
            'result': statusResult(
              state: 'completed',
              claimTxid: 'cd' * 32,
              fundingVout: 0,
            ),
          };
        }
        return {'error': {'code': 'NOT_IMPLEMENTED', 'message': 'test'}};
      };
      final updated = await service.refresh(session);
      expect(updated.state, SwapClientState.completed);
      expect(updated.claimTxid, 'cd' * 32);
      expect(updated.fundingVout, 0);
      expect(
        fake.receivedRequests.map((r) => r['method']),
        ['swap_funding', 'swap_status'],
      );
      expect(
        (await sessionStore.byId(session.swapId))!.state,
        SwapClientState.completed,
      );
    });

    test('sessione terminale: nessuna chiamata al provider', () async {
      await connectProvider();
      final session = persistedSession(state: SwapClientState.completed);
      final updated = await service.refresh(session);
      expect(updated.state, SwapClientState.completed);
      expect(fake.receivedRequests, isEmpty);
    });
  });

  group('refund', () {
    test('raw firmata + broadcast; richiede txid/vout del funding', () async {
      final session = persistedSession(
        state: SwapClientState.expired,
        fundingTxid: 'ff' * 32,
        fundingVout: 1,
      );
      when(
        () => bitcoinService.buildSignedRefundTx(
          mnemonic: any(named: 'mnemonic'),
          refundDerivationPath: any(named: 'refundDerivationPath'),
          paymentHashHex: any(named: 'paymentHashHex'),
          claimPubkeyHex: any(named: 'claimPubkeyHex'),
          refundPubkeyHex: any(named: 'refundPubkeyHex'),
          cltvHeight: any(named: 'cltvHeight'),
          witnessScriptHex: any(named: 'witnessScriptHex'),
          fundingTxid: any(named: 'fundingTxid'),
          fundingVout: any(named: 'fundingVout'),
          fundingAmountSats: any(named: 'fundingAmountSats'),
          destinationAddress: any(named: 'destinationAddress'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
        ),
      ).thenAnswer((_) async => 'deadbeef');
      when(() => bitcoinService.broadcastTransaction(any()))
          .thenAnswer((_) async => 'cc' * 32);

      final txid = await service.refund(
        session: session,
        mnemonic: 'test mnemonic',
        destinationAddress: 'bc1qdestination',
        feeRateSatVb: 2,
      );
      expect(txid, 'cc' * 32);
      // La chiave usata è QUELLA della sessione (indice 2 → path 2').
      verify(
        () => bitcoinService.buildSignedRefundTx(
          mnemonic: 'test mnemonic',
          refundDerivationPath: SwapService.refundPathFor(2),
          paymentHashHex: 'ab' * 32,
          claimPubkeyHex: '02${'11' * 32}',
          refundPubkeyHex: '02${'22' * 32}',
          cltvHeight: 972144,
          witnessScriptHex: scriptHexForQuote(),
          fundingTxid: 'ff' * 32,
          fundingVout: 1,
          fundingAmountSats: 5250,
          destinationAddress: 'bc1qdestination',
          feeRateSatVb: 2,
        ),
      ).called(1);
      verify(() => bitcoinService.broadcastTransaction('deadbeef')).called(1);
    });

    test('REFUND_NOT_READY: senza vout del funding', () async {
      final session = persistedSession(
        state: SwapClientState.expired,
        fundingTxid: 'ff' * 32,
      );
      await expectLater(
        service.refund(
          session: session,
          mnemonic: 'test mnemonic',
          destinationAddress: 'bc1qdestination',
          feeRateSatVb: 2,
        ),
        throwsA(
          isA<SwapException>().having((e) => e.code, 'code', 'REFUND_NOT_READY'),
        ),
      );
    });
  });

  group('recovery blob e utility', () {
    test('export → import: round-trip nel registro', () async {
      final session = persistedSession(state: SwapClientState.paymentFailed);
      final blob = service.exportRecoveryBlob(session);
      expect(blob.startsWith('swaprecover1.'), true);
      final imported = await service.importRecoveryBlob(blob);
      expect(imported.swapId, session.swapId);
      expect(imported.state, SwapClientState.paymentFailed);
      expect(await sessionStore.byId(session.swapId), isNotNull);
    });

    test('refundPathFor: account 2\' e chain 0, coin type dal wallet', () {
      final path = SwapService.refundPathFor(5);
      expect(path.startsWith('m/84\''), true);
      expect(path.contains("/2'/0/5"), true);
    });

    test('isLikelyInvoice: soft-check BOLT11 (anche con prefisso URI)', () {
      expect(SwapService.isLikelyInvoice('lnbc50u1ptest'), true);
      expect(SwapService.isLikelyInvoice('lightning:lnbc50u1ptest'), true);
      expect(SwapService.isLikelyInvoice('bc1qnotaninvoice'), false);
    });

    test('cancelSession: rimuove la sessione dal registro', () async {
      final session = persistedSession();
      await sessionStore.upsert(session);
      expect(await sessionStore.byId(session.swapId), isNotNull);
      await service.cancelSession(session.swapId);
      expect(await sessionStore.byId(session.swapId), isNull);
    });
  });
}
