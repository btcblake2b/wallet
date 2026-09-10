import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/widgets/password_dialog.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/balance_cache.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/rbf_params_registry.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/services/security_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'api_error_text.dart';
import 'send_screen.dart';
import '../../../core/models/transaction_record.dart';
import '../../../core/models/wallet_snapshot.dart';
import 'widgets/bump_fee_dialog.dart';
import 'widgets/transaction_history_section.dart';
import 'widgets/seed_phrase_verifier.dart';

class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
    required this.walletRepository,
    required this.biometricService,
    required this.bitcoinService,
    required this.cryptoService,
    required this.deviceService,
    this.random,
  });

  final WalletRecord wallet;
  final WalletRepository walletRepository;
  final BiometricService biometricService;
  final BitcoinService bitcoinService;
  final CryptoService cryptoService;
  final DeviceService deviceService;

  /// Random iniettabile per test deterministici della verifica seed.
  final Random? random;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen>
    with WidgetsBindingObserver {
  static const _kSeedAutoHide = Duration(seconds: 60);

  late WalletRecord _wallet;
  bool _isLoading = true;
  bool _checkingBiometric = false;
  String? _seedPhrase;

  // ── Verifica backup seed (S7.1) ──
  bool _seedHidden = false;
  bool _showVerify = false;
  bool _seedVerified = false;
  Timer? _seedTimer;

  // ── Snapshot unico (single source of truth) ──
  // PERCHÉ: saldo, txCount, UTXO e storico derivano TUTTI da un unico snapshot
  // condiviso in BalanceCache → niente variabili separate che si desincronizzano.
  WalletSnapshot? _snapshot;

  /// True durante un refresh esplicito CON dati già visibili (spinner piccolo).
  bool _refreshing = false;

  /// True mentre è in corso un bump fee (RBF S8/C) — guardia anti doppio tap.
  bool _bumping = false;

  /// Errore del caricamento iniziale (solo quando non c'è ancora snapshot).
  String? _error;

  // ── Coin control (S7) ──
  // PERCHÉ: selezione come Set di chiavi '$txid:$vout' — identifica un UTXO
  // univoco anche dopo un refresh (stesso txid/vout = stesso output).
  final Set<String> _selectedUtxoKeys = {};

  // ── Getter derivati dallo snapshot ──
  // PERCHÉ: tutta la UI (saldo, "N transazioni", coin control, storico) legge
  // da questi getter: aggiornare `_snapshot` aggiorna tutto in un colpo solo.
  // PERCHÉ (P1 watch-only): il wallet di sola lettura non ha seed — le azioni
  // che richiedono firma vengono nascoste/disabilitate.
  bool get _isWatchOnly => _wallet.kind == WalletKind.watchOnly;
  double get _balance => (_snapshot?.balanceSats ?? 0).toDouble();
  int get _txCount => _snapshot?.txCount ?? 0;
  // PERCHÉ: la semantica storica era "lista vuota → null" (SendScreen tratta
  // initialUtxos != null come UTXO forniti dal coin control). Una lista vuota
  // deve equivalere a "nessun UTXO noto", non a una selezione vuota esplicita.
  List<UtxoInfo>? get _utxos {
    final utxos = _snapshot?.utxos;
    return (utxos == null || utxos.isEmpty) ? null : utxos;
  }

  List<TransactionRecord> get _transactions =>
      _snapshot?.transactions ?? const [];

  /// Somma dei valueSat degli UTXO selezionati (coin control S7).
  int get _selectedUtxoSats => (_utxos ?? const <UtxoInfo>[])
      .where((u) => _selectedUtxoKeys.contains('${u.txid}:${u.vout}'))
      .fold<int>(0, (s, u) => s + u.valueSat);

  int get _selectedUtxoCount => _selectedUtxoKeys.length;

  String _formatUtxoBtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} BTC';

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wallet = widget.wallet;
    _nameController = TextEditingController(text: _wallet.name ?? '');
    // Politica refresh minima — NESSUN fetch automatico a ogni ingresso:
    // - snapshot fresco in cache (TTL) → mostra subito, ZERO rete;
    // - snapshot presente ma vecchio → mostra subito + aggiornamento silenzioso
    //   in background (l'utente non vede mai dati "polverosi");
    // - nessuno snapshot → primo caricamento (spinner).
    final cached = BalanceCache.snapshotOf(_wallet.publicAddress);
    if (cached != null) {
      _snapshot = cached;
      _isLoading = false;
      // PERCHÉ: snapshot PARZIALE (Home all'avvio: solo saldo+UTXO senza
      // storico) → va completato; snapshot completo ma vecchio (TTL) → va
      // aggiornato. In entrambi i casi refresh SILENZIOSO: i dati già visibili
      // restano a schermo e l'UI non si blocca.
      if (!cached.isComplete || !cached.isFresh(kSnapshotTtl)) {
        _refresh(silent: true);
      }
    } else {
      _refresh();
    }

    // Protect screen when viewing wallet details
    SecurityService().protectScreen(true);
    _checkDeviceSecurity();
  }

  Future<void> _checkDeviceSecurity() async {
    // Passa il context per mostrare il dialog di blocco
    await SecurityService().enforceDeviceSecurity(context: context);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.walletDetailCopied(label))),
    );

    // Clear clipboard after 60 seconds for security
    Future.delayed(const Duration(seconds: 60), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _seedTimer?.cancel();
    _nameController.dispose();
    SecurityService().protectScreen(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // PERCHÉ: nascondi la seed quando l'app perde il focus (inactive, es. app
    // switcher — dove uno screenshot catturerebbe la seed) o va in background
    // (paused). Il ri-mostra richiede comunque ri-autenticazione.
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _seedPhrase != null) {
      _seedTimer?.cancel();
      setState(() => _seedHidden = true);
    }
  }

  /// Refresh del wallet: fetch completo (saldo+UTXO+storico) con dedup e salvataggio
  /// nella cache condivisa (notifica la Home). `silent` = aggiornamento in
  /// background senza spinner pieno (usato quando c'è già uno snapshot visibile).
  Future<void> _refresh({bool silent = false}) async {
    if (mounted) {
      setState(() {
        // PERCHÉ: spinner pieno solo al PRIMO caricamento (nessuno snapshot);
        // con dati già visibili si mostra solo l'indicatore piccolo di refresh.
        if (_snapshot == null) {
          _isLoading = true;
          _error = null;
        } else {
          _refreshing = true;
        }
      });
    }

    try {
      // PERCHÉ (P1 watch-only): i watch-only non hanno seed — lo snapshot si
      // costruisce dall'xpub (sola lettura); i wallet hot decriptano il seed.
      // getOrFetch deduplica: se la Home sta già caricando questo wallet
      // (avvio app) il Detail attende lo stesso fetch invece di lanciarne un
      // secondo (niente doppia chiamata di rete). Al completamento salva in
      // cache e notifica i listener.
      final snapshot = await BalanceCache.getOrFetch(
        _wallet.publicAddress,
        () async {
          if (_isWatchOnly) {
            return widget.bitcoinService.fetchWatchOnlySnapshot(
              accountXpub: _wallet.accountXpub ?? '',
              scriptType: WalletScriptType.fromDerivationPath(
                _wallet.derivationPath,
              ),
            );
          }
          final seed = await widget.walletRepository.decryptSeed(_wallet);
          return widget.bitcoinService.fetchWalletSnapshot(
            seed,
            derivationPath: _wallet.derivationPath,
          );
        },
      );
      if (!mounted) return;

      // PERCHÉ (S7): dopo un refresh gli UTXO spesi spariscono → azzera la
      // selezione per non conservare chiavi orfane.
      _selectedUtxoKeys.clear();

      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('WalletDetail refresh error: $e');
      setState(() {
        _isLoading = false;
        _refreshing = false;
        // PERCHÉ (errore primo avvio): senza snapshot mostriamo un errore con
        // retry; con uno snapshot vecchio lo teniamo (mai schermo vuoto/0 BTC).
        // Il messaggio è localizzato e distinto per causa (rate limit /
        // servizio giù / rete), non il dump tecnico dell'eccezione.
        if (_snapshot == null) {
          final loc = AppLocalizations.of(context);
          _error =
              apiErrorReason(loc, apiErrorCode(e)) ?? loc.walletDetailTxError;
        }
      });
    }
  }

  Future<void> _updateName(String name) async {
    if (name == _wallet.name) return;
    final updated = _wallet.copyWith(name: name);
    await widget.walletRepository.updateWallet(updated);
    if (mounted) {
      setState(() => _wallet = updated);
    }
  }

  Future<void> _showSeedPhrase() async {
    // PERCHÉ (P1): i watch-only non hanno seed da mostrare (mai chiavi
    // private). Il bottone è nascosto in UI; guardia difensiva sotto.
    if (_isWatchOnly) return;
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.walletDetailShowSeedTitle),
        content: Text(loc.walletDetailShowSeedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.passwordDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.walletDetailShowSeedConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _checkingBiometric = true);

    try {
      final authenticated = await _authenticateSeedView();
      if (!mounted || !authenticated) return;

      final seed = await widget.walletRepository.decryptSeed(_wallet);
      if (!mounted) return;
      setState(() {
        _seedPhrase = seed;
        _seedHidden = false;
        _seedVerified = _wallet.seedBackupConfirmed;
        _showVerify = false;
      });
      _startSeedTimer();

      // Offerta di verifica SOLO se il backup non è ancora stato confermato.
      // PERCHÉ: UX-003 — niente più checkbox di auto-affermazione: si propone
      // una verifica reale (3 parole) come nella creazione del wallet.
      if (!_wallet.seedBackupConfirmed && mounted) {
        final verify = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(loc.backupSeedVerifyTitle),
            content: Text(loc.walletDetailSeedVerifyPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(loc.walletDetailSeedVerifyNotNow),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(loc.walletDetailSeedVerifyYes),
              ),
            ],
          ),
        );
        if (verify == true && mounted) {
          setState(() => _showVerify = true);
        } else {
          // PERCHÉ: se l'utente non vuole verificare ora, nascondi la seed per
          // sicurezza (lo stato "non confermato" resta visibile dal banner).
          debugPrint('[LoopEngineer] Backup non verificato — seed nascosta');
          _seedTimer?.cancel();
          if (mounted) setState(() => _seedPhrase = null);
        }
      }
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  /// Autenticazione per vedere la seed (biometria nativa / password web).
  /// Estratta per essere riusata dal ri-mostra dopo l'auto-hide.
  ///
  /// // PERCHÉ (S8/C): le ragioni (password web / biometria) sono
  /// parametrizzabili con default = seed: il bump fee riusa lo stesso
  /// flusso di auth con ragioni dedicate, zero duplicazione.
  Future<bool> _authenticateSeedView({
    String? passwordReason,
    String? biometricReason,
  }) async {
    final loc = AppLocalizations.of(context);
    if (kIsWeb) {
      final has = await widget.biometricService.canAuthenticate();
      if (!mounted) return false;
      if (!has) {
        final pw = await PasswordDialog.showCreatePasswordDialog(context);
        if (pw == null) return false;
        await widget.biometricService.setPassword(pw);
        await widget.walletRepository.enablePasswordProtection(pw);
      }
      if (!mounted) return false;
      final entered = await PasswordDialog.showEnterPasswordDialog(
        context,
        reason: passwordReason ?? loc.walletDetailPasswordSeedReason,
      );
      if (!mounted || entered == null) return false;
      final ok = await widget.biometricService.verifyPassword(entered);
      if (ok) {
        await widget.walletRepository.unlockWebStorage(entered);
        await widget.walletRepository.enablePasswordProtection(entered);
      }
      return ok;
    }
    return widget.biometricService.authenticateForSensitiveAction(
      reason: biometricReason ?? loc.walletDetailBiometricSeedReason,
    );
  }

  /// Predicato bump fee (RBF S8/C): tx pending OUTGOING nostra, con i
  /// parametri di sessione registrati al broadcast (incremento B).
  ///
  /// // PERCHÉ: `RbfParamsRegistry` è l'unica fonte che garantisce di avere
  /// i dati per ricostruire la tx; i wallet watch-only non firmano mai e
  /// non hanno parametri → esclusi dal predicato.
  bool _canBumpTx(TransactionRecord tx) =>
      !_isWatchOnly &&
      tx.direction == TxDirection.outgoing &&
      tx.isPending &&
      RbfParamsRegistry.contains(tx.txid);

  /// Orchestratore "Aumenta fee" (RBF S8/C): scelta fee → auth → bump.
  //
  // FLOW: Aumento Fee RBF (BIP125)
  Future<void> _onBumpFee(TransactionRecord tx) async {
    final loc = AppLocalizations.of(context);
    if (_isWatchOnly || _bumping) return;
    final params = RbfParamsRegistry.of(tx.txid);
    if (params == null) return; // guardia: predicato già verificato

    setState(() => _bumping = true);
    try {
      // STEP: 1 — stime fee dal mempool (null → dialog solo custom)
      FeeEstimates? estimates;
      try {
        estimates = await widget.bitcoinService.fetchFeeEstimates();
      } catch (e) {
        debugPrint('[LoopEngineer] bumpFee: stime non disponibili: $e');
      }
      if (!mounted) return;

      // STEP: 2 — scelta della nuova fee (dialog dedicato, filtra ≤ originale)
      final newFeeRate = await showBumpFeeDialog(
        context,
        originalFeeRateSatVb: params.originalFeeRateSatVb,
        estimates: estimates,
      );
      if (newFeeRate == null || !mounted) return;

      // STEP: 3 — auth di spesa (biometria nativa / password web)
      final authorized = await _authenticateSeedView(
        passwordReason: loc.walletDetailPasswordBumpReason,
        biometricReason: loc.walletDetailBiometricBumpReason,
      );
      if (!authorized || !mounted) return;

      // STEP: 4 — decrypt seed + bump (mai seed in cache, solo per firma)
      final mnemonic = await widget.walletRepository.decryptSeed(_wallet);
      final result = await widget.bitcoinService.bumpFee(
        mnemonic: mnemonic,
        txid: tx.txid,
        newFeeRateSatVb: newFeeRate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.walletDetailBumpFeeSuccess(result.txid)),
        ),
      );
      // Il replacement è broadcastato: la vecchia tx diventa evicted al
      // prossimo probe (404) e la nuova compare come pending.
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      // PERCHÉ: bumpFee lancia ArgumentError se la fee non è maggiore —
      // messaggio dedicato; gli altri errori mostrano il dettaglio.
      final msg =
          e is ArgumentError ? loc.walletDetailBumpFeeErrorFee : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _bumping = false);
    }
  }

  /// Avvia (o riavvia) il timer di auto-hide della seed dopo inattività.
  void _startSeedTimer() {
    _seedTimer?.cancel();
    // PERCHÉ: se qualcuno prende il telefono mentre la seed è a schermo,
    // questa sparisce da sola dopo il timeout — i campi di verifica restano.
    _seedTimer = Timer(_kSeedAutoHide, () {
      if (mounted && _seedPhrase != null && !_seedHidden) {
        debugPrint('[LoopEngineer] Auto-hide seed (timer)');
        setState(() => _seedHidden = true);
      }
    });
  }

  void _resetSeedTimer() {
    if (_seedPhrase != null && !_seedHidden) _startSeedTimer();
  }

  /// Ri-mostra la seed dopo l'auto-hide: richiede una breve ri-autenticazione.
  Future<void> _revealSeedAgain() async {
    // PERCHÉ: senza ri-auth l'auto-hide sarebbe solo scenografico.
    setState(() => _checkingBiometric = true);
    try {
      final ok = await _authenticateSeedView();
      if (!mounted || !ok) return;
      setState(() => _seedHidden = false);
      _startSeedTimer();
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  /// Verifica seed completata (3 parole corrette) → conferma il backup.
  Future<void> _onSeedVerified() async {
    final updated = await widget.walletRepository.confirmSeedBackup(_wallet);
    if (!mounted) return;
    setState(() {
      _wallet = updated;
      _seedVerified = true;
      _showVerify = false;
    });
    debugPrint('[LoopEngineer] Backup seed verificato per ${_wallet.walletId}');
    _startSeedTimer();
  }

  /// Derivazione indirizzi/xpub branchando sul tipo di wallet.
  /// PERCHÉ (P1): per i watch-only la derivazione parte dall'xpub salvato
  /// (nessun seed in memoria); per i wallet hot dal seed. Restituisce gli
  /// indirizzi external e l'xpub (per il watch-only: quello salvato/validato).
  Future<({List<String> addresses, String xpub})> _deriveAddresses({
    int addressCount = 100,
  }) async {
    if (_isWatchOnly) {
      final derived = await widget.bitcoinService.deriveWatchOnlyData(
        accountXpub: _wallet.accountXpub ?? '',
        scriptType: WalletScriptType.fromDerivationPath(_wallet.derivationPath),
        addressCount: addressCount,
      );
      return (
        addresses: derived.externalAddresses,
        xpub: derived.accountXpub,
      );
    }
    final seed = await widget.walletRepository.decryptSeed(_wallet);
    final result = await widget.bitcoinService.deriveWalletDataFromMnemonic(
      seed,
      derivationPath: _wallet.derivationPath,
      addressCount: addressCount,
    );
    return (addresses: result.addresses, xpub: result.xpub);
  }

  Future<void> _showAddressesList() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final derived = await _deriveAddresses();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (context, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.walletDetailFirst100Addresses,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: derived.addresses.length,
                    separatorBuilder: (context, index) =>
                        const Divider(indent: 72, height: 1),
                    itemBuilder: (context, index) {
                      final addr = derived.addresses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          addr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: addr));
                            final loc = AppLocalizations.of(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.walletDetailAddressCopied),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: addr));
                          final loc = AppLocalizations.of(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.walletDetailAddressCopied),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.walletDetailErrorAddresses(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showXpubDialog() async {
    setState(() => _isLoading = true);
    try {
      // PERCHÉ (P1): per un watch-only l'xpub è quello salvato (già validato
      // all'import) — nessuna derivazione da seed.
      final derived = await _deriveAddresses();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(loc.walletDetailXpubTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.walletDetailXpubDesc,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    derived.xpub,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: derived.xpub));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(loc.walletDetailXpubCopied)),
                  );
                },
                child: Text(loc.walletDetailCopy),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.walletDetailClose),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.walletDetailErrorXpub(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWallet() async {
    final loc = AppLocalizations.of(context);

    // PERCHÉ (UX-001): se il backup della seed non è confermato, la seed può
    // andare persa per sempre — richiedi una conferma extra prima di eliminare.
    // PERCHÉ (P1): i watch-only non hanno seed da perdere → gate saltato.
    if (!_wallet.seedBackupConfirmed && !_isWatchOnly) {
      final backupFirst = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.walletDetailBackupNotConfirmed),
          content: Text(loc.walletDetailDeleteWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.passwordDialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(loc.walletDetailDeleteConfirm),
            ),
          ],
        ),
      );
      if (backupFirst != true || !mounted) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.walletDetailDeleteTitle),
        content: Text(loc.walletDetailDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.passwordDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.walletDetailDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await widget.walletRepository.deleteWallet(_wallet.walletId);
    if (mounted) {
      // Usa maybePop invece di pop per evitare crash se lo stack
      // di navigazione è già vuoto.
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    }
  }

  /// Indirizzo di ricezione: primo indirizzo external (/0/N) SENZA UTXO.
  ///
  /// PERCHÉ (gap BIP44): se il primo indirizzo (publicAddress = /0/0) ha già
  /// UTXO, il dialog Ricevi deve mostrare il successivo indirizzo libero.
  /// Riusa `_utxos` già popolato dal refresh (avvio app + ingresso detail) —
  /// nessuna scan di rete aggiuntiva, quindi il dialog resta veloce.
  Future<String> _resolveReceiveAddress() async {
    final used = (_utxos ?? const <UtxoInfo>[])
        .map((u) => u.ownerAddress)
        .whereType<String>()
        .toSet();
    // PERCHÉ: nessun UTXO noto → il primo indirizzo è ancora libero.
    if (used.isEmpty) return _wallet.publicAddress;

    // PERCHÉ (P1 watch-only): per i watch-only si deriva dall'xpub (nessun
    // seed); per i wallet hot dal seed. decryptSeed SOLO nel ramo hot.
    if (_isWatchOnly) {
      final derived = await _deriveAddresses();
      for (final addr in derived.addresses) {
        if (!used.contains(addr)) return addr;
      }
      return _wallet.publicAddress;
    }
    final seed = await widget.walletRepository.decryptSeed(_wallet);
    final derivationResult =
        await widget.bitcoinService.deriveWalletDataFromMnemonic(
      seed,
      derivationPath: _wallet.derivationPath,
    );
    for (final addr in derivationResult.addresses) {
      if (!used.contains(addr)) return addr;
    }
    // PERCHÉ: fallback conservativo — tutti i derivati usati, torna al primo.
    return _wallet.publicAddress;
  }

  Future<void> _showReceiveDialog() async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: mostra lo spinner mentre si risolve l'indirizzo (derivazione
    // locale, veloce — nessuna chiamata di rete).
    setState(() => _isLoading = true);
    String receiveAddress;
    try {
      receiveAddress = await _resolveReceiveAddress();
    } catch (_) {
      // PERCHÉ: se la derivazione fallisce, il primo indirizzo resta valido.
      receiveAddress = _wallet.publicAddress;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.walletDetailReceiveQr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              excludeSemantics: true,
              child: RepaintBoundary(
                key: ValueKey(receiveAddress),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox.square(
                    dimension: 200,
                    child: QrImageView(
                      data: receiveAddress,
                      version: QrVersions.auto,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      errorStateBuilder: (ctx, error) {
                        debugPrint('QR address error: $error');
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              receiveAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            // PERCHÉ: pulsantino per copiare subito l'indirizzo mostrato nel
            // dialog (usato anche dall'utente che non vuole scannerizzare).
            TextButton.icon(
              onPressed: () => _copyToClipboard(
                receiveAddress,
                loc.walletDetailAddress,
              ),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(loc.walletDetailCopy),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.walletDetailClose),
          ),
        ],
      ),
    );
  }

  // FLOW: Invia BTC — variante coin control (S7)
  Future<void> _openSendScreen() async {
    // PERCHÉ (S7): se l'utente ha selezionato UTXO (coin control), passa solo
    // il sottoinsieme; altrimenti comportamento attuale (tutti gli UTXO).
    final selected = _selectedUtxos();
    final initialUtxos =
        (selected != null && selected.isNotEmpty) ? selected : _utxos;
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendScreen(
          wallet: _wallet,
          walletRepository: widget.walletRepository,
          bitcoinService: widget.bitcoinService,
          // PERCHÉ (audit A1): SendScreen richiede l'autenticazione
          // (biometria) prima di firmare — gli passa il servizio condiviso.
          biometricService: widget.biometricService,
          balanceSats: _balance.toInt(),
          initialUtxos: initialUtxos,
        ),
      ),
    );
    if (sent == true && mounted) {
      await _refresh();
    }
  }

  /// Sottoinsieme degli UTXO selezionati (ordine = _utxos). null se nessuno.
  List<UtxoInfo>? _selectedUtxos() {
    if (_selectedUtxoKeys.isEmpty || _utxos == null) return null;
    return _utxos!
        .where((u) => _selectedUtxoKeys.contains('${u.txid}:${u.vout}'))
        .toList();
  }

  void _toggleUtxoSelection(UtxoInfo utxo) {
    final key = '${utxo.txid}:${utxo.vout}';
    setState(() {
      if (!_selectedUtxoKeys.add(key)) {
        _selectedUtxoKeys.remove(key);
      }
    });
  }

  String? _utxoLabel(UtxoInfo utxo) {
    final label = _wallet.utxoLabels['${utxo.txid}:${utxo.vout}'];
    return label == null || label.trim().isEmpty ? null : label.trim();
  }

  Future<void> _renameUtxo(UtxoInfo utxo) async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: il controller vive dentro un widget dedicato (_RenameUtxoDialog)
    // che lo smaltisce in dispose(), quando il dialog è stato smontato del
    // tutto. Dispose subito dopo await showDialog() causava l'assert
    // "_dependents.isEmpty" perché il TextField era ancora montato durante
    // l'animazione di chiusura del dialog.
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameUtxoDialog(
        loc: loc,
        initialName: _utxoLabel(utxo) ?? '',
      ),
    );
    if (name == null || !mounted) return;

    final labels = Map<String, String>.from(_wallet.utxoLabels);
    final key = '${utxo.txid}:${utxo.vout}';
    if (name.isEmpty) {
      labels.remove(key);
    } else {
      labels[key] = name;
    }

    final updated = _wallet.copyWith(utxoLabels: labels);
    await widget.walletRepository.updateWallet(updated);
    if (mounted) setState(() => _wallet = updated);
  }

  void _clearUtxoSelection() {
    setState(_selectedUtxoKeys.clear);
  }

  Future<void> _showSignVerifyDialog() async {
    final messageController = TextEditingController();
    final addressController =
        TextEditingController(text: _wallet.publicAddress);
    final signatureController = TextEditingController();
    bool isVerifying = _isWatchOnly;
    String? result;
    bool processing = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            title: Text(
              isVerifying
                  ? loc.walletDetailVerifyMessage
                  : loc.walletDetailSignMessage,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PERCHÉ (P1): per un watch-only il dialog è SOLO verifica
                  // (nessuna chiave privata da cui firmare).
                  if (!_isWatchOnly)
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(loc.walletDetailSign),
                          icon: const Icon(Icons.edit),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(loc.walletDetailVerify),
                          icon: const Icon(Icons.check_circle),
                        ),
                      ],
                      selected: {isVerifying},
                      onSelectionChanged: (val) => setDialogState(() {
                        isVerifying = val.first;
                        result = null;
                      }),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.walletDetailMessage,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (isVerifying) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: loc.walletDetailBitcoinAddress,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: signatureController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: loc.walletDetailSignature,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(ctx2).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerifying
                                ? loc.walletDetailResult
                                : loc.walletDetailSignatureLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            result!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: Text(loc.walletDetailClose),
              ),
              if (processing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                FilledButton(
                  onPressed: () async {
                    if (messageController.text.isEmpty) return;
                    setDialogState(() => processing = true);
                    try {
                      if (isVerifying) {
                        final ok = await widget.bitcoinService.verifyMessage(
                          addressController.text,
                          messageController.text,
                          signatureController.text,
                        );
                        // PERCHÉ: usa AppLocalizations per la validazione firma
                        setDialogState(() {
                          result = ok
                              ? loc.walletDetailValidSig
                              : loc.walletDetailInvalidSig;
                        });
                      } else {
                        final seed =
                            await widget.walletRepository.decryptSeed(_wallet);
                        final sig = await widget.bitcoinService
                            .signMessage(seed, messageController.text);
                        setDialogState(() => result = sig);
                      }
                    } catch (e) {
                      setDialogState(() => result = 'Error: $e');
                    } finally {
                      setDialogState(() => processing = false);
                    }
                  },
                  child: Text(
                    isVerifying ? loc.walletDetailVerify : loc.walletDetailSign,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    final loc = AppLocalizations.of(context);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.walletDetailInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(loc.walletDetailId, _wallet.walletId),
            _buildInfoRow(loc.walletDetailAddress, _wallet.publicAddress),
            _buildInfoRow(
              loc.walletDetailCreated,
              formatter.format(_wallet.createdAt.toLocal()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.walletDetailClose),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Build — Sezioni riorganizzate per gerarchia visiva (P0 #2)
  // Ordine: Nome → Backup Warning → Saldo → Azioni → Info → Strumenti
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.walletDetailTitle),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteWallet();
                } else if (value == 'info') {
                  _showInfoDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'info',
                  child: Text(loc.walletDetailInfo),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    loc.walletDetailDeleteTitle,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 1. Wallet Name ────────────────────────────────
            _buildNameField(colorScheme),
            const SizedBox(height: 24),

            // ── 2. Backup Warning Banner ─────────────────────
            // PERCHÉ (UX-006): visibile finché il backup della seed non è
            // stato confermato dall'utente. PERCHÉ (P1): i watch-only non
            // hanno seed → banner mai mostrato.
            if (!_wallet.seedBackupConfirmed && !_isWatchOnly)
              _buildBackupWarningBanner(colorScheme, loc),

            // ── 3. Balance Card (sempre visibile, priorità max) ──
            _buildBalanceCard(colorScheme, loc),
            const SizedBox(height: 24),

            // ── 4. Azioni primarie (thumb zone) ──────────────
            _buildQuickActions(colorScheme, loc),

            // ── 4b. Storico transazioni (S1) ────────────────
            const SizedBox(height: 24),
            TransactionHistorySection(
              transactions: _transactions,
              // PERCHÉ: spinner dello storico solo al primo caricamento; con
              // snapshot già visibile i dati restano a schermo.
              isLoading: _isLoading,
              // PERCHÉ: errore con retry visibile solo se NON c'è ancora alcuno
              // snapshot (primo avvio fallito) — mai schermo vuoto.
              error: _snapshot == null ? _error : null,
              onRetry: () => _refresh(),
              isBumpable: _canBumpTx,
              onBumpFee: _onBumpFee,
            ),

            // ── 5. Info Wallet (collassabile) ────────────────
            _buildWalletInfoSection(colorScheme, loc),

            // ── 5b. Coin control / UTXO (S7) ────────────────
            const SizedBox(height: 8),
            _buildUtxoSection(colorScheme, loc),

            // ── 6. Strumenti avanzati (collassabile) ─────────
            const SizedBox(height: 8),
            _buildAdvancedToolsSection(colorScheme, loc),

            // ── 7. Seed phrase rivelata ──────────────────────
            if (_seedPhrase != null) ...[
              const SizedBox(height: 24),
              _buildSeedPhraseDisplay(colorScheme, loc),
            ],

            // ── 8. Elimina wallet (sempre in fondo) ──────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _deleteWallet,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                loc.walletDetailDeleteTitle,
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Sezioni del build
  // ──────────────────────────────────────────────────────────────

  /// 1. Campo nome wallet
  Widget _buildNameField(ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PERCHÉ (P1): badge di sola lettura per i wallet watch-only —
        // chiaro all'utente che non può firmare da questo wallet.
        if (_isWatchOnly) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              loc.watchOnlyBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _nameController,
          onChanged: _updateName,
          decoration: InputDecoration(
            labelText: loc.walletDetailNameLabel,
            hintText: loc.walletDetailNameHint,
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 3. Card saldo con refresh
  Widget _buildBalanceCard(ColorScheme colorScheme, AppLocalizations loc) {
    // PERCHÉ (errore primo avvio): se NON c'è ancora alcuno snapshot e il primo
    // caricamento è fallito, mostriamo un errore con retry — mai 0 BTC o uno
    // spinner infinito.
    if (_snapshot == null && _error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(loc.walletDetailBalanceLabel),
          const SizedBox(height: 8),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.5),
            borderColor: colorScheme.error.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_off, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.walletDetailTxError,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
                // PERCHÉ: motivo distinto (rate limit / servizio giù / rete)
                // quando noto — `_error` contiene già il testo localizzato.
                if (_error != null && _error != loc.walletDetailTxError) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _refresh(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(loc.walletDetailTxRetry),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(loc.walletDetailBalanceLabel),
        const SizedBox(height: 8),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          borderColor: colorScheme.primary.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        // PERCHÉ (F4): senza snapshot (primo caricamento in
                        // corso) niente "0.00000000 BTC" finto — stato
                        // esplicito. Il caso errore esce prima con la card
                        // error+retry (mai 0).
                        _snapshot != null
                            ? '${(_balance / 100000000).toStringAsFixed(8)} BTC'
                            : loc.balanceUnavailable,
                        // PERCHÉ (S5): onSurface (bianco in dark, scuro in
                        // light) — prima era Colors.white fisso.
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _isLoading
                          ? loc.walletDetailUpdating
                          : loc.walletDetailNTransactions(_txCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_isLoading || _refreshing)
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.onSurface,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(loc.walletDetailRefresh),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.8),
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4a. Azioni rapide (Receive / Send) — wallet unlocked
  /// PERCHÉ (P1): un watch-only non ha chiavi per firmare → SOLO Receive.
  Widget _buildQuickActions(ColorScheme colorScheme, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _showReceiveDialog,
              icon: const Icon(Icons.call_received),
              label: Text(loc.walletDetailReceive),
            ),
          ),
          if (!_isWatchOnly) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _openSendScreen,
                icon: const Icon(Icons.call_made),
                label: Text(loc.walletDetailSend),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Label del tipo di wallet mostrata in Wallet Info.
  /// PERCHÉ (BIP49): non è più un testo fisso — dipende dal derivation path
  /// (m/84'… → Native SegWit, m/49'… → Nested SegWit).
  String _walletTypeLabel(AppLocalizations loc) {
    final type = WalletScriptType.fromDerivationPath(_wallet.derivationPath);
    if (type.isLegacy) return loc.walletTypeLegacy;
    return type.isNested
        ? loc.walletTypeNestedSegwit
        : loc.walletTypeNativeSegwit;
  }

  /// 5. Sezione info wallet (collassabile)
  Widget _buildWalletInfoSection(
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          loc.walletDetailInfo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.info_outline, color: colorScheme.primary),
        children: [
          // Wallet Type
          _buildLabel(loc.walletDetailType),
          Text(
            _walletTypeLabel(loc),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Wallet Address
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              loc.walletDetailWalletAddress,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _wallet.publicAddress,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            trailing: const Icon(Icons.copy, size: 20),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: _wallet.publicAddress),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.walletDetailAddressCopied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              loc.walletDetailShowAddresses,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, size: 20),
            onTap: _isLoading ? null : _showAddressesList,
          ),
          const SizedBox(height: 8),

          // Master Fingerprint + Derivation Path
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_wallet.masterFingerprint != null) {
                      _copyToClipboard(
                        _wallet.masterFingerprint!,
                        'Fingerprint',
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(loc.walletDetailMasterFingerprint),
                        Row(
                          children: [
                            Text(
                              _wallet.masterFingerprint ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final path = _wallet.derivationPath ??
                        BitcoinNetworkConfig.defaultDerivationPath;
                    _copyToClipboard(path, 'Derivation Path');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(loc.walletDetailDerivationPath),
                        Row(
                          children: [
                            Text(
                              _wallet.derivationPath ??
                                  BitcoinNetworkConfig.defaultDerivationPath,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Display in Home toggle
          _buildLabel(loc.walletDetailSettings),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              loc.walletDetailDisplayHome,
              style: const TextStyle(fontSize: 14),
            ),
            value: _wallet.displayInHomeScreen,
            onChanged: (val) async {
              final updated = _wallet.copyWith(displayInHomeScreen: val);
              await widget.walletRepository.updateWallet(updated);
              setState(() => _wallet = updated);
            },
          ),
        ],
      ),
    );
  }

  /// 5b. Coin control / UTXO (S7): lista UTXO con selezione manuale.
  Widget _buildUtxoSection(ColorScheme colorScheme, AppLocalizations loc) {
    final utxos = _utxos ?? const <UtxoInfo>[];
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          loc.walletDetailUtxos,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Icon(
          Icons.account_balance_wallet_outlined,
          color: colorScheme.secondary,
        ),
        children: [
          if (utxos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                loc.walletDetailUtxoEmpty,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else ...[
            for (final utxo in utxos) _buildUtxoRow(utxo, colorScheme, loc),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.walletDetailUtxoSelected(
                      _selectedUtxoCount,
                      _selectedUtxoSats,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed:
                      _selectedUtxoKeys.isEmpty ? null : _clearUtxoSelection,
                  child: Text(loc.walletDetailUtxoClearSelection),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // PERCHÉ (P1): solo i wallet con chiavi possono inviare — il
            // pulsante "Invia selezionati" del coin control è nascosto per i
            // watch-only (la lista UTXO resta consultabile in sola lettura).
            if (!_isWatchOnly)
              FilledButton.icon(
                // PERCHÉ: solo con selezione attiva — senza selezione si usa il
                // pulsante Invia principale (comportamento attuale).
                onPressed: _selectedUtxoKeys.isEmpty ? null : _openSendScreen,
                icon: const Icon(Icons.send),
                label: Text(loc.walletDetailUtxoSendSelected),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildUtxoRow(
    UtxoInfo utxo,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final key = '${utxo.txid}:${utxo.vout}';
    final selected = _selectedUtxoKeys.contains(key);
    final pending = utxo.confirmations == 0;
    final confirmations = utxo.confirmations;
    final label = _utxoLabel(utxo);
    final shortTxid =
        utxo.txid.length > 8 ? utxo.txid.substring(0, 8) : utxo.txid;
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => _toggleUtxoSelection(utxo),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              _formatUtxoBtc(utxo.valueSat),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _renameUtxo(utxo),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(label ?? loc.walletDetailUtxoRename),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '$shortTxid…:${utxo.vout}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                // PERCHÉ: riuso walletDetailTxPending (stessa semantica).
                loc.walletDetailTxPending,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            )
          else if (confirmations != null && confirmations > 0)
            Text(
              loc.walletDetailUtxoConfirmations(confirmations),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  /// 6. Strumenti avanzati (collassabile)
  Widget _buildAdvancedToolsSection(
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          loc.walletDetailAdvancedTools,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.build, color: colorScheme.secondary),
        children: [
          // PERCHÉ (P1): i watch-only non hanno seed da esportare → il
          // bottone "Export seed" è nascosto; resta XPUB (mostra l'xpub
          // salvato) e Sign/Verify in modalità solo-verifica.
          if (!_isWatchOnly) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // PERCHÉ: disabilita il pulsante mentre la verifica biometrica o
                // password è in corso, evitando doppi tap sul flusso sensibile.
                onPressed: _checkingBiometric ? null : _showSeedPhrase,
                icon: const Icon(Icons.backup),
                label: Text(loc.walletDetailExportSeed),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _showXpubDialog,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.key),
              label: Text(loc.walletDetailShowXpub),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showSignVerifyDialog,
              icon: const Icon(Icons.security),
              label: Text(loc.walletDetailSignVerify),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 7. Seed phrase rivelata
  Widget _buildSeedPhraseDisplay(
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final seedVisible = _seedPhrase != null && !_seedHidden;
    return Listener(
      // PERCHÉ: ogni interazione (tap) resetta il timer di auto-hide.
      onPointerDown: (_) => _resetSeedTimer(),
      child: GlassContainer(
        backgroundColor: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (seedVisible)
              SelectableText(
                _seedPhrase!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            if (!seedVisible && _seedPhrase != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      loc.walletDetailSeedHidden,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkingBiometric ? null : _revealSeedAgain,
                    child: Text(loc.walletDetailSeedShowAgain),
                  ),
                ],
              ),
            ],
            if (_showVerify && !_seedVerified) ...[
              const SizedBox(height: 12),
              // PERCHÉ: la verifica resta montata anche con seed nascosta
              // (timer) — i campi già compilati non si perdono.
              SeedPhraseVerifier(
                seed: _seedPhrase!,
                onVerified: _onSeedVerified,
                onChanged: _resetSeedTimer,
                random: widget.random,
              ),
            ],
            if (_seedVerified) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.walletDetailSeedVerified,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (seedVisible) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _seedTimer?.cancel();
                  setState(() => _seedHidden = true);
                },
                icon: const Icon(Icons.visibility_off),
                label: Text(loc.walletDetailHideSeed),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Banner di avviso quando la seed phrase non è stata salvata.
  /// PERCHÉ (UX-006/UX-004): visibile finché il backup non è confermato.
  /// Testo localizzato.
  Widget _buildBackupWarningBanner(
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.walletDetailBackupNotConfirmed,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.walletDetailBackupNotConfirmedDesc,
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Dialog di rinomina UTXO con ciclo di vita del controller corretto.
///
/// PERCHÉ: il TextEditingController deve essere smaltito SOLO quando il dialog
/// è stato smontato (dispose() dello State), non subito dopo `await
/// showDialog` — altrimenti il TextField ancora montato durante l'animazione
/// di chiusura scatena l'assert "_dependents.isEmpty".
class _RenameUtxoDialog extends StatefulWidget {
  const _RenameUtxoDialog({
    required this.loc,
    required this.initialName,
  });

  final AppLocalizations loc;
  final String initialName;

  @override
  State<_RenameUtxoDialog> createState() => _RenameUtxoDialogState();
}

class _RenameUtxoDialogState extends State<_RenameUtxoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.loc.walletDetailUtxoRenameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: widget.loc.walletDetailNameLabel,
          hintText: widget.loc.walletDetailNameHint,
        ),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.loc.passwordDialogCancel),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: Text(widget.loc.walletDetailSave),
        ),
      ],
    );
  }
}
