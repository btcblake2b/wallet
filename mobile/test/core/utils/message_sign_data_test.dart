import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';

void main() {
  group('MessageSignData', () {
    test('should instantiate', () {
      final sut = MessageSignData('test_mnemonic', 'test_message');

      expect(sut, isNotNull);
      expect(sut.mnemonic, 'test_mnemonic');
      expect(sut.message, 'test_message');
    });
  });
}
