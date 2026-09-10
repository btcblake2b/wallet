import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_balance.dart';

void main() {
  group('WalletBalance', () {
    test('fromChainStats somma funded−spent di catena e mempool', () {
      final balance = WalletBalance.fromChainStats(
        chainStats: {
          'funded_txo_sum': 100000,
          'spent_txo_sum': 40000,
          'tx_count': 5,
        },
        mempoolStats: {
          'funded_txo_sum': 5000,
          'spent_txo_sum': 0,
          'tx_count': 1,
        },
      );

      expect(balance.balanceSats, equals(65000)); // (100000+5000)-(40000+0)
      expect(balance.txCount, equals(6));
    });

    test('fromChainStats tollera campi mancanti (fallback a 0)', () {
      final balance = WalletBalance.fromChainStats(
        chainStats: const {},
        mempoolStats: const {},
      );

      expect(balance.balanceSats, equals(0));
      expect(balance.txCount, equals(0));
    });

    test('fromChainStats tollera valori non numerici senza crash', () {
      final balance = WalletBalance.fromChainStats(
        chainStats: {
          'funded_txo_sum': 'x',
          'spent_txo_sum': null,
          'tx_count': 3.7,
        },
        mempoolStats: const {},
      );

      // PERCHÉ: `_asInt` converte 3.7 → 3 e i valori non-numerici → 0.
      expect(balance.balanceSats, equals(0));
      expect(balance.txCount, equals(3));
    });

    test('formatTbtc formatta 99.999.856 satoshi → 0.99999856 BTC', () {
      expect(WalletBalance.formatTbtc(99999856), equals('0.99999856 BTC'));
    });

    test('formatTbtc formatta zero → 0.00000000 BTC', () {
      expect(WalletBalance.formatTbtc(0), equals('0.00000000 BTC'));
    });

    test('formatTbtc formatta 1 BTC → 1.00000000 BTC', () {
      expect(WalletBalance.formatTbtc(100000000), equals('1.00000000 BTC'));
    });

    test('round-trip toMap/fromMap conserva i campi', () {
      const balance = WalletBalance(balanceSats: 123, txCount: 4);
      final restored = WalletBalance.fromMap(balance.toMap());

      expect(restored.balanceSats, equals(123));
      expect(restored.txCount, equals(4));
    });

    test('copyWith aggiorna solo i campi specificati', () {
      const balance = WalletBalance(balanceSats: 123, txCount: 4);
      final updated = balance.copyWith(txCount: 9);

      expect(updated.balanceSats, equals(123));
      expect(updated.txCount, equals(9));
    });
  });

  group('TxStatus', () {
    test('fromMap parsa transazione confermata', () {
      final status = TxStatus.fromMap(const {
        'status': {
          'confirmed': true,
          'block_height': 172048,
          'block_hash': '0000abc',
        },
      });

      expect(status.confirmed, isTrue);
      expect(status.blockHeight, equals(172048));
      expect(status.blockHash, equals('0000abc'));
    });

    test('fromMap senza status → confirmed false e blocchi null', () {
      final status = TxStatus.fromMap(const {'txid': 'abc'});

      expect(status.confirmed, isFalse);
      expect(status.blockHeight, isNull);
      expect(status.blockHash, isNull);
    });

    test('fromMap con status non confermato → blockHeight null', () {
      final status = TxStatus.fromMap(const {
        'status': {'confirmed': false},
      });

      expect(status.confirmed, isFalse);
      expect(status.blockHeight, isNull);
      expect(status.blockHash, isNull);
    });

    test('round-trip toMap/fromMap conserva i campi', () {
      const status = TxStatus(
        confirmed: true,
        blockHeight: 172048,
        blockHash: '0000abc',
      );
      final restored = TxStatus.fromMap(status.toMap());

      expect(restored.confirmed, isTrue);
      expect(restored.blockHeight, equals(172048));
      expect(restored.blockHash, equals('0000abc'));
    });

    test('copyWith azzera blockHeight con clearBlockHeight', () {
      const status = TxStatus(
        confirmed: true,
        blockHeight: 172048,
        blockHash: '0000abc',
      );
      final cleared = status.copyWith(clearBlockHeight: true);

      expect(cleared.blockHeight, isNull);
      expect(cleared.blockHash, equals('0000abc'));
    });
  });
}
