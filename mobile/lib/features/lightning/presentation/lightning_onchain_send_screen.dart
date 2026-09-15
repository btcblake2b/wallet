import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/lightning_onchain_fees.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../wallet/presentation/scan_qr_screen.dart';

/// Invio on-chain dal nodo Lightning (withdraw) con conferma forte.
///
/// // FLOW: Gestione nodo Lightning — invio on-chain
/// STEP 1: estimate_onchain_fees → livelli fee (sat/vB)
/// STEP 2: validazione indirizzo/importo lato client
/// STEP 3: pay_onchain → txid; i fondi escono dal wallet del nodo
class LightningOnchainSendScreen extends StatefulWidget {
  const LightningOnchainSendScreen({
    super.key,
    required this.lightningService,
    this.availableSats,
  });

  final LightningService lightningService;

  /// Saldo on-chain noto del nodo (validazione + MAX) — null se ignoto.
  final int? availableSats;

  @override
  State<LightningOnchainSendScreen> createState() =>
      _LightningOnchainSendScreenState();
}

class _LightningOnchainSendScreenState
    extends State<LightningOnchainSendScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  LightningOnchainFees _fees = const LightningOnchainFees();

  // PERCHÉ (bug 15/09): la selezione è per LIVELLO (0=min, 1=economico,
  // 2=prioritario), NON per valore: `feerates` può restituire lo stesso sat/vB
  // su più livelli e col confronto sul valore tutti i chip risultavano
  // selezionati (azzurri fissi) e non cliccabili.
  int? _selectedTier;

  bool _sending = false;
  String? _txid;

  /// Fee del livello scelto (null = decide il nodo).
  int? get _selectedFeeSatVb => switch (_selectedTier) {
        0 => _fees.minSatVb,
        1 => _fees.economicalSatVb,
        2 => _fees.prioritySatVb,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFees());
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFees() async {
    try {
      // FLOW: STEP 1
      final fees = await widget.lightningService.estimateOnchainFees();
      if (!mounted) return;
      setState(() {
        _fees = fees;
        // Default: livello economico se disponibile, altrimenti il minimo.
        _selectedTier = fees.economicalSatVb != null
            ? 1
            : (fees.minSatVb != null ? 0 : null);
      });
    } on LightningException catch (e) {
      // PERCHÉ: la stima è un'ottimizzazione — se fallisce, l'invio resta
      // possibile con la fee scelta dal nodo.
      debugPrint('[LoopEngineer] estimate_onchain_fees non disponibile: $e');
    }
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(mode: ScanQrMode.bitcoinAddress),
      ),
    );
    if (scanned == null || !mounted) return;
    setState(() => _addressController.text = scanned);
  }

  void _setMax() {
    final available = widget.availableSats;
    if (available == null) return;
    setState(() => _amountController.text = '$available');
  }

  Future<void> _send() async {
    final loc = AppLocalizations.of(context);
    final address = _addressController.text.trim();
    final amountSats = int.tryParse(_amountController.text.trim());

    // FLOW: STEP 2 — validazione locale prima di toccare i fondi.
    if (!BitcoinNetworkConfig.isValidAddress(address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningOnchainInvalidAddress)),
      );
      return;
    }
    if (amountSats == null || amountSats <= 0) return;
    final available = widget.availableSats;
    if (available != null && amountSats > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningOnchainInsufficient)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningOnchainConfirmTitle),
        content: Text(
          '$address\n'
          '$amountSats sat'
          '${_selectedFeeSatVb != null ? ' · $_selectedFeeSatVb sat/vB' : ''}\n\n'
          '${loc.lightningOnchainWarning}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.lightningCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(loc.lightningConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    try {
      // FLOW: STEP 3
      final result = await widget.lightningService.payOnchain(
        address: address,
        amountSats: amountSats,
        feeRateSatVb: _selectedFeeSatVb,
      );
      debugPrint('[LoopEngineer] pay_onchain inviato: txid=${result.txid}');
      if (!mounted) return;
      setState(() => _txid = result.txid);
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
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final txid = _txid;
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningOnchainSendTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (txid != null)
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.lightningAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(loc.lightningOnchainSuccess),
                    const SizedBox(height: 8),
                    SelectableText(
                      txid,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(loc.homeOk),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _addressController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: loc.lightningOnchainAddressLabel,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: loc.scanQrTitle,
                    onPressed: _sending ? null : _scan,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: loc.lightningOnchainAmountLabel,
                  suffixIcon: TextButton(
                    onPressed: _setMax,
                    child: Text(loc.sendScreenMax),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.lightningOnchainFeeLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (!_fees.isEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    _feeChip(loc.lightningOnchainFeeMin, _fees.minSatVb, 0),
                    _feeChip(
                      loc.lightningOnchainFeeEconomical,
                      _fees.economicalSatVb,
                      1,
                    ),
                    _feeChip(
                      loc.lightningOnchainFeePriority,
                      _fees.prioritySatVb,
                      2,
                    ),
                  ],
                )
              else
                Text(
                  loc.lightningFeesUnavailable,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(loc.lightningOnchainConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feeChip(String label, int? satVb, int tier) {
    if (satVb == null) return const SizedBox.shrink();
    // PERCHÉ: l'identità è il livello — due livelli possono avere lo stesso
    // sat/vB e restare comunque selezionabili singolarmente.
    final selected = _selectedTier == tier;
    return ChoiceChip(
      label: Text('$label · $satVb sat/vB'),
      selected: selected,
      onSelected: (_) => setState(() => _selectedTier = tier),
    );
  }
}
