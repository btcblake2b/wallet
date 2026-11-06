import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/gap_window_policy.dart';

void main() {
  group('GapWindowEvaluator (ADR 31/10-16)', () {
    List<AddressCheck> window({required int used, required int total}) {
      return List<AddressCheck>.generate(
        total,
        (i) => i < used ? AddressCheck.used : AddressCheck.unused,
      );
    }

    test('gap trovato: 20 consecutive non usate', () {
      final result = GapWindowEvaluator.evaluate(
        checks: window(used: 5, total: 40),
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.gapStartIndex, 5);
      expect(result.probed, 40);
    });

    test('MERCHANT 30 incassi: finestra 40 non conclude, serve estendere', () {
      // PERCHÉ (ADR 31/10-16 §1): 30 usate + 10 libere in fondo non sono «tutte
      // usate» (gapExhausted) né un gap valido. Senza questo caso la finestra
      // non si estendeva e lo stato restava non classificato.
      final window40 = GapWindowEvaluator.evaluate(
        checks: window(used: 30, total: 40),
        startIndex: 0,
      );

      expect(window40.outcome, GapWindowOutcome.gapNotEstablished);
      expect(GapWindowEvaluator.needsExtension(window40.outcome), isTrue);

      // Finestra 80: dal 30 in poi ci sono 50 libere → gap a 30.
      final window80 = GapWindowEvaluator.evaluate(
        checks: window(used: 30, total: 80),
        startIndex: 0,
      );

      expect(window80.outcome, GapWindowOutcome.gapFound);
      expect(window80.gapStartIndex, 30);
    });

    test('estesa e ancora senza gap: resta da estendere', () {
      // 65 usate su 80, 15 libere → meno di 20 consecutive.
      final result = GapWindowEvaluator.evaluate(
        checks: window(used: 65, total: 80),
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.gapNotEstablished);
    });

    test('tutte usate: gapExhausted (sotto-caso con messaggio dedicato)', () {
      final result = GapWindowEvaluator.evaluate(
        checks: window(used: 40, total: 40),
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.gapExhausted);
    });

    test('timeout a inizio finestra: NON diventa un gap (fail-closed)', () {
      // PERCHÉ: con un seam `bool` questi 20 timeout sarebbero «non usate» e
      // produrrebbero un indice 0 → reuse. Devono restare inconcludenti.
      final checks = List<AddressCheck>.filled(20, AddressCheck.unreachable);

      final result = GapWindowEvaluator.evaluate(
        checks: checks,
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.unreachable);
      expect(result.gapStartIndex, isNull);
      expect(result.probed, 0);
      expect(result.unreachable, 20);
    });

    test('anche UN solo timeout impedisce di concludere', () {
      final checks = window(used: 0, total: 20)
        ..[10] = AddressCheck.unreachable;

      final result = GapWindowEvaluator.evaluate(
        checks: checks,
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.unreachable);
      expect(result.probed, 19);
      expect(result.probedFraction, closeTo(19 / 20, 1e-9));
    });

    test('gap trovato VINCE sui timeout (dati sufficienti)', () {
      // 25 posizioni libere consecutive PRIMA del timeout: il gap c'è, il
      // timeout su una posizione successiva non cambia la conclusione.
      final checks = List<AddressCheck>.generate(
        40,
        (i) => i == 30 ? AddressCheck.unreachable : AddressCheck.unused,
      );

      final result = GapWindowEvaluator.evaluate(
        checks: checks,
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.gapStartIndex, 0);
    });

    test('BUG: timeout PRIMA del run ⇒ NON è gapFound (indice non inventato)',
        () {
      // PERCHÉ (ADR 31/10-17 §1): 0-19 timeout, 20-39 libere. Riportare 20
      // significherebbe saltare 20 indirizzi mai usati: il vero indice è 0 (o
      // 11, se 0-10 fossero usate). Con dati incompleti non si conclude.
      final checks = <AddressCheck>[
        ...List<AddressCheck>.filled(20, AddressCheck.unreachable),
        ...List<AddressCheck>.filled(20, AddressCheck.unused),
      ];

      final result = GapWindowEvaluator.evaluate(
        checks: checks,
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.unreachable);
      expect(result.gapStartIndex, isNull);
      expect(result.unreachable, 20);
      expect(result.probed, 20);
    });

    test('used sporadico prima del run: gapFound ancora valido', () {
      // Il vincolo è «nessun unreachable prima», non «nessun used».
      final checks = <AddressCheck>[
        AddressCheck.used,
        AddressCheck.used,
        ...List<AddressCheck>.filled(20, AddressCheck.unused),
      ];

      final result = GapWindowEvaluator.evaluate(
        checks: checks,
        startIndex: 0,
      );

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.gapStartIndex, 2);
    });

    test('indice globale: la finestra 40 riporta l\'indice assoluto', () {
      final result = GapWindowEvaluator.evaluate(
        checks: window(used: 12, total: 40),
        startIndex: 40,
      );

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.gapStartIndex, 52);
    });

    test('finestra vuota: nessun gap, nessun timeout → non concluso', () {
      final result =
          GapWindowEvaluator.evaluate(checks: const [], startIndex: 0);

      expect(result.outcome, GapWindowOutcome.gapExhausted);
      expect(result.probedFraction, 0);
    });
  });
}
