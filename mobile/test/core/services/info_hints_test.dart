import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/info_hints.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('InfoHints', () {
    setUp(() {
      InfoHints.resetForTest();
    });

    test('default: enabled = true', () {
      final hints = InfoHints();
      expect(hints.enabled, isTrue);
    });

    test('init() con storage "false" → disabled', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'false');
      final hints = InfoHints(storage: storage);
      await hints.init();
      expect(hints.enabled, isFalse);
    });

    test('init() con storage null → default ON (fail-open)', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      final hints = InfoHints(storage: storage);
      await hints.init();
      expect(hints.enabled, isTrue);
    });

    test('init() con storage che lancia → default ON (fail-open)', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key'))).thenThrow(Exception('boom'));
      final hints = InfoHints(storage: storage);
      await hints.init();
      expect(hints.enabled, isTrue);
    });

    test('setEnabled(false) scrive storage e notifica', () async {
      final storage = MockStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      final hints = InfoHints(storage: storage);
      await hints.setEnabled(false);
      expect(hints.enabled, isFalse);
      verify(
        () => storage.write(key: 'info_hints_enabled', value: 'false'),
      ).called(1);
    });

    test('setEnabled(true) scrive storage e notifica', () async {
      final storage = MockStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      // PERCHÉ: parto da OFF per forzare la scrittura (altrimenti early-return).
      InfoHints.instance = InfoHints(storage: storage);
      await InfoHints.instance.setEnabled(false);
      expect(InfoHints.instance.enabled, isFalse);
      await InfoHints.instance.setEnabled(true);
      expect(InfoHints.instance.enabled, isTrue);
      verify(
        () => storage.write(key: 'info_hints_enabled', value: 'true'),
      ).called(1);
    });

    test('resetForTest ripristina default', () {
      // PERCHÉ: resetForTest crea una nuova istanza con storage in-memory;
      // il default è enabled=true, quindi anche se prima era OFF, dopo il reset torna ON.
      final hints = InfoHints();
      hints.setEnabled(false); // modifica locale (nessuna persistenza)
      expect(hints.enabled, isFalse);
      InfoHints.resetForTest();
      expect(InfoHints.instance.enabled, isTrue);
    });

    test('resetForTest con storage mockato', () async {
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      InfoHints.instance = InfoHints(storage: storage);
      await InfoHints.instance.init();
      expect(InfoHints.instance.enabled, isTrue);
      InfoHints.resetForTest();
      expect(InfoHints.instance.enabled, isTrue);
    });
  });
}
