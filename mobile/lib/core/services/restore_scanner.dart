import 'gap_scan_budget.dart';
import 'gap_window_policy.dart';

/// Sonda un singolo indirizzo. Tre esiti, mai un `bool`.
///
/// // PERCHÉ (ADR 31/10-16 §2): un timeout non è «non usata» — con due esiti il
/// // gap-scan inventerebbe un gap e adotterebbe un indice troppo basso.
typedef AddressCheckProbe = Future<AddressCheck> Function(int index);

/// Esito di una scansione del gap per **una** catena.
class RestoreScanResult {
  const RestoreScanResult({
    required this.outcome,
    required this.probed,
    required this.derived,
    required this.requested,
    required this.unreachable,
    required this.lastPhaseBudgetEstimated,
    this.scannedIndex,
  }) : assert(
          outcome != GapWindowOutcome.gapFound || scannedIndex != null,
          'gapFound richiede scannedIndex: un esito conclusivo senza indice '
          'non è utilizzabile dal chiamante',
        );

  final GapWindowOutcome outcome;

  /// Indirizzi **verificati** (used + unused + unreachable).
  final int probed;

  /// Indirizzi **derivati** finora: batching della derivazione (economica), non
  /// «quanti ne servivano». Coincide con la finestra cumulativa corrente
  /// (20 → 40 → 80), quindi può superare [probed] quando l'early-stop ferma la
  /// sonda a metà finestra: `probed 25 / derived 40` è normale.
  final int derived;

  /// Posizioni concesse dalla fase corrente (20 / 40 / 80).
  final int requested;

  final int unreachable;

  /// True se il budget della fase in cui la scansione si è **conclusa** è stato
  /// stimato (nessuna misura disponibile) invece che calcolato sulla mediana.
  ///
  /// // SOLO DIAGNOSTICA (ADR 02/11-27 §1): non governa la UI. Nemmeno la
  /// // frazione governa la UI: l'etichetta dipende dall'esito e la calcola
  /// // [RestoreOutcomePresenter] (ADR 02/11-28 §3). Questo campo serve a
  /// // leggere il comportamento del budget adattivo nei test e in Diagnostica.
  final bool lastPhaseBudgetEstimated;

  /// Indice autoritativo, presente **solo** se la scansione è conclusiva.
  final int? scannedIndex;

  /// True se la scansione è conclusa e [scannedIndex] è utilizzabile.
  bool get isConclusive => outcome == GapWindowOutcome.gapFound;

  double get probedFraction => requested <= 0 ? 0 : probed / requested;
}

/// Scansione del gap **sequenziale con early-stop** (ADR 31/10-18 §1).
///
/// Semantica: «finestra» = fase di **budget** (20 / 40 / 80 check massimi), i
/// check sono sequenziali e la scansione si ferma appena [gapLimit] posizioni
/// consecutive risultano non usate.
///
/// **Sessione**: lo stato (check accumulati, fase, tempo speso) vive
/// nell'istanza. Non esiste un `resumeFrom` libero: `resume()` riprende solo da
/// ciò che questa sessione ha realmente verificato, quindi la regola «`gapFound`
/// valido solo se tutto ciò che precede è `used`» non è aggirabile con un
/// indice inventato dal chiamante (ADR 31/10-19 §1). Un'istanza nuova = nuova
/// sessione = scansione da 0.
class RestoreScanner {
  RestoreScanner({
    required AddressCheckProbe probe,
    GapScanBudgetCalculator budget = const GapScanBudgetCalculator(),
    int gapLimit = 20,
    Stopwatch Function()? stopwatchFactory,
  })  : _probe = probe,
        _budget = budget,
        _gapLimit = gapLimit,
        _stopwatchFactory = stopwatchFactory ?? Stopwatch.new;

  final AddressCheckProbe _probe;
  final GapScanBudgetCalculator _budget;
  final int _gapLimit;
  final Stopwatch Function() _stopwatchFactory;

