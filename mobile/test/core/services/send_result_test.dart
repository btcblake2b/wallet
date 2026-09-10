import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

void main() {
  group('SendResult', () {
    test('should instantiate', () {
      final sut = SendResult(
        txid: 'test_txid',
        feePaid: 1000,
      );

      expect(sut, isNotNull);
      expect(sut.txid, 'test_txid');
      expect(sut.feePaid, 1000);
    });
  });
}
