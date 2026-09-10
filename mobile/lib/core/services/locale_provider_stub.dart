/// Stub implementation of LocaleProvider platform methods for native (non-web).
///
/// On Android/iOS:
/// - Language detection uses PlatformDispatcher.instance.locale
/// - Persistence uses FlutterSecureStorage (shared key `lang` is already used
///   by the landing page; on native it's stored in Android Keystore / iOS Keychain)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _storageKey = 'lang';

Future<String?> readStoredLanguageImpl() async {
  try {
    final value = await _storage.read(key: _storageKey);
    if (kDebugMode) {
      debugPrint('LocaleProvider: readStoredLanguage = $value');
    }
    return value;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('LocaleProvider: readStoredLanguage failed: $e');
    }
    return null;
  }
}

Future<void> persistLanguageImpl(String langTag) async {
  try {
    await _storage.write(key: _storageKey, value: langTag);
    if (kDebugMode) {
      debugPrint('LocaleProvider: persisted language: $langTag');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('LocaleProvider: persistLanguage failed: $e');
    }
  }
}

Future<String?> detectSystemLanguageImpl() async {
  final locale = PlatformDispatcher.instance.locale;
  final code = locale.countryCode != null && locale.countryCode!.isNotEmpty
      ? '${locale.languageCode}-${locale.countryCode}'
      : locale.languageCode;
  if (kDebugMode) {
    debugPrint('LocaleProvider: detected system language: $code');
  }
  return code;
}
