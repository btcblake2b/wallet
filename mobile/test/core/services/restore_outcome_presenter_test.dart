import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/gap_window_policy.dart';
import 'package:btc_blake2b_wallet/core/services/restore_outcome_presenter.dart';
import 'package:btc_blake2b_wallet/core/services/restore_scanner.dart';

RestoreScanResult _result({
  required GapWindowOutcome outcome,
  int probed = 20,
  int requested = 20,
  int? scannedIndex,
  int unreachable = 0,
}) {
  return RestoreScanResult(
    outcome: outcome,
    probed: probed,
    derived: requested,
    requested: requested,
    unreachable: unreachable,
    lastPhaseBudgetEstimated: false,
    scannedIndex: scannedIndex,
  );
}

void main() {
  group('RestoreOutcomePresenter (ADR 02/11-28 §3, 02/11-29 §6)', () {
    test('gapFound ⇒ indice, non una frazione', () {
      final label = RestoreOutcomePresenter.labelFor(
        _result(
          outcome: GapWindowOutcome.gapFound,
          probed: 25,
          requested: 40,
          scannedIndex: 24,
        ),
      );

      expect(label, isA<RestoreGapFound>());
      expect((label as RestoreGapFound).lastUsedIndex, 24);
    });

    test('unreachable a 20/20 ⇒ INTERROTTA, mai «parziale»', () {
      // PERCHÉ: il budget può scadere sull'ultimo check, quindi `probed ==
      // requested` non significa concluso. Con un messaggio «X/Y» l'utente
      // leggerebbe «fatto» mentre l'esito è «riprova».
      final label = RestoreOutcomePresenter.labelFor(
        _result(
          outcome: GapWindowOutcome.unreachable,
          probed: 20,
          requested: 20,
          unreachable: 1,
        ),
      );

      expect(label, isA<RestoreGapInterrupted>());
      final interrupted = label as RestoreGapInterrupted;
      expect(interrupted.probed, 20);
      expect(interrupted.requested, 20);
    });

    test('gapExhausted ⇒ parziale (riprovare non cambia l\'esito)', () {
      final label = RestoreOutcomePresenter.labelFor(
        _result(
          outcome: GapWindowOutcome.gapExhausted,
          probed: 80,
          requested: 80,
        ),
      );

      expect(label, isA<RestoreGapPartial>());
      expect((label as RestoreGapPartial).requested, 80);
    });

    test('gapNotEstablished ⇒ parziale', () {
      final label = RestoreOutcomePresenter.labelFor(
        _result(
          outcome: GapWindowOutcome.gapNotEstablished,
          probed: 12,
          requested: 20,
        ),
      );

      expect(label, isA<RestoreGapPartial>());
    });

    test('lo switch sui tre tipi è esaustivo (garanzia di compilazione)', () {
      // Se un domani nasce un quarto esito, questo switch non compila: è il
      // modo per far rompere il compilatore invece dell'utente.
      String describe(RestoreOutcomeLabel label) => switch (label) {
            RestoreGapFound(:final lastUsedIndex) => 'found:$lastUsedIndex',
            RestoreGapPartial(:final probed) => 'partial:$probed',
            RestoreGapInterrupted(:final probed) => 'interrupted:$probed',
          };

      expect(
        describe(
          RestoreOutcomePresenter.labelFor(
            _result(outcome: GapWindowOutcome.gapFound, scannedIndex: 0),
          ),
        ),
        'found:0',
      );
    });

    test('gapFound senza indice viola l\'invariante del costruttore', () {
      // PERCHÉ: un esito conclusivo senza indice non è utilizzabile; meglio
      // un'asserzione in sviluppo che un `null` che arriva alla UI.
      expect(
        () => _result(outcome: GapWindowOutcome.gapFound),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
