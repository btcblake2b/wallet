import 'package:flutter/foundation.dart';

import '../../core/services/app_lock_service.dart';
import '../../core/services/biometric_service.dart';
import '../../l10n/app_localizations.dart';

/// Attivazione del blocco app con verifica biometrica preventiva.
///
/// PERCHÉ (vincolo 2026-09-11): il blocco si attiva SOLO se la biometria è
/// presente e registrata; la verifica al momento dell'attivazione garantisce
/// che il metodo funzioni davvero (nessun lock-out al prossimo avvio).
class AppLockFlow {
  const AppLockFlow._();

  // FLOW: Attivazione Blocco App
  static Future<bool> enable({
    required BiometricService biometricService,
    required AppLockService appLockService,
    required AppLocalizations loc,
  }) async {
    // STEP: 1 — la biometria deve essere presente e registrata
    final enrolled = await biometricService.hasEnrolledBiometrics();
    if (!enrolled) {
      debugPrint('[LoopEngineer] appLock.enable: nessuna biometria registrata');
      return false;
    }

    // STEP: 2 — verifica biometrica (fallback PIN/password di sistema)
    var ok = false;
    try {
      ok = await biometricService.authenticateForUnlock(
        reason: loc.appLockReason,
      );
    } catch (e) {
      debugPrint('[LoopEngineer] appLock.enable auth error: $e');
    }
    debugPrint('[LoopEngineer] appLock.enable: auth=$ok');
    if (!ok) return false;

    // STEP: 3 — attivazione persistente
    await appLockService.setEnabled(value: true);
    return true;
  }
}