  /// Check accumulati **dall'indice 0**: l'evaluator li vede sempre completi,
  /// quindi il vincolo sul prefisso è strutturale e non una convenzione.
  final List<AddressCheck> _checks = <AddressCheck>[];

  /// Durate delle singole chiamate: è la materia prima del budget adattivo.
  ///
  /// // PERCHÉ (ADR 31/10-20 §1): senza questa lista `planFor` riceveva sempre
  /// // `measuredPerCall = null`, quindi la parte adattiva dell'ADR 15/16 non
  /// // era mai in esecuzione — dead code documentato come feature.
  final List<Duration> _callDurations = <Duration>[];

  RestoreScanResult? _lastResult;
  int _phaseIndex = 0;
  int _derived = 0;
  Duration _spent = Duration.zero;
  bool _started = false;

  /// `estimated` dell'ultimo piano calcolato: serve al return finale (fuori dal
  /// loop), dove il `plan` locale non è più in scope.
  bool _lastEstimated = true;

  /// True se c'è una sessione con almeno un check: solo allora `resume()` ha
  /// qualcosa da riprendere.
  bool get canResume => _started && _checks.isNotEmpty;

  /// Check già verificati in questa sessione.
  int get probedSoFar => _checks.length;

  /// Nuova scansione da 0 (azzera la sessione).
  Future<RestoreScanResult> scan() {
    _checks.clear();
    _callDurations.clear();
    _lastResult = null;
    _lastEstimated = true;
    _phaseIndex = 0;
    _derived = 0;
    _spent = Duration.zero;
    _started = true;
    return _run();
  }

  /// Riprende la sessione corrente; senza sessione equivale a [scan].
  ///
  /// Prima di continuare **riprova** le posizioni rimaste `unreachable`: se
  /// anche una sola resta non verificata, torna parziale senza avanzare — un
  /// retry che non chiude il buco non deve fingere progresso.
  ///
  /// Se la sessione ha già un risultato **conclusivo**, `resume()` non risonda
  /// nulla: il gap è chiuso, e continuare sarebbe lavoro sprecato.
  Future<RestoreScanResult> resume() {
    if (!canResume) return scan();
    final previous = _lastResult;
    if (previous != null && previous.isConclusive) {
      return Future<RestoreScanResult>.value(previous);
    }
    return _run();
  }

