import 'package:flutter/material.dart';

import '../../../core/models/lightning_forward.dart';
import '../../../core/models/lightning_node_stats.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Diagnostica del nodo: economia, plugin e forwarding.
///
/// // FLOW: Gestione nodo Lightning — diagnostica
/// STEP 1: get_node_stats (aggregato dell'accounting + plugin + conteggi)
/// STEP 2: list_forwards (pagina da 25, "Carica altri" per la successiva)
class LightningDiagnosticsScreen extends StatefulWidget {
  const LightningDiagnosticsScreen({
    super.key,
    required this.lightningService,
  });

  final LightningService lightningService;

  /// Dimensione pagina dei forward: sono pochi, 25 basta e avanza.
  static const int pageSize = 25;

  @override
  State<LightningDiagnosticsScreen> createState() =>
      _LightningDiagnosticsScreenState();
}

class _LightningDiagnosticsScreenState
    extends State<LightningDiagnosticsScreen> {
  LightningNodeStats? _stats;
  List<LightningForward> _forwards = const [];
  bool _loading = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // PERCHÉ: due letture indipendenti in parallelo — una sola attesa.
      final results = await Future.wait([
        widget.lightningService.getNodeStats(),
        widget.lightningService.listForwards(
          limit: LightningDiagnosticsScreen.pageSize,
        ),
      ]);
      if (!mounted) return;
      final forwards = results[1] as List<LightningForward>;
      setState(() {
        _stats = results[0] as LightningNodeStats;
        _forwards = forwards;
        _hasMore = forwards.length == LightningDiagnosticsScreen.pageSize;
      });
      debugPrint(
        '[LoopEngineer] diagnostica: netto ${_stats?.netMsat} msat, '
        '${_forwards.length} forward',
      );
    } on LightningException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final page = await widget.lightningService.listForwards(
        limit: LightningDiagnosticsScreen.pageSize,
        offset: _forwards.length,
      );
      if (!mounted) return;
      setState(() {
        _forwards = [..._forwards, ...page];
        _hasMore = page.length == LightningDiagnosticsScreen.pageSize;
      });
    } on LightningException catch (e) {
      _showError(e);
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

  /// Etichetta leggibile per i tag dell'accounting; i tag ignoti restano grezzi.
  ///
  /// // PERCHÉ: i tag li decide il nodo (possono cambiare con la versione):
  /// non si inventa una traduzione, si mostra il tag così com'è.
  String _tagLabel(AppLocalizations loc, String tag) => switch (tag) {
        'deposit' => loc.lightningStatsTagDeposit,
        'invoice' => loc.lightningStatsTagInvoice,
        'withdrawal' => loc.lightningStatsTagWithdrawal,
        'onchain_fee' => loc.lightningStatsTagOnchainFee,
        'channel_open' => loc.lightningStatsTagChannelOpen,
        'channel_close' => loc.lightningStatsTagChannelClose,
        'routed' || 'forward' => loc.lightningStatsTagRouted,
        _ => tag,
      };

  String _fmt(int sats) {
    final s = '$sats';
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = _stats;

    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningDiagnostics)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stats == null && _loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                _economyCard(loc, theme, stats),
                const SizedBox(height: 12),
                _pluginsCard(loc, theme, stats),
                const SizedBox(height: 12),
                _forwardsCard(loc, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _economyCard(
    AppLocalizations loc,
    ThemeData theme,
    LightningNodeStats? stats,
  ) {
    final net = stats?.netSats ?? 0;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.lightningStatsEconomy,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (stats == null || stats.tags.isEmpty)
            Text(loc.lightningStatsEmpty, style: theme.textTheme.bodyMedium)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(loc.lightningStatsNet,
                      style: theme.textTheme.bodySmall,),
                ),
                Text(
                  '${_fmt(net)} sat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    // PERCHÉ: il segno è l'informazione: verde guadagno,
                    // arancio perdita.
                    color: net >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...stats.tags.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tagLabel(loc, t.tag),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            loc.lightningStatsEntries(t.entries),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${t.netSats >= 0 ? '+' : ''}${_fmt(t.netSats)} sat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.netSats >= 0
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // PERCHÉ: dichiarare la fonte: senza questo il numero è magia.
            Text(loc.lightningStatsSource, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _pluginsCard(
    AppLocalizations loc,
    ThemeData theme,
    LightningNodeStats? stats,
  ) {
    final plugins = stats?.plugins ?? const [];
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.lightningPluginsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (plugins.isEmpty)
            Text(loc.lightningStatsEmpty, style: theme.textTheme.bodyMedium)
          else ...[
            Text(
              loc.lightningPluginsActiveCount(
                plugins.where((p) => p.active).length,
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in plugins)
                  Chip(
                    label: Text(
                      p.active
                          ? p.name
                          : '${p.name} · ${loc.lightningPluginInactive}',
                      style: theme.textTheme.bodySmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: p.active
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : theme.dividerColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // PERCHÉ: informazione onesta sulla feature assente (scelta 15/09).
            Text(
              loc.lightningNodeLiquidityAdsUnsupported,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _forwardsCard(AppLocalizations loc, ThemeData theme) => GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.lightningForwardsTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_forwards.isEmpty)
              Text(loc.lightningForwardsEmpty,
                  style: theme.textTheme.bodyMedium,)
            else ...[
              ..._forwards.map((f) => _forwardRow(loc, theme, f)),
              if (_hasMore) ...[
                const SizedBox(height: 8),
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : _loadMore,
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(loc.lightningMovementsLoadMore),
                  ),
                ),
              ],
            ],
          ],
        ),
      );

  Widget _forwardRow(
    AppLocalizations loc,
    ThemeData theme,
    LightningForward f,
  ) {
    final statusLabel = switch (f.status) {
      'settled' => loc.lightningForwardSettled,
      'failed' => loc.lightningForwardFailed,
      'offered' => loc.lightningForwardOffered,
      _ => f.status,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${f.inChannel ?? '—'} → ${f.outChannel ?? '—'}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(statusLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(f.inSats)} sat',
                style: theme.textTheme.bodySmall,
              ),
              if (f.feeSats != null)
                Text(
                  '+${_fmt(f.feeSats!)} sat',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.greenAccent),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
