import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/receive_address_presenter.dart';

/// Avviso presentazionale per gli stati degli indici (ADR 30/10-6 §4 e 19).
///
/// // PERCHÉ un solo widget (ADR 31/10-21): gli stessi tre messaggi servono in
/// // Ricevi, Canali e Cassa. Se ogni schermata componesse il testo per conto
/// // suo, metà mostrerebbe il messaggio generico e metà quello giusto.
///
/// Non fa I/O e non decide nulla: riceve la vista dal presenter.
class WalletIndicesNotice extends StatelessWidget {
  const WalletIndicesNotice({
    super.key,
    required this.view,
    this.onRetry,
    this.onResetToZero,
    this.onRestoreBackup,
    this.onContactSupport,
    this.onUnlock,
  });

  final ReceiveAddressView view;

  /// Riprova la scansione (solo per il corrotto).
  final VoidCallback? onRetry;

  /// Riparti da 0 con conferma (solo per il corrotto: l'anomalo non lo ha).
  final VoidCallback? onResetToZero;

  /// Importa un backup (corrotto e anomalo).
  final VoidCallback? onRestoreBackup;

  /// Supporto (solo per l'anomalo).
  final VoidCallback? onContactSupport;

  /// Sblocco del vault per derivare e salvare l'`accountXpub` (seedRequired).
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (view) {
      case ReceiveAddressView.corruptBlocked:
        return _Notice(
          icon: Icons.error_outline,
          title: loc.indicesCorruptTitle,
          body: loc.indicesCorruptBody,
          actions: <Widget>[
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(loc.indicesActionRetry),
              ),
            if (onRestoreBackup != null)
              TextButton(
                onPressed: onRestoreBackup,
                child: Text(loc.indicesActionRestore),
              ),
            if (onResetToZero != null)
              TextButton(
                onPressed: onResetToZero,
                child: Text(loc.indicesAdoptionTitle),
              ),
          ],
        );
      case ReceiveAddressView.anomalousBlocked:
        return _Notice(
          icon: Icons.warning_amber_outlined,
          title: loc.indicesAnomalousTitle,
          body: loc.indicesAnomalousBody,
          // PERCHÉ nessun «riparti da 0»: l'indice anomalo è NOTO, ripartire
          // sarebbe reuse informato (ADR 30/10-9 §1).
          actions: <Widget>[
            if (onRestoreBackup != null)
              TextButton(
                onPressed: onRestoreBackup,
                child: Text(loc.indicesActionRestore),
              ),
            if (onContactSupport != null)
              TextButton(
                onPressed: onContactSupport,
                child: Text(loc.indicesActionSupport),
              ),
          ],
        );
      case ReceiveAddressView.adoptionRequired:
        return _Notice(
          icon: Icons.autorenew,
          title: loc.indicesAdoptionTitle,
          body: loc.indicesAdoptionBody,
          actions: <Widget>[
            if (onResetToZero != null)
              TextButton(
                onPressed: onResetToZero,
                child: Text(loc.indicesActionContinue),
              ),
          ],
        );
      case ReceiveAddressView.seedRequired:
        return _Notice(
          icon: Icons.lock_outline,
          title: loc.indicesSeedRequiredTitle,
          body: loc.indicesSeedRequiredBody,
          actions: <Widget>[
            if (onUnlock != null)
              TextButton(
                onPressed: onUnlock,
                child: Text(loc.indicesActionUnlock),
              ),
          ],
        );
      case ReceiveAddressView.seedMismatch:
        return _Notice(
          icon: Icons.gpp_bad_outlined,
          title: loc.indicesSeedMismatchTitle,
          body: loc.indicesSeedMismatchBody,
          // Nessuno sblocco: la seed c'è, è quella sbagliata (ADR 02/11-33 §1).
          actions: <Widget>[
            if (onRestoreBackup != null)
              TextButton(
                onPressed: onRestoreBackup,
                child: Text(loc.indicesActionRestore),
              ),
            if (onContactSupport != null)
              TextButton(
                onPressed: onContactSupport,
                child: Text(loc.indicesActionSupport),
              ),
          ],
        );
      case ReceiveAddressView.alreadyAssigned:
        return _Notice(
          icon: Icons.info_outline,
          title: null,
          body: loc.indicesAlreadyAssigned,
        );
      case ReceiveAddressView.fresh:
        return const SizedBox.shrink();
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.body,
    this.title,
    this.actions,
  });

  final IconData icon;
  final String body;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                if (title != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodySmall),
            if (actions != null && actions!.isNotEmpty)
              Wrap(spacing: 8, children: actions!),
          ],
        ),
      ),
    );
  }
}
