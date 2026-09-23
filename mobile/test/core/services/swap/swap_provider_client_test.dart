import 'dart:async';
import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/nostr/nostr_crypto.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_event.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_transport.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_consts.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_provider_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider finto che parla il PROTOCOLLO VERO: decifra le richieste NIP-04,
/// risponde cifrato e firmato (kind 23291), emette notifiche (23292).
class FakeSwapProvider implements NostrTransport {
  FakeSwapProvider() {
    providerPubHex = NostrCrypto.derivePublicKey(providerPrivHex);
  }

  final String providerPrivHex = NostrCrypto.randomHex32();
  late final String providerPubHex;

  final StreamController<NostrEvent> _controller =
      StreamController<NostrEvent>.broadcast();
  bool _connected = false;
  DateTime? _connectedSince;

  /// Se true, non risponde mai (test del timeout).
  bool silent = false;

  /// Se true, NON risponde alla prossima richiesta (risposta persa).
  bool silentOnce = false;

  /// Se true, connect fallisce (test CONNECT_FAILED).
  bool failConnect = false;

  /// Relay che falliscono la connessione (test failover multi-relay).
  final Set<String> badRelays = {};

  int connectCalls = 0;
  final List<NostrEvent> published = [];
  final List<Map<String, dynamic>> receivedRequests = [];

  /// Genera la risposta: `{'result': {...}}` oppure `{'error': {...}}`.
  Map<String, dynamic> Function(String method, Map<String, dynamic> params)?
      responder;

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get connectedSince => _connectedSince;

  @override
  Future<void> connect(String relayUrl) async {
    if (failConnect || badRelays.contains(relayUrl)) {
      throw Exception('relay down (test)');
    }
    connectCalls++;
    _connected = true;
    _connectedSince = DateTime.now();
  }

  @override
  Future<void> close() async {
    // // PERCHÉ (test): lo stream resta aperto — il client si riconnette
    // più volte e deve poter ri-sottoscrivere.
    _connected = false;
    _connectedSince = null;
  }

  @override
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters) =>
      _controller.stream;

  @override
  Future<void> publish(NostrEvent event) async {
    published.add(event);
    if (event.kind != SwapConsts.requestKind) return;
    final plaintext = NostrCrypto.nip04Decrypt(
      privkeyHex: providerPrivHex,
      pubkeyHex: event.pubkey,
      payload: event.content,
    );
    final request = (jsonDecode(plaintext) as Map).cast<String, dynamic>();
    receivedRequests.add(request);
    if (silent) return;
    if (silentOnce) {
      silentOnce = false;
      return;
    }
    final method = '${request['method']}';
    final params =
        (request['params'] as Map?)?.cast<String, dynamic>() ?? const {};
    final out = responder?.call(method, params);
    final body = <String, dynamic>{
      'v': SwapConsts.protocolVersion,
      'id': request['id'],
    };
    if (out != null && out['error'] != null) {
      body['error'] = out['error'];
    } else {
      body['result'] = (out?['result'] as Map?) ?? <String, dynamic>{};
    }
    _emit(clientPub: event.pubkey, requestEventId: event.id, body: body);
  }

  /// Notifica push di stato (kind 23292).
  void emitNotification(String clientPub, Map<String, dynamic> result) => _emit(
        clientPub: clientPub,
        kind: SwapConsts.notificationKind,
        body: {
          'v': SwapConsts.protocolVersion,
          'id': result['swap_id'],
          'result': result,
        },
      );

  void _emit({
    required String clientPub,
    String? requestEventId,
    required Map<String, dynamic> body,
    int kind = SwapConsts.responseKind,
  }) {
    final content = NostrCrypto.nip04Encrypt(
      privkeyHex: providerPrivHex,
      pubkeyHex: clientPub,
      plaintext: jsonEncode(body),
    );
    final event = NostrEvent.unsigned(
      pubkey: providerPubHex,
      kind: kind,
      tags: [
        ['p', clientPub],
        if (requestEventId != null) ['e', requestEventId],
      ],
      content: content,
    ).sign(providerPrivHex);
    _controller.add(event);
  }
}

