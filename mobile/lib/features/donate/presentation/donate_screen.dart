import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Indirizzo Bitcoin per donazioni al progetto Btc Blake2b Wallet.
const kDonateBtcAddress = 'bc1q94tmp4s2jk0zkzdjvv6g6rkep0ywppdnepdwav';

/// Schermata di donazione mostrata come full-screen page o bottom sheet.
///
/// Supporta:
/// - Visualizzazione indirizzo Bitcoin
/// - Pulsante copia negli appunti con feedback visivo
/// - Frase motivazionale
/// - Su Android: tentativo di apertura wallet Bitcoin nativo via `bitcoin:` URI
class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  /// Mostra la schermata di donazione come [BottomSheet] modale.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DonateScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AppBackground(
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return GlassContainer(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Titolo
                Text(
                  loc.donateTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Frase motivazionale
                Text(
                  loc.donatePhrase,
                  style: textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Box indirizzo Bitcoin
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        loc.donateAddressLabel,
                        style: textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.06,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        kDonateBtcAddress,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Pulsanti azione
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          const _CopyButton(address: kDonateBtcAddress),
                          if (!kIsWeb &&
                              (defaultTargetPlatform ==
                                      TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS))
                            const _OpenWalletButton(address: kDonateBtcAddress),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nota finale
                Text(
                  loc.donateNote,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pulsante che copia l'indirizzo BTC negli appunti con feedback visivo.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.address});
  final String address;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: _copy,
      icon: Icon(_copied ? Icons.check : Icons.copy),
      label: Text(_copied ? loc.donateCopied : loc.donateCopy),
      style: _copied
          ? FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

/// Pulsante che tenta di aprire un wallet Bitcoin installato sul dispositivo
/// tramite l'URI scheme `bitcoin:` (standard BIP21). Se nessun wallet è
/// installato, mostra un messaggio informativo.
class _OpenWalletButton extends StatefulWidget {
  const _OpenWalletButton({required this.address});
  final String address;

  @override
  State<_OpenWalletButton> createState() => _OpenWalletButtonState();
}

class _OpenWalletButtonState extends State<_OpenWalletButton> {
  bool _loading = false;

  Future<void> _openWallet() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('bitcoin:${widget.address}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showNoWalletDialog();
      }
    } catch (_) {
      if (!mounted) return;
      _showNoWalletDialog();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showNoWalletDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.donateNoWalletTitle),
        content: Text(loc.donateNoWalletMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.homeOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _loading ? null : _openWallet,
      icon: _loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wallet),
      label: Text(loc.donateOpenWallet),
    );
  }
}
