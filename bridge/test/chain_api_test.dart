import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nwc_cln_bridge/src/swap/chain_api.dart';
import 'package:test/test.dart';

/// Test del [ChainApi] Esplora con un client HTTP finto: nessuna rete.
void main() {
  group('EsploraChainApi', () {
    const baseUrl = 'https://example.test/api';

    EsploraChainApi apiWith(MockClient client) =>
        EsploraChainApi(baseUrl: baseUrl, httpClient: client);

    test('tipHeight legge il testo della risposta', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/blocks/tip/height');
        return http.Response('972123', 200);
      });
      expect(await apiWith(client).tipHeight(), 972123);
    });

    test('txStatus: confirmed + block_height', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/tx/${'ab' * 32}/status');
        return http.Response('{"confirmed":true,"block_height":972100}', 200);
      });
      final status = await apiWith(client).txStatus('ab' * 32);
      expect(status, isNotNull);
      expect(status!.confirmed, isTrue);
      expect(status.blockHeight, 972100);
    });

    test('txStatus: 404 → null (tx sconosciuta)', () async {
      final client = MockClient((req) async => http.Response('not found', 404));
      expect(await apiWith(client).txStatus('cd' * 32), isNull);
    });

    test('txHex: raw hex e null su 404', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/tx/${'ee' * 32}/hex');
        return http.Response('aabbcc\n', 200);
      });
      expect(await apiWith(client).txHex('ee' * 32), 'aabbcc');

      final missing = MockClient((req) async => http.Response('nope', 404));
      expect(await apiWith(missing).txHex('ff' * 32), isNull);
    });

    test('addressTxs: mappa mempool e chain', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/address/bc1qtest/txs');
        return http.Response(
          '[{"txid":"${'aa' * 32}","status":{"confirmed":true,"block_height":972000}},'
          '{"txid":"${'bb' * 32}","status":{"confirmed":false}}]',
          200,
        );
      });
      final txs = await apiWith(client).addressTxs('bc1qtest');
      expect(txs.length, 2);
      expect(txs[0].txid, 'aa' * 32);
      expect(txs[0].confirmed, isTrue);
      expect(txs[0].blockHeight, 972000);
      expect(txs[1].confirmed, isFalse);
      expect(txs[1].blockHeight, isNull);
    });

    test('outspends: mappa spent e spendingTxid per vout', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/tx/${'ee' * 32}/outspends');
        return http.Response(
          '[{"spent":false},{"spent":true,"txid":"${'ff' * 32}","vin":0}]',
          200,
        );
      });
      final outs = await apiWith(client).outspends('ee' * 32);
      expect(outs.length, 2);
      expect(outs[0].vout, 0);
      expect(outs[0].spent, isFalse);
      expect(outs[1].vout, 1);
      expect(outs[1].spent, isTrue);
      expect(outs[1].spendingTxid, 'ff' * 32);
    });

    test('broadcast: POST del raw hex e ritorno del txid', () async {
      final client = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/tx');
        expect(req.headers['Content-Type'], contains('text/plain'));
        expect(req.body, 'deadbeef');
        return http.Response('${'12' * 32}\n', 200);
      });
      expect(await apiWith(client).broadcast('deadbeef'), '12' * 32);
    });
  });

  group('EsploraChainApi errori', () {
    test('status non-200 → ChainApiException', () async {
      final client = MockClient((req) async => http.Response('boom', 500));
      final api = EsploraChainApi(
        baseUrl: 'https://example.test/api',
        httpClient: client,
      );
      await expectLater(api.tipHeight(), throwsA(isA<ChainApiException>()));
      await expectLater(
        api.addressTxs('bc1qtest'),
        throwsA(isA<ChainApiException>()),
      );
      await expectLater(
        api.broadcast('00'),
        throwsA(isA<ChainApiException>()),
      );
    });
  });
}
