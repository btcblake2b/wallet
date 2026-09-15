import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_balance.dart';
import '../../../core/models/lightning_node_address.dart';
import '../../../core/models/lightning_utxo.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'lightning_deposit_screen.dart';
import 'lightning_onchain_send_screen.dart';

/// On-chain del nodo: saldo, indirizzi di deposito e UTXO.
///
/// // FLOW: On-chain del nodo Lightning
/// STEP 1: get_balance + list_addresses + list_utxos (una sola schermata)
/// STEP 2: nuovo indirizzo (bech32 o taproot) per il deposito
/// STEP 3: invio on-chain → schermata di conferma forte (I1)
class LightningOnchainScreen extends StatefulWidget {
  const LightningOnchainScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningOnchainScreen> createState() => _LightningOnchainScreenState();
}

class _LightningOnchainScreenState extends State<LightningOnchainScreen> {
  LightningBalance? _balance;
  List<LightningNodeAddress> _addresses = const [];
  List<LightningUtxo> _utxos = const [];
  LightningException? _error;
  bool _loading = false;
  bool _creating = false;

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.lightningService.getBalance(),
        widget.lightningService.listAddresses(),
        widget.lightningService.listUtxos(),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0] as LightningBalance;
        _addresses = results[1] as List<LightningNodeAddress>;
        _utxos = results[2] as List<LightningUtxo>;
      });
      debugPrint(
        '[LoopEngineer] onchain: ${_addresses.length} indirizzi, '
        '${_utxos.length} utxo',
      );
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(LightningException e) {
    if (!mounted) return;
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

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  /// Chiede il tipo di indirizzo e ne genera uno nuovo dal nodo.
  Future<void> _newAddress() async {
    final loc = AppLocalizations.of(context);
    var type = 'bech32';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningOnchainNewAddress),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.lightningOnchainAddressType),
              const SizedBox(height: 12),
              // PERCHÉ: SegmentedButton (già usato nella home) invece di radio:
              // niente API deprecate e stesso linguaggio visivo dell'app.
              SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'bech32',
                    label: Text(loc.lightningOnchainTypeBech32),
                  ),
                  ButtonSegment<String>(
                    value: 'p2tr',
                    label: Text(loc.lightningOnchainTypeTaproot),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (selection) =>
                    setDialogState(() => type = selection.first),
              ),
            ],
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

    setState(() => _creating = true);
    try {
      final address = await widget.lightningService.makeNewAddress(
        addressType: type,
      );
      debugPrint('[LoopEngineer] onchain: nuovo indirizzo ${address.type}');
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(address.address)),
      );
    } on LightningException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  int get _confirmedSats => _utxos
      .where((u) => u.isConfirmed)
      .fold(0, (sum, u) => sum + u.amountSats);

  int get _pendingSats => _utxos
      .where((u) => !u.isConfirmed)
      .fold(0, (sum, u) => sum + u.amountSats);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balance = _balance;

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningOnchainNode)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading && balance == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (_error != null)
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _error!.isPermissionDenied
                          ? loc.lightningErrorRestricted
                          : loc.lightningErrorGeneric(_error!.message),
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                if (balance?.onchainSats != null)
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.lightningOnchainBalance,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt(balance!.onchainSats!)} sat',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.lightningAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${loc.lightningOnchainConfirmed}: '
                          '${_fmt(_confirmedSats)} sat',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.greenAccent),
                        ),
                        if (_pendingSats > 0)
                          Text(
                            '${loc.lightningOnchainPending}: '
                            '${_fmt(_pendingSats)} sat',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.orangeAccent),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LightningDepositScreen(
                                lightningService: widget.lightningService,
                              ),
                            ),
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: Text(loc.lightningDeposit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LightningOnchainSendScreen(
                                lightningService: widget.lightningService,
                              ),
                            ),
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: Text(loc.lightningWithdraw),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.lightningOnchainAddresses,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _creating ? null : _newAddress,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(loc.lightningOnchainNewAddress),
                    ),
                  ],
                ),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      for (final a in _addresses)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.shortAddress,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      [
                                        if (a.keyIndex != null)
                                          '#${a.keyIndex}',
                                        if (a.type != null) a.type!,
                                      ].join(' · '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (a.hasFunds == true)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    loc.lightningOnchainHasFunds,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.greenAccent),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: loc.lightningCopied,
                                onPressed: () => _copy(a.address),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.lightningOnchainUtxos,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      if (_utxos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            loc.lightningOnchainUtxosEmpty,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      else
                        for (final u in _utxos)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_fmt(u.amountSats)} sat',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: u.isConfirmed
                                              ? Colors.greenAccent
                                              : Colors.orangeAccent,
                                        ),
                                      ),
                                      Text(
                                        [
                                          u.isConfirmed
                                              ? loc.lightningOnchainConfirmed
                                              : loc.lightningOnchainPending,
                                          if (u.blockHeight != null)
                                            '${loc.lightningOnchainBlockHeight}'
                                                ' ${u.blockHeight}',
                                          if (u.reserved)
                                            loc.lightningOnchainReserved,
                                        ].join(' · '),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Text(
                                        ':${u.vout} · ${u.shortTxid}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: loc.lightningCopied,
                                  onPressed: () => _copy(u.txid),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
