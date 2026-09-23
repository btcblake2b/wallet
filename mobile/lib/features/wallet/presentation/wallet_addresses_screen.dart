import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/wallet_address.dart';
import '../../../core/models/wallet_balance.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Indirizzi e UTXO del wallet on-chain, in **sola lettura**.
///
/// // PERCHÉ (P7): un wallet self-custodial deve poter ispezionare i propri
/// indirizzi e i propri UTXO (parità con BlueWallet). Nessuna firma e nessuna
/// spesa da qui: le azioni on-chain restano nei flussi esistenti (Invia, con
/// il coin control di S7) — questa schermata non duplica quel percorso.
// FLOW: Visualizzazione Indirizzi e UTXO
// STEP: 1 — derivazione indirizzi + stato on-chain (rete)
// STEP: 2 — tab Indirizzi (stato/saldo) e tab UTXO (dallo snapshot, zero rete)
class WalletAddressesScreen extends StatefulWidget {
  const WalletAddressesScreen({
    super.key,
    required this.wallet,
    required this.walletRepository,
    required this.bitcoinService,
    this.initialUtxos,
  });

  final WalletRecord wallet;
  final WalletRepository walletRepository;
  final BitcoinService bitcoinService;

  /// UTXO già caricati dallo snapshot del wallet (null = non disponibili).
  ///
  /// // PERCHÉ: passandoli dal detail la tab UTXO non costa NESSUNA chiamata
  /// di rete — è una vista su dati che l'app ha già in `BalanceCache`.
  final List<UtxoInfo>? initialUtxos;

  @override
  State<WalletAddressesScreen> createState() => _WalletAddressesScreenState();
}

class _WalletAddressesScreenState extends State<WalletAddressesScreen> {
  List<WalletAddress> _addresses = const [];
  bool _loading = false;
  String? _error;

  bool get _isWatchOnly => widget.wallet.kind == WalletKind.watchOnly;

