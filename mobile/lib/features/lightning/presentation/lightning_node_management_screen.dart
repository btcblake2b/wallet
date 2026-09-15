import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_balance.dart';
import '../../../core/models/lightning_channel.dart';
import '../../../core/models/lightning_invoice_record.dart';
import '../../../core/models/lightning_movement.dart';
import '../../../core/models/lightning_node_info.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'lightning_channels_screen.dart';
import 'lightning_diagnostics_screen.dart';
import 'lightning_movements_screen.dart';
import 'lightning_onchain_screen.dart';
import 'lightning_payments_screen.dart';
import 'lightning_peers_screen.dart';
import 'widgets/movement_tile.dart';

/// Dashboard di gestione del nodo Lightning: identità, liquidità e movimenti.
///
/// // FLOW: Gestione nodo Lightning
/// STEP 1: get_info (identità e contatori) + get_balance (on-chain/LN)
/// STEP 2: list_channels (liquidità outbound/inbound) + list_transactions
/// STEP 3: navigazione alle sezioni operative (peer, canali, movimenti)
class LightningNodeManagementScreen extends StatefulWidget {
  const LightningNodeManagementScreen({
    super.key,
    required this.lightningService,
  });

  final LightningService lightningService;

  /// Quanti movimenti mostrare in dashboard (lo storico completo ha "tutti").
  static const int previewMovements = 10;

  @override
  State<LightningNodeManagementScreen> createState() =>
      _LightningNodeManagementScreenState();
}

