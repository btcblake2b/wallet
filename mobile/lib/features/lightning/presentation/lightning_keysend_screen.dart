import 'package:flutter/material.dart';

import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

/// Invio "keysend": paga un nodo SENZA fattura, conoscendone la pubkey.
///
/// // FLOW: Gestione nodo Lightning — keysend
/// STEP 1: get_node_info (best-effort: dà un nome al destinatario)
/// STEP 2: conferma esplicita con destinazione + importo + fee massima
/// STEP 3: keysend (muove fondi subito, mai ritentato su timeout)
class LightningKeysendScreen extends StatefulWidget {
  const LightningKeysendScreen({
    super.key,
    required this.lightningService,
  });

  final LightningService lightningService;

  @override
  State<LightningKeysendScreen> createState() => _LightningKeysendScreenState();
}

class _LightningKeysendScreenState extends State<LightningKeysendScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _maxFeeController = TextEditingController();

  bool _sending = false;

  /// Nome del destinatario risolto dal gossip (null = non risolto).
  String? _peerName;
  bool _resolving = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    _maxFeeController.dispose();
    super.dispose();
  }

  /// Una pubkey di nodo è di 33 byte = 66 caratteri esadecimali (02/03).
  static bool _isValidPubkey(String value) =>
      RegExp(r'^0[23][0-9a-fA-F]{64}$').hasMatch(value.trim());

  /// Chiede al gossip chi è il destinatario (best-effort: senza gossip si
  /// procede comunque, mostrando l'id troncato).
  Future<void> _resolvePeer() async {
    final destination = _destinationController.text.trim();
    if (!_isValidPubkey(destination) || _resolving) return;
    setState(() => _resolving = true);
    try {
      final node = await widget.lightningService.getNodeInfo(destination);
      if (!mounted) return;
      setState(() => _peerName = node.displayName);
      debugPrint('[LoopEngineer] keysend: destinatario ${node.displayName}');
    } on LightningException catch (e) {
      // PERCHÉ: la risoluzione è un di più — se il nodo non è nel gossip si
      // continua con l'id troncato, senza allarmare l'utente.
      debugPrint(
          '[LoopEngineer] keysend: get_node_info non risolto (${e.code})',);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context);
    final destination = _destinationController.text.trim();
    if (!_isValidPubkey(destination)) {
      _snack(loc.lightningKeysendInvalidPubkey);
      return;
    }
    final amountSats = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amountSats <= 0) {
      _snack(loc.lightningKeysendInvalidAmount);
      return;
    }
    final maxFeeSats = int.tryParse(_maxFeeController.text.trim());
    // Il nome si risolve ora: la conferma deve dire A CHI si sta pagando.
    await _resolvePeer();
    if (!mounted) return;
    final target = _peerName ?? _shortId(destination);

    // PERCHÉ: conferma forte — un keysend sposta fondi subito e non si annulla.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningKeysendConfirmTitle),
        content: Text(
          '${loc.lightningKeysendDestination}: $target\n'
          '$amountSats sat\n\n'
          '${loc.lightningKeysendWarning}',
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

    setState(() => _sending = true);
    try {
      final result = await widget.lightningService.sendKeysend(
        destination: destination,
        amountSats: amountSats,
        // Le fee massime in sat → msat (il protocollo ragiona in msat).
        maxFeeMsat: maxFeeSats == null ? null : maxFeeSats * 1000,
      );
      if (!mounted) return;
      _snack(
        result.feeSats == null
            ? '${loc.lightningKeysendSent}: ${result.amountSats} sat'
            : '${loc.lightningKeysendSent}: ${result.amountSats} sat '
                '(+${result.feeSats} sat)',
      );
      debugPrint(
        '[LoopEngineer] keysend inviato: ${result.paymentHash} '
        '(status=${result.status})',
      );
      Navigator.of(context).pop(true);
    } on LightningException catch (e) {
      if (!mounted) return;
      _snack(
        e.isPermissionDenied
            ? loc.lightningErrorRestricted
            : loc.lightningErrorGeneric(e.message),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _shortId(String id) =>
      id.length <= 16 ? id : '${id.substring(0, 16)}…';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final destination = _destinationController.text.trim();

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningKeysendTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _destinationController,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                // Un nuovo destinatario azzera il nome risolto prima.
                if (_peerName != null) setState(() => _peerName = null);
              },
              onSubmitted: (_) => _resolvePeer(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningKeysendHint,
                helperText: _peerName == null
                    ? null
                    : '${loc.lightningKeysendDestination}: $_peerName',
                suffixIcon: _resolving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: loc.lightningKeysendDestination,
                        onPressed:
                            _isValidPubkey(destination) ? _resolvePeer : null,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningKeysendAmountLabel,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxFeeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningKeysendMaxFeeLabel,
                helperText: loc.lightningKeysendMaxFeeHelp,
              ),
            ),
            const SizedBox(height: 20),
            // PERCHÉ: avviso sempre visibile, non solo nel dialog: l'utente
            // deve sapere PRIMA di premere che il pagamento è immediato.
            Text(
              loc.lightningKeysendWarning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orangeAccent),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flash_on),
              label: Text(loc.lightningKeysendSend),
            ),
          ],
        ),
      ),
    );
  }
}
