import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/lightning_invoice.dart';
import '../../../core/models/lightning_offer.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/inbound_liquidity_card.dart';

/// Ricezione Lightning: crea un invoice e lo mostra come QR + testo.
class LightningReceiveScreen extends StatefulWidget {
  const LightningReceiveScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  /// Ogni quanto interrogare il nodo per sapere se l'invoice è stata pagata.
  static const Duration pollInterval = Duration(seconds: 5);

  /// Dopo N errori consecutivi il polling si ferma (nodo irraggiungibile).
  static const int maxPollFailures = 3;

  @override
  State<LightningReceiveScreen> createState() => _LightningReceiveScreenState();
}

class _LightningReceiveScreenState extends State<LightningReceiveScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  LightningInvoice? _invoice;
  bool _creating = false;

  /// Polling dello stato della fattura (5 s) mentre la schermata è aperta.
  Timer? _pollTimer;
  int _pollFailures = 0;
  bool _paid = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// // PERCHÉ (I3c): senza polling l'utente non sa se il pagamento è arrivato
  /// — deve indovinare guardando il saldo. Bastano poche righe per mostrare
  /// "Pagata" appena il nodo la registra.
  void _startPolling(String paymentHash) {
    _pollTimer?.cancel();
    _pollFailures = 0;
    _paid = false;
    _pollTimer = Timer.periodic(
      LightningReceiveScreen.pollInterval,
      (_) => _checkPaid(paymentHash),
    );
  }

  Future<void> _checkPaid(String paymentHash) async {
    try {
      final invoice = await widget.lightningService.lookupInvoice(
        paymentHash: paymentHash,
      );
      if (!mounted) return;
      _pollFailures = 0;
      if (!invoice.isPaid) return;
      _pollTimer?.cancel();
      setState(() => _paid = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).lightningReceivePaid),
        ),
      );
      debugPrint('[LoopEngineer] receive: fattura pagata');
    } on LightningException catch (e) {
      _pollFailures++;
      debugPrint('[LoopEngineer] receive: lookup fallito (${e.code})');
      if (_pollFailures >= LightningReceiveScreen.maxPollFailures) {
        _pollTimer?.cancel();
      }
    }
  }

  /// Offerta BOLT12 creata (modalità "codice riutilizzabile").
  LightningOffer? _offer;

  /// True = crea un'offerta BOLT12 invece di una fattura monouso.
  ///
  /// // PERCHÉ (BOLT12): la fattura va rigenerata per ogni pagamento; un
  /// // codice offerta resta valido e chi paga sceglie l'importo. Nessun
  /// // polling: un'offerta non è un singolo pagamento.
  bool _reusable = false;

  Future<void> _create() async {
    final loc = AppLocalizations.of(context);
    final sats = int.tryParse(_amountController.text.trim());
    if (!_reusable && (sats == null || sats <= 0)) return;
    final description = _descriptionController.text.trim();
    setState(() => _creating = true);
    try {
      if (_reusable) {
        final offer = await widget.lightningService.makeOffer(
          description: description.isEmpty
              ? loc.lightningOfferDefaultDescription
              : description,
          amountMsat: (sats != null && sats > 0) ? sats * 1000 : null,
        );
        if (!mounted) return;
        setState(() {
          _offer = offer;
          _invoice = null;
        });
        return;
      }
      final invoice = await widget.lightningService.makeInvoice(
        amountMsat: sats! * 1000,
        description: description,
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _offer = null;
      });
      _startPolling(invoice.paymentHash);
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
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _copy() async {
    final invoice = _invoice;
    final code = _offer?.bolt12 ?? invoice?.bolt11;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final invoice = _invoice;
    final offer = _offer;
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningReceive)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PERCHÉ (BOLT12): due modi di ricevere — fattura monouso (BOLT11)
            // o codice riutilizzabile (offerta). La scelta è esplicita perché
            // cambia cosa si condivide: un codice stabile contro un QR che scade.
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(loc.lightningReceiveModeInvoice),
                  icon: const Icon(Icons.receipt_long, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(loc.lightningReceiveModeOffer),
                  icon: const Icon(Icons.qr_code_2, size: 16),
                ),
              ],
              selected: {_reusable},
              onSelectionChanged: (selection) => setState(() {
                _reusable = selection.first;
                _invoice = null;
                _offer = null;
                _paid = false;
                _pollTimer?.cancel();
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _reusable
                    ? loc.lightningOfferAmountOptional
                    : loc.lightningInvoiceAmount,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningInvoiceDescription,
              ),
            ),
            const SizedBox(height: 20),
            // PERCHÉ (adozione, 26/10): l'avviso sta PRIMA del pulsante che
            // genera il QR — è l'ultimo punto utile per dirlo, perché subito
            // dopo l'utente condivide un codice che nessuno potrà pagare.
            InboundLiquidityCard(lightningService: widget.lightningService),
            FilledButton.icon(
              onPressed: _creating ? null : _create,
              icon: _creating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(loc.lightningInvoiceCreate),
            ),
            if (offer != null) ...[
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      loc.lightningOfferTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.lightningOfferReusableHint,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      // PERCHÉ: il QR deve restare leggibile in dark mode.
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: QrImageView(
                        data: offer.bolt12,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      offer.bolt12,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(loc.lightningCopied),
                    ),
                  ],
                ),
              ),
            ],
            if (invoice != null) ...[
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      loc.lightningInvoiceTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (_paid) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.lightningReceivePaid,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (invoice.bolt11.isNotEmpty)
                      Container(
                        // PERCHÉ: il QR deve restare leggibile in dark mode.
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: QrImageView(
                          data: invoice.bolt11,
                          version: QrVersions.auto,
                          size: 220,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SelectableText(
                      invoice.bolt11,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(loc.lightningCopied),
                    ),
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
