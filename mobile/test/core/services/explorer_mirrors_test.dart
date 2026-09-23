import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

/// PERCHÉ (2026-09-16): la scelta "usa solo mempool.guide" è una preferenza di
/// processo (il BitcoinService del bootstrap vive tutta la sessione) e va
/// letta dal layer rete a ogni richiesta.
void main() {
  group('ExplorerMirrors', () {
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      ExplorerMirrors.resetForTest();
    });

    tearDown(ExplorerMirrors.resetForTest);

    test('default: mirror attivi (3 host di lettura, 2 di broadcast)', () {
      final mirrors = ExplorerMirrors(storage: storage);

      expect(mirrors.enabled, isTrue);
      expect(mirrors.readHosts, hasLength(3));
      expect(mirrors.readHosts.first, equals('https://mempool.guide/api'));
      expect(mirrors.broadcastHosts, hasLength(2));
    });

    test('init: preferenza "false" persistita → solo il primario', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'false');

      final mirrors = ExplorerMirrors(storage: storage);
      await mirrors.init();

      expect(mirrors.enabled, isFalse);
      expect(mirrors.readHosts, equals(['https://mempool.guide/api']));
      expect(mirrors.broadcastHosts, equals(['https://mempool.guide/api']));
    });

    test('init: storage vuoto → resta ON (default)', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final mirrors = ExplorerMirrors(storage: storage);
      await mirrors.init();

      expect(mirrors.enabled, isTrue);
    });

    test('init: storage che lancia → fail-open ON, nessuna eccezione',
        () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(Exception('storage non disponibile'));

      final mirrors = ExplorerMirrors(storage: storage);
      await mirrors.init();

      expect(mirrors.enabled, isTrue);
    });

    test('setEnabled(false) persiste la scelta e notifica la UI', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      var notifications = 0;

      final mirrors = ExplorerMirrors(storage: storage);
      mirrors.addListener(() => notifications++);
      await mirrors.setEnabled(false);

      expect(mirrors.enabled, isFalse);
      expect(mirrors.readHosts, equals(['https://mempool.guide/api']));
      expect(notifications, equals(1));
      verify(
        () => storage.write(key: 'explorer_mirrors_enabled', value: 'false'),
      ).called(1);
    });

    test('setEnabled(true) ripristina gli host dei mirror', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final mirrors = ExplorerMirrors(storage: storage);
      await mirrors.setEnabled(false);
      await mirrors.setEnabled(true);

      expect(mirrors.enabled, isTrue);
      expect(mirrors.readHosts, hasLength(3));
      expect(mirrors.broadcastHosts, hasLength(2));
    });
  });
}
