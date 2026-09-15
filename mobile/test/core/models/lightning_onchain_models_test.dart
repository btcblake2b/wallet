import 'package:btc_blake2b_wallet/core/models/lightning_balance.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_node_address.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_node_info.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_onchain_fees.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_onchain_result.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_utxo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningBalance', () {
    test('breakdown presente', () {
      final b = LightningBalance.fromJson({
        'balance': 42000000,
        'onchain': 7000000,
        'lightning': 35000000,
      });
      expect(b.balanceSats, 42000);
      expect(b.onchainSats, 7000);
      expect(b.lightningSats, 35000);
    });

    test('breakdown assente → fallback sul totale', () {
      final b = LightningBalance.fromJson({'balance': 42000});
      expect(b.onchainSats, isNull);
      expect(b.lightningSats, 42);
    });
  });

  group('LightningOnchainFees', () {
    test('parse completo', () {
      final f = LightningOnchainFees.fromJson(
        {'min': 1, 'economical': 2, 'priority': 5},
      );
      expect(f.minSatVb, 1);
      expect(f.economicalSatVb, 2);
      expect(f.prioritySatVb, 5);
      expect(f.isEmpty, isFalse);
    });

    test('campi mancanti → isEmpty', () {
      final f = LightningOnchainFees.fromJson({});
      expect(f.isEmpty, isTrue);
    });
  });

  group('LightningNodeAddress / LightningOnchainResult', () {
    test('parse indirizzo', () {
      final a = LightningNodeAddress.fromJson(
        {
          'address': 'bc1qabc',
          'type': 'bech32',
          'keyidx': 1,
          'has_funds': true,
        },
      );
      expect(a.address, 'bc1qabc');
      expect(a.type, 'bech32');
      expect(a.keyIndex, 1);
      expect(a.hasFunds, isTrue);
    });

    test('retrocompatibilità: payload vecchio con `used`', () {
      final a = LightningNodeAddress.fromJson(
        {'address': 'bc1qabc', 'used': false},
      );
      expect(a.hasFunds, isFalse);
      expect(a.keyIndex, isNull);
    });

    test('indirizzo lungo → shortAddress abbreviato', () {
      final a = LightningNodeAddress.fromJson(
        {
          'address':
              'bc1p8ypv5hpwm5sm47nvlx9h9t05vyfrjj9hmgw5d9upjhkwrnnk2dsqdjakt4',
        },
      );
      expect(a.shortAddress, 'bc1p8ypv5h…djakt4');
    });

    test('parse txid', () {
      expect(LightningOnchainResult.fromJson({'txid': 'ff'}).txid, 'ff');
    });
  });

  group('LightningUtxo', () {
    test('parse output confermato', () {
      final u = LightningUtxo.fromJson(const {
        'txid': 'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6',
        'vout': 1,
        'amount_msat': 19382000,
        'address': 'bc1p8ypv5',
        'status': 'confirmed',
        'blockheight': 971913,
        'reserved': false,
      });
      expect(u.vout, 1);
      expect(u.amountSats, 19382);
      expect(u.isConfirmed, isTrue);
      expect(u.blockHeight, 971913);
      expect(u.reserved, isFalse);
      expect(u.shortTxid, 'b34ada85…b10cd6');
    });

    test('output in attesa e riservato', () {
      final u = LightningUtxo.fromJson(const {
        'txid': 'cc99',
        'output': 0,
        'amount_msat': 5000000,
        'status': 'unconfirmed',
        'reserved': true,
      });
      expect(u.isConfirmed, isFalse);
      expect(u.reserved, isTrue);
      expect(u.address, isNull);
      expect(u.blockHeight, isNull);
      expect(u.shortTxid, 'cc99');
    });

    test('campi mancanti → default sicuri', () {
      final u = LightningUtxo.fromJson(const {});
      expect(u.txid, '');
      expect(u.vout, 0);
      expect(u.amountSats, 0);
      expect(u.status, 'unknown');
      expect(u.isConfirmed, isFalse);
      expect(u.reserved, isFalse);
    });
  });

  group('LightningNodeInfo', () {
    test('block_height (spec dln)', () {
      final i = LightningNodeInfo.fromJson({'block_height': 961640});
      expect(i.blockHeight, 961640);
    });

    test('fallback blockheight (payload storici)', () {
      final i = LightningNodeInfo.fromJson({'blockheight': 100});
      expect(i.blockHeight, 100);
    });
  });
}