  @override
  void initState() {
    super.initState();
    // PERCHÉ: la prima fetch parte dopo il primo frame, così la schermata
    // mostra subito lo spinner invece di bloccarsi sull'apertura.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Carica gli indirizzi con stato on-chain (hot da seed, watch-only da xpub).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<WalletAddress> addresses;
      if (_isWatchOnly) {
        addresses = await widget.bitcoinService.fetchWalletAddresses(
          accountXpub: widget.wallet.accountXpub ?? '',
          scriptType: WalletScriptType.fromDerivationPath(
            widget.wallet.derivationPath,
          ),
        );
      } else {
        // PERCHÉ: il seed viene decifrato solo per derivare e non viene
        // conservato in un campo dello stato (stessa regola del resto dell'app).
        final mnemonic = await widget.walletRepository.decryptSeed(
          widget.wallet,
        );
        addresses = await widget.bitcoinService.fetchWalletAddresses(
          mnemonic: mnemonic,
          derivationPath: widget.wallet.derivationPath,
        );
      }
      if (!mounted) return;
      setState(() => _addresses = addresses);
      debugPrint(
        '[LoopEngineer] Indirizzi wallet: ${addresses.length} '
        '(con attività=${addresses.where((a) => a.hasActivity).length})',
      );
    } catch (e) {
      // PERCHÉ (F5): un errore di rete non è "nessun indirizzo" — lo stato di
      // errore è esplicito, con retry, e non mostra valori inventati.
      if (!mounted) return;
      setState(() => _error = e.toString());
      debugPrint('[LoopEngineer] Indirizzi wallet: errore: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: AppBackground(
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.walletAddressesTitle),
            bottom: TabBar(
              tabs: [
                Tab(text: loc.walletAddressesTabAddresses),
                Tab(text: loc.walletAddressesTabUtxos),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildAddressesTab(loc),
              _buildUtxoTab(loc),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Indirizzi ──────────────────────────────────────────────────────────

  Widget _buildAddressesTab(AppLocalizations loc) {
    if (_loading && _addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _addresses.isEmpty) {
      return _buildErrorState(loc, _error!);
    }
    final receive = _addresses
        .where((a) => a.branch == WalletAddressBranch.external)
        .toList();
    final change = _addresses
        .where((a) => a.branch == WalletAddressBranch.change)
        .toList();
    if (receive.isEmpty && change.isEmpty) {
      return _buildEmptyState(loc.walletAddressesEmpty);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              loc.walletAddressesHintTap,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (receive.isNotEmpty) ...[
            _buildBranchHeader(loc.walletAddressesReceiveBranch, receive),
            ...receive.map((a) => _buildAddressTile(loc, a)),
          ],
          if (change.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBranchHeader(loc.walletAddressesChangeBranch, change),
            ...change.map((a) => _buildAddressTile(loc, a)),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchHeader(String label, List<WalletAddress> items) {
    final active = items.where((a) => a.hasActivity).length;
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            loc.walletAddressesTxCount(active),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(AppLocalizations loc, WalletAddress address) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '${address.index}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shorten(address.address),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  address.derivationPath,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildStatusChip(loc, address),
                    const SizedBox(width: 8),
                    Text(
                      WalletBalance.formatTbtc(address.balanceSats),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: loc.walletAddressesHintTap,
            onPressed: () => _copy(loc, address.address),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AppLocalizations loc, WalletAddress address) {
    final scheme = Theme.of(context).colorScheme;
    final (String label, Color color) = switch (address.status) {
      WalletAddressStatus.hasFunds => (
          loc.walletAddressesStatusFunds,
          scheme.primary,
        ),
      WalletAddressStatus.usedEmpty => (
          loc.walletAddressesStatusUsed,
          scheme.secondary,
        ),
      WalletAddressStatus.unused => (
          loc.walletAddressesStatusUnused,
          scheme.outline,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  // ── Tab UTXO ───────────────────────────────────────────────────────────────

  Widget _buildUtxoTab(AppLocalizations loc) {
    final utxos = widget.initialUtxos ?? const <UtxoInfo>[];
    if (utxos.isEmpty) {
      return _buildEmptyState(loc.walletDetailUtxoEmpty);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: utxos.map((u) => _buildUtxoTile(loc, u)).toList(),
    );
  }

  Widget _buildUtxoTile(AppLocalizations loc, UtxoInfo utxo) {
    final confirmations = utxo.confirmations;
    final status = (confirmations == null || confirmations == 0)
        ? loc.walletDetailTxPending
        : loc.walletDetailUtxoConfirmations(confirmations);
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WalletBalance.formatTbtc(utxo.valueSat),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(status, style: Theme.of(context).textTheme.bodySmall),
                if (utxo.ownerAddress != null && utxo.ownerAddress!.isNotEmpty)
                  Text(
                    _shorten(utxo.ownerAddress!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                if (utxo.ownerDerivationPath != null)
                  Text(
                    utxo.ownerDerivationPath!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: loc.walletAddressesHintTap,
            onPressed: () => _copy(loc, '${utxo.txid}:${utxo.vout}'),
          ),
        ],
      ),
    );
  }

  // ── Stati e utilità ────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations loc, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.walletDetailErrorAddresses(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: Text(loc.walletDetailTxRetry),
            ),
          ],
        ),
      ),
    );
  }

  /// Copia negli appunti con conferma a schermo (pattern del wallet detail).
  void _copy(AppLocalizations loc, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.walletDetailAddressCopied),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Abbrevia un indirizzo lungo mantenendo inizio e fine riconoscibili.
  /// // PERCHÉ: su mobile un bech32 intero (42+ caratteri) va a capo e rende
  /// la lista illeggibile; il tap copia comunque l'indirizzo COMPLETO.
  static String _shorten(String value) {
    if (value.length <= 20) return value;
    return '${value.substring(0, 12)}…${value.substring(value.length - 6)}';
  }
}
