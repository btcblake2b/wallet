import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';

void main() {
  group('BtcNetwork', () {
    test('should have expected enum values', () {
      expect(BtcNetwork.testnet, isNotNull);
      expect(BtcNetwork.mainnet, isNotNull);
      expect(BtcNetwork.values.length, 2);
    });
  });
}
