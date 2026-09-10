import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_snapshot.dart';

void main() {
  group('WalletSnapshot', () {
    test('isFresh true entro il TTL', () {
      final s = WalletSnapshot(
        balanceSats: 1,
        txCount: 0,
        fetchedAt: DateTime.now(),
      );
      expect(s.isFresh(const Duration(minutes: 5)), isTrue);
    });

    test('isFresh false oltre il TTL', () {
      final s = WalletSnapshot(
        balanceSats: 1,
        txCount: 0,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(s.isFresh(const Duration(minutes: 5)), isFalse);
    });

    test('isComplete true quando ci sono utxos e transactions', () {
      final s = WalletSnapshot(
        balanceSats: 1,
        txCount: 0,
        utxos: const [],
        transactions: const [],
        fetchedAt: DateTime.now(),
      );
      expect(s.isComplete, isTrue);
    });

    test('isComplete false quando mancano utxos/transactions', () {
      final s = WalletSnapshot(
        balanceSats: 1,
        txCount: 0,
        fetchedAt: DateTime.now(),
      );
      expect(s.isComplete, isFalse);
    });
  });
}
