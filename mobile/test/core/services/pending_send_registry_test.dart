import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';

void main() {
  group('PendingSendRegistry', () {
    setUp(PendingSendRegistry.resetForTest);

    test('register + activeTxids + amountOf', () {
      PendingSendRegistry.register('tx1', amountSats: 5000);
      PendingSendRegistry.register('tx2', amountSats: 0);

      expect(PendingSendRegistry.activeTxids, containsAll(['tx1', 'tx2']));
      expect(PendingSendRegistry.contains('tx1'), isTrue);
      expect(PendingSendRegistry.amountOf('tx1'), 5000);
      expect(PendingSendRegistry.amountOf('unknown'), 0);
    });

    test('register ignora txid vuoto', () {
      PendingSendRegistry.register('', amountSats: 1);
      expect(PendingSendRegistry.activeTxids, isEmpty);
    });

    test('markConfirmed rimuove dal registro (niente leak)', () {
      PendingSendRegistry.register('tx1', amountSats: 10);
      PendingSendRegistry.markConfirmed('tx1');

      expect(PendingSendRegistry.activeTxids, isEmpty);
      expect(PendingSendRegistry.contains('tx1'), isFalse);
    });

    test('markEvicted resta attiva e leggibile', () {
      PendingSendRegistry.register('tx1', amountSats: 10);
      expect(PendingSendRegistry.isEvicted('tx1'), isFalse);

      PendingSendRegistry.markEvicted('tx1');
      expect(PendingSendRegistry.isEvicted('tx1'), isTrue);
      expect(PendingSendRegistry.activeTxids, contains('tx1'));
    });

    test('resetForTest svuota', () {
      PendingSendRegistry.register('tx1', amountSats: 1);
      PendingSendRegistry.resetForTest();
      expect(PendingSendRegistry.activeTxids, isEmpty);
    });
  });
}
