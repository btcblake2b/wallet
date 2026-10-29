import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bolt12_offer_utils.dart';
import '../../../core/utils/lightning_invoice_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../wallet/presentation/scan_qr_screen.dart';
import 'lightning_cross_chain_screen.dart';
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
  final TextEditingController _amountController = TextEditingController();
  bool _paying = false;

  /// True quando l'input è un'offerta BOLT12 (`lno1…`) invece di una fattura.
  ///
  /// // PERCHÉ (BOLT12): l'offerta può essere senza importo — in quel caso è
  /// // chi paga a deciderlo, quindi va chiesto prima di inviare.
  bool _isOffer = false;

  /// Importo scritto nell'offerta (msat), se il destinatario l'ha fissato.
  ///
  /// // PERCHÉ (BOLT12): quando c'è, il nodo lo legge dall'offerta: chiederlo
  /// // all'utente sarebbe un campo senza effetto sul pagamento.
  int? _offerAmountMsat;

  /// True se il nodo espone il pagamento cross-chain (`cross_chain_*`).
  ///
  /// // PERCHÉ (P9): il bridge cross-chain è un servizio esterno opzionale:
  /// senza i metodi nel `get_info` la voce sarebbe un vicolo cieco.
  bool _supportsCrossChain = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCapabilities());
  }

  /// Legge le capability del nodo per decidere cosa mostrare.
  ///
  /// // PERCHÉ: in caso di errore si lascia la voce visibile — un `get_info`
  /// // fallito non deve nascondere una funzione che il nodo magari ha.
  Future<void> _loadCapabilities() async {
    try {
      final info = await widget.lightningService.getInfo();
      if (!mounted) return;
      setState(() => _supportsCrossChain = info.supportsCrossChain);
    } on LightningException catch (e) {
      debugPrint('[LoopEngineer] send: capability non lette (${e.code})');
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(mode: ScanQrMode.lightningInvoice),
      ),
    );
    if (scanned == null || !mounted) return;
    setState(() {
      _invoiceController.text = scanned;
      _isOffer = isLightningOffer(scanned);
      _offerAmountMsat = _isOffer ? bolt12OfferAmountMsat(scanned) : null;
    });
  }

  Future<void> _pay() async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: accetta anche il formato URI `lightning:…`: il nodo vuole la
    // stringa pura. Un'offerta BOLT12 (`lno1…`) passa dallo stesso metodo.
    final bolt11 = normalizeLightningInvoice(_invoiceController.text);
    if (bolt11.isEmpty) return;
    // PERCHÉ (BOLT12): se l'offerta porta già l'importo lo legge il nodo;
    // altrimenti lo sceglie chi paga, e senza di esso il nodo non può pagare.
    final needsAmount = _isOffer && _offerAmountMsat == null;
    final amountSats = int.tryParse(_amountController.text.trim());
    final amountMsat = needsAmount && amountSats != null && amountSats > 0
        ? amountSats * 1000
        : null;
    if (needsAmount && amountMsat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningOfferAmountRequired)),
      );
      return;
    }

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
      await widget.lightningService.payInvoice(bolt11, amountMsat: amountMsat);
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
              onChanged: (value) {
                final offer = isLightningOffer(value);
                final offerAmount = offer ? bolt12OfferAmountMsat(value) : null;
                if (offer != _isOffer || offerAmount != _offerAmountMsat) {
                  setState(() {
                    _isOffer = offer;
                    _offerAmountMsat = offerAmount;
                  });
                }
              },
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
            // PERCHÉ (BOLT12): il campo importo compare solo se l'offerta NON
            // lo porta già scritto — altrimenti lo decide il destinatario.
            if (_isOffer && _offerAmountMsat == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: loc.lightningOfferAmountLabel,
                ),
              ),
            ],
            if (_isOffer && _offerAmountMsat != null) ...[
              const SizedBox(height: 12),
              Text(
                loc.lightningOfferFixedAmount(
                  NumberFormat.decimalPattern()
                      .format(_offerAmountMsat! ~/ 1000),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isOffer ? loc.lightningPayOffer : loc.lightningPay),
            ),
            const SizedBox(height: 8),
            // PERCHÉ (P9): pagare una fattura della chain SHA-256 passa da un
            // bridge esterno non-custodial — è un percorso separato, così
            // l'utente sa che sta uscendo dalla nostra chain. Compare solo se
            // il nodo dichiara le due operazioni.
            if (_supportsCrossChain)
              TextButton.icon(
                onPressed: _paying
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                            builder: (_) => LightningCrossChainScreen(
                              lightningService: widget.lightningService,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(loc.lightningCrossChainEntry),
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
