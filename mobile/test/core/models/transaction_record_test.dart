import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';

/// Dati realistici nel formato Esplora verificato su mempool.guide testnet4.
/// `walletAddresses` = indirizzo principale del wallet di test.
const _walletAddrs = <String>{'tb1qqws3aatj6jz2nz8d7zefwmtmcccx4umlc5ygr7'};

Map<String, dynamic> _txJson({
  String txid =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  List<Map<String, dynamic>>? vout,
  List<Map<String, dynamic>>? vin,
  bool confirmed = true,
  int? blockHeight = 149987,
  int? blockTime = 1787842810,
  int? fee = 51000,
}) {
  return {
    'txid': txid,
    'version': 1,
    'locktime': 0,
    'fee': fee,
    'vin': vin ??
        [
          {
            'txid':
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            'vout': 0,
            'prevout': {
              'value': 3700000,
              'scriptpubkey_address':
                  'tb1qother0000000000000000000000000000000',
            },
          },
        ],
    'vout': vout ??
        [
          {
            'value': 3645814,
            'scriptpubkey_address':
                'tb1qqws3aatj6jz2nz8d7zefwmtmcccx4umlc5ygr7',
          },
        ],
    'status': {
      'confirmed': confirmed,
      if (blockHeight != null) 'block_height': blockHeight,
      if (blockTime != null) 'block_time': blockTime,
    },
  };
}

Map<String, dynamic> _vout(int value, String address) => {
      'value': value,
      'scriptpubkey_address': address,
    };

Map<String, dynamic> _vin(int value, String address, {bool coinbase = false}) {
  if (coinbase) {
    return {'txid': '', 'vout': 0, 'is_coinbase': true, 'prevout': null};
  }
  return {
    'txid': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'vout': 0,
    'prevout': {'value': value, 'scriptpubkey_address': address},
  };
}

void main() {
  group('TransactionRecord.isPending / isEvicted', () {
    test('isEvicted: non è pending e si distingue da orphan', () {
      const orphan = TransactionRecord(
        txid: 'a',
        direction: TxDirection.incoming,
        amountSats: 1,
        isOrphan: true,
      );
      const evicted = TransactionRecord(
        txid: 'b',
        direction: TxDirection.outgoing,
        amountSats: 2,
        isEvicted: true,
      );

      expect(orphan.isPending, isFalse);
      expect(orphan.isEvicted, isFalse);
      expect(evicted.isPending, isFalse, reason: 'evicted non è in attesa');
      expect(evicted.isEvicted, isTrue);
    });
  });

  group('TransactionRecord.fromExplorerJson', () {
    test('tx con solo vout al nostro indirizzo → incoming con importo corretto',
        () {
      final json = _txJson(
        vout: [_vout(3645814, _walletAddrs.first), _vout(1000, 'tb1qother...')],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.direction, TxDirection.incoming);
      expect(record.amountSats, 3645814);
      expect(record.txid, 'a' * 64);
      expect(record.feeSats, 51000);
      expect(record.confirmations, 1);
      expect(record.blockHeight, 149987);
      expect(record.isPending, isFalse);
      expect(record.timestamp, isNotNull);
    });

    test('tx con solo vin dal nostro indirizzo → outgoing', () {
      final json = _txJson(
        vin: [_vin(3700000, _walletAddrs.first)],
        vout: [_vout(3640000, 'tb1qdestinatario...')],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.direction, TxDirection.outgoing);
      expect(record.amountSats, 3700000);
    });

    test('tx mista (vin + change al nostro indirizzo) → netto corretto', () {
      // Spende 3.700.000 ma riceve 600.000 di change → netto −3.100.000 (out)
      final json = _txJson(
        vin: [_vin(3700000, _walletAddrs.first)],
        vout: [
          _vout(3100000, 'tb1qdestinatario...'),
          _vout(600000, _walletAddrs.first), // change
        ],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.direction, TxDirection.outgoing);
      expect(record.amountSats, 3100000);
    });

    test('coinbase (prevout null) → nessun crash, incoming se vout nostro', () {
      final json = _txJson(
        vin: [_vin(0, '', coinbase: true)],
        vout: [_vout(5000219525, _walletAddrs.first)],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.direction, TxDirection.incoming);
      expect(record.amountSats, 5000219525);
      expect(record.feeSats, 51000);
      // Coinbase CONFERMATA → non è orfana.
      expect(record.isOrphan, isFalse);
      expect(record.isPending, isFalse);
    });

    test('coinbase non confermata → orfana (blocco perso), NON pending', () {
      // PERCHÉ: blocco orfano perso per riorg/competizione → l'API Esplora lo
      // riporta con confirmed=false ma non è in attesa nel mempool: non si
      // confermerà mai. Deve essere marcato isOrphan e NON isPending.
      final json = _txJson(
        vin: [_vin(0, '', coinbase: true)],
        vout: [_vout(5000219525, _walletAddrs.first)],
        confirmed: false,
        blockHeight: null,
        blockTime: null,
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.isOrphan, isTrue);
      expect(record.isPending, isFalse);
      expect(record.confirmations, 0);
      expect(record.direction, TxDirection.incoming);
      expect(record.amountSats, 5000219525);
    });

    test('tx normale non confermata → pending, NON orfana', () {
      final json = _txJson(
        confirmed: false,
        blockHeight: null,
        blockTime: null,
        vout: [_vout(5000, _walletAddrs.first)],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.isPending, isTrue);
      expect(record.isOrphan, isFalse);
      expect(record.confirmations, 0);
    });

    test('pending (confirmed=false) → confirmations 0, blockHeight null', () {
      final json = _txJson(
        confirmed: false,
        blockHeight: null,
        blockTime: null,
        vout: [_vout(5000, _walletAddrs.first)],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.isPending, isTrue);
      expect(record.isOrphan, isFalse);
      expect(record.confirmations, 0);
      expect(record.blockHeight, isNull);
      expect(record.timestamp, isNull);
    });

    test('vout op_return (scriptpubkey_address vuoto) → ignorato', () {
      final json = _txJson(
        vout: [
          _vout(5000219525, _walletAddrs.first),
          {'value': 0, 'scriptpubkey_address': ''}, // op_return
        ],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.direction, TxDirection.incoming);
      expect(record.amountSats, 5000219525);
    });

    test('conferme reali con tipHeight (tip − height + 1)', () {
      final json = _txJson(blockHeight: 149987);

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
        tipHeight: 149990,
      );

      expect(record.confirmations, 4);
    });

    test('tx non appartenente al wallet → ignored (netto 0, incoming 0)', () {
      final json = _txJson(
        vout: [_vout(5000, 'tb1qcompletamente-estraneo...')],
        vin: [_vin(6000, 'tb1qaltroeestraneo...')],
      );

      final record = TransactionRecord.fromExplorerJson(
        json,
        walletAddresses: _walletAddrs,
      );

      expect(record.amountSats, 0);
      expect(record.direction, TxDirection.incoming);
    });
  });
}
