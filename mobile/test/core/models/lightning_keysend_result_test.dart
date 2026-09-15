import 'package:btc_blake2b_wallet/core/models/lightning_keysend_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningKeysendResult', () {
    test('parse completo con preimage e fee', () {
      final result = LightningKeysendResult.fromJson(const {
        'destination': '02bfcaa8328a89aa03ef55b3b810dc0',
        'payment_hash': 'h1',
        'payment_preimage': 'p1',
        'status': 'complete',
        'amount_msat': 1000000,
        'fee_msat': 1000,
        'created_at': 1789364186,
      });

      expect(result.destination, '02bfcaa8328a89aa03ef55b3b810dc0');
      expect(result.paymentHash, 'h1');
      expect(result.preimage, 'p1');
      expect(result.isComplete, isTrue);
      expect(result.amountSats, 1000);
      expect(result.feeSats, 1);
      expect(result.createdAt, 1789364186);
    });

    test('preimage assente (pagamento non concluso) → null', () {
      final result = LightningKeysendResult.fromJson(const {
        'destination': '02aa',
        'payment_hash': 'h2',
        'status': 'pending',
        'amount_msat': 500000,
      });

      expect(result.preimage, isNull);
      expect(result.isComplete, isFalse);
      expect(result.feeMsat, isNull);
      expect(result.feeSats, isNull);
    });

    test('campi mancanti → default sicuri', () {
      final result = LightningKeysendResult.fromJson(const {});

      expect(result.destination, '');
      expect(result.paymentHash, '');
      expect(result.status, 'unknown');
      expect(result.amountSats, 0);
      expect(result.shortDestination, '');
    });

    test('destinazione lunga → id troncato per la UI', () {
      final result = LightningKeysendResult.fromJson(const {
        'destination':
            '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389',
        'payment_hash': 'h3',
      });

      expect(result.shortDestination, '02bfcaa8328a89aa…');
    });
  });
}
