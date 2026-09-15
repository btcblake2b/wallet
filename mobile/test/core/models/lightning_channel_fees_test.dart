import 'package:btc_blake2b_wallet/core/models/lightning_channel_fees.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningChannelFees', () {
    test('parse completo con unità convertite in sat', () {
      final f = LightningChannelFees.fromJson(const {
        'id': 'ch1',
        'short_channel_id': '1000x1x0',
        'fee_base_msat': 2000,
        'fee_proportional_millionths': 25,
        'htlc_min_msat': 1000,
        'htlc_max_msat': 150000000,
        'cltv_delta': 34,
        'our_reserve_msat': 1500000,
        'their_reserve_msat': 1600000,
        'to_self_delay': 144,
      });

      expect(f.id, 'ch1');
      expect(f.shortChannelId, '1000x1x0');
      expect(f.feeBaseSats, 2);
      expect(f.feePpm, 25);
      expect(f.htlcMinSats, 1);
      expect(f.htlcMaxSats, 150000);
      expect(f.cltvDelta, 34);
      expect(f.reserveSats, 1500);
      expect(f.toSelfDelay, 144);
      expect(f.warning, isNull);
    });

    test('warning del nodo esposto alla UI', () {
      final f = LightningChannelFees.fromJson(const {
        'id': 'ch1',
        'warning': 'htlcmin raised by peer',
      });
      expect(f.warning, 'htlcmin raised by peer');
    });

    test('campi mancanti → default sicuri', () {
      final f = LightningChannelFees.fromJson(const {});

      expect(f.id, '');
      expect(f.feeBaseMsat, 0);
      expect(f.feePpm, 0);
      expect(f.htlcMinSats, isNull);
      expect(f.htlcMaxSats, isNull);
      expect(f.cltvDelta, isNull);
      expect(f.reserveSats, isNull);
      expect(f.toSelfDelay, isNull);
    });
  });
}
