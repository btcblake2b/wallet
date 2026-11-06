import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/gap_scan_budget.dart';

void main() {
  group('GapScanBudgetCalculator (ADR 31/10-15)', () {
    const calc = GapScanBudgetCalculator();

    test('prima finestra: budget di partenza, non stimato da misure', () {
      final plan = calc.planFor(windowSize: 20);

      expect(plan.budget, const Duration(seconds: 30));
      expect(plan.estimated, isTrue);
      expect(plan.truncated, isFalse);
    });

    test('finestra 40 con explorer a 1 s/chiamata: budget adattivo 60 s', () {
      // PERCHÉ il difetto che chiude: con 30 s fissi la finestra 40 falliva
      // sempre con un explorer realistico (1 s/chiamata = 40 s). Il budget si
      // deriva dal throughput misurato (40 × 1 s × 1,5 = 60 s).
      final plan = calc.planFor(
        windowSize: 40,
        measuredPerCall: const Duration(seconds: 1),
      );

      expect(plan.budget, const Duration(seconds: 60));
      expect(plan.estimated, isFalse);
    });

    test('finestra 80 a 1 s/chiamata: 120 s (tetto per finestra)', () {
      final plan = calc.planFor(
        windowSize: 80,
        measuredPerCall: const Duration(seconds: 1),
      );

      expect(plan.budget, const Duration(seconds: 120));
      expect(plan.estimated, isFalse);
    });

    test('explorer veloce: budget più basso, non più alto', () {
      final plan = calc.planFor(
        windowSize: 40,
        measuredPerCall: const Duration(milliseconds: 400),
      );

      // 0,4 s/chiamata × 40 × 1,5 = 24 s
      expect(plan.budget, const Duration(seconds: 24));
    });

    test('il budget è tagliato dal tetto totale, non lo supera', () {
      final plan = calc.planFor(
        windowSize: 80,
        measuredPerCall: const Duration(seconds: 1),
        alreadySpent: const Duration(seconds: 160),
      );

      // Tetto totale 180 s − 160 s spesi = 20 s disponibili.
      expect(plan.budget, const Duration(seconds: 20));
      expect(plan.truncated, isTrue);
    });

    test('tetto totale esaurito: budget zero (nessuna estensione)', () {
      final plan = calc.planFor(
        windowSize: 80,
        alreadySpent: const Duration(seconds: 180),
      );

      expect(plan.budget, Duration.zero);
    });

    test('stima proporzionale: la finestra 40 non eredita i 30 s della 20', () {
      // PERCHÉ (ADR 31/10-16 §5): senza misura la stima scala con la finestra
      // (30 s × 40/20 = 60 s). Dare 30 s alla 40 peggiorerebbe il caso
      // «explorer lento» proprio quando si estende.
      for (final size in [40, 80]) {
        final plan = calc.planFor(windowSize: size);
        expect(plan.estimated, isTrue);
        expect(
          plan.budget,
          Duration(
            seconds: 30 * size ~/ GapScanBudgetCalculator.referenceWindow,
          ),
          reason: 'finestra $size',
        );
      }
    });

    test('mediana, non media: una chiamata lenta non regala budget', () {
      final median = GapScanBudgetCalculator.medianOf(const [
        Duration(milliseconds: 900),
        Duration(seconds: 5),
        Duration(milliseconds: 950),
      ]);

      expect(median, const Duration(milliseconds: 950));
      expect(GapScanBudgetCalculator.medianOf(const []), isNull);
      expect(
        GapScanBudgetCalculator.medianOf(const [
          Duration(milliseconds: 100),
          Duration(milliseconds: 300),
        ]),
        const Duration(milliseconds: 200),
      );
    });

    test('finestra minima: mai sotto il minimo per misure velocissime', () {
      final plan = calc.planFor(
        windowSize: 20,
        measuredPerCall: const Duration(milliseconds: 10),
      );

      expect(plan.budget, calc.minWindowBudget);
    });

    test('cap pratico 80, guardia algoritmica 200 (numeri distinti)', () {
      // PERCHÉ: chi legge l'ADR deve vedere la copertura reale. Oltre 80 non si
      // arriva con nessun explorer reale, quindi il numero che conta è 80.
      expect(GapScanBudgetCalculator.windows.last, 80);
      expect(GapScanBudgetCalculator.algorithmicCeiling, 200);
    });

    test('explorer lento: soglia per catena, 50% esatto non è lento', () {
      expect(
        GapScanBudgetCalculator.isExplorerTooSlow(probed: 9, requested: 20),
        isTrue,
      );
      // Confine dichiarato: esattamente metà NON è «lento» (soglia `< 0.5`).
      expect(
        GapScanBudgetCalculator.isExplorerTooSlow(probed: 10, requested: 20),
        isFalse,
      );
      expect(
        GapScanBudgetCalculator.isExplorerTooSlow(probed: 11, requested: 20),
        isFalse,
      );
      expect(
        GapScanBudgetCalculator.isExplorerTooSlow(probed: 20, requested: 20),
        isFalse,
      );
      expect(
        GapScanBudgetCalculator.isExplorerTooSlow(probed: 0, requested: 0),
        isFalse,
      );
    });
  });
}
