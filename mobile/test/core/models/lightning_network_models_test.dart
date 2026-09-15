import 'package:btc_blake2b_wallet/core/models/lightning_forward.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_network_node.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningNetworkNode', () {
    test('parse con indirizzi (forma reale del gossip)', () {
      final node = LightningNetworkNode.fromJson(const {
        'node_id':
            '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389',
        'alias': 'Paperclip Pool',
        'color': 'f56835',
        'last_timestamp': 1789321362,
        'features': '808898880a8a59a1',
        'addresses': [
          {'type': 'ipv4', 'address': '140.99.254.11', 'port': 9735},
          {'type': 'torv3', 'address': 'ob7.onion', 'port': 9735},
        ],
      });

      expect(node.displayName, 'Paperclip Pool');
      expect(node.colorHex, 'f56835');
      expect(node.addresses, hasLength(2));
      expect(node.addresses.first.label, '140.99.254.11:9735');
      expect(node.addresses.last.type, 'torv3');
    });

    test('senza alias → id troncato come nome', () {
      final node = LightningNetworkNode.fromJson(const {
        'node_id':
            '021f62aeda679b26935308a9f62434949ee3a2fec8e6e3cbc920a3754d63889374',
      });

      expect(node.alias, isNull);
      expect(node.displayName, '021f62aeda679b26…');
      expect(node.addresses, isEmpty);
    });

    test('alias vuoto → id troncato', () {
      final node = LightningNetworkNode.fromJson(const {
        'node_id': '02aa',
        'alias': '   ',
      });

      expect(node.displayName, '02aa');
    });
  });

  group('LightningRoute', () {
    test('rotta a due hop: fee e delay dal primo hop', () {
      final route = LightningRoute.fromJson(const {
        'route': [
          {
            'id': '02aa',
            'channel': '100x1x1',
            'direction': 0,
            'amount_msat': 1010000,
            'delay': 20,
            'style': 'tlv',
          },
          {
            'id': '02bb',
            'channel': '200x1x0',
            'direction': 1,
            'amount_msat': 1000000,
            'delay': 9,
          },
        ],
        'fee_msat': 10000,
        'total_delay': 20,
      });

      expect(route.isEmpty, isFalse);
      expect(route.hops, hasLength(2));
      expect(route.feeSats, 10);
      expect(route.totalDelay, 20);
      expect(route.hops.first.amountSats, 1010);
      expect(route.hops.last.channel, '200x1x0');
      expect(route.hops.last.shortId, '02bb');
    });

    test('rotta vuota (nessun percorso) → isEmpty', () {
      final route = LightningRoute.fromJson(const {'route': []});

      expect(route.isEmpty, isTrue);
      expect(route.feeMsat, 0);
      expect(route.totalDelay, isNull);
    });
  });

  group('LightningForward', () {
    test('forward settled con fee', () {
      final f = LightningForward.fromJson(const {
        'in_channel': '1000x1x0',
        'out_channel': '1001x2x0',
        'in_msat': 2000000,
        'out_msat': 1999000,
        'fee_msat': 1000,
        'status': 'settled',
        'received_time': 1789364186,
        'resolved_time': 1789364187,
      });

      expect(f.inSats, 2000);
      expect(f.feeSats, 1);
      expect(f.isSettled, isTrue);
      expect(f.isFailed, isFalse);
      expect(f.resolvedTime, 1789364187);
    });

    test('forward non risolto: nessuna fee, campi opzionali assenti', () {
      final f = LightningForward.fromJson(const {
        'in_msat': 0,
        'out_msat': 0,
        'status': 'failed',
      });

      expect(f.feeMsat, isNull);
      expect(f.feeSats, isNull);
      expect(f.inChannel, isNull);
      expect(f.isFailed, isTrue);
      expect(f.receivedTime, isNull);
    });
  });
}
