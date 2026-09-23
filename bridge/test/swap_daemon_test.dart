import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nwc_cln_bridge/src/logger.dart';
import 'package:nwc_cln_bridge/src/nostr/nostr_crypto.dart';
import 'package:nwc_cln_bridge/src/nostr/nostr_event.dart';
import 'package:nwc_cln_bridge/src/nostr/nostr_transport.dart';
import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:nwc_cln_bridge/src/swap/swap_consts.dart';
import 'package:nwc_cln_bridge/src/swap/swap_daemon.dart';
import 'package:nwc_cln_bridge/src/swap/swap_handlers.dart';
import 'package:nwc_cln_bridge/src/swap/swap_models.dart';
import 'package:nwc_cln_bridge/src/swap/swap_service.dart';
import 'package:nwc_cln_bridge/src/swap/swap_signer.dart';
import 'package:nwc_cln_bridge/src/swap/swap_store.dart';
import 'package:test/test.dart';

import 'swap_fixtures.dart';

/// Transport fake del daemon: eventi iniettati dai test, pubblicazioni
/// catturate; nessuna rete.
class FakeDaemonTransport implements NostrTransport {
  final StreamController<NostrEvent> _events =
      StreamController<NostrEvent>.broadcast();
  final List<NostrEvent> published = [];
  final List<Map<String, dynamic>> subscriptions = [];
  bool _connected = false;
  DateTime? _since;
  int connectCalls = 0;

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get connectedSince => _since;

  @override
  Future<void> connect(String relayUrl) async {
    connectCalls++;
    _connected = true;
    _since = DateTime.now();
  }

  @override
  Future<void> close() async {
    _connected = false;
    _since = null;
  }

  @override
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters) {
    subscriptions.add(filters.first);
    return _events.stream;
  }

  @override
  Future<void> publish(NostrEvent event) async => published.add(event);

  void emit(NostrEvent event) => _events.add(event);
}

