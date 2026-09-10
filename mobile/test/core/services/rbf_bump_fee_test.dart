import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';
import 'package:btc_blake2b_wallet/core/services/rbf_params_registry.dart';

/// Test del bump fee RBF (incremento B): ricostruzione della stessa tx con
/// fee maggiore via cache parametri di sessione.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';
  const owner = 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu';

  setUp(() {
    PendingSendRegistry.resetForTest();
    RbfParamsRegistry.resetForTest();
  });

  group('RbfParamsRegistry', () {
    test('register/of/remove/contains/reset', () {
      RbfParamsRegistry.register(
        'tx1',
        const RbfTxParams(
          kind: RbfTxKind.send,
          toAddress: 'bc1qtest',
          amountSats: 5000,
          derivationPath: "m/84'/0'/0'",
          originalFeeRateSatVb: 5,
          utxos: [],
        ),
      );
      expect(RbfParamsRegistry.contains('tx1'), isTrue);
      expect(RbfParamsRegistry.of('tx1')!.amountSats, 5000);
      RbfParamsRegistry.remove('tx1');
      expect(RbfParamsRegistry.contains('tx1'), isFalse);
      expect(RbfParamsRegistry.of('unknown'), isNull);
    });

    test('register ignora txid vuoto', () {
      RbfParamsRegistry.register(
        '',
        const RbfTxParams(
          kind: RbfTxKind.send,
          toAddress: 'bc1qtest',
          amountSats: 1,
          derivationPath: "m/84'/0'/0'",
          originalFeeRateSatVb: 1,
          utxos: [],
        ),
      );
      expect(RbfParamsRegistry.of(''), isNull);
    });
  });

  group('bumpFee', () {
    Future<BitcoinService> sendOnce(List<String> bodies, List<String> txids) async {
      var n = 0;
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/tx') && request.method == 'POST') {
          bodies.add(request.body);
          final txid = n < txids.length ? txids[n] : 'tx$n';
          n++;
          return http.Response(txid, 200);
        }
        return http.Response('not found', 404);
      });
      final svc = BitcoinService(client: mock);
      final result = await svc.buildSignAndSend(
        mnemonic: mnemonic,
        toAddress: 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
        amountSats: 50000,
        feeRateSatVb: 5,
        utxos: [
          UtxoInfo(
            txid: 'a' * 64,
            vout: 0,
            valueSat: 100000,
            scriptPubKeyType: 'v0_p2wpkh',
            ownerAddress: owner,
            ownerDerivationPath: "m/84'/0'/0'/0/0",
          ),
        ],
        derivationPath: "m/84'/0'/0'",
      );
      expect(result.txid, txids.first);
      return svc;
    }

    test('ricostruisce con fee maggiore, nuovo txid, cache aggiornata',
        () async {
      final bodies = <String>[];
      final svc = await sendOnce(bodies, ['orig1', 'bumped1']);

      expect(RbfParamsRegistry.contains('orig1'), isTrue);

      final bumped = await svc.bumpFee(
        mnemonic: mnemonic,
        txid: 'orig1',
        newFeeRateSatVb: 20,
      );

      expect(bumped.txid, 'bumped1');
      // fee maggiore → raw diversa e sempre replaceable
      expect(bodies, hasLength(2));
      expect(bodies[1], isNot(equals(bodies[0])));
      expect(
        bodies[1].contains('fdffffff'),
        isTrue,
        reason: 'replacement replaceable (RBF)',
      );
      // l'originale non è più bumpabile; il nuovo txid è registrato
      expect(RbfParamsRegistry.contains('orig1'), isFalse);
      expect(RbfParamsRegistry.contains('bumped1'), isTrue);
      expect(PendingSendRegistry.contains('bumped1'), isTrue);
    });

    test('fee non maggiore dell\'originale → ArgumentError, nessun broadcast',
        () async {
      final bodies = <String>[];
      final svc = await sendOnce(bodies, ['orig2']);

      await expectLater(
        svc.bumpFee(mnemonic: mnemonic, txid: 'orig2', newFeeRateSatVb: 5),
        throwsArgumentError,
      );
      expect(bodies, hasLength(1), reason: 'nessun secondo broadcast');
    });

    test('txid sconosciuto → StateError', () async {
      final svc = BitcoinService(
        client: MockClient(
          (_) async => http.Response('not found', 404),
        ),
      );
      await expectLater(
        svc.bumpFee(mnemonic: mnemonic, txid: 'unknown', newFeeRateSatVb: 20),
        throwsStateError,
      );
    });
  });
}
