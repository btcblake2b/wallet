import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/app_lock_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../l10n/app_localizations.dart';
import 'app_lock_screen.dart';

/// Gate globale del blocco app: quando attivo copre TUTTA l'app (qualsiasi
/// route) senza rimuovere il child → lo stato di navigazione resta invariato.
///
/// PERCHÉ: montato nel `builder` di MaterialApp.router, è sopra il Navigator
/// e copre anche dialog/route push. Il blocco scatta su lifecycle
/// (paused/hidden/detached) e alla partenza (isLocked già true da init()).
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.service,
    required this.biometricService,
    required this.child,
  });

  final AppLockService service;
  final BiometricService biometricService;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  /// Guardia anti-ri-lock: durante il prompt di sistema l'activity può passare
  /// in `paused` (PIN/keyguard) — senza guardia il gate si ri-bloccasse da solo
  /// mentre l'utente sta sbloccando.
  bool _authenticating = false;

  /// True quando la protezione del telefono è sparita (fail-safe da confermare).
  bool _deviceAuthMissing = false;

  /// Un solo tentativo automatico per ogni blocco (poi si usa il bottone).
  bool _autoAttempted = false;

  /// True quando l'app è in primo piano (auto-prompt solo da visibile).
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.addListener(_onServiceChanged);
    // PERCHÉ: cold start già bloccato → tenta subito la biometria.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_maybeAutoUnlock()),
    );
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    if (widget.service.isLocked) {
      _autoAttempted = false;
      _deviceAuthMissing = false;
    }
    setState(() {});
    if (widget.service.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_maybeAutoUnlock()),
      );
    }
  }

  Future<void> _maybeAutoUnlock() async {
    if (!mounted || !_resumed) return;
    if (!widget.service.isLocked || _autoAttempted || _authenticating) return;
    if (_deviceAuthMissing) return; // fail-safe: attende conferma utente
    _autoAttempted = true;
    await _tryUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _resumed = state == AppLifecycleState.resumed;
    // PERCHÉ: `inactive` (dialoghi/tendina di sistema) NON blocca — troppo
    // aggressivo a uso normale. Blocco solo su background reale, e MAI
    // durante un'autenticazione in corso.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_authenticating) return;
      widget.service.lock();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_maybeAutoUnlock());
    }
  }

  @override
  Future<bool> didPopRoute() async {
    // PERCHÉ: con il blocco attivo il tasto back di sistema non deve
    // navigare/chiudere l'app sotto l'overlay (intercettato a livello binding:
    // l'overlay vive sopra il Navigator, fuori dalle route).
    return widget.service.isLocked;
  }

  // FLOW: Sblocco App
  Future<void> _tryUnlock() async {
    if (_authenticating || !widget.service.isLocked) return;
    _authenticating = true;
    if (mounted) setState(() {});

    final loc = AppLocalizations.of(context);
    var ok = false;
    try {
      // STEP: 1 — autenticazione (biometria; fallback PIN/password di sistema)
      ok = await widget.biometricService.authenticateForUnlock(
        reason: loc.appLockReason,
      );
    } catch (e) {
      // PERCHÉ: PlatformException (es. credenziali rimosse) → niente crash;
      // il fail-safe sotto gestisce il caso.
      debugPrint('[LoopEngineer] appLock.unlock error: $e');
    } finally {
      _authenticating = false;
    }

    if (!mounted) return;

    if (ok) {
      // STEP: 2 — sblocco
      setState(() => _deviceAuthMissing = false);
      widget.service.unlock();
      return;
    }

    // STEP: 2b — fail-safe: protezione telefono rimossa (né biometria né PIN)
    // → l'app NON deve restare chiusa fuori: avviso + disattivazione.
    final canStill = await widget.biometricService.canAuthenticate();
    if (!mounted) return;
    if (!canStill) {
      debugPrint(
        '[LoopEngineer] appLock: device auth non disponibile → fail-safe',
      );
      setState(() => _deviceAuthMissing = true);
    } else {
      setState(() {});
    }
  }

  /// Conferma del fail-safe: disattiva il blocco e sblocca.
  void _confirmFailSafe() {
    unawaited(widget.service.setEnabled(value: false));
    widget.service.unlock();
    if (mounted) setState(() => _deviceAuthMissing = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Stack(
      children: [
        widget.child,
        if (widget.service.isLocked)
          Positioned.fill(
            child: AppLockScreen(
              busy: _authenticating,
              notice: _deviceAuthMissing
                  ? loc.appLockNoticeDeviceAuthRemoved
                  : null,
              onUnlock: _tryUnlock,
              onNoticeContinue: _confirmFailSafe,
            ),
          ),
      ],
    );
  }
}
