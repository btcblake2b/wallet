// Web implementation of LocaleProvider platform methods.
// Uses dart:html for localStorage and navigator.language detection.
// Shares the `lang` key with the landing page i18n.js script.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String?> readStoredLanguageImpl() async {
  try {
    return html.window.localStorage['lang'];
  } catch (_) {
    return null;
  }
}

Future<void> persistLanguageImpl(String langTag) async {
  try {
    html.window.localStorage['lang'] = langTag;
  } catch (_) {
    // Silently ignore
  }
}

Future<String?> detectSystemLanguageImpl() async {
  try {
    final navLang = html.window.navigator.language;
    if (navLang.isNotEmpty) {
      return navLang.replaceAll('_', '-');
    }
    // Fallback: check navigator.languages
    final langs = html.window.navigator.languages;
    if (langs != null && langs.isNotEmpty) {
      return langs.first.replaceAll('_', '-');
    }
    return null;
  } catch (_) {
    return null;
  }
}
