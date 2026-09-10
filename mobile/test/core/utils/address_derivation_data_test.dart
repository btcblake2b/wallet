import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';

void main() {
  group('AddressDerivationData', () {
    test('should instantiate', () {
      final sut = AddressDerivationData('test_mnemonic');

      expect(sut, isNotNull);
      expect(sut.mnemonic, 'test_mnemonic');
      expect(sut.addressCount, 100);
    });
  });
}
