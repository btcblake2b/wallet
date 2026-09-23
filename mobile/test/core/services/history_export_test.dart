import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';
import 'package:btc_blake2b_wallet/core/services/export/history_export.dart';

TransactionRecord _tx({
  String txid = 'tx1',
  TxDirection direction = TxDirection.incoming,
  int amountSats = 100000,
  int? feeSats,
  int confirmations = 3,
  int? blockHeight = 150000,
  DateTime? timestamp,
  bool isOrphan = false,
  bool isEvicted = false,
}) {
  return TransactionRecord(
    txid: txid,
    direction: direction,
    amountSats: amountSats,
    feeSats: feeSats,
    confirmations: confirmations,
    blockHeight: blockHeight,
    timestamp: timestamp,
    isOrphan: isOrphan,
    isEvicted: isEvicted,
  );
}

void main() {
  group('buildHistoryCsv', () {
    test('intestazione stabile e riga completa', () {
      final csv = buildHistoryCsv(<TransactionRecord>[
        _tx(
          feeSats: 500,
          timestamp: DateTime.utc(2026, 9, 23, 10, 30),
        ),
      ]);

      expect(
        csv,
        'date_iso,status,direction,amount_sats,fee_sats,confirmations,'
        'block_height,txid,note\r\n'
        '2026-09-23T10:30:00.000Z,confirmed,incoming,100000,500,3,150000,'
        'tx1,\r\n',
      );
    });

    test('lista vuota → sola intestazione con terminatore', () {
      expect(
        buildHistoryCsv(const <TransactionRecord>[]),
        '${kHistoryCsvHeader.join(',')}\r\n',
      );
    });

    test('campi ignoti restano vuoti (data, fee, altezza)', () {
      final csv = buildHistoryCsv(<TransactionRecord>[
        _tx(confirmations: 0, blockHeight: null),
      ]);

      // tx pending senza timestamp: data/fee/altezza vuoti, stato pending.
      expect(csv.split('\r\n')[1], ',pending,incoming,100000,,0,,tx1,');
    });

    test('escapa virgole, virgolette e a capo nelle note', () {
      final csv = buildHistoryCsv(
        <TransactionRecord>[_tx()],
        noteFor: (txid) => 'caffe, "bar"\ne altro',
      );

      expect(csv, contains('"caffe, ""bar""\ne altro"'));
    });

    test('include la nota utente per txid', () {
      final csv = buildHistoryCsv(
        <TransactionRecord>[_tx(txid: 'tx-9')],
        noteFor: (txid) => txid == 'tx-9' ? 'affitto' : null,
      );

      expect(csv.trim().endsWith('tx-9,affitto'), isTrue);
    });

    test('tx in uscita → direction outgoing', () {
      final csv = buildHistoryCsv(<TransactionRecord>[
        _tx(direction: TxDirection.outgoing, feeSats: 210),
      ]);

      expect(csv, contains('confirmed,outgoing,100000,210,'));
    });
  });

  group('buildHistoryJson', () {
    test('payload completo con chiavi stabili', () {
      final json = buildHistoryJson(
        <TransactionRecord>[
          _tx(
            txid: 'txA',
            feeSats: 120,
            timestamp: DateTime.utc(2026, 9, 23, 8),
          ),
        ],
        walletName: 'Risparmi',
        exportedAt: DateTime.utc(2026, 9, 23, 12),
        noteFor: (txid) => txid == 'txA' ? 'nota' : null,
      );

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['wallet'], 'Risparmi');
      expect(decoded['network'], 'bitcoin-blake2b');
      expect(decoded['exported_at'], '2026-09-23T12:00:00.000Z');
      expect(decoded['count'], 1);

      final tx = (decoded['transactions'] as List<dynamic>).single
          as Map<String, dynamic>;
      expect(tx['txid'], 'txA');
      expect(tx['status'], 'confirmed');
      expect(tx['direction'], 'incoming');
      expect(tx['amount_sats'], 100000);
      expect(tx['fee_sats'], 120);
      expect(tx['confirmations'], 3);
      expect(tx['block_height'], 150000);
      expect(tx['note'], 'nota');
    });

    test('valori ignoti → null, non stringa vuota', () {
      final decoded = jsonDecode(
        buildHistoryJson(
          <TransactionRecord>[_tx(confirmations: 0, blockHeight: null)],
          walletName: 'w',
          exportedAt: DateTime.utc(2026),
        ),
      ) as Map<String, dynamic>;

      final tx = (decoded['transactions'] as List<dynamic>).single
          as Map<String, dynamic>;
      expect(tx['fee_sats'], isNull);
      expect(tx['block_height'], isNull);
      expect(tx['date_iso'], isNull);
      expect(tx['note'], isNull);
      expect(tx['status'], 'pending');
    });

    test('lista vuota → transactions vuoto e count 0', () {
      final decoded = jsonDecode(
        buildHistoryJson(
          const <TransactionRecord>[],
          walletName: 'w',
          exportedAt: DateTime.utc(2026),
        ),
      ) as Map<String, dynamic>;

      expect(decoded['count'], 0);
      expect(decoded['transactions'], isEmpty);
    });
  });

  group('historyFileName', () {
    test('nome deterministico da un nome wallet con spazi e accenti', () {
      expect(
        historyFileName(
          'Portafoglio E di Luca',
          json: false,
          now: DateTime.utc(2026, 9, 23, 7, 5),
        ),
        'btc-blake2b-portafoglio-e-di-luca-20260923-0705.csv',
      );
      expect(
        historyFileName(
          'Risparmi',
          json: true,
          now: DateTime.utc(2026, 9, 23, 7, 5),
        ),
        'btc-blake2b-risparmi-20260923-0705.json',
      );
    });

    test('nome non latinizzabile → fallback wallet', () {
      expect(slugifyWalletName('***'), 'wallet');
      expect(slugifyWalletName('   '), 'wallet');
      expect(slugifyWalletName('  Il Mio Wallet  '), 'il-mio-wallet');
    });
  });

  group('historyExportStatus', () {
    test('mappa i quattro stati in forma stabile', () {
      expect(historyExportStatus(_tx()), 'confirmed');
      expect(
        historyExportStatus(_tx(confirmations: 0, blockHeight: null)),
        'pending',
      );
      expect(
        historyExportStatus(
          _tx(confirmations: 0, blockHeight: null, isOrphan: true),
        ),
        'orphan',
      );
      expect(
        historyExportStatus(
          _tx(confirmations: 0, blockHeight: null, isEvicted: true),
        ),
        'evicted',
      );
    });
  });
}