class _LightningNodeManagementScreenState
    extends State<LightningNodeManagementScreen> {
  LightningNodeInfo? _info;
  LightningBalance? _balance;
  List<LightningChannel> _channels = const [];
  List<LightningMovement> _movements = const [];
  List<LightningInvoiceRecord> _invoices = const [];
  LightningException? _error;
  bool _loading = false;

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
      // PERCHÉ: le quattro letture partono insieme — una schermata sola, un
      // solo giro di rete (il nodo risponde in millisecondi).
      final results = await Future.wait([
        widget.lightningService.getInfo(),
        widget.lightningService.getBalance(),
        widget.lightningService.listChannels(),
        widget.lightningService.listTransactions(
          limit: LightningNodeManagementScreen.previewMovements,
        ),
        // PERCHÉ: il riepilogo della riga "Pagamenti" (quante fatture, quante
        // ancora in attesa) arriva dallo stesso giro di rete.
        widget.lightningService.listInvoices(limit: 50),
      ]);
      if (!mounted) return;
      setState(() {
        _info = results[0] as LightningNodeInfo;
        _balance = results[1] as LightningBalance;
        // I4a: i canali chiusi sono storia (Movimenti) — non entrano né in
        // lista né nei contatori di capacità/liquidità (saldi congelati).
        _channels = openOnly(results[2] as List<LightningChannel>);
        _movements = results[3] as List<LightningMovement>;
        _invoices = results[4] as List<LightningInvoiceRecord>;
      });
      debugPrint(
        '[LoopEngineer] management: ${_channels.length} canali, '
        '${_movements.length} movimenti',
      );
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _capacitySats =>
      _channels.fold(0, (sum, c) => sum + c.capacitySats);

  /// Outbound: quello che il nodo può spendere nei canali (fallback sul locale).
  int get _outboundSats => _channels.fold(
        0,
        (sum, c) => sum + (c.spendableSats ?? c.localBalanceSats),
      );

  /// Inbound: quello che i peer possono mandarci (fallback sul remoto).
  int get _inboundSats => _channels.fold(
        0,
        (sum, c) => sum + (c.receivableSats ?? c.remoteBalanceSats),
      );

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = _info;

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningNodeManagement)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading && info == null)
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
                if (info != null) _identityCard(loc, theme, info),
                const SizedBox(height: 20),
                _sectionTitle(loc.lightningLiquidity, theme),
                _liquidityCard(loc, theme),
                const SizedBox(height: 20),
                _sectionTitle(loc.lightningMovements, theme),
                _movementsCard(loc, theme),
                const SizedBox(height: 20),
                _channelsTile(loc),
                const SizedBox(height: 12),
                _onchainTile(loc),
                const SizedBox(height: 12),
                _paymentsTile(loc),
                const SizedBox(height: 12),
                _peerTile(loc),
                const SizedBox(height: 12),
                _diagnosticsTile(loc),
                const SizedBox(height: 20),
                // PERCHÉ: informazione onesta — senza il plugin liquidity-ads
                // il nodo non può annunciare termini di lease (scelta 15/09).
                Text(
                  loc.lightningNodeLiquidityAdsUnsupported,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _identityCard(
    AppLocalizations loc,
    ThemeData theme,
    LightningNodeInfo info,
  ) {
    final pubkey = info.pubkey;
    final short = (pubkey == null || pubkey.length <= 16)
        ? (pubkey ?? '—')
        : '${pubkey.substring(0, 8)}…${pubkey.substring(pubkey.length - 6)}';

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.lightningNodeIdentity,
            style:
                theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (info.alias != null && info.alias!.isNotEmpty)
            Text(info.alias!, style: theme.textTheme.bodyMedium),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${loc.lightningNodePubkey}: $short',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (pubkey != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: loc.lightningNodePubkey,
                  onPressed: () => _copy(pubkey),
                ),
            ],
          ),
          Text(
            '${loc.lightningNodeVersion}: ${info.version ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            '${loc.lightningNodePeersCount}: '
            '${info.numPeersConnected ?? info.numPeers ?? '—'} · '
            '${loc.lightningNodeChannelsActive}: ${info.numActiveChannels ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          if ((info.numPendingChannels ?? 0) > 0)
            Text(
              '${loc.lightningNodeChannelsPending}: ${info.numPendingChannels}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orangeAccent),
            ),
        ],
      ),
    );
  }

  Widget _liquidityCard(AppLocalizations loc, ThemeData theme) {
    if (_channels.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Text(loc.lightningNoChannels, style: theme.textTheme.bodyMedium),
      );
    }
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow(loc.lightningLiquidityTotal, _capacitySats, theme, null),
          _statRow(
            loc.lightningLiquidityOutbound,
            _outboundSats,
            theme,
            Colors.greenAccent,
          ),
          _statRow(
            loc.lightningLiquidityInbound,
            _inboundSats,
            theme,
            _inboundSats == 0 ? Colors.orangeAccent : null,
          ),
          // PERCHÉ: senza inbound il nodo non può ricevere — è l'avviso più
          // utile della schermata (problema n.1 di Lightning mobile).
          if (_inboundSats == 0) ...[
            const SizedBox(height: 8),
            Text(
              loc.lightningLiquidityWarning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orangeAccent),
            ),
          ],
          if (_balance?.onchainSats != null) ...[
            const SizedBox(height: 8),
            Text(
              '${loc.lightningNodeOnchain}: ${_fmt(_balance!.onchainSats!)} sat',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, int sats, ThemeData theme, Color? color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              '${_fmt(sats)} sat',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _movementsCard(AppLocalizations loc, ThemeData theme) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          if (_movements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                loc.lightningMovementsEmpty,
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            ..._movements.map((m) => LightningMovementTile(movement: m)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LightningMovementsScreen(
                        lightningService: widget.lightningService,
                      ),
                    ),
                  );
                  await _load();
                },
                icon: const Icon(Icons.history, size: 18),
                label: Text(loc.lightningMovementsAll),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Riga pagamenti: quante fatture e quante ancora da incassare.
  Widget _paymentsTile(AppLocalizations loc) {
    final pending = _invoices
        .where((i) => i.state == LightningInvoiceState.pending)
        .length;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: AppTheme.lightningAccent,
          ),
          title: Text(loc.lightningPayments),
          subtitle: Text(loc.lightningPaymentsSummary(_invoices.length, pending)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LightningPaymentsScreen(
                  lightningService: widget.lightningService,
                ),
              ),
            );
            await _load();
          },
        ),
      ),
    );
  }

  /// Riga diagnostica: economia del nodo (bkpr), plugin e forwarding.
  Widget _diagnosticsTile(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.monitor_heart_outlined,
              color: AppTheme.lightningAccent,
            ),
            title: Text(loc.lightningDiagnostics),
            subtitle: Text(loc.lightningDiagnosticsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LightningDiagnosticsScreen(
                    lightningService: widget.lightningService,
                  ),
                ),
              );
              await _load();
            },
          ),
        ),
      );

  /// Riga canali: elenco completo (con conteggio) e dettaglio per canale.
  Widget _channelsTile(AppLocalizations loc) => GlassContainer(        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link, color: AppTheme.lightningAccent),
            title: Text(loc.lightningChannels),
            subtitle: Text(loc.lightningChannelsAll(_channels.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LightningChannelsScreen(
                    lightningService: widget.lightningService,
                  ),
                ),
              );
              await _load();
            },
          ),
        ),
      );

  /// Riga on-chain: saldo e accesso a indirizzi/UTXO del nodo.
  Widget _onchainTile(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.lightningAccent,
            ),
            title: Text(loc.lightningOnchainNode),
            subtitle: Text(
              _balance?.onchainSats == null
                  ? '—'
                  : '${_fmt(_balance!.onchainSats!)} sat',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LightningOnchainScreen(
                    lightningService: widget.lightningService,
                  ),
                ),
              );
              await _load();
            },
          ),
        ),
      );

  Widget _peerTile(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        // PERCHÉ: ListTile disegna ink/sfondo sul Material più vicino: senza
        // questo Material (trasparente) gli effetti di tocco sparirebbero.
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.people_alt_outlined,
              color: AppTheme.lightningAccent,
            ),
            title: Text(loc.lightningPeers),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LightningPeersScreen(
                    lightningService: widget.lightningService,
                  ),
                ),
              );
              await _load();
            },
          ),
        ),
      );
}
