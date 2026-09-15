import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_balance.dart';
import '../../../core/models/lightning_channel.dart';
import '../../../core/models/lightning_node_info.dart';
import '../../../core/services/lightning/lightning_connection_store.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'lightning_channel_detail_screen.dart';
import 'lightning_channels_screen.dart';
import 'lightning_connect_screen.dart';
import 'lightning_deposit_screen.dart';
import 'lightning_node_management_screen.dart';
import 'lightning_onchain_send_screen.dart';
import 'lightning_open_channel_screen.dart';
import 'lightning_receive_screen.dart';
import 'lightning_send_screen.dart';
import 'widgets/channel_card.dart';

/// Pannello Lightning della home: stato connessione, saldo, canali, azioni.
///
/// // FLOW: Lightning via nodo remoto (NWC/NCC)
/// Nessun servizio in background: tutto è on-demand verso il nodo remoto.
class LightningView extends StatefulWidget {
  const LightningView({
    super.key,
    required this.lightningService,
    required this.connectionStore,
  });

  final LightningService lightningService;
  final LightningConnectionStore connectionStore;

  @override
  State<LightningView> createState() => _LightningViewState();
}

class _LightningViewState extends State<LightningView> {
  LightningConnectionState _state = LightningConnectionState.disconnected;
  LightningBalance? _balance;
  LightningNodeInfo? _info;
  List<LightningChannel> _channels = const [];
  bool _loading = false;
  LightningException? _error;
  StreamSubscription<LightningConnectionState>? _stateSub;
  StreamSubscription<void>? _notifSub;

  /// True se il nodo dichiara (o non elenca) almeno una capability on-chain.
  ///
  /// // PERCHÉ: se `get_info` elenca i metodi, l'area on-chain appare solo
  /// quando una delle operazioni on-chain e davvero disponibile — con
  /// bridge/nodi vecchi la card sarebbe un vicolo cieco.
  bool get _supportsOnchain {
    final methods = _info?.methods;
    if (methods == null || methods.isEmpty) return true;
    return methods.contains('make_new_address') ||
        methods.contains('pay_onchain');
  }

  /// Il deposito richiede proprio `make_new_address`, non basta il prelievo.
  bool get _supportsDeposit {
    final methods = _info?.methods;
    return methods == null ||
        methods.isEmpty ||
        methods.contains('make_new_address');
  }

  /// Il prelievo on-chain richiede `pay_onchain`.
  bool get _supportsWithdraw {
    final methods = _info?.methods;
    return methods == null || methods.isEmpty || methods.contains('pay_onchain');
  }

