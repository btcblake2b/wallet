import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_snapshot.dart';
import 'package:btc_blake2b_wallet/core/services/balance_cache.dart';

WalletSnapshot _snap({int balance = 1}) => WalletSnapshot(
      balanceSats: balance,
      txCount: 0,
      fetchedAt: DateTime.now(),
    );

void main() {
  setUp(BalanceCache.resetForTest);

  group('BalanceCache', () {
    test('getOrFetch deduplica i fetch concorrenti per lo stesso address',
        () async {
      var calls = 0;
      Future<WalletSnapshot> loader() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _snap();
      }

      final f1 = BalanceCache.getOrFetch('addr', loader);
      final f2 = BalanceCache.getOrFetch('addr', loader);
      final s1 = await f1;
      final s2 = await f2;

      expect(calls, 1);
      expect(identical(s1, s2), isTrue);
      // Al completamento lo snapshot è salvato in cache.
      expect(BalanceCache.snapshotOf('addr'), isNotNull);
    });

    test('getOrFetch su errore libera l\'in-flight (riprova possibile)',
        () async {
      var calls = 0;
      Future<WalletSnapshot> loader() async {
        calls++;
        throw Exception('rete giù');
      }

      await expectLater(BalanceCache.getOrFetch('a', loader), throwsException);
      await expectLater(BalanceCache.getOrFetch('a', loader), throwsException);
      expect(calls, 2);
    });

    test('putSnapshot salva e notifica i listener', () {
      var notified = 0;
      void listener() => notified++;
      BalanceCache.addListener(listener);

      BalanceCache.putSnapshot('addr', _snap());
      expect(notified, 1);
      expect(BalanceCache.snapshotOf('addr'), isNotNull);

      BalanceCache.removeListener(listener);
      BalanceCache.putSnapshot('addr', _snap(balance: 2));
      expect(notified, 1);
    });

    test('freshSnapshot: null se assente o se lo snapshot è vecchio (TTL)', () {
      expect(BalanceCache.freshSnapshot('x'), isNull);

      BalanceCache.putSnapshot('x', _snap());
      expect(BalanceCache.freshSnapshot('x'), isNotNull);

      BalanceCache.putSnapshot(
        'x',
        WalletSnapshot(
          balanceSats: 1,
          txCount: 0,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      );
      expect(BalanceCache.freshSnapshot('x'), isNull);
    });

    test('isFetching true durante un fetch in corso', () async {
      final gate = Completer<WalletSnapshot>();
      final future = BalanceCache.getOrFetch('addr', () => gate.future);
      expect(BalanceCache.isFetching('addr'), isTrue);
      gate.complete(_snap());
      await future;
      expect(BalanceCache.isFetching('addr'), isFalse);
    });
  });
}
