import 'dart:io';

import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:nwc_cln_bridge/src/swap/swap_handlers.dart';
import 'package:nwc_cln_bridge/src/swap/swap_service.dart';
import 'package:nwc_cln_bridge/src/swap/swap_signer.dart';
import 'package:nwc_cln_bridge/src/swap/swap_store.dart';
import 'package:test/test.dart';

import 'swap_fixtures.dart';

/// Dispatch dei metodi swap: validazione parametri e idempotenza.
void main() {
  late FakeCln cln;
  late FakeChain chain;
  late SwapStore store;
  late SwapHandlers handlers;
  late Directory tmp;

  const client = SwapFixtures.clientPubkey;

  setUp(() {
    cln = FakeCln();
    // PERCHÉ (18/09/2026): quote/create passano dalla guardia di pagabilità.
    SwapFixtures.primeReady(cln);
    chain = FakeChain();
    tmp = Directory.systemTemp.createTempSync('swap_handl_');
    store = SwapStore('${tmp.path}/swap-store.json');
    final config = SwapConfig(
      relays: const ['wss://relay.test'],
      clnUrl: 'http://127.0.0.1:3001',
      providerKeyFile: '${tmp.path}/provider.key',
      storeFile: store.path,
      chain: const SwapChainConfig(esploraUrl: 'https://example.test/api'),
    );
    final service = SwapService(
      cln: cln,
      chain: chain,
      store: store,
      config: config,
      signer: SwapSigner('11' * 32),
      clock: () =>
          DateTime.fromMillisecondsSinceEpoch(SwapFixtures.nowSec * 1000),
    );
    handlers = SwapHandlers(service: service, store: store);
    cln.responses['decode'] = SwapFixtures.decodeResponse();
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> doQuote() => handlers.handle(
        method: 'swap_quote',
        params: {
          'invoice': SwapFixtures.bolt11,
          'refund_pubkey': SwapFixtures.refundPubkeyHex,
        },
        requestId: 'q-1',
        clientPubkey: client,
      );

  test('swap_quote: dispatch + validazione parametri', () async {
    final res = await doQuote();
    expect(res['quote_id'], isA<String>());
    expect(res['funding_amount_sats'], 5250);

    await expectLater(
      handlers.handle(
        method: 'swap_quote',
        params: const {},
        requestId: 'q-2',
        clientPubkey: client,
      ),
      throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
    );
    await expectLater(
      handlers.handle(
        method: 'swap_frobnicate',
        params: const {},
        requestId: 'q-3',
        clientPubkey: client,
      ),
      throwsA(isA<RpcError>().having((e) => e.code, 'code', 'NOT_IMPLEMENTED')),
    );
  });

  test('swap_create: idempotente per request_id (una sola sessione)', () async {
    final q = await doQuote();
    final quoteId = q['quote_id'] as String;

    final first = await handlers.handle(
      method: 'swap_create',
      params: {'quote_id': quoteId},
      requestId: 'req-1',
      clientPubkey: client,
    );
    final second = await handlers.handle(
      method: 'swap_create',
      params: {'quote_id': quoteId},
      requestId: 'req-1',
      clientPubkey: client,
    );
    expect(second['swap_id'], first['swap_id']);
    expect(store.all().length, 1);

    // Con un request_id DIVERSO la quote è consumata → errore esplicito
    // (mai una seconda sessione per lo stesso hash).
    await expectLater(
      handlers.handle(
        method: 'swap_create',
        params: {'quote_id': quoteId},
        requestId: 'req-2',
        clientPubkey: client,
      ),
      throwsA(isA<RpcError>().having((e) => e.code, 'code', 'QUOTE_EXPIRED')),
    );
  });

  test('swap_status: client diverso → UNAUTHORIZED', () async {
    final q = await doQuote();
    final created = await handlers.handle(
      method: 'swap_create',
      params: {'quote_id': q['quote_id'] as String},
      requestId: 'req-1',
      clientPubkey: client,
    );
    await expectLater(
      handlers.handle(
        method: 'swap_status',
        params: {'swap_id': created['swap_id'] as String},
        requestId: 'req-2',
        clientPubkey: 'dd' * 32,
      ),
      throwsA(isA<RpcError>().having((e) => e.code, 'code', 'UNAUTHORIZED')),
    );
  });
}
