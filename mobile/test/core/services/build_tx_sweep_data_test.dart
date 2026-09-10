import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

void main() {
  group('BuildTxSweepData', () {
    test('should instantiate', () {
      final sut = BuildTxSweepData(
        mnemonic: 'test_mnemonic twelve words here for testing',
        toAddress: 'tb1qtestaddress',
        feeRateSatVb: 5,
        utxos: <UtxoInfo>[],
        derivationPath: "m/84'/1'/0'/0/0",
      );

      expect(sut, isNotNull);
      expect(sut.mnemonic, 'test_mnemonic twelve words here for testing');
      expect(sut.feeRateSatVb, 5);
    });
  });
}
