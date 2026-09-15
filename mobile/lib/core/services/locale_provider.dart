import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'locale_provider_stub.dart'
    if (dart.library.html) 'locale_provider_web.dart';

/// Manages the application locale with localStorage persistence.
///
/// Shared key `lang` with the landing page i18n.js script so the language
/// choice persists across landing page → PWA transitions.
///
/// Detection order:
/// 1. localStorage['lang'] (user choice)
/// 2. Browser/OS language
/// 3. 'en' (default fallback)
class LocaleProvider extends ChangeNotifier {
  /// [PERCHÉ iniettabile]: i test unitari devono poter simulare storage e
  /// lingua di sistema senza plugin nativi né dipendenza dal device.
  LocaleProvider({
    Future<String?> Function()? readStoredLanguage,
    Future<void> Function(String langTag)? persistLanguage,
    Future<void> Function()? clearStoredLanguage,
    Future<String?> Function()? detectSystemLanguage,
  })  : _readStoredLanguage = readStoredLanguage ?? readStoredLanguageImpl,
        _persistLanguage = persistLanguage ?? persistLanguageImpl,
        _clearStoredLanguage = clearStoredLanguage ?? clearStoredLanguageImpl,
        _detectSystemLanguage =
            detectSystemLanguage ?? detectSystemLanguageImpl;

  static const _defaultLocale = 'en';

  final Future<String?> Function() _readStoredLanguage;
  final Future<void> Function(String langTag) _persistLanguage;
  final Future<void> Function() _clearStoredLanguage;
  final Future<String?> Function() _detectSystemLanguage;

  /// All locales supported by the app (must match l10n.yaml and ARB files).
  /// Nota: `en` per prima — è il fallback per le lingue non supportate
  /// (stessa priorità in `l10n.yaml` → `preferred-supported-locales`).
  /// Gli ARB usano `zh` e `fr` (senza country code): Flutter risolve
  /// `zh-CN` → `zh` e `fr-CA` → `fr` automaticamente.
  static const supportedLocales = [
    'en',
    'it',
    'de',
    'fi',
    'es',
    'zh',
    'fr',
  ];

  Locale _locale = const Locale(_defaultLocale);
  bool _autoMode = true;

  /// True quando la lingua segue il sistema (nessuna scelta salvata).
  /// In questa modalità il selettore mostra “Automatica” come voce attiva.
  bool get isAutoMode => _autoMode;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  /// Initialize the locale from persistent storage or OS/browser preference.
  Future<void> init() async {
    _locale = await _resolveLocale();
    notifyListeners();
  }

  /// Switch to a new locale and persist the choice.
  Future<void> setLocale(Locale newLocale) async {
    if (newLocale == _locale) return;
    final langTag = _localeToString(newLocale);
    if (!supportedLocales.contains(langTag)) return;

    _locale = newLocale;
    _autoMode = false;
    if (kDebugMode) debugPrint('LocaleProvider: setLocale to $langTag');
    await _persistLanguage(langTag);
    notifyListeners();
  }

  /// Torna alla modalità automatica: rimuove la preferenza salvata e
  /// ri-risolve la lingua dalla lingua di sistema (fallback inglese).
  Future<void> useSystemLocale() async {
    await _clearStoredLanguage();
    _locale = await _resolveLocale();
    if (kDebugMode) {
      debugPrint(
        'LocaleProvider: modalità automatica → ${_locale.languageCode}',
      );
    }
    notifyListeners();
  }

  /// Read the language from storage if available, otherwise detect
  /// from browser/OS, falling back to English.
  Future<Locale> _resolveLocale() async {
    // 1. Stored preference (scelta esplicita dell'utente)
    final stored = await _readStoredLanguage();
    if (stored != null && supportedLocales.contains(stored)) {
      _autoMode = false;
      if (kDebugMode) {
        debugPrint('LocaleProvider: resolved from storage: $stored');
      }
      return _stringToLocale(stored);
    }

    // 2. Lingua di sistema (nessuna scelta esplicita → modalità automatica)
    _autoMode = true;
    final detected = await _detectSystemLanguage();
    if (detected != null) {
      // Exact match
      if (supportedLocales.contains(detected)) {
        if (kDebugMode) {
          debugPrint('LocaleProvider: resolved from system (exact): $detected');
        }
        return _stringToLocale(detected);
      }
      // Primary subtag match (e.g., 'zh' → 'zh-CN', 'fr' → 'fr-CA')
      final primary = detected.split('-').first;
      final match = supportedLocales.cast<String?>().firstWhere(
            (l) => l!.startsWith(primary),
            orElse: () => null,
          );
      if (match != null) {
        if (kDebugMode) {
          debugPrint('LocaleProvider: resolved from system (subtag): $match');
        }
        return _stringToLocale(match);
      }
    }

    // 3. Default
    if (kDebugMode) {
      debugPrint('LocaleProvider: resolved to default: $_defaultLocale');
    }
    return const Locale(_defaultLocale);
  }

  // ─── Helpers ───

  static Locale _stringToLocale(String langTag) {
    final parts = langTag.split('-');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  static String _localeToString(Locale locale) {
    final code = locale.countryCode;
    if (code != null && code.isNotEmpty) {
      return '${locale.languageCode}-$code';
    }
    return locale.languageCode;
  }
}
