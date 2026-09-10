// FLOW: Verifica Integrazione API Esploratore (mempool.guide)
//
// Schermata dimostrativa: mostra saldo, tx count e altezza del blocco tip
// per un indirizzo inserito dall'utente (default: indirizzo di test verificato).

import 'package:flutter/material.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/wallet_balance.dart';
import '../../../core/services/explorer_api.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key, ExplorerApi? api}) : _apiOverride = api;

  // PERCHÉ: API iniettabile per i widget test (mock senza rete reale).
  final ExplorerApi? _apiOverride;

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  // Indirizzo di test reale (saldo atteso 0.99999856 tBTC = 99.999.856 sats).
  // PERCHÉ: sostituibile — l'utente può inserire un indirizzo dinamico.
  static const _kTestAddress = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';

  late final ExplorerApi _api;
  late final TextEditingController _addressController;

  WalletBalance? _balance;
  int? _tipHeight;
  bool _loading = false;
  String? _errorCode;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    // PERCHÉ: maxAttempts:3 — la schermata esploratore riprova gli errori
    // transitori (429/502/503) con backoff prima di mostrare l'errore.
    _api = widget._apiOverride ?? ExplorerApi(maxAttempts: 3);
    _addressController = TextEditingController(text: _kTestAddress);
    _load();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final address = _addressController.text.trim();
    // STEP: 1 — validazione indirizzo prima della chiamata (regola servizio).
    if (!BitcoinNetworkConfig.isValidAddress(address)) {
      setState(() {
        _loading = false;
        _errorCode = 'invalid_address';
        _errorDetail = null;
        _balance = null;
        _tipHeight = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorCode = null;
      _errorDetail = null;
    });
    try {
      // STEP: 2 — saldo da mempool.guide (unica fonte).
      final balance = await _api.addressBalance(address);
      // STEP: 3 — altezza del blocco tip.
      final height = await _api.tipHeight();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _tipHeight = height;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // DEBUG: traccia l'errore API per diagnosi future
      debugPrint('[Explorer] ApiException ${e.code} — ${e.message}');
      setState(() {
        _loading = false;
        _errorCode = e.code;
        _errorDetail = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorCode = 'generic';
        _errorDetail = e.toString();
      });
    }
  }

  String _localizedError(AppLocalizations loc, String code) {
    switch (code) {
      case 'invalid_address':
        return loc.explorerErrorInvalidAddress;
      case 'rate_limited':
        return loc.explorerErrorRateLimited;
      case 'node_unavailable':
      case 'internal_error':
        return loc.explorerErrorNodeUnavailable;
      case 'not_found':
        return loc.explorerErrorNotFound;
      case 'timeout':
        return loc.explorerErrorTimeout;
      case 'network':
        return loc.explorerErrorNetwork;
      default:
        return loc.explorerErrorGeneric(_errorDetail ?? code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.explorerTitle)),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: loc.explorerAddressLabel,
                    hintText: BitcoinNetworkConfig.addressPrefixHint,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(loc.explorerRefresh),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorCode != null)
                _ErrorCard(
                  message: _localizedError(loc, _errorCode!),
                  onRetry: _load,
                )
              else if (_balance != null)
                _BalanceCard(
                  balance: _balance!,
                  tipHeight: _tipHeight,
                  theme: theme,
                  loc: loc,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.replay),
            label: Text(loc.explorerRetry),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.tipHeight,
    required this.theme,
    required this.loc,
  });

  final WalletBalance balance;
  final int? tipHeight;
  final ThemeData theme;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.explorerBalanceLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            WalletBalance.formatTbtc(balance.balanceSats),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: loc.explorerTxCount,
            value: '${balance.txCount}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: loc.explorerTipHeight,
            value: tipHeight?.toString() ?? '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
