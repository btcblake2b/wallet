import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Riga di DATO di uno swap: etichetta, valore, copia e link explorer.
///
/// // PERCHÉ (07/10/2026): il dettaglio dello storico mostra molti campi
/// // "lunghi" (hash, txid, indirizzi, invoice) che l'utente deve poter
/// // copiare o verificare on-chain. Un solo widget evita che ogni campo
/// // reinventi copia/snackbar/link e mantiene il comportamento uniforme.
class SwapFieldRow extends StatelessWidget {
  const SwapFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.copyValue,
    this.explorerUrl,
    this.hint,
    this.monospace = false,
  });

  /// Etichetta localizzata (es. "Payment hash").
  final String label;

  /// Valore MOSTRATO (già abbreviato dal chiamante se troppo lungo).
  final String value;

  /// Valore COPIATO — default [value]: se il display è abbreviato, passare
  /// qui il valore intero.
  final String? copyValue;

  /// URL dell'explorer per la verifica; `null` = nessun link.
  final String? explorerUrl;

  /// Riga esplicativa opzionale sotto il valore.
  final String? hint;

  /// Font monospace per hash/txid (allineamento dei caratteri).
  final bool monospace;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: copyValue ?? value));
    if (!context.mounted) return;
    debugPrint('[LoopEngineer] SwapFieldRow: $label copiato');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  /// Apre l'explorer nel browser di sistema.
  ///
  /// // PERCHÉ il try/catch: il lancio può fallire (visibilità mancante nel
  /// // manifest): un tap non deve mai "non fare nulla" senza traccia.
  Future<void> _open() async {
    final url = explorerUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LoopEngineer] SwapFieldRow: apertura $url fallita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
              if (explorerUrl != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: AppLocalizations.of(context).lightningSwapOpenInExplorer,
                  onPressed: _open,
                  icon: const Icon(Icons.open_in_new, size: 18),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context).lightningCopied,
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: monospace
                ? theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Courier'],
                  )
                : theme.textTheme.bodySmall,
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
