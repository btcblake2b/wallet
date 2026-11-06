/// Piano di budget per la scansione del gap (ADR 30/10-14 e 31/10-15).
///
/// // PERCHÉ esiste come classe pura: il budget nasce da MISURE, non da costanti
/// // indovinate. Una finestra da 20 e una da 80 non possono avere lo stesso
/// // tempo se l'explorer risponde in 1 s per chiamata: il budget della finestra
/// // successiva si deriva dal throughput osservato nella precedente.
library;

/// Esito del budget per una singola finestra.
class GapScanWindowPlan {
  const GapScanWindowPlan({
    required this.windowSize,
    required this.budget,
    required this.estimated,
    this.truncated = false,
  });

  final int windowSize;

  /// Tempo concesso a questa finestra.
  final Duration budget;

  /// `false` quando il budget è la costante di partenza (nessuna misura ancora).
  final bool estimated;

  /// True se il budget è stato tagliato dal tetto totale ([maxTotalDuration]).
  final bool truncated;
}

/// Budget adattivo della scansione del gap.
///
/// Regole:
/// - prima finestra: 30 s (nessuna misura disponibile);
/// - finestre successive: `perCall × windowSize × safetyFactor`, dove
///   `perCall` è il tempo medio per chiamata **misurato** nella finestra
///   precedente;
/// - il budget è limitato a [maxWindowBudget] per non trasformare un explorer
///   patologicamente lento in un'attesa senza fine;
/// - la somma non supera [maxTotalDuration].
class GapScanBudgetCalculator {
  const GapScanBudgetCalculator({
    this.firstWindowBudget = const Duration(seconds: 30),
    this.safetyFactor = 1.5,
    this.maxWindowBudget = const Duration(seconds: 120),
    this.maxTotalDuration = const Duration(seconds: 180),
    this.minWindowBudget = const Duration(seconds: 10),
  });

  final Duration firstWindowBudget;
  final double safetyFactor;
  final Duration maxWindowBudget;
  final Duration maxTotalDuration;
  final Duration minWindowBudget;

  /// Finestre provate in ordine. **Cap pratico: 80.**
  ///
  /// // PERCHÉ non 200 (ADR 31/10-15): con un explorer a ~1 s per chiamata la
  /// // finestra 80 costerebbe 80 s; oltre non si arriva mai. Il tetto
  /// // algoritmico resta 200 come guardia, ma il numero che descrive la
  /// // copertura reale è 80 — e va scritto, altrimenti chi legge assume 200.
  static const List<int> windows = <int>[20, 40, 80];

  /// Finestra di riferimento per la stima proporzionale (quella iniziale).
  static const int referenceWindow = 20;

  /// Guardia dell'algoritmo: nessuna scansione deriva più di questo.
  static const int algorithmicCeiling = 200;

  /// Soglia oltre la quale l'explorer è considerato «lento» per quella catena.
  ///
  /// // PERCHÉ per catena e non aggregata (ADR 31/10-15): una catena al 100% e
  /// // l'altra al 20% darebbero 60% aggregato — «riprova» — mentre il problema
  /// // è esattamente la seconda. Esattamente 50% **non** è lento: serve un
  /// // confine dichiarato, altrimenti il test è ambiguo.
  static const double slowExplorerThreshold = 0.5;

  static bool isExplorerTooSlow({required int probed, required int requested}) {
    if (requested <= 0) return false;
    return (probed / requested) < slowExplorerThreshold;
  }

  /// Budget della finestra [windowSize].
  ///
  /// [measuredPerCall] è la **mediana** del tempo per chiamata misurata nella
  /// finestra precedente (non la media: una singola chiamata da 5 s sfasa la
  /// media e regalerebbe budget alle successive). Se manca, la stima è
  /// **proporzionale** alla finestra di riferimento — `30 s × windowSize / 20` —
  /// così la finestra 40 non eredita i 30 s della 20 e il caso «explorer lento»
  /// non peggiora estendendo.
  GapScanWindowPlan planFor({
    required int windowSize,
    Duration? measuredPerCall,
    Duration alreadySpent = Duration.zero,
  }) {
    final remaining = maxTotalDuration - alreadySpent;
    if (remaining <= Duration.zero) {
      return GapScanWindowPlan(
        windowSize: windowSize,
        budget: Duration.zero,
        estimated: false,
      );
    }

    final measuredUsable =
        measuredPerCall != null && measuredPerCall > Duration.zero;

    Duration budget;
    if (measuredUsable) {
      final scaled =
          (measuredPerCall.inMicroseconds * windowSize * safetyFactor).round();
      budget = Duration(microseconds: scaled);
      if (budget < minWindowBudget) budget = minWindowBudget;
      if (budget > maxWindowBudget) budget = maxWindowBudget;
    } else {
      final scaled =
          (firstWindowBudget.inMicroseconds * windowSize / referenceWindow)
              .round();
      budget = Duration(microseconds: scaled);
      if (budget > maxWindowBudget) budget = maxWindowBudget;
    }

    final capped = budget > remaining ? remaining : budget;
    return GapScanWindowPlan(
      windowSize: windowSize,
      budget: capped,
      estimated: !measuredUsable,
      truncated: capped < budget,
    );
  }

  /// Mediana delle durate (per `measuredPerCall`). `null` se la lista è vuota.
  static Duration? medianOf(List<Duration> durations) {
    if (durations.isEmpty) return null;
    final sorted = durations.map((d) => d.inMicroseconds).toList()..sort();
    final mid = sorted.length ~/ 2;
    final micros = sorted.length.isOdd
        ? sorted[mid]
        : ((sorted[mid - 1] + sorted[mid]) / 2).round();
    return Duration(microseconds: micros);
  }
}
