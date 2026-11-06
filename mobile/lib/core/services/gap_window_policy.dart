/// Esito della verifica di un singolo indirizzo durante la scansione del gap.
///
/// // PERCHÉ tre valori e non un `bool` (ADR 31/10-16 §2): con due valori un
/// // timeout diventerebbe «non usata», quindi 20 timeout consecutivi
/// // sembrerebbero un gap di 20 e porterebbero a un indice troppo basso —
/// // reuse, cioè il fail-open che il modello ha già chiuso, reintrodotto al
/// // seam di rete.
enum AddressCheck { used, unused, unreachable }

/// Esito della valutazione di una finestra di scansione.
enum GapWindowOutcome {
  /// Trovate `gapLimit` posizioni consecutive non usate.
  gapFound,

  /// Finestra sondata ma senza `gapLimit` consecutive non usate: il wallet è
  /// più grande della finestra → **estendere**.
  gapNotEstablished,

  /// Tutte le posizioni sondate risultano usate (sotto-caso di
  /// [gapNotEstablished], con messaggio UI dedicato).
  gapExhausted,

  /// Almeno una posizione non è stata verificabile (timeout/5xx/rete):
  /// lo stato **non è concludibile**.
  unreachable,
}

/// Risultato della valutazione di una finestra.
class GapWindowResult {
  const GapWindowResult({
    required this.outcome,
    required this.probed,
    required this.requested,
    required this.unreachable,
    this.gapStartIndex,
  });

  final GapWindowOutcome outcome;

  /// Posizioni effettivamente verificate (`used` + `unused`).
  final int probed;

  /// Posizioni richieste dalla finestra.
  final int requested;

  /// Posizioni non verificabili.
  final int unreachable;

  /// Indice globale della prima posizione del gap, se [outcome] è
  /// [GapWindowOutcome.gapFound].
  final int? gapStartIndex;

  double get probedFraction => requested <= 0 ? 0 : probed / requested;
}

/// Valutazione **pura** di una finestra di scansione del gap.
class GapWindowEvaluator {
  const GapWindowEvaluator._();

  /// Valuta i risultati di una finestra che inizia all'indice globale
  /// [startIndex] ([checks] in ordine).
  ///
  /// [gapLimit] è il numero di posizioni consecutive non usate che chiude una
  /// catena (20 BIP44).
  ///
  /// Precedenza dei verdetti:
  /// 1. `gapFound` — solo se il run di [gapLimit] `unused` è **preceduto
  ///    esclusivamente da `used`**: se prima del run c'è una posizione non
  ///    verificata, il gap potrebbe iniziare prima e l'indice trovato sarebbe
  ///    troppo alto (restore sbagliato: si saltano indirizzi mai usati);
  /// 2. `unreachable` — una posizione non verificata rende la scansione
  ///    inconcludibile;
  /// 3. `gapExhausted` — tutte sondate e tutte usate;
  /// 4. `gapNotEstablished` — ci sono posizioni libere, ma meno di [gapLimit].
  ///
  /// // PERCHÉ `unreachable` prima di `gapExhausted` e non dopo (ADR 31/10-17
  /// // §1): «tutte le sondate sono usate» non significa «tutte usate» se alcune
  /// // non sono state sondate.
  static GapWindowResult evaluate({
    required List<AddressCheck> checks,
    required int startIndex,
    int gapLimit = 20,
  }) {
    var unusedRun = 0;
    var unusedTotal = 0;
    var unreachable = 0;

    for (var i = 0; i < checks.length; i++) {
      switch (checks[i]) {
        case AddressCheck.used:
          unusedRun = 0;
        case AddressCheck.unused:
          unusedTotal++;
          unusedRun++;
          if (unusedRun >= gapLimit) {
            // PERCHÉ (ADR 31/10-17 §1): un `unreachable` PRIMA del run rende
            // l'inizio del gap sconosciuto. Esempio reale: 0-19 timeout e 20-39
            // libere → il vero indice è 0 (o 11), non 20. Riportare 20
            // salterebbe indirizzi mai usati.
            if (unreachable > 0) {
              return GapWindowResult(
                outcome: GapWindowOutcome.unreachable,
                probed: checks.length - unreachable,
                requested: checks.length,
                unreachable: unreachable,
              );
            }
            final gapStart = startIndex + i - gapLimit + 1;
            return GapWindowResult(
              outcome: GapWindowOutcome.gapFound,
              probed: checks.length,
              requested: checks.length,
              unreachable: 0,
              gapStartIndex: gapStart,
            );
          }
        case AddressCheck.unreachable:
          unreachable++;
          unusedRun = 0;
      }
    }

    if (unreachable > 0) {
      return GapWindowResult(
        outcome: GapWindowOutcome.unreachable,
        probed: checks.length - unreachable,
        requested: checks.length,
        unreachable: unreachable,
      );
    }

    return GapWindowResult(
      outcome: unusedTotal == 0
          ? GapWindowOutcome.gapExhausted
          : GapWindowOutcome.gapNotEstablished,
      probed: checks.length,
      requested: checks.length,
      unreachable: 0,
    );
  }

  /// True se l'esito richiede una finestra più grande.
  static bool needsExtension(GapWindowOutcome outcome) =>
      outcome == GapWindowOutcome.gapNotEstablished ||
      outcome == GapWindowOutcome.gapExhausted;
}
