import 'package:flutter/material.dart';

import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lightning_invoice_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../wallet/presentation/scan_qr_screen.dart';
import 'lightning_keysend_screen.dart';

/// Invio Lightning: incolla l'invoice, conferma e paga.
class LightningSendScreen extends StatefulWidget {
  const LightningSendScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningSendScreen> createState() => _LightningSendScreenState();
}

class _LightningSendScreenState extends State<LightningSendScreen> {
  final TextEditingController _invoiceController = TextEditingController();
  bool _paying = false;

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(mode: ScanQrMode.lightningInvoice),
      ),
    );
    if (scanned == null || !mounted) return;
    setState(() => _invoiceController.text = scanned);
  }

  Future<void> _pay() async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: accetta anche il formato URI `lightning:…`: il nodo vuole la
    // stringa BOLT11 pura.
    final bolt11 = normalizeLightningInvoice(_invoiceController.text);
    if (bolt11.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningPayDialogTitle),
        content: Text(loc.lightningPayDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.lightningCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.lightningConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _paying = true);
    try {
      await widget.lightningService.payInvoice(bolt11);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningPaySuccess)),
      );
      Navigator.of(context).pop();
    } on LightningException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isPermissionDenied
                ? loc.lightningErrorRestricted
                : loc.lightningErrorGeneric(e.message),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningSend)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _invoiceController,
              maxLines: 4,
              minLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: loc.lightningPayHint,
                // PERCHÉ: scanner QR accanto al campo: incollare a mano una
                // invoice lunga è scomodo e soggetto a errori.
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: loc.scanQrTitle,
                  onPressed: _paying ? null : _scan,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(loc.lightningPay),
            ),
            const SizedBox(height: 8),
            // PERCHÉ (I3e): il keysend è un altro modo di pagare (senza
            // fattura) — sta qui, dove l'utente cerca "invia".
            TextButton.icon(
              onPressed: _paying
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => LightningKeysendScreen(
                            lightningService: widget.lightningService,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.flash_on, size: 18),
              label: Text(loc.lightningKeysendTitle),
            ),
          ],
        ),
      ),
    );
  }
}