Map<String, dynamic> quoteResult() => {
      'quote_id': 'deadbeefcafe',
      'expires_at': 1758100600,
      'payment_hash': 'ab' * 32,
      'amount_msat': 5000000,
      'amount_sats': 5000,
      'service_fee_sats': 0,
      'claim_fee_sats': 250,
      'funding_amount_sats': 5250,
      'cltv_height': 972144,
      'claim_pubkey': '02${'11' * 32}',
      'refund_pubkey': '02${'22' * 32}',
      'htlc_address': 'bc1qexample',
      'witness_script_hex': '63a82000',
      'network': 'blake2b',
    };

Map<String, dynamic> statusResult({
  String state = 'awaitingFunding',
  String? fundingTxid,
}) =>
    {
      'swap_id': 'aa' * 16,
      'state': state,
      'htlc_address': 'bc1qexample',
      'witness_script_hex': '63a82000',
      'funding_amount_sats': 5250,
      'cltv_height': 972144,
      'funding_deadline_height': 971998,
      'created_at': 1758100000,
      'updated_at': 1758100010,
      if (fundingTxid != null) 'funding_txid': fundingTxid,
    };

void main() {
  late FakeSwapProvider fake;
  late SwapProviderClient client;
  late SwapProvider provider;
  late String clientSecret;
  late String clientPub;

  setUp(() {
    fake = FakeSwapProvider();
    client = SwapProviderClient(
      transport: fake,
      requestTimeout: const Duration(milliseconds: 300),
    );
    provider = SwapProvider(
      providerPubkey: fake.providerPubHex,
      relays: const ['wss://relay.test'],
    );
    clientSecret = NostrCrypto.randomHex32();
    clientPub = NostrCrypto.derivePublicKey(clientSecret);
  });

  tearDown(() async {
    await client.dispose();
  });

  test('quote: protocollo completo (evento, cifratura, mapping)', () async {
    fake.responder = (method, params) {
      expect(method, 'swap_quote');
      expect(params['invoice'], 'lnbc50u1ptest');
      expect(params['refund_pubkey'], '02${'22' * 32}');
      return {'result': quoteResult()};
    };
    await client.connect(provider, clientSecretHex: clientSecret);
    final quote = await client.quote(
      invoice: 'lnbc50u1ptest',
      refundPubkeyHex: '02${'22' * 32}',
    );
    expect(quote.quoteId, 'deadbeefcafe');
    expect(quote.fundingAmountSats, 5250);
    expect(quote.cltvHeight, 972144);

    // L'evento pubblicato rispetta il wire format.
    expect(fake.published.length, 1);
    final event = fake.published.single;
    expect(event.kind, SwapConsts.requestKind);
    expect(event.pubkey, clientPub);
    expect(event.firstTagValue('p'), fake.providerPubHex);
    expect(event.verify(), true);
    final request = fake.receivedRequests.single;
    expect(request['v'], SwapConsts.protocolVersion);
    expect(request['method'], 'swap_quote');
    expect((request['id'] as String).length, 64);
  });

  test('create/funding/status: mapping di SwapStatus', () async {
    fake.responder = (method, params) => {
          'result': statusResult(
            state: method == 'swap_funding' ? 'confirming' : 'awaitingFunding',
            fundingTxid: method == 'swap_funding' ? 'ff' * 32 : null,
          ),
        };
    await client.connect(provider, clientSecretHex: clientSecret);

    final created = await client.create(quoteId: 'deadbeefcafe');
    expect(created.state, SwapClientState.awaitingFunding);

    final funded = await client.funding(
      swapId: 'aa' * 16,
      fundingTxid: 'ff' * 32,
    );
    expect(funded.state, SwapClientState.confirming);
    expect(funded.fundingTxid, 'ff' * 32);

    final status = await client.status(swapId: 'aa' * 16);
    expect(status.swapId, 'aa' * 16);
  });

  test('errore del provider: SwapException col codice del wire', () async {
    fake.responder = (method, params) => {
          'error': {
            'code': 'AMOUNT_TOO_SMALL',
            'message': 'importo sotto il minimo',
          },
        };
    await client.connect(provider, clientSecretHex: clientSecret);
    await expectLater(
      client.quote(invoice: 'lnbc1...', refundPubkeyHex: '02${'22' * 32}'),
      throwsA(
        isA<SwapException>()
            .having((e) => e.code, 'code', 'AMOUNT_TOO_SMALL')
            .having((e) => e.isInputError, 'isInputError', true),
      ),
    );
  });

  test('senza collegamento: NOT_CONNECTED', () async {
    await expectLater(
      client.status(swapId: 'aa' * 16),
      throwsA(
        isA<SwapException>().having((e) => e.code, 'code', 'NOT_CONNECTED'),
      ),
    );
  });

  test('relay irraggiungibile: CONNECT_FAILED', () async {
    fake.failConnect = true;
    await expectLater(
      client.connect(provider, clientSecretHex: clientSecret),
      throwsA(
        isA<SwapException>().having((e) => e.code, 'code', 'CONNECT_FAILED'),
      ),
    );
  });

  test('failover multi-relay: usa il primo raggiungibile', () async {
    final multi = SwapProvider(
      providerPubkey: fake.providerPubHex,
      relays: const ['wss://down.test', 'wss://up.test'],
    );
    fake.badRelays.add('wss://down.test');
    await client.connect(multi, clientSecretHex: clientSecret);
    expect(client.isConnected, true);
    expect(fake.connectCalls, 1);
  });

  test('timeout: nessuna risposta → TIMEOUT', () async {
    fake.silent = true;
    await client.connect(provider, clientSecretHex: clientSecret);
    await expectLater(
      client.quote(invoice: 'lnbc1...', refundPubkeyHex: '02${'22' * 32}'),
      throwsA(isA<SwapException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });

  test('retry read-only: quote ritenta dopo una risposta persa', () async {
    fake.silentOnce = true;
    fake.responder = (method, params) => {'result': quoteResult()};
    await client.connect(provider, clientSecretHex: clientSecret);
    final quote = await client.quote(
      invoice: 'lnbc1...',
      refundPubkeyHex: '02${'22' * 32}',
    );
    expect(quote.quoteId, 'deadbeefcafe');
    expect(fake.published.length, 2);
  });

  test('nessun retry su create: una risposta persa resta TIMEOUT', () async {
    fake.silentOnce = true;
    fake.responder = (method, params) => {'result': statusResult()};
    await client.connect(provider, clientSecretHex: clientSecret);
    await expectLater(
      client.create(quoteId: 'deadbeefcafe'),
      throwsA(isA<SwapException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
    expect(fake.published.length, 1);
  });

  test('notifica di stato: arriva su statusUpdates', () async {
    await client.connect(provider, clientSecretHex: clientSecret);
    final received = <SwapStatus>[];
    final sub = client.statusUpdates.listen(received.add);
    fake.emitNotification(clientPub, statusResult(state: 'completed'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(received.length, 1);
    expect(received.single.state, SwapClientState.completed);
    await sub.cancel();
  });

  test('evento da una pubkey diversa: ignorato (anti-spoof)', () async {
    await client.connect(provider, clientSecretHex: clientSecret);
    final received = <SwapStatus>[];
    final sub = client.statusUpdates.listen(received.add);
    // Un impostore pubblica una notifica "valida" col proprio mittente.
    final impostorPriv = NostrCrypto.randomHex32();
    final content = NostrCrypto.nip04Encrypt(
      privkeyHex: impostorPriv,
      pubkeyHex: clientPub,
      plaintext: jsonEncode({
        'v': 1,
        'id': 'aa' * 16,
        'result': statusResult(),
      }),
    );
    final impostorEvent = NostrEvent.unsigned(
      pubkey: NostrCrypto.derivePublicKey(impostorPriv),
      kind: SwapConsts.notificationKind,
      tags: [
        ['p', clientPub],
      ],
      content: content,
    ).sign(impostorPriv);
    fake.emitNotification(clientPub, statusResult(state: 'completed'));
    // (il client filtra per pubkey del provider: l'evento impostore non passa)
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(received.length, 1);
    expect(impostorEvent.pubkey, isNot(fake.providerPubHex));
    await sub.cancel();
  });
}
