import 'package:flutter/material.dart';

import '../../../core/models/lightning_peer.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lightning_peer_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Gestione dei peer del nodo remoto (NCC): lista, connessione, disconnessione.
///
/// // FLOW: Gestione nodo Lightning — peer
/// STEP 1: list_peers → stato di connessione e canali per peer
/// STEP 2: connect_peer (pubkey + host) / disconnect_peer
class LightningPeersScreen extends StatefulWidget {
  const LightningPeersScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningPeersScreen> createState() => _LightningPeersScreenState();
}

class _LightningPeersScreenState extends State<LightningPeersScreen> {
  List<LightningPeer> _peers = const [];
  bool _loading = false;

  static String _short(String value) => value.length <= 14
      ? value
      : '${value.substring(0, 6)}…${value.substring(value.length - 4)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final peers = await widget.lightningService.listPeers();
      if (!mounted) return;
      setState(() => _peers = peers);
      debugPrint('[LoopEngineer] peers caricati: ${peers.length}');
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

  Future<void> _connectPeer() async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: i controller vivono dentro il dialog (che li smaltisce da sé):
    // smaltirli qui dopo l'await li farebbe usare-disperati durante
    // l'animazione di chiusura della route.
    final request = await showDialog<_ConnectPeerRequest>(
      context: context,
      builder: (_) => const _ConnectPeerDialog(),
    );
    if (request == null || !mounted) return;

    // PERCHÉ: si incolla spesso la forma compatta `pubkey@host:porta`:
    // la separiamo nei due campi attesi dal nodo.
    final parsed = parseNodeConnectionString(request.nodeId);
    var host = request.host;
    if (host.isEmpty && parsed.host != null) {
      host = parsed.host!;
    }
    if (!isValidLightningNodeId(parsed.nodeId) ||
        (host.isNotEmpty && !isValidPeerHost(host))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningOpenChannelInvalid)),
      );
      return;
    }

    try {
      await widget.lightningService.connectPeer(
        nodeId: parsed.nodeId,
        host: host.isEmpty ? null : host,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningConnected)),
      );
      await _load();
    } on LightningException catch (e) {
      _showError(e);
    }
  }

  Future<void> _disconnectPeer(LightningPeer peer) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.lightningDisconnectPeer),
        content: Text(loc.lightningDisconnectPeerConfirm),
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
    try {
      await widget.lightningService.disconnectPeer(nodeId: peer.id);
      await _load();
    } on LightningException catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningPeers)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _connectPeer,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(loc.lightningConnectPeer),
              ),
              const SizedBox(height: 16),
              if (_peers.isEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.lightningPeersEmpty,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ..._peers.map((peer) {
                  final color = peer.connected
                      ? Colors.greenAccent
                      : Colors.orangeAccent;
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  // PERCHÉ: senza alias il nodo non fornisce un
                                  // nome → pubkey abbreviata (quella intera
                                  // resta nella riga "ID peer", con copia).
                                  peer.alias?.isNotEmpty == true
                                      ? peer.alias!
                                      : _short(peer.id),
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  peer.connected
                                      ? loc.lightningConnected
                                      : loc.lightningPeerDisconnected,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${loc.lightningPeerId}: ${_short(peer.id)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (peer.addresses.isNotEmpty)
                            Text(
                              '${loc.lightningPeerAddresses}: '
                              '${peer.addresses.join(', ')}',
                              style: theme.textTheme.bodySmall,
                            ),
                          Text(
                            '${loc.lightningChannels}: ${peer.numChannels}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (peer.connected)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _disconnectPeer(peer),
                                icon: const Icon(Icons.link_off, size: 16),
                                label: Text(loc.lightningDisconnectPeer),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dati inseriti nel dialog "Connetti peer" (già normalizzati con `trim`).
class _ConnectPeerRequest {
  const _ConnectPeerRequest({required this.nodeId, required this.host});

  final String nodeId;
  final String host;
}

/// Form di connessione peer: possiede i propri controller e li smaltisce
/// quando la route del dialog viene rimossa.
class _ConnectPeerDialog extends StatefulWidget {
  const _ConnectPeerDialog();

  @override
  State<_ConnectPeerDialog> createState() => _ConnectPeerDialogState();
}

class _ConnectPeerDialogState extends State<_ConnectPeerDialog> {
  final TextEditingController _nodeId = TextEditingController();
  final TextEditingController _host = TextEditingController();

  @override
  void dispose() {
    _nodeId.dispose();
    _host.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ConnectPeerRequest(
        nodeId: _nodeId.text.trim(),
        host: _host.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.lightningConnectPeer),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nodeId,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: loc.lightningOpenChannelNodeId,
              helperText: loc.lightningOpenChannelHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _host,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: loc.lightningOpenChannelHost,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.lightningCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(loc.lightningConfirm),
        ),
      ],
    );
  }
}
