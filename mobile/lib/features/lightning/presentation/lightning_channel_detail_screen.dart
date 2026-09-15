import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_channel.dart';
import '../../../core/models/lightning_channel_fees.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Dettaglio di un canale Lightning del nodo remoto.
///
/// // FLOW: Gestione nodo Lightning — dettaglio canale
/// STEP 1: mostra stato, fee, HTLC e saldi (in sat)
/// STEP 2: chiusura cooperativa o forzata (con conferma esplicita)
class LightningChannelDetailScreen extends StatefulWidget {
  const LightningChannelDetailScreen({
    super.key,
    required this.channel,
    required this.lightningService,
  });

  final LightningChannel channel;
  final LightningService lightningService;

  @override
  State<LightningChannelDetailScreen> createState() =>
      _LightningChannelDetailScreenState();
}

class _LightningChannelDetailScreenState
    extends State<LightningChannelDetailScreen> {
  bool _closing = false;

  /// Policy di routing letta dal nodo (base/ppm/limiti HTLC/cltv/riserve).
  LightningChannelFees? _fees;
  bool _savingFees = false;

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFees());
  }

  /// // PERCHÉ (I3d): base/ppm arrivano già da list_channels, ma i limiti HTLC,
  /// il cltv e le riserve no — una chiamata dedicata completa il dettaglio.
  Future<void> _loadFees() async {
    try {
      final fees = await widget.lightningService.getChannelFees(
        channelId: widget.channel.id,
      );
      if (!mounted) return;
      setState(() => _fees = fees);
      debugPrint('[LoopEngineer] channel fees: ${fees.id}');
    } on LightningException catch (e) {
      // Il dettaglio canale resta usabile anche se il nodo non supporta le fee.
      debugPrint('[LoopEngineer] channel fees non disponibili (${e.code})');
    }
  }

  /// Chiede i nuovi valori e li applica dopo una conferma esplicita.
  Future<void> _editFees() async {
    final loc = AppLocalizations.of(context);
    final current = _fees;
    if (current == null) return;

    // PERCHÉ: niente TextEditingController qui — il dispose immediato dopo
    // `showDialog` fa esplodere i TextField ancora in animazione di uscita
    // ("used after being disposed"); i valori si catturano con onChanged.
    var newBaseSats = current.feeBaseSats;
    var newPpm = current.feePpm;
    var newMinSats = current.htlcMinSats;
    var newMaxSats = current.htlcMaxSats;

    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningFeeEdit),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: '$newBaseSats',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.lightningFeeBaseLabel,
                ),
                // Un campo svuotato mantiene l'ultimo valore valido.
                onChanged: (v) =>
                    newBaseSats = int.tryParse(v.trim()) ?? newBaseSats,
              ),
              TextFormField(
                initialValue: '$newPpm',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.lightningFeePpmLabel,
                ),
                onChanged: (v) => newPpm = int.tryParse(v.trim()) ?? newPpm,
              ),
              TextFormField(
                initialValue:
                    newMinSats == null ? '' : '$newMinSats',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.lightningHtlcMinLabel,
                ),
                onChanged: (v) =>
                    newMinSats = int.tryParse(v.trim()) ?? newMinSats,
              ),
              TextFormField(
                initialValue:
                    newMaxSats == null ? '' : '$newMaxSats',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.lightningHtlcMaxLabel,
                ),
                onChanged: (v) =>
                    newMaxSats = int.tryParse(v.trim()) ?? newMaxSats,
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

    if (apply != true || !mounted) return;

    // PERCHÉ: la conferma mostra prima → dopo: la modifica delle fee cambia ciò
    // che la rete vede e il nodo accetta poche variazioni al giorno.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningFeeConfirmTitle),
        content: Text(
          '${loc.lightningFeeBefore}: ${current.feeBaseSats} sat + '
          '${current.feePpm} ppm\n'
          '${loc.lightningFeeAfter}: $newBaseSats sat + $newPpm ppm\n\n'
          '${loc.lightningFeeWarning}',
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

    // PERCHÉ: copie final — le variabili catturate dagli onChanged non sono
    // promuovibili, quindi qui servono valori locali non-null.
    final minSats = newMinSats;
    final maxSats = newMaxSats;

    setState(() => _savingFees = true);
    try {
      final updated = await widget.lightningService.setChannelFees(
        channelId: widget.channel.id,
        // PERCHÉ: il protocollo vuole i msat, la UI ragiona in sat.
        baseMsat: newBaseSats * 1000,
        ppm: newPpm,
        // PERCHÉ: il nodo può riportare htlcmin 0 (nessun minimo): inviarlo
        // così com'è farebbe fallire tutta la chiamata — si omette.
        htlcMinMsat: minSats == null || minSats <= 0 ? null : minSats * 1000,
        htlcMaxMsat: maxSats == null || maxSats <= 0 ? null : maxSats * 1000,
      );
      if (!mounted) return;
      setState(() => _fees = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.warning == null
                ? loc.lightningFeeUpdated
                : '${loc.lightningFeeUpdated} — ${updated.warning}',
          ),
        ),
      );
      debugPrint('[LoopEngineer] channel fees aggiornate (${updated.id})');
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
      if (mounted) setState(() => _savingFees = false);
    }
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  Future<void> _close({required bool force}) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          force ? loc.lightningCloseChannelForce : loc.lightningCloseChannel,
        ),
        content: Text(
          force
              ? loc.lightningCloseChannelForceWarning
              : loc.lightningConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.lightningCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: force ? Colors.redAccent : null,
            ),
            child: Text(loc.lightningConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    try {
      await widget.lightningService.closeChannel(
        channelId: widget.channel.id,
        force: force,
      );
      debugPrint(
        '[LoopEngineer] close_channel inviato (id=${widget.channel.id})',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ch = widget.channel;
    final stateColor = ch.isUsable ? Colors.greenAccent : Colors.orangeAccent;

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningChannelDetail)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: stateColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          ch.state,
                          style: TextStyle(
                            color: stateColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (ch.peerConnected != null)
                        Text(
                          ch.peerConnected!
                              ? loc.lightningConnected
                              : loc.lightningPeerDisconnected,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row(loc.lightningChannelPeer, ch.peerLabel ?? ch.peerPubkey),
                  _row(
                    loc.lightningChannelShortId,
                    ch.shortChannelId ?? ch.id,
                    copyValue: ch.shortChannelId ?? ch.id,
                  ),
                  _row(
                    loc.lightningChannelCapacity,
                    '${_fmt(ch.capacitySats)} sat',
                  ),
                  _row(
                    loc.lightningChannelSpendable,
                    ch.spendableSats == null
                        ? '—'
                        : '${_fmt(ch.spendableSats!)} sat',
                  ),
                  _row(
                    loc.lightningChannelReceivable,
                    ch.receivableSats == null
                        ? '—'
                        : '${_fmt(ch.receivableSats!)} sat',
                  ),
                  _row(
                    loc.lightningChannelLocal,
                    '${_fmt(ch.localBalanceSats)} sat',
                  ),
                  _row(
                    loc.lightningChannelRemote,
                    '${_fmt(ch.remoteBalanceSats)} sat',
                  ),
                  if (ch.feeBaseSats != null || ch.feePpm != null)
                    _row(
                      loc.lightningChannelFee,
                      '${ch.feeBaseSats ?? 0} sat + ${ch.feePpm ?? 0} ppm',
                    ),
                  _row(loc.lightningChannelHtlcs, '${ch.htlcCount ?? 0}'),
                  if (ch.fundingTxid != null)
                    _row(
                      loc.lightningChannelFundingTxid,
                      ch.fundingTxid!,
                      copyValue: ch.fundingTxid!,
                    ),
                ],
              ),
            ),
            if (_fees != null) ...[
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.lightningChannelFees,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _savingFees ? null : _editFees,
                          icon: const Icon(Icons.tune, size: 18),
                          label: Text(loc.lightningFeeEdit),
                        ),
                      ],
                    ),
                    _row(
                      loc.lightningChannelFee,
                      '${_fees!.feeBaseSats} sat + ${_fees!.feePpm} ppm',
                    ),
                    if (_fees!.htlcMinSats != null)
                      _row(
                        loc.lightningHtlcMinLabel,
                        '${_fmt(_fees!.htlcMinSats!)} sat',
                      ),
                    if (_fees!.htlcMaxSats != null)
                      _row(
                        loc.lightningHtlcMaxLabel,
                        '${_fmt(_fees!.htlcMaxSats!)} sat',
                      ),
                    if (_fees!.cltvDelta != null)
                      _row(loc.lightningCltvLabel, '${_fees!.cltvDelta}'),
                    if (_fees!.reserveSats != null)
                      _row(
                        loc.lightningChannelReserve,
                        '${_fmt(_fees!.reserveSats!)} sat',
                      ),
                    if (_fees!.toSelfDelay != null)
                      _row(
                        loc.lightningChannelToSelfDelay,
                        '${_fees!.toSelfDelay}',
                      ),
                  ],
                ),
              ),
            ],
            if (ch.status != null && ch.status!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.lightningChannelState,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    ...ch.status!.map(
                      (s) => Text(s, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _closing ? null : () => _close(force: false),
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(loc.lightningCloseChannel),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _closing ? null : () => _close(force: true),
              icon: const Icon(Icons.warning_amber, size: 18),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              label: Text(loc.lightningCloseChannelForce),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {String? copyValue}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (copyValue != null)
              InkWell(
                onTap: () => _copy(copyValue),
                child: const Icon(Icons.copy, size: 16),
              ),
          ],
        ),
      );
}
