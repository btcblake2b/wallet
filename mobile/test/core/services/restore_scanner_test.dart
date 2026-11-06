import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/gap_scan_budget.dart';
import 'package:btc_blake2b_wallet/core/services/gap_window_policy.dart';
import 'package:btc_blake2b_wallet/core/services/restore_scanner.dart';

/// Stopwatch finto: il tempo avanza solo quando lo si chiede esplicitamente.
class _FakeStopwatch implements Stopwatch {
  Duration _elapsed = Duration.zero;
  bool _running = false;
  Duration? _nextStep;

  void expireAfter(Duration step) => _nextStep = step;

  @override
  Duration get elapsed {
    // Il tempo avanza PRIMA di essere letto: così `expireAfter(31s)` rende il
    // budget già scaduto al primo controllo, e `expireAfter(2s)` lo fa scadere
    // progressivamente (2, 4, 6, … 30).
    if (_running && _nextStep != null) {
      _elapsed += _nextStep!;
    }
    return _elapsed;
  }

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;

  @override
  void reset() => _elapsed = Duration.zero;

  @override
  bool get isRunning => _running;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => 0;

  @override
  int get frequency => 1000;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Calcolatore che registra il `measuredPerCall` ricevuto: serve a verificare
/// che il wiring del budget adattivo esista davvero (ADR 31/10-20 §1).
class _RecordingBudget extends GapScanBudgetCalculator {
  _RecordingBudget() : super();

  final List<Duration?> received = <Duration?>[];
  final List<bool> estimated = <bool>[];

