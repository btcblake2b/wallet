import 'gap_window_policy.dart';
import 'restore_scanner.dart';

/// Etichetta da mostrare per una scansione del gap, **specializzata per esito**.
///
/// // PERCHÉ un tipo e non una stringa (ADR 02/11-28 §3 + 02/11-29 §6):
/// // `probed/requested` ha significato **opposto** nei due esiti che finiscono
/// // a schermo — per `gapFound` un `probed < requested` significa «trovato
/// // prima del limite» (bene), per `unreachable` significa «interrotto» (male).
/// // Una sola chiave con `{probed}/{requested}` produce quindi un messaggio
/// // falso in tre casi su quattro. Il tipo qui sotto rende impossibile
/// // chiedere alla UI la frazione quando la frazione non ha senso.
sealed class RestoreOutcomeLabel {
  const RestoreOutcomeLabel();
}

/// Scansione **conclusa**: la catena è verificata fino a [lastUsedIndex].
///
/// La frazione non si mostra: l'informazione utile è dove finisce la catena.
final class RestoreGapFound extends RestoreOutcomeLabel {
  const RestoreGapFound(this.lastUsedIndex);

  /// Indice dell'ultimo indirizzo **usato** (`scannedIndex` della scansione).
  final int lastUsedIndex;
}

/// Scansione **incompleta per limite di scansione**: nessun buco trovato entro
/// il tetto, quindi il wallet è più grande della finestra.
///
/// L'azione non è «riprova» (riprovare dà lo stesso esito): è «verifica il
/// backup» / «il wallet ha più indirizzi del previsto».
final class RestoreGapPartial extends RestoreOutcomeLabel {
  const RestoreGapPartial({required this.probed, required this.requested});

  final int probed;
  final int requested;
}

/// Scansione **interrotta**: explorer non raggiungibile o tempo esaurito.
///
/// Distinta da [RestoreGapPartial] perché l'azione è opposta — qui **riprovare
/// ha senso**. Nota: `probed == requested` è possibile (budget scaduto
/// sull'ultimo check), ed è il motivo per cui questo caso non può condividere
/// il messaggio «parziale X/Y»: a 40/40 sembrerebbe concluso.
final class RestoreGapInterrupted extends RestoreOutcomeLabel {
  const RestoreGapInterrupted({required this.probed, required this.requested});

  final int probed;
  final int requested;
}

/// Traduzione pura (nessun I/O, nessuna localizzazione) esito → etichetta.
class RestoreOutcomePresenter {
  const RestoreOutcomePresenter._();

  static RestoreOutcomeLabel labelFor(RestoreScanResult result) {
    switch (result.outcome) {
      case GapWindowOutcome.gapFound:
        // L'invariante `gapFound ⇒ scannedIndex != null` è asserita nel
        // costruttore di [RestoreScanResult]: qui il `!` è coperto.
        return RestoreGapFound(result.scannedIndex!);
      case GapWindowOutcome.unreachable:
        return RestoreGapInterrupted(
          probed: result.probed,
          requested: result.requested,
        );
      case GapWindowOutcome.gapNotEstablished:
      case GapWindowOutcome.gapExhausted:
        return RestoreGapPartial(
          probed: result.probed,
          requested: result.requested,
        );
    }
  }
}
