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
  static const _defaultLocale = 'en';

  /// All locales supported by the app (must match l10n.yaml and ARB files).
  /// Note: ARB files use `zh` and `fr` (without country codes).
  /// Flutter resolves `zh-CN` → `zh` and `fr-CA` → `fr` automatically.
  static const supportedLocales = [
    'it',
    'en',
    'de',
    'fi',
    'es',
    'zh',
    'fr',
  ];

  Locale _locale = const Locale(_defaultLocale);

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
    if (kDebugMode) debugPrint('LocaleProvider: setLocale to $langTag');
    await persistLanguageImpl(langTag);
    notifyListeners();
  }

  /// Read the language from storage if available, otherwise detect
  /// from browser/OS, falling back to English.
  Future<Locale> _resolveLocale() async {
    // 1. Stored preference (localStorage on web)
    final stored = await readStoredLanguageImpl();
    if (stored != null && supportedLocales.contains(stored)) {
      if (kDebugMode) {
        debugPrint('LocaleProvider: resolved from storage: $stored');
      }
      return _stringToLocale(stored);
    }

    // 2. Browser/OS language
    final detected = await detectSystemLanguageImpl();
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
