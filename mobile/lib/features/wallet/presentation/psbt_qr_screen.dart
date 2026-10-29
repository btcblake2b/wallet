import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/psbt/psbt_qr.dart';
import '../../../core/widgets/animated_qr.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Mostra una PSBT come QR animato (più frame) con copia del base64.
///
/// // PERCHÉ (P4, 26/10): è il punto di scambio fra due telefoni — uno crea o
/// // firma, l'altro inquadra. Il codice non esce mai dal base64 standard
/// // BIP-174: il QR è solo il trasporto (`psbt_qr.dart`).
class PsbtQrScreen extends StatefulWidget {
  const PsbtQrScreen({
    super.key,
    required this.psbtBase64,
    required this.footer,
    this.title,
    this.onBroadcast,
  });

  /// PSBT da mostrare (base64, non firmata o firmata).
  final String psbtBase64;

  /// Riga informativa sotto il QR (fee, resto, numero input…).
  final String footer;

  /// Titolo dell'AppBar; default "Scan this PSBT".
  final String? title;

  /// Se presente, abilita «Trasmetti» e restituisce il txid (o `null` se
  /// l'utente annulla). Chi chiama decide cosa fare del risultato.
  final Future<String?> Function()? onBroadcast;

  @override
  State<PsbtQrScreen> createState() => _PsbtQrScreenState();
}

class _PsbtQrScreenState extends State<PsbtQrScreen> {
  bool _broadcasting = false;

  Future<void> _copy() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: widget.psbtBase64));
    messenger.showSnackBar(SnackBar(content: Text(loc.lightningCopied)));
  }

  Future<void> _broadcast() async {
    final handler = widget.onBroadcast;
    if (handler == null) return;
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _broadcasting = true);
    try {
      final txid = await handler();
      if (!mounted) return;
      if (txid != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(loc.psbtBroadcastDone(_short(txid)))),
        );
        Navigator.of(context).pop(true);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _broadcasting = false);
    }
  }

  static String _short(String txid) =>
      txid.length <= 16 ? txid : '${txid.substring(0, 8)}…';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final frames = encodePsbtFrames(widget.psbtBase64);
    debugPrint('[LoopEngineer] PSBT QR: ${frames.length} frame');
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title ?? loc.psbtQrTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: AnimatedQr(frames: frames, size: 280)),
            const SizedBox(height: 12),
            Text(
              widget.footer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (frames.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                loc.psbtQrFrames('${frames.length}'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy, size: 18),
              label: Text(loc.psbtCopyBase64),
            ),
            const SizedBox(height: 8),
            if (widget.onBroadcast != null)
              FilledButton.icon(
                onPressed: _broadcasting ? null : _broadcast,
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  _broadcasting ? loc.psbtBroadcasting : loc.psbtBroadcast,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
