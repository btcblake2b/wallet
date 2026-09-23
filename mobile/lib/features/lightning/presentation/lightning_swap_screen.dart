import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/config/swap_defaults.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/balance_cache.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/swap/swap_models.dart';
import '../../../core/services/swap/swap_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'swap_error_text.dart';
import 'widgets/swap_claim_row.dart';

/// Pagamento Lightning SENZA nodo personale: swap atomico via provider (P9).
///
/// // FLOW: Pagamento LN via swap (P9) — app
/// // STEP: 1 collega il provider (URI `nostr+swap://…`)
/// // STEP: 2 incolla l'invoice → quote + sessione
/// // STEP: 3 invia i fondi all'HTLC on-chain (firma UNIFIED dell'app)
/// // STEP: 4 segui lo stato (polling + notifiche del provider)
/// // STEP: 5 in caso di fallimento: refund dopo il CLTV o import del blob
///
/// // PERCHÉ: i fondi restano SELF-CUSTODIAL — l'app custodisce le chiavi,
/// // il provider incassa la preimage solo pagando davvero la invoice.
class LightningSwapScreen extends StatefulWidget {
  const LightningSwapScreen({
    super.key,
    required this.swapService,
    required this.wallets,
    required this.walletRepository,
    required this.bitcoinService,
  });

  final SwapService swapService;

  /// Wallet HOT disponibili per lo swap (solo firmabili: mai watch-only).
  ///
  /// // PERCHÉ: l'utente deve poter scegliere QUALE wallet usare; il funding
  /// // e il refund usano il wallet LEGATO alla sessione (la chiave di refund
  /// // deriva dal suo seed: un altro wallet non può recuperare l'HTLC).
  final List<WalletRecord> wallets;
  final WalletRepository walletRepository;
  final BitcoinService bitcoinService;

  @override
  State<LightningSwapScreen> createState() => _LightningSwapScreenState();
}

class _LightningSwapScreenState extends State<LightningSwapScreen> {
  final TextEditingController _uriCtrl = TextEditingController();
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _blobCtrl = TextEditingController();

  SwapProvider? _provider;
  List<SwapSession> _sessions = const [];
  SwapSession? _current;
  Timer? _poll;
  bool _busy = false;

  /// Wallet selezionato per le NUOVE sessioni (default: il primo hot).
  late WalletRecord _wallet = widget.wallets.first;

