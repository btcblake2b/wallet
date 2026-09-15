import 'package:flutter/material.dart';

import '../../../core/models/lightning_channel.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'lightning_channel_detail_screen.dart';
import 'widgets/channel_card.dart';

/// Elenco completo dei canali del nodo.
///
/// // PERCHÉ (I3a): la schermata principale mostra solo i primi canali; qui
/// l'utente vede tutti e apre il dettaglio (fee, HTLC, chiusura).
class LightningChannelsScreen extends StatefulWidget {
  const LightningChannelsScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningChannelsScreen> createState() =>
      _LightningChannelsScreenState();
}

class _LightningChannelsScreenState extends State<LightningChannelsScreen> {
  List<LightningChannel> _channels = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channels = await widget.lightningService.listChannels();
      if (!mounted) return;
      // I4a: i canali chiusi sono storia (Movimenti), non "canali".
      setState(() => _channels = openOnly(channels));
      debugPrint('[LoopEngineer] canali (elenco): ${channels.length}');
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

  Future<void> _openDetail(LightningChannel channel) async {
    final closed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LightningChannelDetailScreen(
          channel: channel,
          lightningService: widget.lightningService,
        ),
      ),
    );
    if (closed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningChannels)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading && _channels.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_channels.isEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.lightningNoChannels,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ..._channels.map(
                  (channel) => LightningChannelCard(
                    channel: channel,
                    onTap: () => _openDetail(channel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
