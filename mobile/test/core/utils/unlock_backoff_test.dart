import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/utils/unlock_backoff.dart';

void main() {
  group('unlockBackoffDelay', () {
    test('nessun ritardo per i primi errori (sviste di battitura)', () {
      expect(unlockBackoffDelay(0), Duration.zero);
      expect(unlockBackoffDelay(1), Duration.zero);
      expect(unlockBackoffDelay(2), Duration.zero);
    });

    test('backoff crescente dal terzo tentativo fallito', () {
      expect(unlockBackoffDelay(3), const Duration(seconds: 1));
      expect(unlockBackoffDelay(4), const Duration(seconds: 2));
      expect(unlockBackoffDelay(5), const Duration(seconds: 4));
    });

    test('cap a 8 secondi per tentativi elevati', () {
      expect(unlockBackoffDelay(6), const Duration(seconds: 8));
      expect(unlockBackoffDelay(7), const Duration(seconds: 8));
      expect(unlockBackoffDelay(1000), const Duration(seconds: 8));
    });
  });
}
