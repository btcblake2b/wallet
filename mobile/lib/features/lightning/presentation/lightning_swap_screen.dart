import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/config/swap_defaults.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/balance_cache.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/swap/swap_models.dart';
import '../../../core/services/swap/swap_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/coinbase_maturity.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'lightning_swap_detail_screen.dart';
import 'swap_error_text.dart';
import 'widgets/swap_claim_row.dart';
import 'widgets/swap_history_tile.dart';

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

  /// Limiti/liquidità del provider collegato (`swap_info`): null se non noti.
  SwapProviderInfo? _info;

  /// Verdetto sull'ultima invoice verificata (destinatario raggiungibile).
  SwapPeerCheck? _peerCheck;
  bool _checkingPeer = false;

  /// Stato della sonda sul nodo predefinito, mostrato accanto al menu.
  _DefaultProbe _defaultProbe = _DefaultProbe.unknown;

  static final NumberFormat _satsFmt = NumberFormat.decimalPattern();

  String _fmt(int sats) => _satsFmt.format(sats);

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
    // PERCHÉ (27/10/2026): chi non ha un nodo proprio non sa procurarsi una
    // URI — il nodo del progetto è già nel menu e preselezionato, così basta
    // un tocco su "Collega provider". La sonda dice solo se RISULTA vivo.
    if (_provider == null) {
      if (_uriCtrl.text.trim().isEmpty) {
        _uriCtrl.text = SwapDefaults.providerUri;
      }
      unawaited(_probeDefaultProvider());
    } else {
      unawaited(_loadProviderInfo());
    }
  }

  /// Sonda il nodo predefinito e ne mostra lo stato accanto al menu.
  ///
  /// // PERCHÉ: il nodo nostro resta SEMPRE selezionabile (serve a chi non ha
  /// // un provider), ma un suggerimento morto non deve sembrare funzionante:
  /// // la sonda decide se l'etichetta è "raggiungibile" o "non risponde".
  Future<void> _probeDefaultProvider() async {
    if (!mounted || _provider != null) return;
    setState(() => _defaultProbe = _DefaultProbe.checking);
    final available = await widget.swapService.probeProvider(
      SwapDefaults.providerUri,
    );
    if (!mounted || _provider != null) return;
    setState(() {
      _defaultProbe =
          available ? _DefaultProbe.reachable : _DefaultProbe.unreachable;
    });
    debugPrint('[LoopEngineer] SwapScreen: sonda nodo predefinito: $available');
  }

  Future<void> _loadKnownUris() async {
    final uris = await widget.swapService.knownProviderUris();
    if (!mounted) return;
    // PERCHÉ: il nodo predefinito è sempre in coda al menu, anche se l'utente
    // non l'ha mai usato — è l'unico modo per chi parte da zero.
    setState(() => _knownUris = SwapDefaults.withDefault(uris));
  }

  /// Limiti e liquidità del provider collegato (`swap_info`).
  ///
  /// // PERCHÉ: senza questo dato l'utente scopriva il tetto solo dall'errore
  /// // della quote, dopo aver scelto wallet e importo.
  Future<void> _loadProviderInfo() async {
    if (_provider == null) return;
    try {
      final info = await widget.swapService.providerInfo();
      if (!mounted) return;
      setState(() => _info = info);
    } on SwapException catch (e) {
      debugPrint(
        '[LoopEngineer] SwapScreen: limiti provider non disponibili (${e.code})',
      );
    }
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
      await _loadProviderInfo();
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
      if (mounted) {
        setState(() {
          _provider = null;
          _info = null;
          _peerCheck = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Verifica che il DESTINATARIO (peer) della invoice sia raggiungibile dal
  /// provider e che l'importo stia nei limiti di liquidità.
  ///
  /// // PERCHÉ (27/10/2026): il controllo esiste anche server-side nella quote,
  /// // ma lì l'utente lo scopre solo DOPO aver scelto wallet e importo. Qui è
  /// // esplicito e non muove fondi: nessuna sessione viene aperta.
  Future<SwapPeerCheck?> _checkPeer({String? invoice}) async {
    final target = (invoice ?? _invoiceCtrl.text).trim();
    if (target.isEmpty || _provider == null) return null;
    setState(() => _checkingPeer = true);
    try {
      final info = await widget.swapService.providerInfo(invoice: target);
      if (!mounted || info == null) return info?.check;
      setState(() {
        _info = info;
        _peerCheck = info.check;
      });
      return info.check;
    } on SwapException catch (e) {
      if (mounted) setState(() => _peerCheck = null);
      _showSwapError(e);
      return null;
    } finally {
      if (mounted) setState(() => _checkingPeer = false);
    }
  }

  /// Messaggio localizzato per un verdetto negativo sul destinatario.
  String _peerIssueText(AppLocalizations loc, SwapPeerCheck check) =>
      swapErrorReason(loc, check.reason ?? '') ??
      check.message ??
      loc.lightningSwapErrorPeerUnreachable;

  Future<void> _startSwap() async {
    final loc = AppLocalizations.of(context);
    final invoice = _invoiceCtrl.text.trim();
    if (!SwapService.isLikelyInvoice(invoice)) {
      _showMessage(loc.lightningSwapInvalidInvoice);
      return;
    }
    // CONTROLLO DESTINATARIO (obbligatorio prima di lockare fondi): una
    // fattura senza rotta verso il peer non va finanziata — i fondi
    // resterebbero nell'HTLC fino al refund.
    if (_peerCheck == null) {
      final check = await _checkPeer(invoice: invoice);
      if (check != null && !check.reachable) {
        _showMessage(_peerIssueText(loc, check));
        return;
      }
    } else if (!_peerCheck!.reachable) {
      _showMessage(_peerIssueText(loc, _peerCheck!));
      return;
    }
    if (!mounted) return;
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
      // PERCHÉ (A3): si usano SOLO gli spendibili — un payout di mining in
      // periodo di attesa non può finanziare lo swap (la tx non sarebbe
      // propagata); lo si cita solo nel messaggio d'errore.
      final snapshot = BalanceCache.snapshotOf(wallet.publicAddress);
      var utxos = snapshot?.utxos;
      var blockedSats = snapshot?.blockedCoinbaseSats ?? 0;
      if (utxos == null || utxos.isEmpty) {
        final split = await widget.bitcoinService.fetchWalletUtxos(
          mnemonic,
          derivationPath: derivationPath,
        );
        utxos = split.spendable;
        blockedSats = sumUtxoSats(split.blocked);
      }
      if (utxos.isEmpty) {
        _showMessage(
          blockedSats > 0
              ? '${loc.walletBalanceWaiting('$blockedSats sat')} — '
                    '${loc.walletUtxoWaitingHint(BitcoinNetworkConfig.coinbaseRelayMaturityBlocks)}'
              : loc.lightningSwapNoUtxos,
        );
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
          blockedSats > 0
              ? loc.lightningSwapInsufficientFundsWaiting(
                  '$needed',
                  '$totalIn',
                  '$blockedSats',
                )
              : loc.lightningSwapInsufficientFunds('$needed', '$totalIn'),
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
    setState(() => _busy = true);
    try {
      // STEP: 5 — refund dopo il CLTV: la destinazione è l'indirizzo del
      // wallet LEGATO alla sessione (nessun input utente aggiuntivo nel PoC).
      final txid = await _refundTx(session);
      _showMessage(loc.lightningSwapRefundSent('${txid.substring(0, 12)}…'));
      await _reloadSessions();
    } on SwapException catch (e) {
      // PERCHÉ: il refund è trasmissibile solo dal CLTV — messaggio dedicato
      // invece dell'errore grezzo del nodo (incidente 18/09/2026).
      if (e.code == 'REFUND_TOO_EARLY') {
        _showMessage(loc.lightningSwapRefundNotYet(session.cltvHeight));
      } else if (e.code == 'WALLET_MISSING') {
        _showMessage(loc.lightningSwapWalletMissing);
      } else {
        _showSwapError(e);
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Costruisce, firma e trasmette il refund; ritorna il txid.
  ///
  /// // PERCHÉ separato da [_refund] (07/10/2026): il DETTAGLIO dello storico
  /// // riusa questa stessa logica — una sola implementazione di firma/broadcast.
  Future<String> _refundTx(SwapSession session) async {
    final wallet = _walletFor(session);
    if (wallet == null) {
      throw const SwapException(
        'WALLET_MISSING',
        'wallet della sessione non disponibile',
      );
    }
    final mnemonic = await widget.walletRepository.decryptSeed(wallet);
    return widget.swapService.refund(
      session: session,
      mnemonic: mnemonic,
      destinationAddress: wallet.publicAddress,
      feeRateSatVb: await _feeRateSatVb(),
    );
  }

  /// Apre il dettaglio di una transazione dello storico.
  ///
  /// // PERCHÉ seleziona anche la sessione: tornando indietro l'utente trova
  /// // la card con le azioni (refund) già puntata sullo swap giusto.
  Future<void> _openDetail(SwapSession session) async {
    setState(() => _current = session);
    final refunded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LightningSwapDetailScreen(
          session: session,
          recoveryBlob: widget.swapService.exportRecoveryBlob(session),
          onRefund: session.state.isRefundable ? () => _refundTx(session) : null,
        ),
      ),
    );
    if (refunded == true) {
      await _reloadSessions();
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
            _buildHistoryCard(loc),
            const SizedBox(height: 12),
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
                // PERCHÉ: il nodo predefinito arriva già selezionato — chi non
                // ha un provider non deve digitare nulla.
                initialValue: _knownUris.contains(_uriCtrl.text.trim())
                    ? _uriCtrl.text.trim()
                    : null,
                decoration: InputDecoration(
                  labelText: loc.lightningSwapKnownUris,
                ),
                items: [
                  for (final uri in _knownUris)
                    DropdownMenuItem(
                      value: uri,
                      child: Text(
                        _uriLabel(loc, uri),
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
            if (_defaultProbe != _DefaultProbe.unknown) ...[
              const SizedBox(height: 6),
              Text(
                switch (_defaultProbe) {
                  _DefaultProbe.checking => loc.lightningSwapProviderChecking,
                  _DefaultProbe.reachable => loc.lightningSwapProviderReachable,
                  _ => loc.lightningSwapProviderDown,
                },
                style: Theme.of(context).textTheme.bodySmall,
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
            if (_info != null) ...[
              const SizedBox(height: 8),
              // Limite di invio dedotto dalla liquidità MISURATA dal provider.
              Text(
                loc.lightningSwapProviderSendLimit(
                  _fmt(_info!.minSendableSats),
                  _fmt(_info!.maxSendableSats),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                loc.lightningSwapProviderLiquidity(_fmt(_info!.availableSats)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
              // PERCHÉ: cambiando fattura il verdetto precedente non vale più.
              onChanged: (_) {
                if (_peerCheck != null) setState(() => _peerCheck = null);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || _checkingPeer ? null : _checkPeer,
                  icon: _checkingPeer
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route, size: 18),
                  label: Text(loc.lightningSwapPeerCheck),
                ),
              ],
            ),
            if (_peerCheck != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _peerCheck!.reachable
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 18,
                    color: _peerCheck!.reachable
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _peerCheck!.reachable
                          ? loc.lightningSwapPeerReachable(
                              _fmt(_peerCheck!.amountSats),
                            )
                          : _peerIssueText(loc, _peerCheck!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
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
                // PERCHÉ: il messaggio grezzo del nodo è troncato e tecnico —
                // si mappa il CODICE su un testo comprensibile e si tiene il
                // dettaglio solo come fallback (utile al supporto).
                swapErrorReason(loc, session.errorCode!) ??
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
            if (session.state.isRefundable) ...[
              Text(
                loc.lightningSwapRefundHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _refund(session),
                icon: const Icon(Icons.undo),
                label: Text(loc.lightningSwapRefund),
              ),
            ],
            TextButton(
              onPressed: () => _copyBlob(session),
              child: Text(loc.lightningSwapCopyBlob),
            ),
          ],
        ),
      );

  /// Storico delle transazioni fatte via provider (P9), più recenti prima.
  ///
  /// // PERCHÉ (07/10/2026): dopo un pagamento l'utente deve poterlo ritrovare
  /// // e rileggere; tap sulla riga → dettaglio completo (dati on-chain,
  /// // protocollo e recupero fondi).
  Widget _buildHistoryCard(AppLocalizations loc) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.lightningSwapHistoryTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (_sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.lightningSwapHistoryEmpty,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final s in _sessions)
                SwapHistoryTile(
                  session: s,
                  stateLabel: _stateLabel(loc, s.state),
                  onTap: _busy ? null : () => _openDetail(s),
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
            // Le sessioni note sono elencate nella sezione "Storico" (con
            // dettaglio e refund): qui niente doppioni.
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

  /// Etichetta nel menu: il nodo predefinito ha un nome leggibile, il resto
  /// resta la URI abbreviata.
  String _uriLabel(AppLocalizations loc, String uri) =>
      uri == SwapDefaults.providerUri
          ? loc.lightningSwapProviderDefaultLabel
          : _shortUri(uri);

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
    final snapshot = BalanceCache.snapshotOf(w.publicAddress);
    final sats = snapshot?.balanceSats;
    final base = loc.lightningSwapWalletBalance(sats?.toString() ?? '?');
    // PERCHÉ (A3 + saldo): il pagamento LN via provider può contare solo sui
    // sat spendibili — se ce ne sono in periodo di attesa vanno detti, non
    // sommati (il funding non li può usare).
    final waiting = snapshot?.blockedCoinbaseSats ?? 0;
    if (waiting <= 0) return base;
    final remaining = snapshot?.blockedRemainingBlocks;
    final waitingText = remaining != null
        ? '${loc.walletBalanceWaiting('$waiting sat')} · '
              '${loc.walletUtxoWaitingBlocks(remaining)}'
        : loc.walletBalanceWaiting('$waiting sat');
    return '$base\n$waitingText';
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

/// Stato della sonda sul provider predefinito (il nodo del progetto).
///
/// // PERCHÉ: il nodo è sempre selezionabile, ma l'utente deve sapere se in
/// // questo momento risponde o se conviene riprovare più tardi.
enum _DefaultProbe { unknown, checking, reachable, unreachable }
