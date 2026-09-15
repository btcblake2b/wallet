import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_peer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningChannel — unità msat → sat', () {
    test('converte capacità e saldi da msat a sat', () {
      // PERCHÉ: bug storico — i msat del protocollo venivano mostrati come sat
      // (16.000.000 invece di 16.000). I getter *Sats sono la barriera: qui il
      // test li blinda, così una regressione si vede subito.
      final c = LightningChannel.fromJson(const {
        'id': 'ch1',
        'capacity': 16000000,
        'local_balance': 9000000,
        'remote_balance': 7000000,
        'state': 'Usable',
      });

      expect(c.capacitySats, 16000);
      expect(c.localBalanceSats, 9000);
      expect(c.remoteBalanceSats, 7000);
      expect(c.capacity, 16000000); // il modello conserva i msat originali
    });

    test('mappa i campi additivi di I2 (alias, fee, htlc, stato peer)', () {
      final c = LightningChannel.fromJson(const {
        'id': 'ch1',
        'peer_pubkey': '02aa',
        'alias': 'peer-one',
        'state': 'Usable',
        'capacity': 100000000,
        'local_balance': 50000000,
        'remote_balance': 50000000,
        'fee_base_msat': 1000,
        'fee_proportional_millionths': 250,
        'htlc_count': 2,
        'spendable_msat': 49000000,
        'receivable_msat': 48000000,
        'peer_connected': true,
        'status': ['CHANNELD_NORMAL:Funding transaction locked.'],
      });

      expect(c.peerLabel, 'peer-one');
      expect(c.feeBaseMsat, 1000);
      expect(c.feeBaseSats, 1);
      expect(c.feePpm, 250);
      expect(c.htlcCount, 2);
      expect(c.spendableSats, 49000);
      expect(c.receivableSats, 48000);
      expect(c.peerConnected, isTrue);
      expect(c.isUsable, isTrue);
      expect(c.status, hasLength(1));
      expect(c.status!.first, contains('CHANNELD_NORMAL'));
    });

    test('campi mancanti → default sicuri (nessuna eccezione)', () {
      final c = LightningChannel.fromJson(const {});

      expect(c.id, '');
      expect(c.state, 'Unknown');
      expect(c.isUsable, isFalse);
      expect(c.capacitySats, 0);
      expect(c.peerLabel, isNull);
      expect(c.feeBaseSats, isNull);
      expect(c.spendableSats, isNull);
      expect(c.receivableSats, isNull);
      expect(c.peerConnected, isNull);
      expect(c.status, isNull);
    });

    test('alias vuoto → null (la UI usa la pubkey abbreviata)', () {
      final c = LightningChannel.fromJson(const {
        'id': 'ch1',
        'alias': '',
        'state': 'Usable',
      });

      expect(c.peerAlias, isNull);
      expect(c.peerLabel, isNull);
    });
  });

  group('LightningPeer', () {
    test('mappa i campi di list_peers', () {
      final p = LightningPeer.fromJson(const {
        'id': '02dd',
        'alias': 'peer-one',
        'connected': true,
        'num_channels': 3,
        'addresses': ['140.99.254.11:9735', 'abcd.onion:9735'],
        'remote_addr': '1.2.3.4:1691',
      });

      expect(p.id, '02dd');
      expect(p.label, 'peer-one');
      expect(p.connected, isTrue);
      expect(p.numChannels, 3);
      expect(p.addresses, hasLength(2));
      expect(p.addresses.first, '140.99.254.11:9735');
      expect(p.remoteAddr, '1.2.3.4:1691');
    });

    test('peer senza alias → label = pubkey (id)', () {
      final p = LightningPeer.fromJson(const {
        'id': '03ee',
        'alias': '',
        'connected': false,
      });

      expect(p.alias, isNull);
      expect(p.label, '03ee');
    });

    test('campi mancanti → default sicuri', () {
      final p = LightningPeer.fromJson(const {});

      expect(p.id, '');
      expect(p.alias, isNull);
      expect(p.connected, isFalse);
      expect(p.numChannels, 0);
      expect(p.addresses, isEmpty);
      expect(p.remoteAddr, isNull);
    });
  });
}
