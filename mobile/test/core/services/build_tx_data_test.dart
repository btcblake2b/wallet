import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/send_output.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

void main() {
  group('BuildTxData', () {
    test('should instantiate', () {
      // PERCHÉ (P3): i destinatari sono una LISTA — il caso singolo ne ha uno.
      final sut = BuildTxData(
        mnemonic: 'test_mnemonic twelve words here for testing',
        outputs: const [
          SendOutput(address: 'tb1qtestaddress', amountSats: 10000),
        ],
        feeRateSatVb: 5,
        utxos: <UtxoInfo>[],
        derivationPath: "m/84'/1'/0'/0/0",
      );

      expect(sut, isNotNull);
      expect(sut.mnemonic, 'test_mnemonic twelve words here for testing');
      expect(sut.outputs, hasLength(1));
      expect(sut.outputs.single.amountSats, 10000);
      expect(sut.outputs.single.address, 'tb1qtestaddress');
    });
  });
}
