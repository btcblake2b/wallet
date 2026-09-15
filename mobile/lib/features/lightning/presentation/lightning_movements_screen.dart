import 'package:flutter/material.dart';

import '../../../core/models/lightning_movement.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/movement_tile.dart';

/// Storico completo dei movimenti del nodo, con paginazione.
///
/// // FLOW: Gestione nodo Lightning — movimenti
/// STEP 1: list_transactions (pagina da 50, dal più recente)
/// STEP 2: "Carica altri" appende la pagina successiva (offset = già caricati)
class LightningMovementsScreen extends StatefulWidget {
  const LightningMovementsScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  /// Dimensione pagina: il bridge limita a 200, 50 tiene i payload piccoli.
  static const int pageSize = 50;

  @override
  State<LightningMovementsScreen> createState() =>
      _LightningMovementsScreenState();
}

class _LightningMovementsScreenState extends State<LightningMovementsScreen> {
  List<LightningMovement> _movements = const [];
  bool _hasMore = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Carica la prima pagina (o ricarica tutto con pull-to-refresh).
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await widget.lightningService.listTransactions(
        limit: LightningMovementsScreen.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _movements = page;
        _hasMore = page.length == LightningMovementsScreen.pageSize;
      });
      debugPrint('[LoopEngineer] movimenti (pagina 1): ${page.length}');
    } on LightningException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Appende la pagina successiva partendo dal numero già caricato.
  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final page = await widget.lightningService.listTransactions(
        limit: LightningMovementsScreen.pageSize,
        offset: _movements.length,
      );
      if (!mounted) return;
      setState(() {
        _movements = [..._movements, ...page];
        _hasMore = page.length == LightningMovementsScreen.pageSize;
      });
      debugPrint('[LoopEngineer] movimenti (append): totali ${_movements.length}');
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningMovements)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
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
                    else
                      ..._movements.map(
                        (m) => LightningMovementTile(movement: m),
                      ),
                  ],
                ),
              ),
              if (_hasMore) ...[
                const SizedBox(height: 12),
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : _loadMore,
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(loc.lightningMovementsLoadMore),
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
