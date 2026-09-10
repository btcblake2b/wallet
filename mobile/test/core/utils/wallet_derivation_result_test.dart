import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';

void main() {
  group('WalletDerivationResult', () {
    test('should instantiate', () {
      final sut = WalletDerivationResult(
        publicAddress: 'test_address',
        masterFingerprint: 'test_fingerprint',
        derivationPath: "m/84'/1'/0'/0/0",
        xpub: 'xpub_test',
        addresses: ['test_address_1', 'test_address_2'],
        changeAddresses: ['test_change_1', 'test_change_2'],
      );

      expect(sut, isNotNull);
      expect(sut.publicAddress, 'test_address');
      expect(sut.masterFingerprint, 'test_fingerprint');
      expect(sut.changeAddresses, ['test_change_1', 'test_change_2']);
    });
  });
}
