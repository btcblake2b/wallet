import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('AppLockService', () {
    late MockFlutterSecureStorage storage;
    late AppLockService sut;

    setUp(() {
      storage = MockFlutterSecureStorage();
      sut = AppLockService(storage: storage);
    });

    test('default: disattivato, non bloccato, proposta non vista', () {
      expect(sut.isEnabled, isFalse);
      expect(sut.isLocked, isFalse);
      expect(sut.isPromptSeen, isFalse);
    });

    test('lock() è no-op quando il blocco è disattivato', () {
      sut.lock();
      expect(sut.isLocked, isFalse);
    });

    test('init: con enabled=true l\'app parte già bloccata (cold start)',
        () async {
      when(() => storage.read(key: 'app_lock_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => storage.read(key: 'app_lock_prompt_seen'))
          .thenAnswer((_) async => 'true');

      await sut.init();

      expect(sut.isEnabled, isTrue);
      expect(sut.isLocked, isTrue);
      expect(sut.isPromptSeen, isTrue);
    });

    test('setEnabled(true) persiste e lock()/unlock() cambiano stato',
        () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await sut.setEnabled(value: true);

      expect(sut.isEnabled, isTrue);
      sut.lock();
      expect(sut.isLocked, isTrue);
      sut.unlock();
      expect(sut.isLocked, isFalse);
      verify(() => storage.write(key: 'app_lock_enabled', value: 'true'))
          .called(1);
    });

    test('setEnabled(false) sblocca e persiste', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      await sut.setEnabled(value: true);
      sut.lock();

      await sut.setEnabled(value: false);

      expect(sut.isEnabled, isFalse);
      expect(sut.isLocked, isFalse);
      verify(() => storage.write(key: 'app_lock_enabled', value: 'false'))
          .called(1);
    });

    test('markPromptSeen persiste il flag', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await sut.markPromptSeen();

      expect(sut.isPromptSeen, isTrue);
      verify(() => storage.write(key: 'app_lock_prompt_seen', value: 'true'))
          .called(1);
    });

    test('init fail-open su errore di storage (mai chiuso fuori)', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(Exception('storage unavailable'));

      await sut.init();

      expect(sut.isEnabled, isFalse);
      expect(sut.isLocked, isFalse);
    });
  });
}
