import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/config/env.dart';

void main() {
  group('Env', () {
    test('should have a default empty appSignature', () {
      // PERCHÉ: default vuoto = controllo integrità disabilitato finché
      // APP_SIGNATURE non viene configurata in .env per la release.
      expect(Env.appSignature, isEmpty);
    });
  });
}
