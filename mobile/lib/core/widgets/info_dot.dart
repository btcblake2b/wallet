import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/info_hints_l10n.dart';
import '../services/info_hints.dart';

/// Pallino "ⓘ": apre la spiegazione di [id] in un dialog centrato.
///
/// PERCHÉ: quando l'utente disattiva gli aiuti il pallino NON deve lasciare uno
/// spazio vuoto → `SizedBox.shrink()`.
class InfoDot extends StatelessWidget {
  const InfoDot({super.key, required this.id, this.size = 16});

  final InfoHintId id;
  final double size;

  @override
  Widget build(BuildContext context) {
    // PERCHÉ: ListenableBuilder sul registro di processo → il toggle in
    // Impostazioni nasconde i pallini anche nelle schermate GIÀ montate.
    return ListenableBuilder(
      listenable: InfoHints.instance,
      builder: (context, _) {
        if (!InfoHints.instance.enabled) return const SizedBox.shrink();
        final loc = AppLocalizations.of(context);
        final color = Theme.of(context).colorScheme.onSurfaceVariant;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          iconSize: size,
          color: color,
          icon: Icon(Icons.info_outline, size: size),
          tooltip: loc.infoTitle(id),
          onPressed: () => showInfoHintDialog(context, id),
        );
      },
    );
  }
}

/// AlertDialog centrato con titolo e corpo della spiegazione [id].
Future<void> showInfoHintDialog(BuildContext context, InfoHintId id) {
  final loc = AppLocalizations.of(context);
  debugPrint('[LoopEngineer] infoHint aperto: ${id.name}');
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(loc.infoTitle(id))),
        ],
      ),
      content: SingleChildScrollView(child: Text(loc.infoBody(id))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          // PERCHÉ: riusa la chiave esistente "Chiudi" → nessuna stringa nuova.
          child: Text(loc.walletDetailClose),
        ),
      ],
    ),
  );
}
