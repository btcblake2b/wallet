import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';

/// Test del segnale RBF upstream (incremento A): le tx inviate dall'app sono
/// replaceable (sequence 0xfffffffd) — prerequisito per il bump fee.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  // Primo indirizzo BIP84 mainnet del vettore noto (abandon…about).
  const owner = 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu';

  setUp(PendingSendRegistry.resetForTest);

  Future<String> broadcastRawWith({required bool enableRBF}) async {
    String? posted;
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/tx') && request.method == 'POST') {
        posted = request.body;
        return http.Response('rbftxid123', 200);
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
      enableRBF: enableRBF,
    );

    expect(result.txid, 'rbftxid123');
    expect(posted, isNotNull, reason: 'broadcast deve aver ricevuto la raw tx');
    return posted!;
  }

  test('default spesa: la tx serializzata è replaceable (0xfffffffd)',
      () async {
    final raw = await broadcastRawWith(enableRBF: true);
    // 0xfffffffd little-endian = fdffffff — sequence non-final (BIP125).
    expect(
      raw.contains('fdffffff'),
      isTrue,
      reason: 'tx dovrebbe avere sequence RBF opt-in',
    );
  });

  test('enableRBF false: sequence finale (ffffffff), nessun fdffffff',
      () async {
    final raw = await broadcastRawWith(enableRBF: false);
    expect(
      raw.contains('ffffffff'),
      isTrue,
      reason: 'sequence finale attesa',
    );
    expect(raw.contains('fdffffff'), isFalse);
  });
}
