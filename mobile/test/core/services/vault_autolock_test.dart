import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/vault_autolock.dart';

void main() {
  // PERCHÉ (hardening 2.4): i test usano testWidgets (FakeAsync) per
  // controllare il tempo senza attese reali.
  group('VaultAutoLock', () {
    testWidgets('blocca il vault dopo il timeout di inattività', (tester) async {
      var locks = 0;
      final autoLock = VaultAutoLock(
        onLock: () => locks++,
        inactivityTimeout: const Duration(minutes: 10),
      )..start();

      expect(autoLock.isArmed, isTrue);

      await tester.pump(
        const Duration(minutes: 10) + const Duration(seconds: 1),
      );

      expect(locks, 1);
      expect(autoLock.isArmed, isFalse);
      autoLock.stop();
    });

    testWidgets('touch() riavvia il countdown (nessun blocco anticipato)',
        (tester) async {
      var locks = 0;
      final autoLock = VaultAutoLock(
        onLock: () => locks++,
        inactivityTimeout: const Duration(minutes: 10),
      )..start();

      await tester.pump(const Duration(minutes: 6));
      autoLock.touch();
      await tester.pump(const Duration(minutes: 6));
      expect(locks, 0);

      await tester.pump(const Duration(minutes: 5));
      expect(locks, 1);
      autoLock.stop();
    });

    testWidgets('non blocca due volte senza nuova attività', (tester) async {
      var locks = 0;
      final autoLock = VaultAutoLock(
        onLock: () => locks++,
        inactivityTimeout: const Duration(minutes: 1),
      )..start();

      await tester.pump(const Duration(minutes: 5));
      expect(locks, 1);
      autoLock.stop();
    });

    testWidgets('pagina nascosta → blocco immediato; al ritorno si riarma',
        (tester) async {
      var locks = 0;
      final autoLock = VaultAutoLock(
        onLock: () => locks++,
        inactivityTimeout: const Duration(minutes: 10),
      )..start();

      autoLock.handleVisibility(visible: false);
      expect(locks, 1);

      autoLock.handleVisibility(visible: true);
      expect(autoLock.isArmed, isTrue);

      await tester.pump(
        const Duration(minutes: 10) + const Duration(seconds: 1),
      );
      expect(locks, 2);
      autoLock.stop();
    });

    testWidgets('stop() impedisce il blocco (dispose della schermata)',
        (tester) async {
      var locks = 0;
      final autoLock = VaultAutoLock(
        onLock: () => locks++,
        inactivityTimeout: const Duration(minutes: 1),
      )..start();

      autoLock.stop();
      await tester.pump(const Duration(minutes: 5));
      expect(locks, 0);
    });
  });
}
