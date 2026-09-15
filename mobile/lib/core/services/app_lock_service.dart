import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stato e preferenze del blocco app (apertura con biometria/PIN del telefono).
///
/// PERCHÉ: il blocco è un gate UX sopra dati già protetti dal keyring OS
/// (la seed è cifrata a riposo): NON aggiunge crittografia, protegge
/// dall'accesso fisico a un telefono sbloccato.
/// Fail-open deliberato: un errore di storage non deve mai chiudere fuori
/// l'utente dal wallet.
class AppLockService extends ChangeNotifier {
  AppLockService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Istanza di test ISOLATA (in-memory, nessuna persistenza).
  @visibleForTesting
  AppLockService.test({bool enabled = false, bool promptSeen = true})
      : _storage = null {
    _enabled = enabled;
    _promptSeen = promptSeen;
  }

  static const String _enabledKey = 'app_lock_enabled';
  static const String _promptSeenKey = 'app_lock_prompt_seen';

  final FlutterSecureStorage? _storage;

  bool _enabled = false;
  bool _locked = false;
  bool _promptSeen = false;

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get isPromptSeen => _promptSeen;

  /// Legge le preferenze persistite. Da chiamare UNA volta prima di runApp.
  /// Al termine, se il blocco è attivo l'app risulta GIA bloccata (cold start).
  Future<void> init() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      final enabled = await storage.read(key: _enabledKey);
      final promptSeen = await storage.read(key: _promptSeenKey);
      _enabled = enabled == 'true';
      _promptSeen = promptSeen == 'true';
      _locked = _enabled;
      debugPrint(
        '[LoopEngineer] appLock.init: enabled=$_enabled, '
        'promptSeen=$_promptSeen',
      );
      notifyListeners();
    } catch (e) {
      // PERCHÉ: fail-open — l'errore di storage non deve bloccare fuori
      // l'utente (il gate è UX, non crittografico).
      _enabled = false;
      _locked = false;
      debugPrint('[LoopEngineer] appLock.init error (fail-open): $e');
    }
  }

  /// Persiste l'attivazione; su [value]=false sblocca anche (idempotente).
  Future<void> setEnabled({required bool value}) async {
    _enabled = value;
    if (!value) _locked = false;
    notifyListeners();
    debugPrint('[LoopEngineer] appLock.setEnabled: $value');
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.write(key: _enabledKey, value: value ? 'true' : 'false');
    } catch (e) {
      debugPrint('[LoopEngineer] appLock.setEnabled persist error: $e');
    }
  }

  /// Segna la proposta di primo avvio come mostrata (non si ripete).
  Future<void> markPromptSeen() async {
    _promptSeen = true;
    notifyListeners();
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.write(key: _promptSeenKey, value: 'true');
    } catch (e) {
      debugPrint('[LoopEngineer] appLock.markPromptSeen persist error: $e');
    }
  }

  /// Blocca l'app. No-op se il blocco è disattivato o già bloccata.
  void lock() {
    if (!_enabled || _locked) return;
    _locked = true;
    debugPrint('[LoopEngineer] appLock.lock');
    notifyListeners();
  }

  void unlock() {
    if (!_locked) return;
    _locked = false;
    debugPrint('[LoopEngineer] appLock.unlock');
    notifyListeners();
  }
}
