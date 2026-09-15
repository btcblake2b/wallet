import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/lightning_movement.dart';
import '../../../../l10n/app_localizations.dart';

/// Riga di un movimento del nodo, condivisa tra dashboard e storico.
///
/// // PERCHÉ: la stessa informazione (tipo, data, importo) deve avere un solo
/// aspetto in tutta l'app — la tile evita due implementazioni divergenti.
class LightningMovementTile extends StatelessWidget {
  const LightningMovementTile({super.key, required this.movement});

  final LightningMovement movement;

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  /// PERCHÉ: formato numerico (non nomi di mese) → identico in 7 lingue.
  static String _date(DateTime d) =>
      DateFormat('dd/MM/yyyy · HH:mm').format(d);

  static IconData _icon(LightningMovement m) {
    switch (m.type) {
      case LightningMovementType.deposit:
        return Icons.arrow_downward_rounded;
      case LightningMovementType.withdrawal:
        return Icons.arrow_upward_rounded;
      case LightningMovementType.channelOpen:
        return Icons.add_link;
      case LightningMovementType.channelClose:
        return Icons.link_off;
      case LightningMovementType.invoice:
        return Icons.bolt;
      case LightningMovementType.onchainFee:
        return Icons.local_gas_station_outlined;
      case LightningMovementType.forward:
        return Icons.swap_horiz;
      case LightningMovementType.other:
        return Icons.receipt_long_outlined;
    }
  }

  static String _label(AppLocalizations loc, LightningMovementType type) {
    switch (type) {
      case LightningMovementType.deposit:
        return loc.lightningMovementDeposit;
      case LightningMovementType.withdrawal:
        return loc.lightningMovementWithdrawal;
      case LightningMovementType.channelOpen:
        return loc.lightningMovementChannelOpen;
      case LightningMovementType.channelClose:
        return loc.lightningMovementChannelClose;
      case LightningMovementType.invoice:
        return loc.lightningMovementInvoice;
      case LightningMovementType.onchainFee:
        return loc.lightningMovementOnchainFee;
      case LightningMovementType.forward:
        return loc.lightningMovementForward;
      case LightningMovementType.other:
        return loc.lightningMovementOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color =
        movement.isIncoming ? Colors.greenAccent : Colors.orangeAccent;
    final sign = movement.isIncoming ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(_icon(movement), size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(loc, movement.type),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _date(movement.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '$sign${_fmt(movement.amountSats)} sat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
