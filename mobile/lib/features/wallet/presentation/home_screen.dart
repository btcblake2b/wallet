import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/wallet_record.dart';
import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/wallet_snapshot.dart';
import '../../../core/services/balance_cache.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/services/locale_provider.dart';
import '../../../core/services/theme_provider.dart';
import '../../../core/services/vault_autolock.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/lightning/lightning_connection_store.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../donate/presentation/donate_screen.dart';
import '../../lightning/presentation/lightning_view.dart';
import '../../settings/presentation/settings_screen.dart';
import 'wallet_detail_screen.dart';
import 'import_wallet_screen.dart';
import 'backup_seed_screen.dart';
import 'api_error_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/connectivity.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/glass_container.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../l10n/app_localizations.dart';
import '../../lock/app_lock_flow.dart';

/// Contesto selezionato nella home: wallet on-chain o Lightning.
enum WalletLayer { onchain, lightning }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.walletRepository,
    required this.biometricService,
    required this.bitcoinService,
    required this.cryptoService,
    required this.deviceService,
    required this.localeProvider,
    required this.appLockService,
    this.themeProvider,
    this.lightningService,
    this.lightningConnectionStore,
  });

  final WalletRepository walletRepository;
  final BiometricService biometricService;
  final BitcoinService bitcoinService;
  final CryptoService cryptoService;
  final DeviceService deviceService;
  final LocaleProvider localeProvider;

  /// Blocco app (biometria/PIN): proposta al primo avvio + gate globale.
  final AppLockService appLockService;

  /// Opzionale (S5): se presente abilita il toggle tema nelle Impostazioni.
  final ThemeProvider? themeProvider;

  /// Client Lightning (nodo remoto via NWC/NCC). Se null il selettore
  /// On-chain/Lightning non viene mostrato (feature spenta / test legacy).
  final LightningService? lightningService;
  final LightningConnectionStore? lightningConnectionStore;

  /// // PERCHÉ (S6): storage del disclaimer sovrascrivibile nei test.
  /// Lo State è privato ma nella stessa libreria → accesso al membro statico.
  @visibleForTesting
  static set secureStorageForTest(FlutterSecureStorage storage) {
    _HomeScreenState._secureStorage = storage;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<List<WalletRecord>> _walletsFuture;

  /// Auto-lock del vault web (hardening 2.4): attivo solo su web, null altrove.
  VaultAutoLock? _vaultAutoLock;

  bool _creating = false;
  final Map<String, double> _balances = {};
  bool _loadingBalances = false;

  /// Codice del primo errore di caricamento saldi (per mostrare il motivo nel
  /// riepilogo: rate limit / servizio giù / rete). Null = nessun errore.
  String? _loadErrorCode;

  /// Ultima lista wallet risolta: il listener della cache condivisa la usa per
  /// riallineare i saldi senza rifare il fetch di tutti.
  List<WalletRecord>? _lastWallets;
  bool _isFabOpen = false;

  // ── Modalità selezione multipla (P1 #7) ──
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _deleting = false;

  /// Disclaimer legale accettato (persistente in FlutterSecureStorage).
  bool _disclaimerAccepted = false;
  static FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _disclaimerKey = 'disclaimer_accepted';

  /// Layer selezionato nella home: On-chain (wallet blake2b) o Lightning.
  WalletLayer _layer = WalletLayer.onchain;

  @override
  void initState() {
    super.initState();
    _loadDisclaimerAccepted();
    // PERCHÉ: proposta UNA TANTUM del blocco app (solo con biometria
    // registrata e al primo avvio non ancora deciso).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptAppLock());
    // PERCHÉ: nessun refresh automatico periodico — politica "all'avvio e poi
    // basta": si aggiorna su azioni utente (pull-to-refresh, invio, import) o
    // quando la cache condivisa cambia (il Detail notifica dopo "Aggiorna").
    BalanceCache.addListener(_onCacheChanged);

    // PERCHÉ: nessun wallet pendingTransfer nel fork blake2b → niente polling.
    if (!kIsWeb) {
      // Native: i dati locali sono protetti dal keyring OS → caricamento diretto.
      _loadData();
    } else {
      // Web (audit F1): il vault chiavi è protetto da password. I wallet
      // vengono caricati SOLO dopo l'autenticazione.
      WidgetsBinding.instance.addPostFrameCallback((_) => _initWebVault());
      // PERCHÉ (hardening 2.4): auto-lock del vault — le chiavi vengono rimosse
      // dalla memoria dopo inattività o quando la pagina è nascosta (prima
      // restavano in RAM fino al reload della scheda).
      WidgetsBinding.instance.addObserver(this);
      GestureBinding.instance.pointerRouter
          .addGlobalRoute(_onGlobalPointerEvent);
      _vaultAutoLock = VaultAutoLock(onLock: _onVaultAutoLock)..start();
    }
  }

  /// Web (audit F1): gate di avvio — sblocca (o crea) la password e solo poi
  /// carica i wallet. Senza password il vault chiavi NON è leggibile.
  Future<void> _initWebVault() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);

    // PERCHÉ (audit F1): il vault si considera pronto SOLO se la password è
    // stata creata/verificata e la protezione attivata. Se l'utente annulla,
    // la chiave AES resterebbe in chiaro in localStorage: NON si caricano i
    // wallet (lista vuota, vault bloccato) invece di procedere.
    var vaultReady = false;

    final protected = await widget.walletRepository.isWebKeyProtected();
    if (!mounted) return;

    if (protected) {
      // Vault già protetto → chiedi la password per sbloccarlo.
      final entered = await PasswordDialog.showEnterPasswordDialog(
        context,
        reason: loc.passwordDialogEnterTitle,
      );
      if (!mounted) return;
      if (entered == null || entered.isEmpty) {
        _loadEmpty(); // utente ha annullato → lista vuota (vault bloccato)
        return;
      }
      final ok = await widget.biometricService.verifyPassword(entered);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.passwordDialogWrong)),
        );
        _loadEmpty();
        return;
      }
      await widget.walletRepository.unlockWebStorage(entered);
      vaultReady = true;
    } else {
      // Vault non ancora protetto.
      final has = await widget.biometricService.canAuthenticate();
      if (!mounted) return;

      if (!has) {
        // Primo avvio: crea la password e proteggi subito il vault (F1).
        final pw = await PasswordDialog.showCreatePasswordDialog(context);
        if (!mounted) return;
        if (pw != null) {
          await widget.biometricService.setPassword(pw);
          await widget.walletRepository.enablePasswordProtection(pw);
          vaultReady = true;
        }
      } else {
        // Legacy: la password esiste ma il vault non è protetto. Chiedila una
        // volta per abilitare il key-wrapping e sbloccare i dati.
        final entered = await PasswordDialog.showEnterPasswordDialog(
          context,
          reason: loc.passwordDialogEnterTitle,
        );
        if (!mounted) return;
        if (entered != null &&
            entered.isNotEmpty &&
            await widget.biometricService.verifyPassword(entered)) {
          await widget.walletRepository.enablePasswordProtection(entered);
          await widget.walletRepository.unlockWebStorage(entered);
          vaultReady = true;
        }
      }
    }

    if (!mounted) return;
    if (vaultReady) {
      // PERCHÉ (hardening 2.4): vault sbloccato → riarma il countdown.
      _vaultAutoLock?.start();
      _loadData();
    } else {
      _loadEmpty();
    }
  }

  /// Mostra una lista wallet vuota (usata quando il vault web è bloccato).
  void _loadEmpty() {
    setState(() {
      _walletsFuture = Future.value(<WalletRecord>[]);
    });
  }

  /// Hardening 2.4: QUALSIASI interazione (anche su schermate push sopra la
  /// home) riarma il countdown dell'auto-lock: scatta solo dopo vera inattività.
  void _onGlobalPointerEvent(PointerEvent event) => _vaultAutoLock?.touch();

  /// Blocca il vault web rimuovendo le chiavi dalla memoria (hardening 2.4).
  /// Idempotente: se le chiavi sono già state rimosse non cambia nulla.
  void _onVaultAutoLock() {
    if (!kIsWeb) return;
    unawaited(widget.walletRepository.lockWebStorage());
    widget.biometricService.lockCache();
    if (!mounted) return;
    // PERCHÉ: notifica non invasiva — le azioni sensibili (invio, backup,
    // dettaglio) chiederanno di nuovo la password perché le chiavi non sono
    // più in RAM; la lista wallet (dati pubblici) resta visibile.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).homeVaultLocked)),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final autoLock = _vaultAutoLock;
    if (autoLock == null) return;
    // PERCHÉ (hardening 2.4): quando la pagina/app diventa nascosta il vault si
    // blocca SUBITO (protegge da multitasking e schede dimenticate); al ritorno
    // il countdown riparte. `inactive` (es. finestra che perde focus) NON
    // blocca: sarebbe troppo aggressivo durante l'uso normale.
    if (state == AppLifecycleState.resumed) {
      autoLock.handleVisibility(visible: true);
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      autoLock.handleVisibility(visible: false);
    }
  }

  @override
  void dispose() {
    // PERCHÉ: rimuovi il listener della cache condivisa — evita setState dopo
    // il dispose quando il Detail notifica un aggiornamento dello snapshot.
    BalanceCache.removeListener(_onCacheChanged);
    // PERCHÉ (hardening 2.4): ferma l'auto-lock e stacca observer/route globale
    // — senza questo il timer sopravvivrebbe alla schermata.
    _vaultAutoLock?.stop();
    if (_vaultAutoLock != null) {
      WidgetsBinding.instance.removeObserver(this);
      GestureBinding.instance.pointerRouter
          .removeGlobalRoute(_onGlobalPointerEvent);
    }
    super.dispose();
  }

  /// Controlla tutti i wallet con stato pendingTransfer: verifica lo stato
  /// sul server e, se assente, tenta la registrazione automatica.
  Future<void> _loadDisclaimerAccepted() async {
    final accepted = await _secureStorage.read(key: _disclaimerKey);
    if (mounted) {
      setState(() => _disclaimerAccepted = accepted == 'true');
    }
  }

  Future<void> _acceptDisclaimer() async {
    await _secureStorage.write(key: _disclaimerKey, value: 'true');
    if (mounted) setState(() => _disclaimerAccepted = true);
  }

  /// Mostra un dialog che informa l'utente che deve accettare il disclaimer.
  void _showDisclaimerRequired(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.legalInfoTitle),
        content: Text(loc.homeSecurityWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.homeOk),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData({bool force = false}) {
    setState(() {
      _walletsFuture = widget.walletRepository.loadWallets();
    });
    return _walletsFuture.then((wallets) {
      // PERCHÉ: la cache evita rifetch a ogni navigazione; force solo su
      // apertura/pull/invio/import.
      _lastWallets = wallets;
      _fetchBalances(wallets, force: force);
      // PERCHÉ: wallet 100% locale — nessun sync con backend.
    });
  }

  /// Refresh esplicito (pull-to-refresh): forza il fetch di tutti i wallet.
  Future<void> _reload() async {
    await _loadData(force: true);
  }

  /// Riallinea i saldi della lista quando la cache condivisa cambia (es. il
  /// Detail ha aggiornato lo snapshot dopo un invio o un "Aggiorna").
  ///
  /// PERCHÉ: NESSUNA richiesta di rete — legge solo gli snapshot presenti e
  /// aggiorna il saldo dei wallet coinvolti (single source of truth in cache).
  void _onCacheChanged() {
    if (!mounted || _loadingBalances) return;
    final wallets = _lastWallets;
    if (wallets == null) return;
    setState(() {
      for (final w in wallets) {
        if (!w.displayInHomeScreen) continue;
        final snap = BalanceCache.snapshotOf(w.publicAddress);
        if (snap != null) {
          _balances[w.publicAddress] = snap.balanceSats.toDouble();
        }
      }
    });
  }

  /// Carica (o riusa in cache) lo snapshot di un singolo wallet, branchando
  /// sul tipo: watch-only → fetch da xpub (nessun seed); hot → decrypt seed →
  /// fetchWalletSnapshot. PERCHÉ (P1): un watch-only non deve MAI passare da
  /// decryptSeed (niente chiavi private in memoria).
  Future<WalletSnapshot?> _loadSnapshotForWallet(
    WalletRecord w,
    BitcoinService bitcoinService,
  ) async {
    if (w.kind == WalletKind.watchOnly) {
      final xpub = w.accountXpub;
      if (xpub == null || xpub.isEmpty) return null;
      return BalanceCache.getOrFetch(
        w.publicAddress,
        () => bitcoinService.fetchWatchOnlySnapshot(
          accountXpub: xpub,
          scriptType: WalletScriptType.fromDerivationPath(w.derivationPath),
          includeHistory: false,
        ),
      );
    }
    final seed = await widget.walletRepository.decryptSeed(w);
    return BalanceCache.getOrFetch(
      w.publicAddress,
      () => bitcoinService.fetchWalletSnapshot(
        seed,
        derivationPath: w.derivationPath,
        // PERCHÉ: all'avvio serve SOLO il saldo (scan) — niente storico
        // (pesante): si carica lazy al primo ingresso nel Detail.
        includeHistory: false,
      ),
    );
  }

  Future<void> _fetchBalances(
    List<WalletRecord> wallets, {
    bool force = false,
  }) async {
    // PERCHÉ: wallet normale senza stati locked/unlocked — sono attivi
    // tutti i wallet visibili nella home.
    final activeWallets = wallets.where((w) => w.displayInHomeScreen).toList();
    if (activeWallets.isEmpty) {
      if (mounted) {
        setState(() {
          _balances.clear();
          _loadingBalances = false;
        });
      }
      return;
    }

    // PERCHÉ: throttle — evita fetch concorrenti (es. pull + ritorno insieme).
    if (_loadingBalances) return;
    // PERCHÉ: reset del motivo d'errore a ogni nuovo caricamento (verrà
    // ricatturato sotto se un wallet fallisce).
    _loadErrorCode = null;
    if (mounted) setState(() => _loadingBalances = true);

    final bitcoinService = widget.bitcoinService;
    try {
      // PERCHÉ: la cache condivisa è la fonte primaria — se lo snapshot è
      // fresco (TTL) e non è richiesto un refresh forzato, nessuna richiesta
      // di rete (es. ritorno dal detail). Altrimenti si fetcha tramite
      // getOrFetch, che DEDUPLICA con il Detail (un solo scan di rete se
      // entrambi lo chiedono insieme, es. avvio app + apertura detail).
      final fresh = <String, WalletSnapshot>{};
      final toFetch = <WalletRecord>[];
      for (final w in activeWallets) {
        final snap = force ? null : BalanceCache.freshSnapshot(w.publicAddress);
        if (snap != null) {
          fresh[w.publicAddress] = snap;
        } else {
          toFetch.add(w);
        }
      }

      if (toFetch.isNotEmpty) {
        final results = await Future.wait(
          toFetch.map((w) async {
            try {
              // PERCHÉ (P1 watch-only): branch sul tipo dentro l'helper — i
              // watch-only non hanno seed da decriptare.
              return await _loadSnapshotForWallet(w, bitcoinService);
            } catch (e) {
              // PERCHÉ: fallback non bloccante — un wallet che fallisce non
              // deve bloccare il caricamento degli altri. Conserviamo il
              // codice del PRIMO errore per mostrare il motivo nel riepilogo.
              _loadErrorCode ??= apiErrorCode(e);
              return null;
            }
          }),
        );
        for (var i = 0; i < toFetch.length; i++) {
          final snap = results[i];
          if (snap != null) fresh[toFetch[i].publicAddress] = snap;
        }
      }

      if (!mounted) return;
      setState(() {
        _balances.clear();
        // PERCHÉ (F4): `_balances` contiene SOLO snapshot caricati con
        // successo (anche con saldo 0 REALE). L'assenza di una chiave =
        // fetch fallito → la UI mostra "non disponibile", mai 0 confermato.
        for (final entry in fresh.entries) {
          _balances[entry.key] = entry.value.balanceSats.toDouble();
        }
        _loadingBalances = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingBalances = false);
    }
  }

  Future<bool> _hasInternet() async => hasInternet();

  /// Dialog per scegliere il tipo di wallet da creare (default Native BIP84).
  /// PERCHÉ (multi-tipo): permette di creare anche BIP49/BIP44 (per test e
  /// per utenti che vogliono quel tipo); annulla (null) = nessuna creazione.
  Future<WalletScriptType?> _askCreateType() async {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return showDialog<WalletScriptType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.createWalletTypeTitle),
        children: [
          for (final type in const <WalletScriptType>[
            WalletScriptType.p2wpkh,
            WalletScriptType.p2shP2wpkh,
            WalletScriptType.p2pkh,
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(type),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _walletTypeLabel(type, loc),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    loc.importScriptTypeHint(type.addressPrefix),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Label localizzata del tipo di wallet.
  String _walletTypeLabel(WalletScriptType type, AppLocalizations loc) {
    switch (type) {
      case WalletScriptType.p2wpkh:
        return loc.importScriptTypeNativeSegwit;
      case WalletScriptType.p2shP2wpkh:
        return loc.importScriptTypeNestedSegwit;
      case WalletScriptType.p2pkh:
        return loc.importScriptTypeLegacy;
    }
  }

  Future<void> _createWallet() async {
    final loc = AppLocalizations.of(context);
    if (!_disclaimerAccepted) {
      _showDisclaimerRequired(loc);
      return;
    }
    if (!await _hasInternet()) {
      if (!mounted) return;
      // PERCHÉ (i18n): il dialog usava stringhe hardcoded — ora localizzato.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.homeNoConnectionTitle),
          content: Text(loc.homeNoConnectionCreate),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.homeOk),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      // PERCHÉ (multi-tipo): l'utente sceglie prima il tipo (default BIP84).
      final type = await _askCreateType();
      if (type == null || !mounted) return;

      // FLOW: Creazione Wallet con Backup proattivo
      // STEP: 1 — creazione seed cifrata + persistenza locale
      final wallet = await widget.walletRepository.createWallet(
        derivationPath: type.accountPath(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeWalletCreated)),
      );
      // // PERCHÉ (S3): backup proattivo subito dopo la creazione — la seed
      // va salvata ORA, non "a richiesta". Se l'utente skippa, il banner di
      // warning resta visibile nel dettaglio wallet.
      // STEP: 2 — wizard backup seed (verifica 3 parole)
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => BackupSeedScreen(
            wallet: wallet,
            walletRepository: widget.walletRepository,
            biometricService: widget.biometricService,
          ),
        ),
      );
      // PERCHÉ: nuovo wallet → lista locale; saldo dalla cache (0 per il nuovo).
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeWalletCreateError(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Future<void> _openWalletDetail(WalletRecord wallet) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletDetailScreen(
          wallet: wallet,
          walletRepository: widget.walletRepository,
          biometricService: widget.biometricService,
          bitcoinService: widget.bitcoinService,
          cryptoService: widget.cryptoService,
          deviceService: widget.deviceService,
        ),
      ),
    );
    // PERCHÉ: il detail aggiorna la cache dopo un invio → qui basta la cache
    // (nessun fetch al semplice ritorno).
    await _loadData();
  }

  Future<void> _importWalletFlow() async {
    if (!_disclaimerAccepted) {
      _showDisclaimerRequired(AppLocalizations.of(context));
      return;
    }
    final imported = await Navigator.of(context).push<WalletRecord>(
      MaterialPageRoute(
        builder: (_) => ImportWalletScreen(
          walletRepository: widget.walletRepository,
        ),
      ),
    );

    if (imported != null && mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeWalletImported)),
      );
      // FLOW: Import Wallet con Backup proattivo
      // STEP: 1 — import seed e derivazione
      if (imported.kind != WalletKind.watchOnly) {
        // STEP: 2 — wizard backup seed (verifica 3 parole) — SOLO wallet con
        // seed. PERCHÉ (P1): un watch-only non ha seed da salvare.
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BackupSeedScreen(
              wallet: imported,
              walletRepository: widget.walletRepository,
              biometricService: widget.biometricService,
            ),
          ),
        );
      }
      // PERCHÉ: import raro → fetch del saldo del nuovo wallet (mostra subito
      // i fondi reali, non 0).
      await _loadData(force: true);
    }
  }

  /// Apre la pagina Impostazioni (sostituisce il vecchio menu overflow).
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          themeProvider: widget.themeProvider,
          localeProvider: widget.localeProvider,
          appLockService: widget.appLockService,
          biometricService: widget.biometricService,
          walletRepository: widget.walletRepository,
        ),
      ),
    );
  }

  /// Proposta UNA TANTUM del blocco app (vincolo: SOLO con biometria
  /// registrata; se assente non si propone e non si marca il flag, così la
  /// proposta riappare se in futuro viene registrata).
  Future<void> _maybePromptAppLock() async {
    if (kIsWeb) return;
    final service = widget.appLockService;
    if (service.isEnabled || service.isPromptSeen) return;
    if (!await widget.biometricService.hasEnrolledBiometrics()) return;
    if (!mounted) return;
    await service.markPromptSeen();
    if (!mounted) return;

    final loc = AppLocalizations.of(context);
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.appLockPromptTitle),
        content: Text(loc.appLockPromptMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.appLockPromptLater),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.appLockPromptEnable),
          ),
        ],
      ),
    );
    if (enable != true || !mounted) return;

    final ok = await AppLockFlow.enable(
      biometricService: widget.biometricService,
      appLockService: widget.appLockService,
      loc: loc,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? loc.settingsAppLockEnabled : loc.settingsAppLockEnableFailed,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Selezione multipla ed eliminazione (P1 #7)
  // ──────────────────────────────────────────────────────────────

  /// Attiva la modalità selezione con long-press su una card.
  void _enterSelectionMode(String walletId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectionMode = true;
      _selectedIds.add(walletId);
      _isFabOpen = false;
    });
  }

  /// Toggle selezione di un wallet (tap in modalità selezione).
  void _toggleSelection(String walletId) {
    setState(() {
      if (_selectedIds.contains(walletId)) {
        _selectedIds.remove(walletId);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(walletId);
      }
    });
  }

  /// Esce dalla modalità selezione.
  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  /// Elimina tutti i wallet selezionati.
  Future<void> _deleteSelectedWallets() async {
    final loc = AppLocalizations.of(context);
    final count = _selectedIds.length;

    // PERCHÉ (P3.3/UX-001): il multi-delete non aveva il gate di backup seed
    // che esiste nel delete singolo. Se tra i selezionati c'è un wallet
    // sbloccato con backup NON confermato, avvisa prima della conferma —
    // altrimenti la seed può andare persa per sempre senza preavviso.
    final wallets = await _walletsFuture;
    // PERCHÉ: guardia mounted dopo l'await — il context viene usato nei
    // dialog successivi (use_build_context_synchronously).
    if (!mounted) return;
    final hasUnbacked = wallets.any(
      (w) =>
          _selectedIds.contains(w.walletId) &&
          // PERCHÉ (P1): i watch-only non hanno seed da perdere → esclusi
          // dal gate di backup.
          w.kind != WalletKind.watchOnly &&
          !w.seedBackupConfirmed,
    );
    if (hasUnbacked) {
      final backupOk = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.walletDetailBackupNotConfirmed),
          content: Text(loc.walletDetailDeleteWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.homeOk),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(loc.walletDetailDeleteConfirm),
            ),
          ],
        ),
      );
      if (backupOk != true || !mounted) return;
    }

    // Conferma
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.homeDeleteSelected),
        content: Text(loc.homeDeleteConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.homeOk),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.walletDetailDeleteTitle),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    final idsToDelete = Set<String>.from(_selectedIds);
    int successCount = 0;
    String? lastError;

    for (final walletId in idsToDelete) {
      try {
        await widget.walletRepository.deleteWallet(walletId);
        successCount++;
      } catch (e) {
        lastError = e.toString();
      }
      // Aggiorna UI per mostrare progresso
      if (mounted) {
        setState(() => _selectedIds.remove(walletId));
      }
    }

    if (mounted) {
      setState(() {
        _deleting = false;
        _selectionMode = false;
        _selectedIds.clear();
      });

      final remaining = idsToDelete.length - successCount;
      if (remaining == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.homeDeleted(successCount)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.homeDeleteMultiSummary(
                successCount,
                remaining,
                lastError ?? '',
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // PERCHÉ: eliminazione → lista locale; saldo dalla cache (i rimanenti).
      await _loadData();
    }
  }

  /// Selettore di layer (On-chain ↔ Lightning), sotto l'AppBar.
  ///
  /// // PERCHÉ: il contesto cambia completamente (rete, saldo, azioni) —
  /// il segmento rende esplicito dove ci si trova; accent viola per Lightning.
  Widget _buildLayerSelector(BuildContext context, AppLocalizations loc) {
    if (widget.lightningService == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<WalletLayer>(
        segments: [
          ButtonSegment(
            value: WalletLayer.onchain,
            icon: const Icon(Icons.currency_bitcoin, size: 18),
            label: Text(loc.walletLayerOnchain),
          ),
          ButtonSegment(
            value: WalletLayer.lightning,
            icon: const Icon(Icons.bolt, size: 18),
            label: Text(loc.walletLayerLightning),
          ),
        ],
        selected: {_layer},
        onSelectionChanged: (selection) {
          setState(() => _layer = selection.first);
        },
        expandedInsets: EdgeInsets.zero,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: _layer == WalletLayer.lightning
              ? AppTheme.lightningAccent.withValues(alpha: 0.25)
              : null,
          selectedForegroundColor:
              _layer == WalletLayer.lightning ? AppTheme.lightningAccent : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppBackground(
      // PERCHÉ: in modalità Lightning i glow virano sul viola dedicato.
      accent: _layer == WalletLayer.lightning ? AppTheme.lightningAccent : null,
      child: Scaffold(
        appBar: _selectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  '${_selectedIds.length} ${loc.homeSelected}',
                ),
                actions: [
                  IconButton(
                    icon: _deleting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleting || _selectedIds.isEmpty
                        ? null
                        : _deleteSelectedWallets,
                    tooltip: loc.walletDetailDeleteTitle,
                  ),
                ],
              )
            : AppBar(
                title: Text(loc.homeScreenTitle),
                // PERCHÉ (UX): due sole icone (Impostazioni + Donazioni) — le
                // voci secondarie (lingua, tema, legali, explorer, about) sono
                // confluite nella pagina Impostazioni; il menu "⋮" era un
                // nascondiglio poco scopribile.
                actions: [
                  IconButton(
                    tooltip: loc.settingsTitle,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _openSettings,
                  ),
                  IconButton(
                    tooltip: loc.donateButton,
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () => DonateScreen.show(context),
                  ),
                ],
              ),
        floatingActionButton: null,
        body: Column(
          children: [
            _buildLayerSelector(context, loc),
            Expanded(
              child: _layer == WalletLayer.lightning
                  ? LightningView(
                      lightningService: widget.lightningService!,
                      connectionStore: widget.lightningConnectionStore!,
                    )
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _reload,
                          child: FutureBuilder<List<WalletRecord>>(
                            future: _walletsFuture,
                            builder: (context, snapshot) {
                              final wallets =
                                  snapshot.data ?? const <WalletRecord>[];

                              return ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                children: [
                                  if (!_disclaimerAccepted)
                                    GlassContainer(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer
                                          .withValues(alpha: 0.8),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.homeSecurityWarning,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onTertiaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _acceptDisclaimer(),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 16,
                                              ),
                                              label: Text(
                                                loc.homeDisclaimerAccept,
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!_disclaimerAccepted)
                                    const SizedBox(height: 16),
                                  if (!_selectionMode) ...[
                                    const SizedBox(height: 20),
                                    // ── Bilancio totale ──
                                    if (wallets
                                        .any((w) => w.displayInHomeScreen)) ...[
                                      _TotalBalanceCard(
                                        wallets: wallets,
                                        balances: _balances,
                                        isLoading: _loadingBalances,
                                        errorCode: _loadErrorCode,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    Text(
                                      loc.homeLocalWallets,
                                      style: textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      wallets.isEmpty)
                                    const Column(
                                      children: [
                                        GlassCardSkeleton(lines: 3),
                                        SizedBox(height: 12),
                                        GlassCardSkeleton(lines: 2),
                                      ],
                                    )
                                  else if (snapshot.hasError)
                                    GlassContainer(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        loc.homeErrorLoading(
                                          snapshot.error ?? '',
                                        ),
                                      ),
                                    )
                                  else if (wallets.isEmpty)
                                    EmptyStateWidget(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      title: loc.homeEmptyTitle,
                                      subtitle: loc.homeEmptySubtitle,
                                      actionLabel: loc.homeCreateWallet,
                                      onAction: _createWallet,
                                      secondaryLabel: loc.homeImportWallet,
                                      onSecondaryAction: _importWalletFlow,
                                    )
                                  else
                                    Column(
                                      children: wallets
                                          .map(
                                            (wallet) => _WalletCard(
                                              wallet: wallet,
                                              onTap: () {
                                                if (_selectionMode) {
                                                  _toggleSelection(
                                                    wallet.walletId,
                                                  );
                                                } else {
                                                  _openWalletDetail(wallet);
                                                }
                                              },
                                              onLongPress: () =>
                                                  _enterSelectionMode(
                                                wallet.walletId,
                                              ),
                                              isSelectionMode: _selectionMode,
                                              isSelected: _selectedIds
                                                  .contains(wallet.walletId),
                                              balance: _balances[
                                                  wallet.publicAddress],
                                              isLoading: _loadingBalances &&
                                                  wallet.displayInHomeScreen &&
                                                  !_balances.containsKey(
                                                    wallet.publicAddress,
                                                  ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  const SizedBox(height: 120),
                                ],
                              );
                            },
                          ),
                        ),
                        if (_isFabOpen)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFabOpen = false;
                              });
                            },
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        // ── Bottom action bar ──
                        if (!_selectionMode)
                          // PERCHÉ: Align (non-positioned) al posto di Positioned(bottom:0).
                          // Root cause (dal log reale): minimumSize con larghezza infinita sotto il
                          // FittedBox -> 'BoxConstraints forces an infinite width'; il 'Cannot hit test'
                          // del log era solo la cascata del box senza size.
                          // Layout invariato: bottomCenter + Row full-width (mainAxisSize.max) = barra in basso.
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (_isFabOpen) ...[
                                          FloatingActionButton.extended(
                                            heroTag: 'fab_import',
                                            onPressed: () {
                                              setState(
                                                () => _isFabOpen = false,
                                              );
                                              _importWalletFlow();
                                            },
                                            icon:
                                                const Icon(Icons.file_download),
                                            label: Text(loc.homeImportWallet),
                                          ),
                                          const SizedBox(height: 12),
                                          FloatingActionButton.extended(
                                            heroTag: 'fab_create',
                                            onPressed: _creating
                                                ? null
                                                : () {
                                                    setState(
                                                      () => _isFabOpen = false,
                                                    );
                                                    _createWallet();
                                                  },
                                            icon: _creating
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.add),
                                            label: Text(loc.homeCreateWallet),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        FloatingActionButton(
                                          heroTag: 'fab_main',
                                          onPressed: () {
                                            setState(
                                              () => _isFabOpen = !_isFabOpen,
                                            );
                                          },
                                          child: Icon(
                                            _isFabOpen
                                                ? Icons.close
                                                : Icons.menu,
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.onTap,
    this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
    this.balance,
    required this.isLoading,
  });

  final WalletRecord wallet;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final double? balance;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (wallet.name != null && wallet.name!.isNotEmpty)
        ? wallet.name!
        : wallet.publicAddress;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).homeWalletSemantics(
        balance != null
            ? '${(balance! / 100000000).toStringAsFixed(8)} BTC'
            : AppLocalizations.of(context).balanceUnavailable,
        name,
      ),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                // Checkbox in modalità selezione, icona stato altrimenti
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeColor: colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Nome + metadati
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // PERCHÉ (P1): badge di sola lettura per i wallet
                          // watch-only (nessuna chiave privata nel device).
                          if (wallet.kind == WalletKind.watchOnly) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context).watchOnlyBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                          if (wallet.displayInHomeScreen && !isSelectionMode)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: isLoading
                                  ? const SizedBox.square(
                                      dimension: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : balance != null
                                      ? Text(
                                          '${(balance! / 100000000).toStringAsFixed(8)} BTC',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // PERCHÉ (F4): fetch fallito →
                                            // stato esplicito, mai 0. Label
                                            // a larghezza limitata: niente
                                            // overflow su viewport stretti.
                                            Icon(
                                              Icons.cloud_off,
                                              size: 13,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 4),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 100,
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context)
                                                    .balanceUnavailable,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatter.format(wallet.createdAt.toLocal()),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // PERCHÉ (P1): per i watch-only niente icona di
                          // verifica backup — non esiste un seed da salvare.
                          if (wallet.kind != WalletKind.watchOnly)
                            Tooltip(
                              message: wallet.seedBackupConfirmed
                                  ? AppLocalizations.of(context)
                                      .homeBackupVerified
                                  : AppLocalizations.of(context)
                                      .homeBackupNotVerified,
                              child: Icon(
                                wallet.seedBackupConfirmed
                                    ? Icons.verified
                                    : Icons.warning_amber_rounded,
                                size: 17,
                                color: wallet.seedBackupConfirmed
                                    ? Colors.green
                                    : colorScheme.tertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.outline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.wallets,
    required this.balances,
    required this.isLoading,
    this.errorCode,
  });

  final List<WalletRecord> wallets;
  final Map<String, double> balances;
  final bool isLoading;

  /// Codice d'errore del caricamento (rate limit / servizio giù / rete…).
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double total = 0;
    var hasMissing = false;

    for (final w in wallets) {
      if (!w.displayInHomeScreen) continue;
      final balance = balances[w.publicAddress];
      // PERCHÉ (F4): un saldo ASSENTE non è 0 — è "non disponibile".
      // Decisione (totale con fallimenti parziali): se ANCHE UN SOLO wallet
      // visibile non ha un saldo caricato, mostriamo "—" invece della somma
      // parziale — una somma incompleta sarebbe un numero sbagliato
      // presentato come vero (principio LESSONS.md). Il saldo 0 REALE ha la
      // chiave presente con valore 0.0 e viene sommato normalmente.
      if (balance == null) {
        hasMissing = true;
        break;
      }
      total += balance;
    }
    // PERCHÉ: motivo del "—" (rate limit / servizio giù / rete) quando c'è
    // un errore di caricamento noto; altrimenti resta il messaggio generico.
    final missingReason = hasMissing && errorCode != null
        ? apiErrorReason(loc, errorCode!)
        : null;

    return GlassContainer(
      borderRadius: 16,
      borderColor: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                loc.homeBalanceTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (hasMissing)
            Column(
              children: [
                Text(
                  '—',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.balanceUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                if (missingReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    missingReason,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                Text(
                  '${(total / 100000000).toStringAsFixed(8)} BTC',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
