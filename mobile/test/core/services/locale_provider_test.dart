import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';

void main() {
  group('LocaleProvider', () {
    test('should instantiate', () {
      final instance = LocaleProvider();
      expect(instance, isNotNull);
    });

    test('preferenza salvata vince sulla lingua di sistema', () async {
      final p = LocaleProvider(
        readStoredLanguage: () async => 'de',
        detectSystemLanguage: () async => 'it-IT',
      );
      await p.init();
      expect(p.languageCode, 'de');
      expect(p.isAutoMode, isFalse);
    });

    test('lingua di sistema supportata (sottotag) → locale corrispondente',
        () async {
      final p = LocaleProvider(
        readStoredLanguage: () async => null,
        detectSystemLanguage: () async => 'it-IT',
      );
      await p.init();
      expect(p.languageCode, 'it');
      expect(p.isAutoMode, isTrue);
    });

    test('lingua di sistema NON supportata → fallback inglese', () async {
      final p = LocaleProvider(
        readStoredLanguage: () async => null,
        detectSystemLanguage: () async => 'pt-BR',
      );
      await p.init();
      expect(p.languageCode, 'en');
      expect(p.isAutoMode, isTrue);
    });

    test('lingua salvata non supportata → viene ignorata (usa il sistema)',
        () async {
      final p = LocaleProvider(
        readStoredLanguage: () async => 'xx',
        detectSystemLanguage: () async => 'fr-CA',
      );
      await p.init();
      expect(p.languageCode, 'fr');
      expect(p.isAutoMode, isTrue);
    });

    test('setLocale persiste la scelta e disattiva la modalità automatica',
        () async {
      String? persisted;
      final p = LocaleProvider(
        readStoredLanguage: () async => null,
        detectSystemLanguage: () async => 'en-US',
        persistLanguage: (langTag) async => persisted = langTag,
      );
      await p.init();
      await p.setLocale(const Locale('de'));
      expect(p.languageCode, 'de');
      expect(persisted, 'de');
      expect(p.isAutoMode, isFalse);
    });

    test('setLocale ignora lingue non supportate', () async {
      final p = LocaleProvider(
        readStoredLanguage: () async => null,
        detectSystemLanguage: () async => 'en-US',
      );
      await p.init();
      await p.setLocale(const Locale('xx'));
      expect(p.languageCode, 'en');
    });

    test('useSystemLocale azzera la preferenza e torna al sistema', () async {
      var cleared = false;
      String? stored = 'it';
      final p = LocaleProvider(
        readStoredLanguage: () async => stored,
        detectSystemLanguage: () async => 'en-US',
        clearStoredLanguage: () async {
          cleared = true;
          stored = null;
        },
      );
      await p.init();
      expect(p.languageCode, 'it');
      expect(p.isAutoMode, isFalse);
      await p.useSystemLocale();
      expect(cleared, isTrue);
      expect(p.languageCode, 'en');
      expect(p.isAutoMode, isTrue);
    });
  });
}
