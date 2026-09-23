import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Politica delle fee (18/09/2026): il tier di ALTA priorità non deve mai
/// scendere sotto il pavimento di rete — su questa chain le stime collassano al
/// minimo di relay (1 sat/vB) e senza pavimento "Alta" non darebbe priorità.
void main() {
  final floor = BitcoinNetworkConfig.priorityFeeFloorSatVb;

  test('il pavimento è il tier high del fallback di rete (blake2b: 3 sat/vB)',
      () {
    expect(floor, BitcoinNetworkConfig.fallbackFeeEstimates.high);
    expect(floor, greaterThan(1));
  });

  test('mercato al minimo (tutti i tier a 1) → priority usa il pavimento', () {
    final e = FeeEstimates(lowSatVb: 1, normalSatVb: 1, highSatVb: 1);
    expect(e.prioritySatVb, floor);
    expect(e.prioritySatVb, greaterThan(e.highSatVb));
  });

  test('mercato alto (stima sopra il pavimento) → priority usa la stima', () {
    final e = FeeEstimates(lowSatVb: 5, normalSatVb: 9, highSatVb: 12);
    expect(e.prioritySatVb, 12);
  });
}
