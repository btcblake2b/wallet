import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nwc_cln_bridge/src/cln/cln_api.dart';
import 'package:nwc_cln_bridge/src/cross/kilobridge_client.dart';
import 'package:nwc_cln_bridge/src/handlers.dart';
import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:test/test.dart';

/// Fattura BOLT11 sintetica con un payment hash noto.
///
/// // PERCHÉ: il PoW del bridge lega la challenge al payment hash, che va
/// // estratto dalla fattura: serve una fattura con struttura reale (timestamp,
/// // campo `p`, firma) ma generata a mano, senza dipendenze di firma.
String bolt11WithHash(String hashHex) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  final bytes = [
    for (var i = 0; i < hashHex.length; i += 2)
      int.parse(hashHex.substring(i, i + 2), radix: 16),
  ];
  // 32 byte → 52 word da 5 bit (padding a destra: 260 bit).
  final bits = <int>[];
  for (final b in bytes) {
    for (var i = 7; i >= 0; i--) {
      bits.add((b >> i) & 1);
    }
  }
  while (bits.length % 5 != 0) {
    bits.add(0);
  }
  final words = <int>[];
  for (var i = 0; i + 5 <= bits.length; i += 5) {
    var v = 0;
    for (var j = 0; j < 5; j++) {
      v = (v << 1) | bits[i + j];
    }
    words.add(v);
  }
  String enc(int w) => charset[w];
  final timestamp = '0' * 7;
  final len = words.length; // 52 word
  final lenPrefix = '${enc(len >> 5)}${enc(len & 0x1f)}';
  final signature = 'q' * 104;
  return 'lnbc50u1$timestamp${enc(1)}$lenPrefix'
      '${words.map(enc).join()}$signature';
}

class FakeCln implements ClnApi {
  FakeCln(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<String> calls = [];
  final List<Map<String, dynamic>> callParams = [];

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add(method);
    callParams.add(params);
    final r = responses[method];
    if (r == null) throw RpcError('OTHER', 'comando non simulato: $method');
    return r;
  }
}

