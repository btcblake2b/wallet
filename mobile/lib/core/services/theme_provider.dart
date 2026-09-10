import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestisce il tema (dark/light) con persistenza.
///
/// // PERCHÉ (S5): pattern ChangeNotifier come LocaleProvider, con
/// persistenza su FlutterSecureStorage (funziona su nativo e web).
/// Il tema scelto resta attivo tra i riavvii.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Legge la preferenza persistita (default: dark).
  Future<void> init() async {
    try {
      final stored = await _storage.read(key: _key);
      _mode = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {
      // // PERCHÉ: storage non disponibile → default dark, mai bloccare.
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    try {
      await _storage.write(
        key: _key,
        value: mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggle() async {
    await setThemeMode(
      _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
