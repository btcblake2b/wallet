import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/utils/cln_release_utils.dart';

/// Riconoscimento del gate di peering dalla versione del nodo.
///
/// // PERCHÉ (P8): un falso positivo mostrerebbe un avviso all'utente quando
/// non serve; un falso negativo lo lascerebbe senza spiegazione. Entrambi i
/// lati sono coperti qui, incluse le versioni che NON sappiamo leggere.
void main() {
  group('parsePeeringGate', () {
    test('release .4 → gate del bit 68', () {
      // Versione reale letta sul nodo di test il 2026-09-16.
      expect(parsePeeringGate('v26.06.7-blake2b.4'), ClnPeeringGate.bit68);
    });

    test('release .5 (bit 512/514) → gate della numerazione nuova', () {
      // Versione reale letta sul nodo di test il 2026-09-30 (upgrade `.5`).
      expect(parsePeeringGate('v26.06.8-blake2b.5'), ClnPeeringGate.newBits);
    });

    test('release successive (.6, .10) → sempre numerazione nuova', () {
      expect(parsePeeringGate('v26.06.8-blake2b.6'), ClnPeeringGate.newBits);
      expect(parsePeeringGate('v26.06.8-blake2b.10'), ClnPeeringGate.newBits);
    });

    test('confine: `.4` è bit68 e `.5` è newBits (mai il contrario)', () {
      expect(
        parsePeeringGate('v26.06.7-blake2b.4'),
        isNot(ClnPeeringGate.newBits),
      );
      expect(
        parsePeeringGate('v26.06.8-blake2b.5'),
        isNot(ClnPeeringGate.bit68),
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

  group('clnHasPeeringGate', () {
    test('true per entrambe le generazioni di gate', () {
      expect(clnHasPeeringGate('v26.06.7-blake2b.4'), isTrue);
      expect(clnHasPeeringGate('v26.06.8-blake2b.5'), isTrue);
    });

    test('false per le release precedenti al gate', () {
      expect(clnHasPeeringGate('v26.06.7-blake2b.3'), isFalse);
    });

    test('unknown non è "gate assente": nessun avviso', () {
      expect(clnHasPeeringGate(null), isFalse);
      expect(clnHasPeeringGate('v0.1.0'), isFalse);
    });
  });

  group('parseSpliceSupport', () {
    test('release .2/.5 → splice non disponibile', () {
      expect(parseSpliceSupport('v26.06.7-blake2b.2'), ClnSpliceSupport.unavailable);
      expect(parseSpliceSupport('v26.06.8-blake2b.5'), ClnSpliceSupport.unavailable);
    });

    test('release .6 (prima release con lo splice) → outdated', () {
      expect(parseSpliceSupport('v26.06.8-blake2b.6'), ClnSpliceSupport.outdated);
    });

    test('release .7/.8 → splice ok ma senza i fix di sicurezza', () {
      expect(parseSpliceSupport('v26.06.9-blake2b.7'), ClnSpliceSupport.outdated);
      expect(parseSpliceSupport('v26.06.9-blake2b.8'), ClnSpliceSupport.outdated);
    });

    test('release .9 e successive (anche .10) → safe', () {
      expect(parseSpliceSupport('v26.06.9-blake2b.9'), ClnSpliceSupport.safe);
      expect(parseSpliceSupport('v26.06.9-blake2b.10'), ClnSpliceSupport.safe);
    });

    test('confine: `.5` non è outdated e `.6` non è unavailable', () {
      expect(
        parseSpliceSupport('v26.06.8-blake2b.5'),
        isNot(ClnSpliceSupport.outdated),
      );
      expect(
        parseSpliceSupport('v26.06.8-blake2b.6'),
        isNot(ClnSpliceSupport.unavailable),
      );
    });

    test('versione non riconoscibile → unknown (nessun avviso)', () {
      expect(parseSpliceSupport(null), ClnSpliceSupport.unknown);
      expect(parseSpliceSupport(''), ClnSpliceSupport.unknown);
      expect(parseSpliceSupport('v0.1.0'), ClnSpliceSupport.unknown);
    });
  });
}
