import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_cross_chain.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lightning_invoice_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Paga una fattura della chain SHA-256 con i fondi della chain BLAKE2b.
///
/// // FLOW (P9) — pagamento cross-chain non-custodial:
/// STEP 1: incolla la fattura e verifica il costo (nessuna prenotazione)
/// STEP 2: conferma → il bridge emette una hold invoice sulla nostra chain
/// STEP 3: paghiamo la hold invoice; il bridge incassa solo dopo aver pagato
///         la fattura di destinazione (se fallisce, scade e i sat tornano)
class LightningCrossChainScreen extends StatefulWidget {
  const LightningCrossChainScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningCrossChainScreen> createState() =>
      _LightningCrossChainScreenState();
}

class _LightningCrossChainScreenState extends State<LightningCrossChainScreen> {
  final TextEditingController _invoiceController = TextEditingController();

  LightningCrossChainEstimate? _estimate;
  LightningCrossChainResult? _result;
  bool _checking = false;
  bool _paying = false;

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  /// Cambio e spread arrivano dal bridge come frazioni (`0.98`, `0.02`).
  static final NumberFormat _rateFmt = NumberFormat('#,##0.####');
  static final NumberFormat _spreadFmt = NumberFormat('0.##');

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final invoice = normalizeLightningInvoice(_invoiceController.text);
    if (invoice.isEmpty) return;
    setState(() => _checking = true);
    try {
      final estimate = await widget.lightningService.crossChainCheck(invoice);
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _result = null;
      });
    } on LightningException catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _pay() async {
    final loc = AppLocalizations.of(context);
    final estimate = _estimate;
    if (estimate == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningCrossChainConfirmTitle),
        content: Text(
          loc.lightningCrossChainConfirmBody(
            _fmt(estimate.costSats ?? estimate.amountSats),
          ),
        ),
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

    final invoice = normalizeLightningInvoice(_invoiceController.text);
    setState(() => _paying = true);
    try {
      // PERCHÉ: il tetto blocca il pagamento se il cambio si è mosso tra la
      // verifica e il quote — l'utente ha approvato quella cifra, non una più alta.
      final result = await widget.lightningService.crossChainPay(
        invoice,
        maxSats: estimate.costSats == null
            ? null
            : (estimate.costSats! * 102) ~/ 100,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on LightningException catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showError(LightningException e) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.isPermissionDenied
              ? loc.lightningErrorRestricted
              : loc.lightningErrorGeneric(e.message),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final estimate = _estimate;
    final result = _result;
    final busy = _checking || _paying;

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningCrossChainTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              loc.lightningCrossChainHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _invoiceController,
              maxLines: 4,
              minLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: loc.lightningPayHint,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : _check,
              icon: _checking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: Text(loc.lightningCrossChainCheck),
            ),
            if (estimate != null) ...[
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.lightningCrossChainCost(
                        _fmt(estimate.costSats ?? estimate.amountSats),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.lightningCrossChainInvoiceAmount(
                        _fmt(estimate.amountSats),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // PERCHÉ: il costo dipende da cambio e spread del bridge:
                    // mostrarli separati rende verificabile il prezzo invece
                    // di un solo totale opaco.
                    if (estimate.rate != null)
                      Text(
                        loc.lightningCrossChainRate(
                          _rateFmt.format(estimate.rate!),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (estimate.spread != null)
                      Text(
                        loc.lightningCrossChainSpread(
                          _spreadFmt.format(estimate.spread! * 100),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (estimate.waitSeconds != null)
                      Text(
                        loc.lightningCrossChainWait(estimate.waitSeconds!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ? null : _pay,
                icon: _paying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(loc.lightningCrossChainPay),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isSettled
                          ? loc.lightningCrossChainDone
                          : loc.lightningCrossChainState(result.state),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: result.isSettled ? Colors.greenAccent : null,
                          ),
                    ),
                    if (result.preimage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        result.preimage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
