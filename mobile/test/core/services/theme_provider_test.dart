import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ThemeProvider', () {
    test('init → dark di default quando storage vuoto', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final provider = ThemeProvider(storage: storage);
      await provider.init();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDark, isTrue);
    });

    test('init → light quando storage contiene "light"', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'light');

      final provider = ThemeProvider(storage: storage);
      await provider.init();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('setThemeMode persiste la scelta su storage', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final provider = ThemeProvider(storage: storage);
      await provider.init();
      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);
      verify(
        () => storage.write(key: any(named: 'key'), value: 'light'),
      ).called(1);
    });

    test('toggle alterna dark → light → dark', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final provider = ThemeProvider(storage: storage);
      await provider.init();

      await provider.toggle();
      expect(provider.themeMode, ThemeMode.light);

      await provider.toggle();
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
