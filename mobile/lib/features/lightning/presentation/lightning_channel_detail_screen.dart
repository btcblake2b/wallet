import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_channel.dart';
import '../../../core/models/lightning_channel_fees.dart';
import '../../../core/models/lightning_splice.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cln_release_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/info_dot.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/info_hints_l10n.dart';

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

  /// Splice in corso: blocca le azioni sul canale finché il nodo risponde.
  bool _splicing = false;

  /// Policy di routing letta dal nodo (base/ppm/limiti HTLC/cltv/riserve).
  LightningChannelFees? _fees;
  bool _savingFees = false;

  /// Indirizzo del peer (`host:porta`) per comporre `pubkey@host:porta`.
  String? _peerAddress;

  /// Supporto dello splice da parte della release del nodo (26/10).
  ///
  /// // PERCHÉ: lo splice esiste solo da `.6` e sotto `.9` porta con sé buchi di
  /// sicurezza che possono costare i fondi del canale (`ecosystem-watch.md`,
  /// `W-98`): l'utente deve saperlo PRIMA di premere, non dopo l'errore.
  ClnSpliceSupport _spliceSupport = ClnSpliceSupport.unknown;

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  /// True se lo splice non è proponibile su questo canale.
  ///
  /// // PERCHÉ (SPLICE): il nodo accetta lo splice solo su un canale pronto
  /// // (`Usable`) e con il peer raggiungibile — su un canale in apertura o con
  /// // peer offline la richiesta fallirebbe dopo aver già costruito il PSBT.
  bool get _spliceBlocked =>
      !widget.channel.isUsable || widget.channel.peerConnected == false;

  /// Testo dell'errore di splice, con la causa spiegata quando è riconoscibile.
  ///
  /// // PERCHÉ: `NOT_IMPLEMENTED` qui non è "errore generico" — significa che il
  /// // bridge del nodo è più vecchio dell'app e non conosce le operazioni di
  /// // splice; dirlo evita di far cercare il problema su CLN o sul peer.
  String _spliceErrorText(AppLocalizations loc, LightningException e) {
    if (e.isPermissionDenied) return loc.lightningErrorRestricted;
    if (e.code == 'NOT_IMPLEMENTED') return loc.lightningSpliceBridgeOutdated;
    if (e.code == 'INSUFFICIENT_BALANCE') {
      // PERCHÉ: lo splice-in si fonda sul wallet on-chain del nodo — il testo di
      // CLN dice di quanto manca ("25298sat short"), quindi si tiene in coda.
      return '${loc.lightningSpliceInsufficientOnchain}\n${e.message}';
    }
    if (e.code == 'CHANNEL_FAILED') {
      // PERCHÉ: qui vuol dire quasi sempre "il peer non sa fare lo splice"
      // (canali senza `option_unified_sigs`).
      return '${loc.lightningSpliceChannelFailed}\n${e.message}';
    }
    return loc.lightningErrorGeneric(e.message);
  }

  /// Fondi on-chain del nodo (msat→sat), null se il nodo non li espone.
  ///
  /// // PERCHÉ (SPLICE): il splice-in spende il wallet on-chain del nodo; sapere
  /// // quanto c'è evita di far costruire un PSBT che non può essere finanziato.
  Future<int?> _loadOnchainSats() async {
    try {
      final balance = await widget.lightningService.getBalance();
      return balance.onchainSats;
    } on LightningException catch (e) {
      debugPrint('[LoopEngineer] on-chain del nodo non letto (${e.code})');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFees());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPeerAddress());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNodeVersion());
  }

  /// Versione del nodo → stato dello splice. Tollerante: se la lettura fallisce
  /// resta `unknown` e non si mostra nessun avviso.
  Future<void> _loadNodeVersion() async {
    try {
      final info = await widget.lightningService.getInfo();
      if (!mounted) return;
      setState(() => _spliceSupport = parseSpliceSupport(info.version));
    } on LightningException catch (e) {
      debugPrint('[LoopEngineer] versione del nodo non letta (${e.code})');
    }
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

  /// Indirizzo del peer per il formato `pubkey@host:porta` (da copiare).
  ///
  /// // PERCHÉ: il canale non porta il netaddr del peer; si incrocia
  /// // `list_peers` sull'id — si preferisce remote_addr (attivo), poi il
  /// // primo indirizzo annunciato.
  Future<void> _loadPeerAddress() async {
    try {
      final peers = await widget.lightningService.listPeers();
      for (final p in peers) {
        if (p.id != widget.channel.peerPubkey) continue;
        final addr = (p.remoteAddr?.isNotEmpty ?? false)
            ? p.remoteAddr
            : (p.addresses.isNotEmpty ? p.addresses.first : null);
        if (addr != null && mounted) {
          setState(() => _peerAddress = addr);
        }
        break;
      }
    } on LightningException catch (e) {
      debugPrint('[LoopEngineer] peer address non disponibile (${e.code})');
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
                initialValue: newMinSats == null ? '' : '$newMinSats',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.lightningHtlcMinLabel,
                ),
                onChanged: (v) =>
                    newMinSats = int.tryParse(v.trim()) ?? newMinSats,
              ),
              TextFormField(
                initialValue: newMaxSats == null ? '' : '$newMaxSats',
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
          force ? loc.lightningCloseChannelForceWarning : loc.lightningConfirm,
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

  /// Splice: ridimensiona il canale senza chiuderlo.
  ///
  /// // PERCHÉ (SPLICE): chiudere e riaprire costa due transazioni on-chain e
  /// // interrompe il canale; qui il canale resta online e si paga una sola
  /// // transazione. L'importo è sempre positivo nella UI: il segno (splice-in
  /// // vs splice-out) lo decide la direzione scelta.
  Future<void> _splice() async {
    final loc = AppLocalizations.of(context);
    var addFunds = true;
    var amountSats = 0;
    LightningSpliceEstimate? estimate;
    var estimating = false;

    // PERCHÉ: il splice-in spende l'on-chain del nodo — se non basta il PSBT
    // fallisce dopo la conferma, quindi il dato va mostrato PRIMA.
    final onchainSats = await _loadOnchainSats();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(loc.lightningSpliceTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(loc.lightningSpliceIn),
                      icon: const Icon(Icons.add, size: 16),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(loc.lightningSpliceOut),
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                  ],
                  selected: {addFunds},
                  onSelectionChanged: (selection) {
                    setDialogState(() {
                      addFunds = selection.first;
                      estimate = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.lightningSpliceAmountLabel,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim()) ?? 0;
                    // PERCHÉ: il tasto "Stima fee" si abilita solo con un
                    // importo valido — la condizione è valutata al build, quindi
                    // ogni modifica deve ricostruire il dialog.
                    setDialogState(() {
                      amountSats = parsed;
                      estimate = null;
                    });
                  },
                ),
                if (addFunds) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: estimating || amountSats <= 0
                        ? null
                        : () async {
                            // PERCHÉ: il messenger si cattura PRIMA dell'await —
                            // `context` attraverserebbe un async gap e il check
                            // giusto (dialogContext.mounted) non lo copre.
                            final messenger = ScaffoldMessenger.of(context);
                            setDialogState(() => estimating = true);
                            try {
                              final result =
                                  await widget.lightningService.estimateSplice(
                                amountSats: amountSats,
                              );
                              if (!dialogContext.mounted) return;
                              setDialogState(() => estimate = result);
                            } on LightningException catch (e) {
                              if (!dialogContext.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(_spliceErrorText(loc, e)),
                                ),
                              );
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(() => estimating = false);
                              }
                            }
                          },
                    icon: const Icon(Icons.speed, size: 18),
                    label: Text(loc.lightningSpliceEstimate),
                  ),
                  if (estimate != null)
                    Text(
                      estimate!.feeSats == null
                          ? loc.lightningSpliceFeeUnavailable
                          : loc.lightningSpliceFee(estimate!.feeSats!),
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  if (onchainSats != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      loc.lightningSpliceOnchainAvailable(
                        _fmt(onchainSats),
                      ),
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                    if (amountSats >= onchainSats)
                      Text(
                        loc.lightningSpliceInsufficientOnchain,
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.orangeAccent),
                      ),
                  ],
                ],
                // PERCHÉ (26/10): da `.6` a `.8` lo splice funziona ma mancano i
                // fix di sicurezza che chiudono una perdita di fondi — l'avviso
                // sta dove si decide, non in una pagina di documentazione.
                if (_spliceSupport == ClnSpliceSupport.outdated) ...[
                  const SizedBox(height: 12),
                  Text(
                    loc.lightningSpliceNodeOutdated,
                    style: Theme.of(dialogContext)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.orangeAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.lightningCancel),
            ),
            TextButton(
              onPressed: () {
                if (amountSats <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.lightningSpliceInvalidAmount)),
                  );
                  return;
                }
                // PERCHÉ: senza fondi on-chain sufficienti `fundpsbt` fallirebbe
                // a PSBT già impostato — si blocca qui, con la cifra mancante.
                if (addFunds &&
                    onchainSats != null &&
                    amountSats >= onchainSats) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.lightningSpliceInsufficientOnchain),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(loc.lightningConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _splicing = true);
    try {
      await widget.lightningService.spliceChannel(
        channelId: widget.channel.id,
        amountSats: addFunds ? amountSats : -amountSats,
      );
      debugPrint(
        '[LoopEngineer] splice_channel inviato '
        '(id=${widget.channel.id}, amount=${addFunds ? amountSats : -amountSats})',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningSpliceDone)),
      );
      Navigator.of(context).pop(true);
    } on LightningException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_spliceErrorText(loc, e))),
      );
    } finally {
      if (mounted) setState(() => _splicing = false);
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PERCHÉ (26/10): con lo stato di splice (`CHANNELD_AWAITING_SPLICE`)
                  // il badge è molto più largo del solito e questa Row può
                  // sforare: il badge si accorcia con ellissi e resta leggibile
                  // anche su schermi stretti.
                  Row(
                    children: [
                      Flexible(
                        child: Container(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: stateColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ch.peerConnected != null)
                        Flexible(
                          child: Text(
                            ch.peerConnected!
                                ? loc.lightningConnected
                                : loc.lightningPeerDisconnected,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row(
                    loc.lightningChannelPeer,
                    ch.peerLabel ?? ch.peerPubkey,
                    copyValue: ch.peerPubkey,
                  ),
                  if (_peerAddress != null)
                    _row(
                      loc.lightningChannelPeerAddress,
                      '${ch.peerPubkey}@$_peerAddress',
                      copyValue: '${ch.peerPubkey}@$_peerAddress',
                    ),
                  _row(
                    loc.lightningChannelShortId,
                    ch.shortChannelId ?? ch.id,
                    copyValue: ch.shortChannelId ?? ch.id,
                  ),
                  _row(
                    loc.lightningChannelCapacity,
                    '${_fmt(ch.capacitySats)} sat',
                  ),
                  const InfoDot(id: InfoHintId.channelCapacity),
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
                  const InfoDot(id: InfoHintId.htlc, size: 14),
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
                        Flexible(
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
                    if (_fees!.reserveSats != null) ...[
                      _row(
                        loc.lightningChannelReserve,
                        '${_fmt(_fees!.reserveSats!)} sat',
                      ),
                      const InfoDot(id: InfoHintId.channelReserve, size: 14),
                    ],
                    if (_fees!.toSelfDelay != null) ...[
                      _row(
                        loc.lightningChannelToSelfDelay,
                        '${_fees!.toSelfDelay}',
                      ),
                      const InfoDot(id: InfoHintId.toSelfDelay, size: 14),
                    ],
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
            if (_spliceBlocked) ...[
              Text(
                loc.lightningSpliceUnavailable,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
            ],
            // PERCHÉ (26/10): sotto `.6` lo splice non esiste proprio nel nodo —
            // un pulsante che fallisce sempre è peggio del pulsante assente,
            // quindi al suo posto si spiega cosa serve aggiornare.
            if (_spliceSupport == ClnSpliceSupport.unavailable) ...[
              Text(
                loc.lightningSpliceNodeTooOld,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.orangeAccent),
              ),
              const SizedBox(height: 6),
            ] else
              OutlinedButton.icon(
                onPressed:
                    (_closing || _splicing || _spliceBlocked) ? null : _splice,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Text(loc.lightningSplice),
              ),
            const SizedBox(height: 8),
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
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.lightningCloseChannelForce),
                  const InfoDot(id: InfoHintId.forceClose),
                ],
              ),
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
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
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
