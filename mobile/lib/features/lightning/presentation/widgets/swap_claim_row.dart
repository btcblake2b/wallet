import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Riga di VERIFICA del claim di uno swap: txid + copia + link explorer.
///
/// // PERCHÉ (18/09/2026): durante lo stato `claiming` la scheda mostrava solo
/// // "claim in corso". Il txid viaggiava già nello stato della sessione
/// // (`claim_txid`) ma non veniva mai mostrato, quindi l'utente non poteva
/// // verificare on-chain la transazione né distinguere l'attesa fisiologica
/// // (il claim è una tx on-chain: conferma al blocco successivo, ~12 min) da
/// // un eventuale problema.
class SwapClaimRow extends StatelessWidget {
  const SwapClaimRow({
    super.key,
    required this.txid,
    required this.label,
    required this.hint,
    this.explorerUrl,
  });

  /// Txid del claim (64 hex).
  final String txid;

  /// Etichetta della riga (localizzata dal chiamante).
  final String label;

  /// Spiegazione dei tempi di conferma (localizzata dal chiamante).
  final String hint;

  /// URL dell'explorer per la verifica; `null` = nessun link mostrato.
  final String? explorerUrl;

  /// Abbreviazione per la UI: testa + coda del txid (resta riconoscibile).
  String get _shortTxid => txid.length > 24
      ? '${txid.substring(0, 12)}…${txid.substring(txid.length - 8)}'
      : txid;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: txid));
    if (!context.mounted) return;
    // // PERCHÉ il debugPrint: conferma nei log che il tap è stato gestito
    // (una copia silenziosa è difficile da diagnosticare su device).
    debugPrint('[LoopEngineer] SwapClaimRow: txid copiato');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  /// Apre l'explorer nel browser di sistema.
  ///
  /// // PERCHÉ il try/catch (fix 16/09 su peering_gate_banner): il lancio può
  /// // fallire per visibilità mancante nel manifest; un tap non deve mai
  /// // "non fare nulla" senza traccia nei log.
  Future<void> _open() async {
    final url = explorerUrl;
    if (url == null) return;
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[LoopEngineer] SwapClaimRow: apertura $url fallita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.labelMedium),
            ),
            if (explorerUrl != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: label,
                onPressed: _open,
                icon: const Icon(Icons.open_in_new, size: 18),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: label,
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        Text(_shortTxid, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(hint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
