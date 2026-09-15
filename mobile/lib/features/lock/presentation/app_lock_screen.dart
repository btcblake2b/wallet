import 'package:flutter/material.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Schermata di blocco (UI pura: nessuna logica di lifecycle o di auth).
/// La logica vive in `AppLockGate`, così la UI è testabile a parte.
class AppLockScreen extends StatelessWidget {
  const AppLockScreen({
    super.key,
    required this.onUnlock,
    required this.busy,
    this.notice,
    this.onNoticeContinue,
  });

  final VoidCallback onUnlock;
  final bool busy;

  /// Se non null, mostra l'avviso fail-safe (protezione telefono rimossa).
  final String? notice;
  final VoidCallback? onNoticeContinue;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final noticeText = notice;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.appLockTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.appLockSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (noticeText != null)
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(noticeText, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: onNoticeContinue,
                            child: Text(loc.appLockNoticeContinue),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: busy ? null : onUnlock,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(loc.appLockUnlock),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
