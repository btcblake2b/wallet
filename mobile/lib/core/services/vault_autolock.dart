import 'dart:async';

/// Auto-lock del vault chiavi (usato dalla variante web).
///
/// PERCHÉ (hardening 2.4): su web le chiavi sbloccate vivono in RAM finché la
/// pagina non viene ricaricata: senza auto-lock una scheda dimenticata aperta
/// mantiene il vault utilizzabile a tempo indefinito. Questa classe è PURA
/// (nessun import Flutter/web) per essere testabile in isolamento: la UI la
/// pilota con [touch] a ogni interazione del puntatore, con [handleVisibility]
/// sugli eventi di lifecycle, e riceve [onLock] quando il timeout scade.
class VaultAutoLock {
  VaultAutoLock({
    required void Function() onLock,
    this.inactivityTimeout = const Duration(minutes: 10),
  }) : _onLock = onLock;

  /// Callback invocata UNA volta quando il vault deve essere bloccato.
  final void Function() _onLock;

  /// Tempo di inattività oltre il quale il vault si blocca.
  ///
  /// PERCHÉ 10 minuti: abbastanza per compilare un invio senza interruzioni,
  /// ma comunque un limite FINITO alla permanenza delle chiavi in memoria
  /// (prima: illimitata fino al reload).
  final Duration inactivityTimeout;

  Timer? _timer;
  bool _fired = false;

  /// True se il countdown è attivo (vault armato).
  bool get isArmed => _timer != null && _timer!.isActive;

  /// Arma il countdown (idempotente: se già attivo non fa nulla).
  void start() {
    if (isArmed) return;
    _arm();
  }

  /// Segnale di attività utente: riavvia (o riarma) il countdown.
  void touch() => _arm();

  /// Evento di visibilità della pagina/app.
  ///
  /// PERCHÉ: quando la pagina è nascosta il vault si blocca SUBITO — protegge
  /// da schede dimenticate in background e dall'anteprima multitasking; al
  /// ritorno il countdown riparte da zero.
  void handleVisibility({required bool visible}) {
    if (visible) {
      _arm();
    } else {
      _fire();
    }
  }

  /// Ferma il countdown senza bloccare (usato in dispose).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _arm() {
    _timer?.cancel();
    _fired = false;
    _timer = Timer(inactivityTimeout, _fire);
  }

  void _fire() {
    // PERCHÉ: guardia di idempotenza — un blocco duplicato è inutile e
    // produrrebbe notifiche ripetute; si riarma solo con una nuova attività.
    if (_fired) return;
    _fired = true;
    _timer?.cancel();
    _timer = null;
    _onLock();
  }
}