  /// URI provider salvate (menu a tendina per il collegamento rapido).
  List<String> _knownUris = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _uriCtrl.dispose();
    _invoiceCtrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  // ── Ciclo di vita ──────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    // STEP: 1 — ripristino del collegamento salvato (se c'è).
    try {
      final provider = await widget.swapService.restoreConnection();
      if (mounted) setState(() => _provider = provider);
    } on SwapException catch (e) {
      debugPrint('[LoopEngineer] SwapScreen: restore fallito (${e.code})');
    }
    await _loadKnownUris();
    await _reloadSessions();
    _ensurePolling();
    // PERCHÉ: se l'utente non ha (ancora) un provider, gli si propone il nodo
    // terzo predefinito — ma SOLO se risponde (altrimenti resta nascosto).
    unawaited(_offerDefaultProvider());
  }

  /// Propone il provider predefinito se (e solo se) risponde sul relay.
  ///
  /// // PERCHÉ: il default serve a chi non sa procurarsi una URI, ma un
  /// // suggerimento morto è peggio di nessun suggerimento → se la sonda
  /// // fallisce non si mostra nulla. Non sovrascrive mai una scelta dell'utente.
  Future<void> _offerDefaultProvider() async {
    if (_provider != null) return;
    final available = await widget.swapService.probeProvider(
      SwapDefaults.providerUri,
    );
    if (!mounted || !available || _provider != null) return;
    // L'utente potrebbe aver scritto nel frattempo: non si sovrascrive.
    if (_uriCtrl.text.trim().isNotEmpty) return;
    setState(() {
      _uriCtrl.text = SwapDefaults.providerUri;
      _knownUris = SwapDefaults.withDefault(_knownUris);
    });
    debugPrint('[LoopEngineer] SwapScreen: provider predefinito proposto');
  }

  Future<void> _loadKnownUris() async {
    final uris = await widget.swapService.knownProviderUris();
    if (mounted) setState(() => _knownUris = uris);
  }

  /// Wallet legato a [session] (null se non è più tra i wallet disponibili).
  WalletRecord? _walletFor(SwapSession session) {
    final id = session.walletId;
    if (id == null) return _wallet;
    for (final w in widget.wallets) {
      if (w.walletId == id) return w;
    }
    return null;
  }

  Future<void> _reloadSessions() async {
    final sessions = await widget.swapService.sessions.all();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      final id = _current?.swapId;
      if (id != null) {
        for (final s in sessions) {
          if (s.swapId == id) {
            _current = s;
            break;
          }
        }
      }
    });
  }

  void _ensurePolling() {
    _poll?.cancel();
    if (!_sessions.any((s) => !s.state.isTerminal)) return;
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_refreshActive());
    });
  }

  Future<void> _refreshActive() async {
    for (final s in List<SwapSession>.from(_sessions)) {
      if (s.state.isTerminal) continue;
      try {
        await widget.swapService.refresh(s);
      } on SwapException catch (e) {
        debugPrint('[LoopEngineer] SwapScreen: refresh (${e.code})');
      } catch (e) {
        debugPrint('[LoopEngineer] SwapScreen: refresh errore: $e');
      }
    }
    await _reloadSessions();
  }

  // ── Azioni ─────────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    final uri = _uriCtrl.text.trim();
    setState(() => _busy = true);
    try {
      final provider = await widget.swapService.connect(uri);
      if (!mounted) return;
      _uriCtrl.clear();
      setState(() => _provider = provider);
      await _loadKnownUris();
    } on FormatException catch (e) {
      _showError(e.message);
    } on SwapException catch (e) {
      _showSwapError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    try {
      await widget.swapService.disconnect();
      if (mounted) setState(() => _provider = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSwap() async {
    final loc = AppLocalizations.of(context);
    final invoice = _invoiceCtrl.text.trim();
    if (!SwapService.isLikelyInvoice(invoice)) {
      _showMessage(loc.lightningSwapInvalidInvoice);
      return;
    }
    setState(() => _busy = true);
    try {
      // STEP: 2 — chiave di refund DEDICATA (account 2') del wallet scelto +
      // quote + sessione.
      final mnemonic = await widget.walletRepository.decryptSeed(_wallet);
      final keyIndex = await widget.swapService.sessions.nextRefundKeyIndex();
      final refundPath = SwapService.refundPathFor(keyIndex);
      final refundPubkey = await widget.bitcoinService.deriveSwapRefundPubkey(
        mnemonic: mnemonic,
        refundDerivationPath: refundPath,
      );
      final session = await widget.swapService.startSwap(
        invoice: invoice,
        refundPubkeyHex: refundPubkey,
        refundKeyIndex: keyIndex,
        walletId: _wallet.walletId,
        walletName: _wallet.name ?? _wallet.publicAddress,
      );
      if (!mounted) return;
      _invoiceCtrl.clear();
      setState(() => _current = session);
      await _reloadSessions();
      _ensurePolling();
    } on SwapException catch (e) {
      _showSwapError(e);
    } on StateError catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fund() async {
    final loc = AppLocalizations.of(context);
    final session = _current;
    if (session == null) return;
    // Il funding DEVE venire dal wallet legato alla sessione (refund key).
    final wallet = _walletFor(session);
    if (wallet == null) {
      _showMessage(loc.lightningSwapWalletMissing);
      return;
    }
    setState(() => _busy = true);
    try {
      final mnemonic = await widget.walletRepository.decryptSeed(wallet);
      final derivationPath =
          wallet.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;
      // UTXO: prima dalla cache della home (istantaneo), altrimenti scan.
      var utxos = BalanceCache.snapshotOf(wallet.publicAddress)?.utxos;
      if (utxos == null || utxos.isEmpty) {
        utxos = await widget.bitcoinService.fetchSpendableWalletUtxos(
          mnemonic,
          derivationPath: derivationPath,
        );
      }
      if (utxos.isEmpty) {
        _showMessage(loc.lightningSwapNoUtxos);
        return;
      }
      // STEP: 3 — funding on-chain verso l'HTLC (fee: tier "normal").
      final feeRate = await _feeRateSatVb();
      // CONTROLLO FONDI (richiesta utente): se il totale disponibile non copre
      // l'importo da lockare + fee stimata, ci si ferma PRIMA di firmare.
      final totalIn = utxos.fold<int>(0, (sum, u) => sum + u.valueSat);
      final estimatedFee = estimateTxVbytes(utxos, 2) * feeRate;
      final needed = session.fundingAmountSats + estimatedFee;
      if (totalIn < needed) {
        _showMessage(
          loc.lightningSwapInsufficientFunds('$needed', '$totalIn'),
        );
        return;
      }
      await widget.swapService.fund(
        session: session,
        mnemonic: mnemonic,
        accountDerivationPath: derivationPath,
        utxos: utxos,
        feeRateSatVb: feeRate,
      );
      await _reloadSessions();
      _ensurePolling();
    } on SwapException catch (e) {
      _showSwapError(e);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refund(SwapSession session) async {
    final loc = AppLocalizations.of(context);
    final wallet = _walletFor(session);
    if (wallet == null) {
      _showMessage(loc.lightningSwapWalletMissing);
      return;
    }
    setState(() => _busy = true);
    try {
      // STEP: 5 — refund dopo il CLTV: la destinazione è l'indirizzo del
      // wallet LEGATO alla sessione (nessun input utente aggiuntivo nel PoC).
      final mnemonic = await widget.walletRepository.decryptSeed(wallet);
      final txid = await widget.swapService.refund(
        session: session,
        mnemonic: mnemonic,
        destinationAddress: wallet.publicAddress,
        feeRateSatVb: await _feeRateSatVb(),
      );
      _showMessage('refund: ${txid.substring(0, 12)}…');
      await _reloadSessions();
    } on SwapException catch (e) {
      // PERCHÉ: il refund è trasmissibile solo dal CLTV — messaggio dedicato
      // invece dell'errore grezzo del nodo (incidente 18/09/2026).
      if (e.code == 'REFUND_TOO_EARLY') {
        _showMessage(loc.lightningSwapRefundNotYet(session.cltvHeight));
      } else {
        _showSwapError(e);
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Annulla (dimentica) una sessione non finanziata, con conferma esplicita.
  Future<void> _cancelSession(SwapSession session) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.lightningSwapCancelTitle),
        content: Text(loc.lightningSwapCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.lightningSwapCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.swapService.cancelSession(session.swapId);
    if (!mounted) return;
    setState(() => _current = null);
    await _reloadSessions();
    _ensurePolling();
  }

  Future<void> _importBlob() async {
    final blob = _blobCtrl.text.trim();
    if (blob.isEmpty) return;
    setState(() => _busy = true);
    try {
      final session = await widget.swapService.importRecoveryBlob(blob);
      if (!mounted) return;
      _blobCtrl.clear();
      setState(() => _current = session);
      await _reloadSessions();
      _ensurePolling();
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyBlob(SwapSession session) async {
    final loc = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: widget.swapService.exportRecoveryBlob(session)),
    );
    _showMessage(loc.lightningSwapBlobCopied);
  }

  /// Fee (sat/vB) delle tx on-chain dello swap: funding e refund.
  ///
  /// // PERCHÉ (18/09/2026): il funding deve prendere la prima conferma (il
  /// // provider paga solo dopo 1 conf) → tier di ALTA priorità, che quando il
  /// // mercato sta al minimo scende al pavimento di rete (mai 1 sat/vB).
  Future<int> _feeRateSatVb() async {
    try {
      final estimates = await widget.bitcoinService.fetchFeeEstimates();
      return estimates.prioritySatVb;
    } catch (e) {
      debugPrint(
        '[LoopEngineer] SwapScreen: fee estimates non disponibili: $e',
      );
      return BitcoinNetworkConfig.priorityFeeFloorSatVb;
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Mostra un errore dello swap: messaggio localizzato per i codici noti,
  /// testo tecnico come fallback.
  ///
  /// // PERCHÉ (P9, ADR 2026-09-18): alcuni codici hanno un significato per
  /// l'utente (relay non consentito su web, provider irraggiungibile) e il
  /// messaggio del protocollo non è comprensibile. Si mappa il CODICE, mai il
  /// testo: cambiare una stringa di protocollo non deve rompere la UI.
  // STEP: errore del provider → UI
  void _showSwapError(SwapException e) {
    final loc = AppLocalizations.of(context);
    _showError(swapErrorReason(loc, e.code) ?? e.message);
  }

  void _showError(String message) {
    if (!mounted) return;
    _showMessage(
      AppLocalizations.of(context).lightningSwapErrorGeneric(message),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningSwapTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntroCard(loc),
            const SizedBox(height: 12),
            _buildProviderCard(loc),
            const SizedBox(height: 12),
            if (_provider != null) ...[
              _buildInvoiceCard(loc),
              const SizedBox(height: 12),
            ],
            if (_current != null) ...[
              _buildSessionCard(loc, _current!),
              const SizedBox(height: 12),
            ],
            _buildRecoveryCard(loc),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppTheme.lightningAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.lightningSwapOpen,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(loc.lightningSwapIntro),
          ],
        ),
      );

  Widget _buildProviderCard(AppLocalizations loc) {
    final provider = _provider;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider == null) ...[
            TextField(
              controller: _uriCtrl,
              decoration: InputDecoration(
                hintText: loc.lightningSwapProviderUriHint,
              ),
              maxLines: 2,
              minLines: 1,
            ),
            if (_knownUris.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.lightningSwapKnownUris,
                ),
                items: [
                  for (final uri in _knownUris)
                    DropdownMenuItem(
                      value: uri,
                      child: Text(
                        _shortUri(uri),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (uri) {
                        if (uri != null) {
                          setState(() => _uriCtrl.text = uri);
                        }
                      },
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _connect,
              icon: const Icon(Icons.link),
              label: Text(loc.lightningSwapProviderConnect),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.lightningSwapProviderConnected(
                      _shortPubkey(provider.providerPubkey),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _busy ? null : _disconnect,
              child: Text(loc.lightningSwapProviderDisconnect),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selettore wallet: mostra nome + saldo noto; il saldo effettivo
            // viene comunque ricontrollato prima di firmare (controllo fondi).
            DropdownButtonFormField<String>(
              initialValue: _wallet.walletId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: loc.lightningSwapWalletLabel,
              ),
              items: [
                for (final w in widget.wallets)
                  DropdownMenuItem(
                    value: w.walletId,
                    child: Text(
                      _walletLabel(w),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (id) {
                      if (id == null) return;
                      setState(() {
                        for (final w in widget.wallets) {
                          if (w.walletId == id) {
                            _wallet = w;
                            break;
                          }
                        }
                      });
                    },
            ),
            const SizedBox(height: 6),
            Text(
              _walletBalanceLine(loc, _wallet),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _invoiceCtrl,
              decoration: InputDecoration(
                hintText: loc.lightningSwapInvoiceHint,
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _startSwap,
              icon: const Icon(Icons.bolt),
              label: Text(loc.lightningSwapStart),
            ),
          ],
        ),
      );

  Widget _buildSessionCard(AppLocalizations loc, SwapSession session) =>
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(loc.lightningSwapStateLabel, _stateLabel(loc, session.state)),
            if (session.walletName != null)
              _row(loc.lightningSwapWalletLabel, session.walletName!),
            _row(
              loc.lightningSwapTotal,
              '${session.fundingAmountSats} sat',
            ),
            Text(
              loc.lightningSwapCltv(session.cltvHeight),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              loc.lightningSwapHtlc,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              session.htlcAddress,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // FLOW: Pagamento LN via swap (P9) — app
            // STEP: 4b verifica on-chain del claim (txid + explorer).
            // // PERCHÉ (18/09/2026): senza il txid l'utente vedeva solo
            // "claim in corso" e non poteva distinguere un'attesa fisiologica
            // (la conferma arriva col blocco successivo) da un problema.
            if (session.claimTxid != null) ...[
              const SizedBox(height: 10),
              SwapClaimRow(
                txid: session.claimTxid!,
                label: loc.lightningSwapClaimTxid,
                hint: loc.lightningSwapClaimHint,
                explorerUrl:
                    BitcoinNetworkConfig.txExplorerUrl(session.claimTxid!),
              ),
            ],
            if (session.errorCode != null) ...[
              const SizedBox(height: 6),
              Text(
                '${session.errorCode}: ${session.errorMessage ?? ''}',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
            const SizedBox(height: 12),
            if (session.state == SwapClientState.awaitingFunding) ...[
              FilledButton.icon(
                onPressed: _busy ? null : _fund,
                icon: const Icon(Icons.arrow_upward),
                label: Text(loc.lightningSwapFund),
              ),
              const SizedBox(height: 6),
              Text(
                loc.lightningSwapFundHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Avviso quando il wallet selezionato NON è quello legato alla
              // sessione (il funding partirà comunque dal wallet legato).
              if (session.walletId != null &&
                  session.walletId != _wallet.walletId &&
                  _walletFor(session) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    loc.lightningSwapBoundWallet(session.walletName ?? ''),
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              // Annulla disponibile SOLO prima del funding (poi i fondi sono
              // in custodia dell'HTLC e le vie sono pagamento o refund).
              if (session.fundingTxid == null) ...[
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _cancelSession(session),
                  icon: const Icon(Icons.close),
                  label: Text(loc.lightningSwapCancel),
                ),
              ],
            ],
            if (session.state.isRefundable)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _refund(session),
                icon: const Icon(Icons.undo),
                label: Text(loc.lightningSwapRefund),
              ),
            TextButton(
              onPressed: () => _copyBlob(session),
              child: Text(loc.lightningSwapCopyBlob),
            ),
          ],
        ),
      );

  Widget _buildRecoveryCard(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.lightningSwapRecoveryTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _blobCtrl,
              decoration: InputDecoration(
                hintText: loc.lightningSwapRecoveryHint,
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importBlob,
              icon: const Icon(Icons.file_download),
              label: Text(loc.lightningSwapRecoveryImport),
            ),
            // Sessioni note recuperabili (refund) o da seguire.
            for (final s in _sessions.where((s) => !s.state.isTerminal))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(s.swapId.substring(0, 8)),
                subtitle: Text(_stateLabel(loc, s.state)),
                onTap: () => setState(() => _current = s),
              ),
          ],
        ),
      );

  /// Riga etichetta/valore della card sessione.
  ///
  /// // PERCHÉ Expanded+Flexible: un valore lungo (es. nome wallet o txid) non
  /// // deve mai generare un RenderFlex overflow — va in ellipsis.
  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  String _shortPubkey(String pubkey) =>
      pubkey.length > 12 ? '${pubkey.substring(0, 12)}…' : pubkey;

  /// Versione compatta di una URI per il menu a tendina (pubkey + coda).
  String _shortUri(String uri) => uri.length > 46
      ? '${uri.substring(0, 20)}…${uri.substring(uri.length - 22)}'
      : uri;

  /// Etichetta del wallet nel menu: SOLO il nome (o indirizzo abbreviato).
  ///
  /// // PERCHÉ niente saldo qui: è già nella riga sotto alla tendina e un
  /// // testo lungo causava overflow nella tendina stessa.
  String _walletLabel(WalletRecord w) {
    final name = w.name;
    if (name != null && name.isNotEmpty) return name;
    final addr = w.publicAddress;
    return addr.length > 20
        ? '${addr.substring(0, 10)}…${addr.substring(addr.length - 6)}'
        : addr;
  }

  String _walletBalanceLine(AppLocalizations loc, WalletRecord w) {
    final sats = BalanceCache.snapshotOf(w.publicAddress)?.balanceSats;
    return loc.lightningSwapWalletBalance(sats?.toString() ?? '?');
  }

  String _stateLabel(AppLocalizations loc, SwapClientState state) =>
      switch (state) {
        SwapClientState.awaitingFunding => loc.swapStateAwaitingFunding,
        SwapClientState.confirming => loc.swapStateConfirming,
        SwapClientState.paying => loc.swapStatePaying,
        SwapClientState.paid => loc.swapStatePaid,
        SwapClientState.claiming => loc.swapStateClaiming,
        SwapClientState.completed => loc.swapStateCompleted,
        SwapClientState.paymentFailed => loc.swapStatePaymentFailed,
        SwapClientState.expired => loc.swapStateExpired,
        SwapClientState.refunded => loc.swapStateRefunded,
      };
}