  @override
  void initState() {
    super.initState();
    _state = widget.lightningService.connectionState;
    _stateSub = widget.lightningService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
    // PERCHÉ (I2): il nodo pubblica notifiche (pagamenti/canali): oltre al
    // refresh mostriamo un avviso discreto che qualcosa è cambiato.
    _notifSub = widget.lightningService.notifications.listen(
      (_) => _onNotification(),
    );
    // PERCHÉ: il refresh iniziale è differito al primo frame — un setState
    // sincrono dentro initState → build phase bloccherebbe il primo mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoReconnect();
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  /// Notifica dal nodo (pagamento ricevuto/inviato, canale aperto/chiuso).
  void _onNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).lightningActivityDetected),
          duration: const Duration(seconds: 2),
        ),
      );
    unawaited(_refresh());
  }

  /// Tenta la riconnessione con l'ultima URI salvata (se presente).
  Future<void> _autoReconnect() async {
    if (widget.lightningService.isConnected) {
      await _refresh();
      return;
    }
    final saved = await widget.connectionStore.load();
    if (saved == null || !mounted) return;
    try {
      await widget.lightningService.connect(saved);
      await _refresh();
    } on LightningException catch (e) {
      debugPrint('[LoopEngineer] Lightning auto-connect fallito: ${e.code}');
    }
  }

  Future<void> _refresh() async {
    if (!widget.lightningService.isConnected || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balance = await widget.lightningService.getBalance();
      final info = await widget.lightningService.getInfo();
      final channels = await widget.lightningService.listChannels();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _info = info;
        // I4a: i canali chiusi sono storia (Movimenti), non "canali".
        _channels = openOnly(channels);
      });
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => LightningConnectScreen(
          lightningService: widget.lightningService,
          connectionStore: widget.connectionStore,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _disconnect() async {
    await widget.lightningService.disconnect();
    await widget.connectionStore.clear();
    if (!mounted) return;
    setState(() {
      _balance = null;
      _info = null;
      _channels = const [];
      _error = null;
    });
  }

  Future<void> _openChannelFlow() async {
    final opened = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LightningOpenChannelScreen(
          lightningService: widget.lightningService,
        ),
      ),
    );
    if (opened == true) {
      await _refresh();
    }
  }

  /// Deposito on-chain: mostra un indirizzo del nodo (QR + copia).
  Future<void> _openDepositFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LightningDepositScreen(
          lightningService: widget.lightningService,
        ),
      ),
    );
    await _refresh();
  }

  /// Invio on-chain dal nodo (withdraw con conferma forte).
  Future<void> _openOnchainSendFlow() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LightningOnchainSendScreen(
          lightningService: widget.lightningService,
          availableSats: _balance?.onchainSats,
        ),
      ),
    );
    if (sent == true) {
      await _refresh();
    }
  }

  /// Apre il dettaglio del canale (dati del nodo + azioni di chiusura).
  Future<void> _openChannelDetail(LightningChannel channel) async {
    final closed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LightningChannelDetailScreen(
          channel: channel,
          lightningService: widget.lightningService,
        ),
      ),
    );
    if (closed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case LightningConnectionState.connecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).lightningConnecting),
            ],
          ),
        );
      case LightningConnectionState.disconnected:
        return _buildDisconnected(context);
      case LightningConnectionState.connected:
        return _buildConnected(context);
    }
  }

  Widget _buildDisconnected(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.lightningAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.lightningDisconnectedTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(loc.lightningDisconnectedBody),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _connectFlow,
                icon: const Icon(Icons.link),
                label: Text(loc.lightningConnectButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnected(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final balance = _balance;
    final info = _info;
    final onchainSats = balance?.onchainSats;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.lightningAccent),
                    const SizedBox(width: 8),
                    Text(
                      loc.lightningBalance,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  balance == null
                      ? '—'
                      : '${NumberFormat.decimalPattern().format(balance.lightningSats)} sat',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (info != null) ...[
                  const SizedBox(height: 6),
                  // PERCHÉ (I1): identità del nodo — l'utente deve sapere a
                  // QUALE nodo è collegato (alias, pubkey abbreviata, altezza).
                  Text(
                    [
                      if (info.alias != null && info.alias!.isNotEmpty)
                        info.alias!,
                      if (info.pubkey != null && info.pubkey!.isNotEmpty)
                        '${info.pubkey!.substring(0, 12)}…',
                      if (info.blockHeight != null) '⛓ ${info.blockHeight}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LightningReceiveScreen(
                              lightningService: widget.lightningService,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: Text(loc.lightningReceive),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LightningSendScreen(
                                lightningService: widget.lightningService,
                              ),
                            ),
                          );
                          await _refresh();
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(loc.lightningSend),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_supportsOnchain) ...[
            const SizedBox(height: 12),
            // PERCHÉ (I1): "area Nodo" — saldo on-chain del nodo con le due
            // operazioni di gestione (deposito e invio on-chain). Nascosta
            // se il nodo non supporta i metodi (bridge vecchio / dln futuro).
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.lightningAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.lightningNodeOnchain,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    onchainSats == null
                        ? '—'
                        : '${NumberFormat.decimalPattern().format(onchainSats)} sat',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_supportsDeposit)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openDepositFlow,
                            icon: const Icon(Icons.call_received, size: 18),
                            label: Text(loc.lightningDeposit),
                          ),
                        ),
                      if (_supportsDeposit && _supportsWithdraw)
                        const SizedBox(width: 12),
                      if (_supportsWithdraw)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openOnchainSendFlow,
                            icon: const Icon(Icons.call_made, size: 18),
                            label: Text(loc.lightningWithdraw),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Text(
                _error!.isPermissionDenied
                    ? loc.lightningErrorRestricted
                    : loc.lightningErrorGeneric(_error!.message),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // PERCHÉ (I3a): peer, movimenti e identità vivono nella schermata
          // dedicata: qui resta un solo ingresso (con i contatori del nodo).
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            // PERCHÉ: ListTile disegna ink/sfondo sul Material più vicino: senza
            // questo Material (trasparente) il GlassContainer coprirebbe gli
            // effetti di tocco e in debug scatta un'asserzione.
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.hub_outlined,
                  color: AppTheme.lightningAccent,
                ),
                title: Text(loc.lightningNodeManagement),
                subtitle: Text(
                  loc.lightningNodeManagementSubtitle(
                    _info?.numPeersConnected ?? _info?.numPeers ?? 0,
                    _info?.numActiveChannels ?? _channels.length,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LightningNodeManagementScreen(
                        lightningService: widget.lightningService,
                      ),
                    ),
                  );
                  await _refresh();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.lightningChannels,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _openChannelFlow,
                icon: const Icon(Icons.add_link, size: 18),
                label: Text(loc.lightningOpenChannel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_channels.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.lightningNoChannels,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            // PERCHÉ (I3a): la principale mostra solo i primi canali — con
            // molti canali la lista spingeva fuori schermo il resto.
            ..._channels.take(2).map(
              (channel) => LightningChannelCard(
                channel: channel,
                onTap: () => _openChannelDetail(channel),
              ),
            ),
          if (_channels.length > 2)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LightningChannelsScreen(
                        lightningService: widget.lightningService,
                      ),
                    ),
                  );
                  await _refresh();
                },
                icon: const Icon(Icons.list_alt, size: 18),
                label: Text(loc.lightningChannelsAll(_channels.length)),
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(loc.lightningDisconnect),
            ),
          ),
        ],
      ),
    );
  }
}
