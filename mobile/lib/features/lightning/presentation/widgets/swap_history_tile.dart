import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/swap/swap_models.dart';

/// Riga dello STORICO swap (P9): importo, data e stato; tap → dettaglio.
///
/// // PERCHÉ (07/10/2026): l'utente deve riconoscere a colpo d'occhio le
/// // transazioni fatte via provider (importo + quando + esito). L'icona e il
/// // colore derivano dallo STATO, così un pagamento riuscito, uno da
/// // recuperare e uno rimborsato si distinguono senza leggere il testo.
class SwapHistoryTile extends StatelessWidget {
  const SwapHistoryTile({
    super.key,
    required this.session,
    required this.stateLabel,
    this.onTap,
  });

  final SwapSession session;

  /// Etichetta già localizzata dello stato.
  final String stateLabel;

  final VoidCallback? onTap;

  /// Importo mostrato: quello della INVOICE (quanto è stato pagato al
  /// destinatario). Se la sessione è antecedente al 07/10/2026 l'importo non
  /// è persistito → si degrada al totale bloccato (fee incluse).
  String get _amount => NumberFormat.decimalPattern()
      .format(session.amountSats ?? session.fundingAmountSats);

  String get _date => DateFormat('dd/MM/yyyy · HH:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(session.createdAt * 1000));

  IconData get _icon => switch (session.state) {
        SwapClientState.completed => Icons.check_circle_outline,
        SwapClientState.refunded => Icons.undo,
        SwapClientState.paymentFailed => Icons.error_outline,
        SwapClientState.expired => Icons.timer_off_outlined,
        _ => Icons.hourglass_top,
      };

  Color _color(BuildContext context) => switch (session.state) {
        SwapClientState.completed => Colors.greenAccent,
        SwapClientState.refunded => Colors.lightBlueAccent,
        SwapClientState.paymentFailed || SwapClientState.expired =>
          Colors.orangeAccent,
        _ => Theme.of(context).colorScheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    // PERCHÉ Material transparente: la tile vive dentro un GlassContainer
    // (DecoratedBox con colore) e senza Material l'ink splash non si vedrebbe
    // (Flutter lo segnala con un assert in debug).
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(_icon, color: color),
        title: Text('$_amount sat'),
        subtitle: Text('$_date · $stateLabel'),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
