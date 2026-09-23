import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/utils/cln_release_utils.dart';

/// Riconoscimento del gate di peering dalla versione del nodo.
///
/// // PERCHÉ (P8): un falso positivo mostrerebbe un avviso all'utente quando
/// non serve; un falso negativo lo lascerebbe senza spiegazione. Entrambi i
/// lati sono coperti qui, incluse le versioni che NON sappiamo leggere.
void main() {
  group('parsePeeringGate', () {
    test('release del fork con gate (>= .4) → bit68', () {
      expect(
        parsePeeringGate('v26.06.7-blake2b.4'),
        ClnPeeringGate.bit68,
      );
      // Versione reale letta sul nodo di test il 2026-09-16.
      expect(
        parsePeeringGate('v26.06.7-blake2b.4'),
        ClnPeeringGate.bit68,
      );
    });

    test('release con numero a più cifre → bit68 (.10)', () {
      expect(
        parsePeeringGate('v26.06.7-blake2b.10'),
        ClnPeeringGate.bit68,
      );
    });

    test('release precedenti al gate (.2, .3) → none', () {
      expect(parsePeeringGate('v26.06.7-blake2b.2'), ClnPeeringGate.none);
      expect(parsePeeringGate('v26.06.7-blake2b.3'), ClnPeeringGate.none);
    });

    test('versione non-fork (upstream) → unknown', () {
      expect(parsePeeringGate('26.06.7'), ClnPeeringGate.unknown);
      expect(parsePeeringGate('v26.06.7'), ClnPeeringGate.unknown);
    });

    test('versione di un nodo non-CLN (dln) → unknown', () {
      expect(parsePeeringGate('v0.1.0'), ClnPeeringGate.unknown);
    });

    test('versione assente o vuota → unknown', () {
      expect(parsePeeringGate(null), ClnPeeringGate.unknown);
      expect(parsePeeringGate(''), ClnPeeringGate.unknown);
    });
  });

  group('clnRequiresBit68', () {
    test('true solo per le release con gate', () {
      expect(clnRequiresBit68('v26.06.7-blake2b.4'), isTrue);
      expect(clnRequiresBit68('v26.06.7-blake2b.3'), isFalse);
    });

    test('unknown non è "gate assente": nessun avviso', () {
      expect(clnRequiresBit68(null), isFalse);
      expect(clnRequiresBit68('v0.1.0'), isFalse);
    });
  });
}
