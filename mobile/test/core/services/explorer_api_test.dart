import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/explorer_api.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

/// Imposta la politica dei mirror come la imposterebbe l'utente dalle
/// Impostazioni (istanza di processo + storage mockato).
Future<void> _setMirrors(bool enabled) async {
  final storage = MockStorage();
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((_) async {});
  ExplorerMirrors.instance = ExplorerMirrors(storage: storage);
  if (!enabled) await ExplorerMirrors.instance.setEnabled(false);
}

void main() {
  // PERCHÉ: il registro dei mirror è di processo → ogni test parte dal default.
  setUp(ExplorerMirrors.resetForTest);
  tearDown(ExplorerMirrors.resetForTest);

  group('ExplorerApi', () {
    test('fetchAddressInfo parsa balance e tx_count dal payload chain_stats',
        () async {
      // PERCHÉ: formato stile Esplora — stesso parsing di BitcoinService.
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/address/bc1qtest');
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 100000,
              'spent_txo_sum': 40000,
              'tx_count': 5,
            },
            'mempool_stats': {
              'funded_txo_sum': 5000,
              'spent_txo_sum': 0,
              'tx_count': 1,
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(client: mock);

      final info = await api.fetchAddressInfo('bc1qtest');

      expect(info['balance'], equals(65000)); // (100000+5000)-(40000+0)
      expect(info['tx_count'], equals(6));
    });

    test('fetchAddressInfo lancia Exception su HTTP 503 (node_unavailable)',
        () async {
      final mock = MockClient(
        (_) async => http.Response('{"error":"node_unavailable"}', 503),
      );
      final api = ExplorerApi(client: mock);

      // PERCHÉ: l'eccezione tipizzata arriva alla UI (nessun fallback).
      await expectLater(api.fetchAddressInfo('bc1qtest'), throwsException);
    });

    test('fetchAddressInfo lancia Exception su errore di rete', () async {
      final mock =
          MockClient((_) async => throw http.ClientException('network down'));
      final api = ExplorerApi(client: mock);

      await expectLater(api.fetchAddressInfo('bc1qtest'), throwsException);
    });

    test('tipHeight ritorna l altezza del blocco tip', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/blocks/tip/height');
        return http.Response('172048', 200);
      });
      final api = ExplorerApi(client: mock);

      expect(await api.tipHeight(), equals(172048));
    });

    // ── Nuovi test: integrazione completa API nodo ──

    test('addressBalance parsa chain_stats+mempool in WalletBalance', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/address/tb1qtest');
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 100000,
              'spent_txo_sum': 40000,
              'tx_count': 5,
            },
            'mempool_stats': {
              'funded_txo_sum': 5000,
              'spent_txo_sum': 0,
              'tx_count': 1,
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(client: mock);

      final balance = await api.addressBalance('tb1qtest');

      expect(balance.balanceSats, equals(65000));
      expect(balance.txCount, equals(6));
    });

    test('addressBalance fa UNA sola richiesta e ritorna il saldo (anche 0)',
        () async {
      // PERCHÉ (2026-09-08): unica fonte mempool.guide — un saldo 0 è un
      // saldo reale, niente doppio salto di fallback.
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        expect(request.url.host, equals('mempool.guide'));
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 0,
              'spent_txo_sum': 0,
              'tx_count': 0,
            },
            'mempool_stats': {
              'funded_txo_sum': 0,
              'spent_txo_sum': 0,
              'tx_count': 0,
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(client: mock);

      final balance = await api.addressBalance('bc1qtest');

      expect(balance.balanceSats, equals(0));
      expect(calls, equals(1)); // UNA sola richiesta, nessun fallback
    });

    test('addressBalance mappa HTTP 429 su ApiException rate_limited',
        () async {
      final mock = MockClient(
        (_) async => http.Response('{"error":"rate_limited"}', 429),
      );
      final api = ExplorerApi(client: mock);

      await expectLater(
        api.addressBalance('tb1qtest'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'rate_limited')
              .having((e) => e.statusCode, 'statusCode', 429),
        ),
      );
    });

    test('addressBalance mappa HTTP 503 su ApiException node_unavailable',
        () async {
      final mock = MockClient(
        (_) async => http.Response('{"error":"node_unavailable"}', 503),
      );
      final api = ExplorerApi(client: mock);

      await expectLater(
        api.addressBalance('tb1qtest'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'node_unavailable'),
        ),
      );
    });

    test('addressBalance lancia ApiException bad_response su body non-JSON',
        () async {
      final mock =
          MockClient((_) async => http.Response('<html>oops</html>', 200));
      final api = ExplorerApi(client: mock);

      await expectLater(
        api.addressBalance('tb1qtest'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'bad_response'),
        ),
      );
    });

    test('addressBalance lancia ApiException network su errore di rete',
        () async {
      final mock =
          MockClient((_) async => throw http.ClientException('network down'));
      final api = ExplorerApi(client: mock);

      await expectLater(
        api.addressBalance('tb1qtest'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'network'),
        ),
      );
    });

    test('addressBalance lancia ApiException timeout oltre il timeout',
        () async {
      final mock = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      });
      final api = ExplorerApi(
        client: mock,
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        api.addressBalance('tb1qtest'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'timeout'),
        ),
      );
    });

    test('txStatus parsa una transazione confermata', () async {
      const txid =
          '43adf284ac5dadd429b23bc57b35001deb78a130fa209d449990437ab91b5788';
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/tx/$txid');
        return http.Response(
          jsonEncode({
            'txid': txid,
            'status': {
              'confirmed': true,
              'block_height': 172048,
              'block_hash': '00000000000000c68c',
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(client: mock);

      final status = await api.txStatus(txid);

      expect(status, isNotNull);
      expect(status?.confirmed, isTrue);
      expect(status?.blockHeight, equals(172048));
      expect(status?.blockHash, equals('00000000000000c68c'));
    });

    test('txStatus senza status nel body ritorna TxStatus non confermata',
        () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'txid': 'abc'}), 200),
      );
      final api = ExplorerApi(client: mock);

      final status = await api.txStatus('abc');

      expect(status, isNotNull);
      expect(status?.confirmed, isFalse);
      expect(status?.blockHeight, isNull);
      expect(status?.blockHash, isNull);
    });

    test('txStatus ritorna null su body non-oggetto', () async {
      final mock = MockClient((_) async => http.Response('[1,2,3]', 200));
      final api = ExplorerApi(client: mock);

      expect(await api.txStatus('abc'), isNull);
    });

    // ── Strato 0: retry su errori transitori + User-Agent ──

    test('retry: 429 poi 200 → successo (2 chiamate, backoff disattivato)',
        () async {
      // PERCHÉ (Strato 0): un rate limit momentaneo non deve far fallire il
      // saldo: dopo il 429 l'api riprova e va a buon fine.
      var calls = 0;
      final mock = MockClient((_) async {
        calls++;
        if (calls == 1) {
          return http.Response('{"error":"rate_limited"}', 429);
        }
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 100,
              'spent_txo_sum': 0,
              'tx_count': 1,
            },
            'mempool_stats': {
              'funded_txo_sum': 0,
              'spent_txo_sum': 0,
              'tx_count': 0,
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(
        client: mock,
        maxAttempts: 3,
        baseRetryDelay: Duration.zero, // PERCHÉ: test veloce e deterministico
      );

      final balance = await api.addressBalance('bc1qtest');

      expect(balance.balanceSats, equals(100));
      expect(calls, equals(2));
    });

    test('retry: 503 persistente esaurisce i tentativi (3 chiamate poi throw)',
        () async {
      var calls = 0;
      final mock = MockClient((_) async {
        calls++;
        return http.Response('{"error":"node_unavailable"}', 503);
      });
      final api = ExplorerApi(
        client: mock,
        maxAttempts: 3,
        baseRetryDelay: Duration.zero,
        // PERCHÉ: test unitario del retry single-host; il failover fra host ha
        // test dedicati nel gruppo "failover multi-host".
        baseUrls: const ['https://mempool.guide/api'],
      );

      await expectLater(
        api.addressBalance('bc1qtest'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'node_unavailable'),
        ),
      );
      expect(calls, equals(3));
    });

    test('invia un User-Agent identificativo a ogni richiesta', () async {
      final mock = MockClient((request) async {
        expect(request.headers['User-Agent'], contains('BtcBlake2bWallet'));
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 1,
              'spent_txo_sum': 0,
              'tx_count': 1,
            },
            'mempool_stats': {
              'funded_txo_sum': 0,
              'spent_txo_sum': 0,
              'tx_count': 0,
            },
          }),
          200,
        );
      });
      final api = ExplorerApi(client: mock);

      await api.addressBalance('bc1qtest');
    });

    // ── Failover fra host Esplora (2026-09-16) ──
    group('failover multi-host', () {
      const primary = 'https://mempool.guide/api';
      const mirror = 'https://mempool.kilombino.com/api';
      const mirror2 = 'https://mempool.maveth.ca/api';
      const hosts = <String>[primary, mirror, mirror2];

      http.Response balanceResponse(int funded) => http.Response(
            jsonEncode({
              'chain_stats': {
                'funded_txo_sum': funded,
                'spent_txo_sum': 0,
                'tx_count': 1,
              },
              'mempool_stats': {
                'funded_txo_sum': 0,
                'spent_txo_sum': 0,
                'tx_count': 0,
              },
            }),
            200,
          );

      test('primario 503 → saldo dal mirror (2 richieste)', () async {
        final hostsHit = <String>[];
        final mock = MockClient((request) async {
          hostsHit.add(request.url.host);
          if (request.url.host == 'mempool.guide') {
            return http.Response('{"error":"node_unavailable"}', 503);
          }
          return balanceResponse(90000);
        });
        final api = ExplorerApi(client: mock, baseUrls: hosts);

        final balance = await api.addressBalance('bc1qtest');

        expect(balance.balanceSats, equals(90000));
        expect(hostsHit, equals(['mempool.guide', 'mempool.kilombino.com']));
      });

      test('404 dal primario → not_found senza failover (1 richiesta)',
          () async {
        // PERCHÉ: 404 è una risposta VALIDA (risorsa assente): ritentarla su
        // un mirror maschererebbe l'esito.
        var calls = 0;
        final mock = MockClient((_) async {
          calls++;
          return http.Response('not found', 404);
        });
        final api = ExplorerApi(client: mock, baseUrls: hosts);

        await expectLater(
          api.addressBalance('bc1qtest'),
          throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 'not_found'),
          ),
        );
        expect(calls, equals(1));
      });

      test('tutti gli host indisponibili → errore del PRIMO host', () async {
        final mock = MockClient(
          (_) async => http.Response('{"error":"node_unavailable"}', 503),
        );
        final api = ExplorerApi(client: mock, baseUrls: hosts);

        await expectLater(
          api.addressBalance('bc1qtest'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'node_unavailable')
                .having((e) => e.statusCode, 'statusCode', 503),
          ),
        );
      });

      test('sticky: dopo il failover le richieste restano sul mirror',
          () async {
        final hostsHit = <String>[];
        final mock = MockClient((request) async {
          hostsHit.add(request.url.host);
          if (request.url.host == 'mempool.guide') {
            return http.Response('{"error":"node_unavailable"}', 503);
          }
          return balanceResponse(1234);
        });
        final api = ExplorerApi(client: mock, baseUrls: hosts);

        await api.addressBalance('bc1qtest'); // primo: failover
        await api.addressBalance('bc1qtest'); // secondo: già sul mirror

        expect(
          hostsHit,
          equals([
            'mempool.guide',
            'mempool.kilombino.com',
            'mempool.kilombino.com',
          ]),
        );
      });

      test('lista con un solo host → nessun failover (comportamento storico)',
          () async {
        var calls = 0;
        final mock = MockClient((_) async {
          calls++;
          return http.Response('{"error":"node_unavailable"}', 503);
        });
        final api = ExplorerApi(client: mock, baseUrls: const [primary]);

        await expectLater(
          api.addressBalance('bc1qtest'),
          throwsA(isA<ApiException>()),
        );
        expect(calls, equals(1)); // maxAttempts default 1, un solo host
      });

      // ── Interruttore "usa solo mempool.guide" (Impostazioni) ──

      test('interruttore OFF: primario 503 → nessun mirror contattato',
          () async {
        await _setMirrors(false);
        final hostsHit = <String>[];
        final mock = MockClient((request) async {
          hostsHit.add(request.url.host);
          return http.Response('{"error":"node_unavailable"}', 503);
        });
        // PERCHÉ: nessun baseUrls esplicito → la lista arriva dal registro.
        final api = ExplorerApi(client: mock);

        await expectLater(
          api.addressBalance('bc1qtest'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'node_unavailable'),
          ),
        );
        expect(hostsHit, equals(['mempool.guide']));
      });

      test('interruttore OFF dopo un failover: si torna al primario', () async {
        await _setMirrors(true);
        final hostsHit = <String>[];
        var primaryCalls = 0;
        final mock = MockClient((request) async {
          hostsHit.add(request.url.host);
          if (request.url.host == 'mempool.guide') {
            primaryCalls++;
            // PERCHÉ: il primario fallisce solo al primo giro (quello che fa
            // scattare il failover); dopo l'OFF deve rispondere normalmente,
            // a prova che le richieste tornano su di lui.
            if (primaryCalls == 1) {
              return http.Response('{"error":"node_unavailable"}', 503);
            }
          }
          return balanceResponse(1234);
        });
        final api = ExplorerApi(client: mock);

        final primo = await api.addressBalance('bc1qtest'); // sticky sul mirror
        await _setMirrors(false); // l'utente disattiva i mirror
        final dopo = await api.addressBalance('bc1qtest');

        expect(primo.balanceSats, equals(1234));
        expect(dopo.balanceSats, equals(1234));
        expect(
          hostsHit,
          equals(['mempool.guide', 'mempool.kilombino.com', 'mempool.guide']),
        );
      });
    });
  });
}