  @override
  GapScanWindowPlan planFor({
    required int windowSize,
    Duration? measuredPerCall,
    Duration alreadySpent = Duration.zero,
  }) {
    received.add(measuredPerCall);
    final plan = super.planFor(
      windowSize: windowSize,
      measuredPerCall: measuredPerCall,
      alreadySpent: alreadySpent,
    );
    estimated.add(plan.estimated);
    return plan;
  }
}

void main() {
  group('RestoreScanner (ADR 31/10-18/19)', () {
    /// Sonda deterministica: [usedUntil] posizioni usate, poi libere.
    AddressCheckProbe probeUsedUntil(int usedUntil) {
      return (int index) async =>
          index < usedUntil ? AddressCheck.used : AddressCheck.unused;
    }

    test('gap a 5: probed 25, derived 60 (early-stop dentro la fase 40)',
        () async {
      final scanner = RestoreScanner(probe: probeUsedUntil(5));

      final result = await scanner.scan();

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.scannedIndex, 5);
      expect(result.probed, 25);
      // Finestra cumulativa: fase 2 = 40 indirizzi derivati.
      expect(result.derived, 40);
      expect(result.requested, 40);
    });

    test('gap a 0: early-stop immediato, un solo blocco da 20', () async {
      final scanner = RestoreScanner(probe: probeUsedUntil(0));

      final result = await scanner.scan();

      expect(result.scannedIndex, 0);
      expect(result.probed, 20);
      expect(result.derived, 20);
    });

    test('merchant 30 incassi: estende a 40 e trova il gap a 30', () async {
      final scanner = RestoreScanner(probe: probeUsedUntil(30));

      final result = await scanner.scan();

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.scannedIndex, 30);
      // 20 (fase 1) + 20 (fase 2) + 10 dentro la fase 3 = 50 check.
      expect(result.probed, 50);
      expect(result.derived, 80);
      expect(result.requested, 80);
    });

    test('timeout PRIMA del run: nessun gap inventato', () async {
      final scanner = RestoreScanner(
        probe: (index) async =>
            index < 20 ? AddressCheck.unreachable : AddressCheck.unused,
      );

      final result = await scanner.scan();

      expect(result.isConclusive, isFalse);
      expect(result.scannedIndex, isNull);
      expect(result.outcome, GapWindowOutcome.unreachable);
    });

    test('probe che lancia equivale a unreachable', () async {
      final scanner = RestoreScanner(
        probe: (index) async {
          if (index == 3) throw StateError('rete');
          return AddressCheck.used;
        },
      );

      final result = await scanner.scan();

      expect(result.isConclusive, isFalse);
      expect(result.unreachable, greaterThanOrEqualTo(1));
    });

    test('tutte usate fino al cap: gapExhausted, non unreachable', () async {
      final scanner = RestoreScanner(probe: (index) async => AddressCheck.used);

      final result = await scanner.scan();

      expect(result.isConclusive, isFalse);
      // 20 + 20 + 40 = 80 indirizzi sondati/derivati al cap pratico.
      expect(result.probed, 80);
      expect(result.derived, 80);
      expect(result.requested, 80);
      // PERCHÉ `gapExhausted` (ADR 31/10-20 §2): nessun buco, tutte usate ⇒
      // «wallet più grande del previsto», non «explorer non raggiungibile».
      expect(result.outcome, GapWindowOutcome.gapExhausted);
      expect(result.unreachable, 0);
    });

    test('resume() senza sessione = scan da 0 (nessun indice libero)',
        () async {
      // PERCHÉ (ADR 31/10-19 §1): non esiste un `resumeFrom` int — un indice
      // arbitrario farebbe passare un gapFound su un prefisso non verificato.
      final probed = <int>[];
      final scanner = RestoreScanner(
        probe: (int index) async {
          probed.add(index);
          return AddressCheck.used;
        },
      );

      await scanner.resume();

      expect(probed.first, 0);
      expect(scanner.canResume, isTrue);
    });

    test('resume() riprova gli unreachable e prosegue dal buco', () async {
      var failing = true;
      final scanner = RestoreScanner(
        probe: (index) async {
          if (failing && index < 20) return AddressCheck.unreachable;
          return index < 25 ? AddressCheck.used : AddressCheck.unused;
        },
      );

      final first = await scanner.scan();
      expect(first.isConclusive, isFalse);
      expect(first.probed, 20);

      failing = false;
      final second = await scanner.resume();

      expect(second.outcome, GapWindowOutcome.gapFound);
      expect(second.scannedIndex, 25);
      expect(second.probed, greaterThan(first.probed));
    });

    test('resume() che non chiude il buco non finge progresso', () async {
      final scanner = RestoreScanner(
        probe: (index) async => AddressCheck.unreachable,
      );

      final first = await scanner.scan();
      final second = await scanner.resume();

      expect(first.isConclusive, isFalse);
      expect(second.isConclusive, isFalse);
      expect(second.probed, first.probed);
    });

    test('scan() azzera la sessione (nuovo dispositivo = da 0)', () async {
      var calls = 0;
      final scanner = RestoreScanner(
        probe: (index) async {
          calls++;
          return AddressCheck.used;
        },
      );

      await scanner.scan();
      expect(scanner.probedSoFar, 80);
      await scanner.scan();

      expect(scanner.probedSoFar, 80);
      expect(calls, 160);
    });

    test('budget esaurito PRIMA di iniziare: probed 0, parziale', () async {
      // Il fake avanza 31 s alla prima lettura: il budget della prima finestra
      // (30 s) è già scaduto, quindi zero check.
      final scan = RestoreScanner(
        probe: (index) async => AddressCheck.used,
        stopwatchFactory: () =>
            _FakeStopwatch()..expireAfter(const Duration(seconds: 31)),
      );

      final result = await scan.scan();

      expect(result.isConclusive, isFalse);
      expect(result.probed, 0);
      expect(result.requested, 20);
      expect(result.derived, 20);
    });

    test('budget esaurito A METÀ fase: si ferma con i check fatti', () async {
      // Il fake avanza 2 s a ogni lettura di `elapsed`: con budget 30 s si
      // fermano ~15 check su 20. Serve l'avanzamento progressivo, non un solo
      // scatto, altrimenti il test descriverebbe un altro caso.
      final scan = RestoreScanner(
        probe: (index) async => AddressCheck.used,
        stopwatchFactory: () =>
            _FakeStopwatch()..expireAfter(const Duration(seconds: 2)),
      );

      final result = await scan.scan();

      expect(result.isConclusive, isFalse);
      expect(result.probed, greaterThan(0));
      expect(result.probed, lessThan(20));
      expect(result.requested, 20);
    });

    test('tetto totale già speso: nessuna fase parte', () async {
      final scan = RestoreScanner(
        probe: (index) async => AddressCheck.used,
        budget: const GapScanBudgetCalculator(maxTotalDuration: Duration.zero),
      );

      final result = await scan.scan();

      expect(result.isConclusive, isFalse);
      expect(result.probed, 0);
    });

    test('il budget adattivo è DAVVERO cablato (mediana misurata)', () async {
      // PERCHÉ (ADR 31/10-20 §1): senza questo test `measuredPerCall` restava
      // null e l'intera parte adattiva dell'ADR 15/16 era dead code. Qui il
      // calcolatore REGISTRA cosa riceve: la prima finestra non ha misure
      // (`null`), dalla seconda in poi deve arrivare la mediana.
      final budget = _RecordingBudget();
      final scan = RestoreScanner(
        probe: (index) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return AddressCheck.used;
        },
        // Stopwatch che non scade mai: si esercita l'estensione delle fasi.
        stopwatchFactory: _FakeStopwatch.new,
        budget: budget,
      );

      final result = await scan.scan();

      expect(result.outcome, GapWindowOutcome.gapExhausted);
      expect(budget.received.length, greaterThanOrEqualTo(2));
      // Prima finestra: nessuna misura disponibile → stima proporzionale.
      expect(budget.received.first, isNull);
      expect(budget.estimated.first, isTrue);
      // Finestre successive: mediana reale → NON è più una stima.
      expect(budget.received[1], isNotNull);
      expect(budget.estimated[1], isFalse);
      // Il campo esposto dal RISULTATO: è ciò che rende osservabile dall'esterno
      // che il wiring esiste (un test su `planFor` non lo dimostrerebbe).
      expect(result.lastPhaseBudgetEstimated, isFalse);
    });

