import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';

void main() {
  group('MessageVerifyData', () {
    test('should instantiate', () {
      final sut = MessageVerifyData(
        'test_address',
        'test_message',
        'test_signature',
      );

      expect(sut, isNotNull);
      expect(sut.address, 'test_address');
      expect(sut.message, 'test_message');
      expect(sut.signature, 'test_signature');
    });
  });
}