/// Daemon swap: protocollo 23290-23292, notifiche sui cambi di stato.
void main() {
  late Directory tmp;
  late FakeCln cln;
  late FakeChain chain;
  late SwapStore store;
  late FakeDaemonTransport transport;
  late SwapDaemon daemon;

  final providerPriv = NostrCrypto.randomHex32();
  late final String providerPub = NostrCrypto.derivePublicKey(providerPriv);
  final clientPriv = NostrCrypto.randomHex32();
  late final String clientPub = NostrCrypto.derivePublicKey(clientPriv);

  SwapConfig buildConfig({List<String> allowed = const []}) => SwapConfig(
        relays: const ['wss://relay.test'],
        clnUrl: 'http://127.0.0.1:3001',
        providerKeyFile: 'unused.key',
        storeFile: '${tmp.path}${Platform.pathSeparator}swap-store.json',
        chain: const SwapChainConfig(esploraUrl: 'https://esplora.test'),
        allowedClientPubkeys: allowed,
      );

  SwapDaemon buildDaemon(SwapConfig config, SwapStore swapStore) {
    final service = SwapService(
      cln: cln,
      chain: chain,
      store: swapStore,
      config: config,
      signer: SwapSigner(providerPriv),
      logger: Logger(minLevel: LogLevel.error),
      // PERCHÉ: clock allineato alle fixture (invoice creata a nowSec): col
      // clock reale l'invoice di test risulterebbe scaduta.
      clock: () => DateTime.fromMillisecondsSinceEpoch(
        SwapFixtures.nowSec * 1000,
      ),
    );
    final handlers = SwapHandlers(
      service: service,
      store: swapStore,
      logger: Logger(minLevel: LogLevel.error),
    );
    return SwapDaemon(
      transport: transport,
      service: service,
      handlers: handlers,
      store: swapStore,
      config: config,
      providerKeyHex: providerPriv,
      logger: Logger(minLevel: LogLevel.error),
    );
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('swapd-test');
    cln = FakeCln();
    // PERCHÉ (18/09/2026): quote/create passano dalla guardia di pagabilità.
    SwapFixtures.primeReady(cln);
    chain = FakeChain();
    store = SwapStore('${tmp.path}${Platform.pathSeparator}swap-store.json');
    transport = FakeDaemonTransport();
    daemon = buildDaemon(buildConfig(), store);
    await daemon.start();
  });

  tearDown(() async {
    await daemon.stop();
    await tmp.delete(recursive: true);
  });

  NostrEvent requestEvent({
    required String method,
    Map<String, dynamic> params = const {},
    String requestId = 'req-1',
    bool signed = true,
  }) {
    final content = NostrCrypto.nip04Encrypt(
      privkeyHex: clientPriv,
      pubkeyHex: providerPub,
      plaintext: jsonEncode({
        'v': SwapConsts.protocolVersion,
        'id': requestId,
        'method': method,
        'params': params,
      }),
    );
    final event = NostrEvent.unsigned(
      pubkey: clientPub,
      kind: SwapConsts.requestKind,
      tags: [
        ['p', providerPub],
      ],
      content: content,
    );
    return signed ? event.sign(clientPriv) : event;
  }

  Map<String, dynamic> decryptBody(NostrEvent event) {
    // Il CLIENT decifra con la propria privkey + pubkey del provider.
    final plain = NostrCrypto.nip04Decrypt(
      privkeyHex: clientPriv,
      pubkeyHex: providerPub,
      payload: event.content,
    );
    return (jsonDecode(plain) as Map).cast<String, dynamic>();
  }

  Future<void> waitFor(bool Function() condition) async {
    for (var i = 0; i < 100 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue, reason: 'condizione non raggiunta (timeout)');
  }

  SwapSession buildSession({SwapState state = SwapState.awaitingFunding}) =>
      SwapSession(
        id: 'sid-1',
        clientPubkey: clientPub,
        invoice: 'lnbc1test',
        paymentHashHex: 'ff' * 32,
        amountMsat: 5000000,
        fundingAmountSats: 5250,
        serviceFeeSats: 0,
        claimFeeSats: 250,
        cltvHeight: 972144,
        claimPubkeyHex: '02${'11' * 32}',
        refundPubkeyHex: '02${'22' * 32}',
        htlcAddress: 'bc1qhtlc',
        witnessScriptHex: '63a820ff',
        fundingDeadlineHeight: 972500,
        state: state,
        createdAt: 1758100000,
        updatedAt: 1758100000,
      );

  test('avvio: connesso, sottoscritto al kind di richiesta per la nostra pubkey',
      () async {
    expect(transport.connectCalls, 1);
    expect(daemon.activeRelay, 'wss://relay.test');
    expect(transport.subscriptions.single['kinds'], [SwapConsts.requestKind]);
    expect(transport.subscriptions.single['#p'], [providerPub]);
  });

  test('swap_quote end-to-end: risposta cifrata, correlata, con la quote',
      () async {
    cln.responses['decode'] = SwapFixtures.decodeResponse();
    final request = requestEvent(
      method: 'swap_quote',
      params: {
        'invoice': SwapFixtures.bolt11,
        'refund_pubkey': SwapFixtures.refundPubkeyHex,
      },
    );
    transport.emit(request);
    await waitFor(() => transport.published.isNotEmpty);

    final reply = transport.published.single;
    expect(reply.kind, SwapConsts.responseKind);
    expect(reply.pubkey, providerPub);
    expect(reply.verify(), isTrue);
    expect(reply.firstTagValue('e'), request.id);
    expect(reply.firstTagValue('p'), clientPub);

    final body = decryptBody(reply);
    expect(body['id'], 'req-1');
    expect(body['v'], SwapConsts.protocolVersion);
    final result = (body['result'] as Map).cast<String, dynamic>();
    expect('${result['quote_id']}'.isNotEmpty, isTrue);
    expect(result['payment_hash'], SwapFixtures.paymentHashHex);
    expect(result['htlc_address'], startsWith('bc1q'));
  });

  test('metodo non supportato: errore NOT_IMPLEMENTED nella risposta',
      () async {
    transport.emit(requestEvent(method: 'swap_boh'));
    await waitFor(() => transport.published.isNotEmpty);
    final body = decryptBody(transport.published.single);
    final error = (body['error'] as Map).cast<String, dynamic>();
    expect(error['code'], 'NOT_IMPLEMENTED');
  });

  test('firma non valida: nessuna risposta', () async {
    transport.emit(requestEvent(method: 'swap_quote', signed: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(transport.published, isEmpty);
  });

  test('dedup: lo stesso evento due volte → una sola risposta', () async {
    cln.responses['decode'] = SwapFixtures.decodeResponse();
    final request = requestEvent(
      method: 'swap_quote',
      params: {
        'invoice': SwapFixtures.bolt11,
        'refund_pubkey': SwapFixtures.refundPubkeyHex,
      },
    );
    transport.emit(request);
    transport.emit(request);
    await waitFor(() => transport.published.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(transport.published.length, 1);
  });

  test('tick: notifica kind 23292 SOLO sul cambio di stato', () async {
    await store.upsert(buildSession());
    // Primo giro: baseline, nessuna notifica.
    await daemon.tick();
    expect(transport.published, isEmpty);

    // Cambio di stato osservato (es. il claim è andato a buon fine).
    await store.upsert(buildSession(state: SwapState.completed));
    await daemon.tick();

    expect(transport.published.length, 1);
    final notification = transport.published.single;
    expect(notification.kind, SwapConsts.notificationKind);
    expect(notification.firstTagValue('p'), clientPub);
    final body = decryptBody(notification);
    expect(body['id'], 'sid-1');
    final result = (body['result'] as Map).cast<String, dynamic>();
    expect(result['swap_id'], 'sid-1');
    expect(result['state'], 'completed');

    // Terzo giro senza cambi: nessuna nuova notifica.
    await daemon.tick();
    expect(transport.published.length, 1);
  });

  test('allowlist: client non autorizzato ignorato', () async {
    // Daemon separato con allowlist che NON include il client di test.
    final isolatedTransport = FakeDaemonTransport();
    final isolatedDaemon = SwapDaemon(
      transport: isolatedTransport,
      service: SwapService(
        cln: cln,
        chain: chain,
        store: store,
        config: buildConfig(allowed: ['ab' * 32]),
        signer: SwapSigner(providerPriv),
        logger: Logger(minLevel: LogLevel.error),
      ),
      handlers: SwapHandlers(
        service: SwapService(
          cln: cln,
          chain: chain,
          store: store,
          config: buildConfig(allowed: ['ab' * 32]),
          signer: SwapSigner(providerPriv),
          logger: Logger(minLevel: LogLevel.error),
        ),
        store: store,
        logger: Logger(minLevel: LogLevel.error),
      ),
      store: store,
      config: buildConfig(allowed: ['ab' * 32]),
      providerKeyHex: providerPriv,
      logger: Logger(minLevel: LogLevel.error),
    );
    await isolatedDaemon.start();
    isolatedTransport.emit(
      requestEvent(
        method: 'swap_quote',
        params: {
          'invoice': SwapFixtures.bolt11,
          'refund_pubkey': SwapFixtures.refundPubkeyHex,
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(isolatedTransport.published, isEmpty);
    await isolatedDaemon.stop();
  });
}
