import 'package:btc_blake2b_wallet/core/models/lightning_node_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningNodeStats', () {
    test('parse completo: netto, tag e plugin', () {
      final stats = LightningNodeStats.fromJson(const {
        'net_msat': 34382000,
        'credits_msat': 35606000,
        'debits_msat': 1224000,
        'tags': [
          {
            'tag': 'deposit',
            'credit_msat': 35606000,
            'debit_msat': 0,
            'entries': 2,
          },
          {
            'tag': 'invoice',
            'credit_msat': 0,
            'debit_msat': 1000000,
            'entries': 1,
          },
        ],
        'plugins': [
          {'name': 'keysend', 'active': true, 'dynamic': false},
          {'name': 'bookkeeper', 'active': true, 'dynamic': false},
          {'name': 'liquidity-ads', 'active': false, 'dynamic': true},
        ],
        'forward_count': 0,
      });

      expect(stats.netMsat, 34382000);
      expect(stats.netSats, 34382);
      expect(stats.creditsMsat, 35606000);
      expect(stats.debitsMsat, 1224000);
      expect(stats.tags, hasLength(2));
      expect(stats.tags.first.tag, 'deposit');
      expect(stats.tags.first.netSats, 35606);
      expect(stats.tags.first.entries, 2);
      // Il tag in uscita ha netto negativo.
      expect(stats.tags.last.netMsat, -1000000);
      expect(stats.plugins, hasLength(3));
      expect(stats.activePluginCount, 2);
      expect(stats.plugins.last.name, 'liquidity-ads');
      expect(stats.plugins.last.active, isFalse);
      expect(stats.plugins.last.isDynamic, isTrue);
      expect(stats.forwardCount, 0);
    });

    test('campi mancanti → default sicuri', () {
      final stats = LightningNodeStats.fromJson(const {});

      expect(stats.netMsat, 0);
      expect(stats.tags, isEmpty);
      expect(stats.plugins, isEmpty);
      expect(stats.activePluginCount, 0);
      expect(stats.forwardCount, 0);
    });

    test('tag ignoto conservato grezzo (nessuna etichetta inventata)', () {
      final stats = LightningNodeStats.fromJson(const {
        'tags': [
          {'tag': 'something_new', 'credit_msat': 1000, 'entries': 1},
        ],
      });

      expect(stats.tags.single.tag, 'something_new');
      expect(stats.tags.single.netSats, 1);
    });

    test('tag senza nome → unknown', () {
      final stats = LightningNodeStats.fromJson(const {
        'tags': [
          {'credit_msat': 1000, 'entries': 1},
        ],
      });

      expect(stats.tags.single.tag, 'unknown');
    });
  });
}
