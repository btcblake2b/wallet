import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';

/// Test della riconciliazione pending/eviction (audit P1-c) tramite il percorso
/// pubblico `fetchTransactionHistory` (nessuna derivazione crypto necessaria).
void main() {
  const addr = 'bc1qtest';

  setUp(PendingSendRegistry.resetForTest);

  MockClient mockWith({
    required String txStatusBody,
    int txStatusStatus = 200,
    String addressTxsBody = '[]',
  }) {
    return MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('100', 200);
      }
      if (path.endsWith('/address/$addr/txs')) {
        return http.Response(addressTxsBody, 200);
      }
      if (path.contains('/tx/')) {
        return http.Response(txStatusBody, txStatusStatus);
      }
      return http.Response('not found', 404);
    });
  }

  String confirmedTx(String txid) => jsonEncode({
        'txid': txid,
        'status': {
          'confirmed': true,
          'block_height': 99,
          'block_hash': 'aa',
        },
      });

  group('eviction detection (audit P1-c)', () {
    test('tx assente + /tx 404 → riga sintetica isEvicted', () async {
      PendingSendRegistry.register('evictedTx', amountSats: 5000);
      final svc = BitcoinService(
        client: mockWith(
          txStatusBody: 'not found',
          txStatusStatus: 404,
        ),
      );

      final records = await svc.fetchTransactionHistory(addr);

      final evicted = records.where((r) => r.isEvicted).toList();
      expect(evicted, hasLength(1));
      expect(evicted.first.txid, 'evictedTx');
      expect(evicted.first.amountSats, 5000);
      expect(evicted.first.isPending, isFalse);
      expect(PendingSendRegistry.isEvicted('evictedTx'), isTrue);
    });

    test('tx assente ma /tx 200 confirmed → confermata, nessuna riga finta',
        () async {
      PendingSendRegistry.register('confirmedTx', amountSats: 300);
      final svc = BitcoinService(
        client: mockWith(txStatusBody: confirmedTx('confirmedTx')),
      );

      final records = await svc.fetchTransactionHistory(addr);

      expect(records.where((r) => r.isEvicted), isEmpty);
      expect(PendingSendRegistry.contains('confirmedTx'), isFalse);
    });

    test('errore di rete sul /tx → fail-open: nessuna riga, stato invariato',
        () async {
      PendingSendRegistry.register('netErr', amountSats: 1);
      final svc = BitcoinService(
        client: mockWith(txStatusBody: 'server error', txStatusStatus: 500),
      );

      final records = await svc.fetchTransactionHistory(addr);

      expect(records.where((r) => r.isEvicted), isEmpty);
      expect(PendingSendRegistry.isEvicted('netErr'), isFalse);
      expect(PendingSendRegistry.contains('netErr'), isTrue);
    });

    test('tx presente nello storico come pending → resta, nessuna eviction',
        () async {
      PendingSendRegistry.register('pendingTx', amountSats: 200);
      // Tx outgoing pending: spende dal nostro indirizzo (vin), non confermata.
      final pendingJson = jsonEncode([
        {
          'txid': 'pendingTx',
          'vin': [
            {
              'prevout': {
                'scriptpubkey_address': addr,
                'value': 1000,
              },
            },
          ],
          'vout': [
            {
              'scriptpubkey_address': 'bc1qother',
              'value': 800,
            },
          ],
          'status': {'confirmed': false},
        },
      ]);
      final svc = BitcoinService(
        client: mockWith(
          txStatusBody: 'not found', // non deve servire: tx già nei records
          addressTxsBody: pendingJson,
        ),
      );

      final records = await svc.fetchTransactionHistory(addr);

      final found = records.firstWhere((r) => r.txid == 'pendingTx');
      expect(found.isPending, isTrue);
      expect(found.isEvicted, isFalse);
      expect(records.where((r) => r.isEvicted), isEmpty);
      expect(PendingSendRegistry.contains('pendingTx'), isTrue);
    });

    test('evicted poi /tx 200 confirmed (reorg) → smette di essere segnalata',
        () async {
      PendingSendRegistry.register('reorgTx', amountSats: 400);
      PendingSendRegistry.markEvicted('reorgTx');

      // Primo refresh: ancora 404 → riga presente.
      final svc404 = BitcoinService(
        client: mockWith(txStatusBody: 'not found', txStatusStatus: 404),
      );
      final r1 = await svc404.fetchTransactionHistory(addr);
      expect(r1.where((r) => r.isEvicted), hasLength(1));

      // Secondo refresh: il nodo ora la conferma (reorg re-inclusione).
      final svcOk = BitcoinService(
        client: mockWith(txStatusBody: confirmedTx('reorgTx')),
      );
      final r2 = await svcOk.fetchTransactionHistory(addr);
      expect(r2.where((r) => r.isEvicted), isEmpty);
      expect(PendingSendRegistry.contains('reorgTx'), isFalse);
    });
  });
}
