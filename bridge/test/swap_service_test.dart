import 'dart:io';

import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:nwc_cln_bridge/src/swap/chain_api.dart';
import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:nwc_cln_bridge/src/swap/swap_models.dart';
import 'package:nwc_cln_bridge/src/swap/swap_script.dart';
import 'package:nwc_cln_bridge/src/swap/swap_service.dart';
import 'package:nwc_cln_bridge/src/swap/swap_signer.dart';
import 'package:nwc_cln_bridge/src/swap/swap_store.dart';
import 'package:test/test.dart';

import 'swap_fixtures.dart';

/// Servizio swap (provider): quote, guardie, macchina a stati, recovery.
void main() {
  late FakeCln cln;
  late FakeChain chain;
  late SwapStore store;
  late SwapService service;
  late DateTime now;
  late Directory tmp;

  const client = SwapFixtures.clientPubkey;

  setUp(() {
    cln = FakeCln();
    // PERCHÉ (18/09/2026): quote/create verificano che il nodo possa pagare —
    // i test che arrivano al lock devono simulare un provider pronto.
    SwapFixtures.primeReady(cln);
    chain = FakeChain();
    tmp = Directory.systemTemp.createTempSync('swap_svc_');
    store = SwapStore('${tmp.path}/swap-store.json');
    now = DateTime.fromMillisecondsSinceEpoch(SwapFixtures.nowSec * 1000);
    final config = SwapConfig(
      relays: const ['wss://relay.test'],
      clnUrl: 'http://127.0.0.1:3001',
      providerKeyFile: '${tmp.path}/provider.key',
      storeFile: store.path,
      chain: const SwapChainConfig(esploraUrl: 'https://example.test/api'),
    );
    service = SwapService(
      cln: cln,
      chain: chain,
      store: store,
      config: config,
      signer: SwapSigner('11' * 32),
      clock: () => now,
    );
    cln.responses['decode'] = SwapFixtures.decodeResponse();
    cln.responses['pay'] = {
      'payment_preimage': SwapFixtures.preimageHex,
      'status': 'complete',
    };
    cln.responses['newaddr'] = {'bech32': SwapFixtures.destinationAddress};
    cln.responses['listpays'] = {'pays': <Object>[]};
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> doQuote() => service.quote(
        bolt11: SwapFixtures.bolt11,
        clientPubkey: client,
        refundPubkeyHex: SwapFixtures.refundPubkeyHex,
      );

  /// Quote → create → funding confermato (in stato `confirming`).
  Future<(String swapId, String fundingTxid)> startFunded() async {
    final quote = await doQuote();
    final created = await service.create(
      quoteId: quote['quote_id'] as String,
      clientPubkey: client,
    );
    final swapId = created['swap_id'] as String;
    final fundingTxid = 'aa' * 32;
    chain.statuses[fundingTxid] = ChainTxStatus(
      txid: fundingTxid,
      confirmed: true,
      blockHeight: 972000,
    );
    chain.rawTxs[fundingTxid] = SwapFixtures.fundingTxHex(
      quote['witness_script_hex'] as String,
      quote['funding_amount_sats'] as int,
    );
    await service.registerFunding(
      swapId: swapId,
      clientPubkey: client,
      fundingTxid: fundingTxid,
    );
    return (swapId, fundingTxid);
  }

  group('quote', () {
    test('campi coerenti col piano e script ricostruibile dai parametri',
        () async {
      final q = await doQuote();
      expect(q['payment_hash'], SwapFixtures.paymentHashHex);
      expect(q['amount_msat'], 5000000);
      expect(q['amount_sats'], 5000);
      expect(q['service_fee_sats'], 0);
      expect(q['claim_fee_sats'], 250);
      expect(q['funding_amount_sats'], 5250);
      expect(q['cltv_height'], 972000 + 144);
      expect((q['htlc_address'] as String).startsWith('bc1q'), isTrue);
      // La verifica dell'app (anti-manomissione) deve passare: lo script
      // dichiarato è ricostruibile ESATTAMENTE dai parametri.
      final rebuilt = SwapScripts.witnessScript(
        SwapScriptParams(
          paymentHashHex: q['payment_hash'] as String,
          claimPubkeyHex: q['claim_pubkey'] as String,
          refundPubkeyHex: q['refund_pubkey'] as String,
          cltvHeight: q['cltv_height'] as int,
        ),
      ).toHex();
      expect(rebuilt, q['witness_script_hex']);
    });

    test('amount_msat in forma stringa ("5000000msat") accettato', () async {
      cln.responses['decode'] = SwapFixtures.decodeResponse(
        amountMsat: '5000000msat',
      );
      final q = await doQuote();
      expect(q['amount_msat'], 5000000);
    });

    test('guardie: minimo/massimo, scaduta, amountless, duplicato', () async {
      Future<void> expectCode(String code, Map<String, dynamic> decode) async {
        cln.responses['decode'] = decode;
        await expectLater(
          doQuote(),
          throwsA(isA<RpcError>().having((e) => e.code, 'code', code)),
        );
      }

      await expectCode(
        'AMOUNT_TOO_SMALL',
        SwapFixtures.decodeResponse(amountMsat: 1000000),
      );
      await expectCode(
        'AMOUNT_TOO_LARGE',
        SwapFixtures.decodeResponse(amountMsat: 300000000),
      );
      await expectCode(
        'INVOICE_EXPIRED',
        SwapFixtures.decodeResponse(createdAt: SwapFixtures.nowSec - 7200),
      );
      await expectCode(
        'INVOICE_INVALID',
        SwapFixtures.decodeResponse(amountMsat: null),
      );
      await expectCode(
        'INVOICE_INVALID',
        SwapFixtures.decodeResponse(amountMsat: '0msat'),
      );

      // Duplicato: sessione esistente con lo stesso payment_hash.
      cln.responses['decode'] = SwapFixtures.decodeResponse();
      await store.upsert(
        SwapFixtures.session(
          id: 'dup',
          paymentHashHex: SwapFixtures.paymentHashHex,
        ),
      );
      await expectLater(
        doQuote(),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'DUPLICATE_SWAP'),
        ),
      );
    });
  });

  group('create / registerFunding', () {
    test('quote sconosciuta o scaduta → QUOTE_EXPIRED', () async {
      await expectLater(
        service.create(quoteId: 'nope', clientPubkey: client),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'QUOTE_EXPIRED')),
      );
      final q = await doQuote();
      now = now.add(const Duration(seconds: 601)); // oltre TTL 600s
      await expectLater(
        service.create(quoteId: q['quote_id'] as String, clientPubkey: client),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'QUOTE_EXPIRED')),
      );
    });

    test(
        'funding sconosciuto → FUNDING_TX_UNKNOWN; client diverso → UNAUTHORIZED',
        () async {
      final q = await doQuote();
      final created = await service.create(
        quoteId: q['quote_id'] as String,
        clientPubkey: client,
      );
      final swapId = created['swap_id'] as String;
      await expectLater(
        service.registerFunding(
          swapId: swapId,
          clientPubkey: client,
          fundingTxid: 'bb' * 32,
        ),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'FUNDING_TX_UNKNOWN'),
        ),
      );
      await expectLater(
        service.registerFunding(
          swapId: swapId,
          clientPubkey: 'dd' * 32,
          fundingTxid: 'bb' * 32,
        ),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
      );
      await expectLater(
        service.status(swapId: swapId, clientPubkey: 'dd' * 32),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
      );
    });
  });

  group('macchina a stati', () {
    test('ciclo felice: confirming → pay → claim → completed (persistito)',
        () async {
      final (swapId, fundingTxid) = await startFunded();
      expect(store.byId(swapId)!.state, SwapState.confirming);
      expect(store.byId(swapId)!.fundingTxid, fundingTxid);

      await service.tick();
      final s = store.byId(swapId)!;
      expect(s.state, SwapState.claiming);
      expect(s.preimageHex, SwapFixtures.preimageHex);
      expect(s.fundingVout, 0);
      expect(chain.broadcasts.length, 1);
      final claimTxid = s.claimTxid!;

      chain.statuses[claimTxid] = ChainTxStatus(
        txid: claimTxid,
        confirmed: true,
        blockHeight: 972050,
      );
      await service.tick();
      expect(store.byId(swapId)!.state, SwapState.completed);

      // Lo stato resta coerente dopo un reload dello store.
      final reloaded = SwapStore(store.path);
      await reloaded.load();
      expect(reloaded.byId(swapId)!.state, SwapState.completed);
    });

    test('expiry: funding non visto entro la deadline', () async {
      final q = await doQuote();
      final created = await service.create(
        quoteId: q['quote_id'] as String,
        clientPubkey: client,
      );
      final swapId = created['swap_id'] as String;

      await service.tick(); // niente da fare: resta in attesa
      expect(store.byId(swapId)!.state, SwapState.awaitingFunding);

      chain.tip = 972137; // oltre la funding deadline (972136)
      await service.tick();
      final s = store.byId(swapId)!;
      expect(s.state, SwapState.expired);
      expect(s.errorCode, 'FUNDING_TIMEOUT');
    });

    test('pay fallito (retry) → paymentFailed → refund osservato → refunded',
        () async {
      final (swapId, fundingTxid) = await startFunded();
      cln.failingMethods.add('pay');

      await service.tick(); // tentativo 1 → resta paying
      expect(store.byId(swapId)!.state, SwapState.paying);
      expect(store.byId(swapId)!.payAttempts, 1);

      await service.tick(); // tentativo 2 (payRetryMax) → paymentFailed
      final failed = store.byId(swapId)!;
      expect(failed.state, SwapState.paymentFailed);
      expect(failed.errorCode, 'PAYMENT_FAILED');

      // L'utente refunda: spesa dell'output HTLC da una tx diversa dal claim.
      chain.outspendMap[fundingTxid] = [
        ChainOutspend(vout: 0, spent: true, spendingTxid: 'ee' * 32),
      ];
      await service.tick();
      expect(store.byId(swapId)!.state, SwapState.refunded);
    });

    test('preimage incoerente → paymentFailed e NESSUN claim', () async {
      final (swapId, _) = await startFunded();
      cln.responses['pay'] = {'payment_preimage': 'ff' * 32};
      await service.tick();
      final s = store.byId(swapId)!;
      expect(s.state, SwapState.paymentFailed);
      expect(s.errorCode, 'PREIMAGE_MISMATCH');
      expect(chain.broadcasts, isEmpty);
    });

    test('recovery: pay fallisce ma listpays ha la preimage → claim emesso',
        () async {
      final (swapId, _) = await startFunded();
      cln.failingMethods.add('pay');
      cln.responses['listpays'] = {
        'pays': [
          {'status': 'complete', 'preimage': SwapFixtures.preimageHex},
        ],
      };
      await service.tick();
      final s = store.byId(swapId)!;
      expect(s.preimageHex, SwapFixtures.preimageHex);
      expect(s.state, SwapState.claiming);
      expect(chain.broadcasts.length, 1);
    });

    test('tick resiliente: chain giù → nessuna eccezione, stato invariato',
        () async {
      final (swapId, _) = await startFunded();
      chain.failing = true;
      await service.tick();
      expect(store.byId(swapId)!.state, SwapState.confirming);
    });

    test('status: funding_confirmations calcolato quando il funding è noto',
        () async {
      final (swapId, _) = await startFunded();
      await service.tick(); // passa a claiming (fundingHeight valorizzato)
      final st = await service.status(swapId: swapId, clientPubkey: client);
      expect(st['state'], 'claiming');
      expect(st['funding_confirmations'], 1);
    });
  });

  group('pre-flight pagabilità (incidente 18/09/2026)', () {
    test('quote rifiutata senza canali con liquidità in uscita', () async {
      cln.responses['listpeerchannels'] = {
        'channels': [
          {'state': 'CHANNELD_NORMAL', 'spendable_msat': 0},
          {'state': 'ONCHAIN', 'spendable_msat': 0},
        ],
      };
      await expectLater(
        doQuote(),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'PROVIDER_UNAVAILABLE'),
        ),
      );
      expect(store.all(), isEmpty);
    });

    test('quote rifiutata se getroutes non trova rotta', () async {
      cln.failingMethods.add('getroutes');
      await expectLater(
        doQuote(),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'PROVIDER_UNAVAILABLE'),
        ),
      );
      expect(store.all(), isEmpty);
    });

    test('quote rifiutata se getroutes risponde senza percorsi', () async {
      cln.responses['getroutes'] = {'routes': <Object>[]};
      await expectLater(
        doQuote(),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'PROVIDER_UNAVAILABLE'),
        ),
      );
    });

    test('quote rifiutata se la invoice è senza payee valido', () async {
      cln.responses['decode'] = {
        ...SwapFixtures.decodeResponse(),
        'payee': 'nope',
      };
      await expectLater(
        doQuote(),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'INVOICE_INVALID'),
        ),
      );
    });

    test('create rifiutata se il nodo peggiora dopo la quote', () async {
      final q = await doQuote();
      cln.responses['listpeerchannels'] = {'channels': <Object>[]};
      await expectLater(
        service.create(quoteId: q['quote_id'] as String, clientPubkey: client),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'PROVIDER_UNAVAILABLE'),
        ),
      );
      expect(store.all(), isEmpty);
    });

    test('quote accettata con canale pronto e rotta valida', () async {
      final q = await doQuote();
      expect(q['htlc_address'], isNotEmpty);
      expect(cln.calls, contains('listpeerchannels'));
      expect(cln.calls, contains('getroutes'));
    });
  });
}