void main() {
  const hash = 'aa11bb22cc33dd44ee55ff6677889900'
      'aabbccddeeff00112233445566778899';

  group('proof of work', () {
    test('leadingZeroBits conta i bit iniziali a zero', () {
      expect(KilobridgeClient.leadingZeroBits([0x00, 0x00, 0xff]), 16);
      expect(KilobridgeClient.leadingZeroBits([0x80]), 0);
      expect(KilobridgeClient.leadingZeroBits([0x01]), 7);
    });

    test('requiredBits legge i bit dalla challenge', () {
      expect(KilobridgeClient.requiredBits('1.1700000000.18.abcdef'), 18);
      expect(KilobridgeClient.requiredBits('garbage'), 18);
    });

    test('solvePow trova un nonce che soddisfa i bit richiesti', () {
      const challenge = '1.1700000000.8.mac';
      final nonce = KilobridgeClient.solvePow(
        challenge: challenge,
        hash: hash,
      );
      expect(nonce, isNotNull);
      final digest = sha256.convert(utf8.encode('$challenge:$hash:$nonce'));
      expect(
        KilobridgeClient.leadingZeroBits(digest.bytes),
        greaterThanOrEqualTo(8),
      );
    });
  });

  group('payment hash dalla fattura', () {
    test('estratto dal campo p (posizione non fissa)', () {
      final invoice = bolt11WithHash(hash);
      expect(KilobridgeClient.paymentHashFromInvoice(invoice), hash);
    });

    test('accetta il prefisso lightning:', () {
      final invoice = bolt11WithHash(hash);
      expect(
        KilobridgeClient.paymentHashFromInvoice('lightning:$invoice'),
        hash,
      );
    });

    test('fattura malformata → null (nessuna eccezione)', () {
      expect(KilobridgeClient.paymentHashFromInvoice('lnbc1test'), isNull);
      expect(KilobridgeClient.paymentHashFromInvoice(''), isNull);
    });
  });

  group('client HTTP', () {
    late List<String> paths;
    late Map<String, dynamic> lastBody;

    KilobridgeClient build(Map<String, Object> routes) {
      paths = [];
      return KilobridgeClient(
        baseUrl: 'https://bridge.test',
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          if (request.body.isNotEmpty) {
            lastBody =
                (jsonDecode(request.body) as Map).cast<String, dynamic>();
          }
          final route = routes[request.url.path];
          if (route == null) {
            return http.Response('{"error":"not_found"}', 404);
          }
          final isError = (route as Map).containsKey('error');
          return http.Response(jsonEncode(route), isError ? 400 : 200);
        }),
      );
    }

    test('check riporta costo e hash', () async {
      final client = build({
        '/api/check': {
          'sat': 5000,
          'estimate_sat': 5100,
          'rate': 0.98,
          'hash': hash,
        },
      });
      final r = await client.check('lnbc1x');
      expect(r['estimate_sat'], 5100);
      expect(lastBody['invoice'], 'lnbc1x');
    });

    test('quote risolve il PoW e restituisce la hold invoice', () async {
      final client = build({
        '/api/pow': {'challenge': '1.1700000000.4.mac'},
        '/api/quote': {
          'hold_invoice': 'lnbc1hold',
          'hash': hash,
          'pay_sat': 5100,
          'token': 'tok',
        },
      });
      final r = await client.quote(bolt11WithHash(hash));
      expect(r['hold_invoice'], 'lnbc1hold');
      expect(paths, ['/api/pow', '/api/quote']);
      final pow = lastBody['pow'] as Map;
      expect(pow['challenge'], '1.1700000000.4.mac');
      expect(pow['nonce'], isNotEmpty);
    });

    test('errore del servizio → RpcError con il suo codice', () async {
      final client = build({
        '/api/check': {'error': 'too_small'},
      });
      await expectLater(
        client.check('lnbc1x'),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('stato dello swap con token', () async {
      final client = build({
        '/api/swap/$hash': {'state': 'settled', 'preimage': 'pre'},
      });
      final r = await client.swap(paymentHash: hash, token: 'tok');
      expect(r['state'], 'settled');
      expect(paths.single, '/api/swap/$hash');
    });
  });

  group('handler cross-chain', () {
    NwcHandlers handlersWith(
      Map<String, Object> routes, {
      Map<String, Map<String, dynamic>>? clnResponses,
    }) {
      final client = KilobridgeClient(
        baseUrl: 'https://bridge.test',
        httpClient: MockClient((request) async {
          final route = routes[request.url.path];
          if (route == null) {
            return http.Response('{"error":"not_found"}', 404);
          }
          final isError = (route as Map).containsKey('error');
          return http.Response(jsonEncode(route), isError ? 400 : 200);
        }),
      );
      return NwcHandlers(
        cln: FakeCln(
          clnResponses ??
              {
                'pay': {
                  'payment_preimage': 'pre',
                  'amount_sent_msat': 5110000,
                  'amount_msat': 5100000,
                },
              },
        ),
        crossChain: client,
        crossChainPollInterval: Duration.zero,
      );
    }

    test('senza bridge configurato → NOT_IMPLEMENTED', () async {
      final handlers = NwcHandlers(cln: FakeCln(const {}));
      await expectLater(
        handlers.handle('cross_chain_check', {'invoice': 'lnbc1'}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'NOT_IMPLEMENTED'),
        ),
      );
    });

    test('cross_chain_check mappa il costo', () async {
      final handlers = handlersWith({
        '/api/check': {'sat': 5000, 'estimate_sat': 5100, 'hash': hash},
      });
      final r = await handlers.handle('cross_chain_check', {
        'invoice': 'lnbc1x',
      });
      expect(r['sat'], 5000);
      expect(r['cost_sats'], 5100);
      expect(r['payment_hash'], hash);
    });

    test('cross_chain_pay paga la hold invoice e attende lo swap', () async {
      final handlers = handlersWith({
        '/api/pow': {'challenge': '1.1700000000.2.mac'},
        '/api/quote': {
          'hold_invoice': 'lnbc1hold',
          'hash': hash,
          'pay_sat': 5100,
          'token': 'tok',
        },
        '/api/swap/$hash': {'state': 'settled', 'preimage': 'preimagehex'},
      });
      final r = await handlers.handle('cross_chain_pay', {
        'invoice': bolt11WithHash(hash),
      });
      expect(r['state'], 'settled');
      expect(r['preimage'], 'preimagehex');
      expect(r['fees_paid'], 10000);
      final cln = (handlers.cln as FakeCln);
      expect(cln.calls, ['pay']);
      expect(cln.callParams.single['bolt11'], 'lnbc1hold');
    });

    test('cross_chain_pay rispetta il tetto max_sats', () async {
      final handlers = handlersWith({
        '/api/pow': {'challenge': '1.1700000000.2.mac'},
        '/api/quote': {
          'hold_invoice': 'lnbc1hold',
          'hash': hash,
          'pay_sat': 9000,
          'token': 'tok',
        },
      });
      await expectLater(
        handlers.handle('cross_chain_pay', {
          'invoice': bolt11WithHash(hash),
          'max_sats': 6000,
        }),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      final cln = (handlers.cln as FakeCln);
      expect(cln.calls, isEmpty);
    });
  });
}