    test('retry budgetato: con il tetto speso, resume() non risonda nulla',
        () async {
      // PERCHÉ (ADR 01/11-25 §5): i retry consumano tempo reale. Se `_spent` ha
      // già raggiunto il tetto totale, `resume()` non deve rifare 20 chiamate.
      var probeCalls = 0;
      final scanner = RestoreScanner(
        probe: (index) async {
          probeCalls++;
          return AddressCheck.unreachable;
        },
        // Avanza 2 s a ogni lettura: la fase 1 esaurisce i 30 s con ~15 check.
        stopwatchFactory: () =>
            _FakeStopwatch()..expireAfter(const Duration(seconds: 2)),
        budget: const GapScanBudgetCalculator(maxTotalDuration: Duration.zero),
      );

      final first = await scanner.scan();
      final callsAfterScan = probeCalls;
      await scanner.resume();

      expect(first.isConclusive, isFalse);
      // Nessun retry: il tetto totale (0) è già speso.
      expect(probeCalls, callsAfterScan);
    });

    test('prima finestra conclusa: lastPhaseBudgetEstimated true sul risultato',
        () async {
      // Se il gap si chiude nella PRIMA finestra non c'è ancora una misura:
      // il risultato deve dirlo (`lastPhaseBudgetEstimated == true`), altrimenti il
      // campo sarebbe sempre falso e non distinguerebbe nulla.
      final result = await RestoreScanner(probe: probeUsedUntil(0)).scan();

      expect(result.outcome, GapWindowOutcome.gapFound);
      expect(result.lastPhaseBudgetEstimated, isTrue);
    });

    test('probedFraction ha il valore atteso, non solo il range', () async {
      // gap a 5 → 25 check su finestra 40.
      final midPhase = await RestoreScanner(probe: probeUsedUntil(5)).scan();
      expect(midPhase.probedFraction, closeTo(25 / 40, 1e-9));

      // gap a 0 → 20 check su finestra 20 = 1.0.
      final full = await RestoreScanner(probe: probeUsedUntil(0)).scan();
      expect(full.probedFraction, 1.0);
    });

    test('il budget adattivo usa la mediana misurata', () {
      expect(
        GapScanBudgetCalculator.medianOf(const [
          Duration(milliseconds: 800),
          Duration(milliseconds: 900),
          Duration(milliseconds: 950),
        ]),
        const Duration(milliseconds: 900),
      );
    });
  });
}
