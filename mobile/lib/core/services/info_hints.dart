import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stato di processo del toggle "pallini info" (Impostazioni → Interfaccia).
///
/// PERCHÉ: i pallini sono sparsi in decine di schermate costruite con
/// costruttori const senza contesto condiviso. Un registro di processo — stesso
/// criterio di [ExplorerMirrors] — è l'unico punto di verità raggiungibile da
/// ogni [InfoDot] senza toccare le firme delle schermate.
class InfoHints extends ChangeNotifier {
  InfoHints({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Istanza di processo. I test la sostituiscono con uno storage mockato.
  static InfoHints instance = InfoHints();

  final FlutterSecureStorage _storage;

  static const String _key = 'info_hints_enabled';

  bool _enabled = true;

  /// True = i pallini "info" sono visibili in tutta l'app.
  bool get enabled => _enabled;

  /// Legge la preferenza persistita.
  /// PERCHÉ fail-open: uno storage illeggibile non deve nascondere gli aiuti
  /// all'utente (si resta sul default ON).
  Future<void> init() async {
    try {
      final stored = await _storage.read(key: _key);
      _enabled = stored != 'false';
    } catch (_) {
      _enabled = true;
    }
    debugPrint('[LoopEngineer] InfoHints.init: enabled=$_enabled');
    notifyListeners();
  }

  /// Mostra/nasconde i pallini e persiste la scelta (best-effort).
  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    try {
      await _storage.write(key: _key, value: value ? 'true' : 'false');
    } catch (e) {
      // PERCHÉ: la preferenza resta valida per la sessione anche se la
      // persistenza fallisce (stesso criterio di ThemeProvider).
      debugPrint('[LoopEngineer] InfoHints.setEnabled persist error: $e');
    }
    debugPrint('[LoopEngineer] InfoHints.setEnabled: $value');
    notifyListeners();
  }

  /// Ripristina l'istanza di default (solo test: nessuna persistenza reale).
  @visibleForTesting
  static void resetForTest() {
    instance = InfoHints();
  }
}
