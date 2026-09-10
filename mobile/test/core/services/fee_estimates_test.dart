import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

void main() {
  group('FeeEstimates', () {
    test('should instantiate', () {
      final sut = FeeEstimates(
        lowSatVb: 1,
        normalSatVb: 5,
        highSatVb: 10,
      );

      expect(sut, isNotNull);
      expect(sut.lowSatVb, 1);
      expect(sut.normalSatVb, 5);
      expect(sut.highSatVb, 10);
    });
  });
}
