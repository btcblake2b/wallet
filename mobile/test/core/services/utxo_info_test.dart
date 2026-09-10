import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

void main() {
  group('UtxoInfo', () {
    test('should instantiate', () {
      final sut = UtxoInfo(
        txid: 'test_txid',
        vout: 0,
        valueSat: 10000,
      );

      expect(sut, isNotNull);
      expect(sut.txid, 'test_txid');
      expect(sut.vout, 0);
      expect(sut.valueSat, 10000);
    });

    test('should preserve confirmations through copyWith', () {
      final sut = UtxoInfo(
        txid: 'test_txid',
        vout: 0,
        valueSat: 10000,
        confirmations: 3,
      );

      final copy = sut.copyWith();

      expect(copy.confirmations, 3);
    });
  });
}