  Future<RestoreScanResult> _run() async {
    await _retryUnreachable();
    if (_hasUnreachable()) {
      return _remember(
        RestoreScanResult(
          outcome: GapWindowOutcome.unreachable,
          probed: _checks.length,
          derived: _derived,
          requested: _currentTarget(),
          unreachable: _countUnreachable(),
          lastPhaseBudgetEstimated: true,
        ),
      );
    }

    while (_phaseIndex < GapScanBudgetCalculator.windows.length) {
      final target = GapScanBudgetCalculator.windows[_phaseIndex];
      _chargeBlock();

      // Budget adattivo: dalla seconda finestra in poi usa la MEDIANA misurata
      // delle chiamate già fatte; la prima cade sulla stima proporzionale.
      final measured = GapScanBudgetCalculator.medianOf(_callDurations);
      final plan = _budget.planFor(
        windowSize: target,
        measuredPerCall: measured,
        alreadySpent: _spent,
      );
      if (plan.budget <= Duration.zero) break;
      _lastEstimated = plan.estimated;

      final stopwatch = _stopwatchFactory()..start();
      var budgetExpired = false;

      while (_checks.length < target) {
        if (stopwatch.elapsed >= plan.budget) {
          budgetExpired = true;
          break;
        }
        final call = Stopwatch()..start();
        _checks.add(await _safeProbe(_checks.length));
        call.stop();
        _callDurations.add(call.elapsed);

        final evaluated = GapWindowEvaluator.evaluate(
          checks: _checks,
          startIndex: 0,
          gapLimit: _gapLimit,
        );
        if (evaluated.outcome == GapWindowOutcome.gapFound) {
          stopwatch.stop();
          return _remember(
            RestoreScanResult(
              outcome: GapWindowOutcome.gapFound,
              probed: _checks.length,
              derived: _derived,
              requested: target,
              unreachable: 0,
              lastPhaseBudgetEstimated: plan.estimated,
              scannedIndex: evaluated.gapStartIndex,
            ),
          );
        }
      }

      stopwatch.stop();
      _spent += stopwatch.elapsed;

      final evaluated = GapWindowEvaluator.evaluate(
        checks: _checks,
        startIndex: 0,
        gapLimit: _gapLimit,
      );

      if (budgetExpired || evaluated.outcome == GapWindowOutcome.unreachable) {
        return _remember(
          RestoreScanResult(
            outcome: GapWindowOutcome.unreachable,
            probed: _checks.length,
            derived: _derived,
            requested: target,
            unreachable: evaluated.unreachable,
            lastPhaseBudgetEstimated: plan.estimated,
          ),
        );
      }

      if (!GapWindowEvaluator.needsExtension(evaluated.outcome)) {
        return _remember(
          RestoreScanResult(
            outcome: evaluated.outcome,
            probed: _checks.length,
            derived: _derived,
            requested: target,
            unreachable: 0,
            lastPhaseBudgetEstimated: plan.estimated,
          ),
        );
      }

      _phaseIndex++;
    }

    // Uscita dal loop: fasi finite **o** tetto totale esaurito.
    // // PERCHÉ `gapExhausted` (ADR 31/10-20 §2): se non ci sono buchi, tutte
    // // le posizioni sondate sono usate ⇒ il wallet è più grande della finestra,
    // // non «explorer non raggiungibile». La distinzione è quella che cambia il
    // // messaggio: «verifica il backup» vs «riprova».
    final unreachable = _countUnreachable();
    return _remember(
      RestoreScanResult(
        outcome: unreachable > 0
            ? GapWindowOutcome.unreachable
            : GapWindowOutcome.gapExhausted,
        probed: _checks.length,
        derived: _derived,
        requested: _currentTarget(),
        unreachable: unreachable,
        lastPhaseBudgetEstimated: _lastEstimated,
      ),
    );
  }

  RestoreScanResult _remember(RestoreScanResult result) {
    _lastResult = result;
    return result;
  }

  Future<void> _retryUnreachable() async {
    for (var i = 0; i < _checks.length; i++) {
      if (_checks[i] != AddressCheck.unreachable) continue;
      // PERCHÉ (ADR 31/10-20 §3): anche i retry consumano tempo reale. Senza
      // contabilizzarli, 20 timeout costa 100 s fuori dal tetto totale.
      if (_spent >= _budget.maxTotalDuration) return;
      final call = Stopwatch()..start();
      _checks[i] = await _safeProbe(i);
      call.stop();
      _spent += call.elapsed;
      _callDurations.add(call.elapsed);
    }
  }

  Future<AddressCheck> _safeProbe(int index) async {
    try {
      return await _probe(index);
    } catch (_) {
      // Un adapter che lancia è indistinguibile da un timeout.
      return AddressCheck.unreachable;
    }
  }

  /// Contabilizza il blocco di derivazione della fase corrente.
  ///
  /// La finestra è **cumulativa**: fase 1 deriva 20 indirizzi, fase 2 arriva a
  /// 40, fase 3 a 80 (incrementi 20 / 20 / 40). `derived` è quindi il totale
  /// derivato, non la somma delle finestre.
  void _chargeBlock() {
    const phases = GapScanBudgetCalculator.windows;
    if (_phaseIndex < phases.length && _derived < phases[_phaseIndex]) {
      _derived = phases[_phaseIndex];
    }
  }

  int _currentTarget() {
    const phases = GapScanBudgetCalculator.windows;
    final index = _phaseIndex < phases.length ? _phaseIndex : phases.length - 1;
    return phases[index];
  }

  bool _hasUnreachable() => _countUnreachable() > 0;

  int _countUnreachable() =>
      _checks.where((c) => c == AddressCheck.unreachable).length;
}
