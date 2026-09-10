import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/backup_seed_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

const _seed =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  setUpAll(() {
    registerFallbackValue(
      WalletRecord(
        walletId: 'fallback',
        encryptedSeed: '',
        publicAddress: '',
        deviceId: '',
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  Widget harness({
    required WalletRecord wallet,
    required WalletRepository repo,
    required BiometricService bio,
    ValueChanged<bool?>? onResult,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(ctx).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BackupSeedScreen(
                    wallet: wallet,
                    walletRepository: repo,
                    biometricService: bio,
                    random: Random(42), // indici deterministici
                  ),
                ),
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('intro: skip chiude senza confermare il backup', (tester) async {
    final repo = MockWalletRepository();
    final bio = MockBiometricService();
    final wallet = WalletRecord(
      walletId: 'w1',
      encryptedSeed: 'enc',
      publicAddress: 'tb1qtest',
      deviceId: 'd',
      createdAt: DateTime(2026, 1, 1),
    );

    bool? result;
    await tester.pumpWidget(
      harness(
        wallet: wallet,
        repo: repo,
        bio: bio,
        onResult: (r) => result = r,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Seed backup'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(BackupSeedScreen), findsNothing);
  });

  testWidgets('flusso completo: intro → auth → seed → verifica → done',
      (tester) async {
    final repo = MockWalletRepository();
    when(() => repo.decryptSeed(any())).thenAnswer((_) async => _seed);
    when(() => repo.confirmSeedBackup(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as WalletRecord).copyWith(
        seedBackupConfirmed: true,
      ),
    );
    final bio = MockBiometricService();
    when(
      () => bio.authenticateForSensitiveAction(reason: any(named: 'reason')),
    ).thenAnswer((_) async => true);

    final wallet = WalletRecord(
      walletId: 'w1',
      encryptedSeed: 'enc',
      publicAddress: 'tb1qtest',
      deviceId: 'd',
      createdAt: DateTime(2026, 1, 1),
    );

    bool? result;
    await tester.pumpWidget(
      harness(
        wallet: wallet,
        repo: repo,
        bio: bio,
        onResult: (r) => result = r,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // intro → start
    await tester.tap(find.text('Start backup'));
    await tester.pumpAndSettle();

    // seed visibile (12 parole del vector BIP39)
    expect(find.textContaining('abandon'), findsWidgets);
    await tester.tap(find.text('I saved the seed'));
    await tester.pumpAndSettle();

    // verifica: ricostruisco gli stessi indici di Random(42)
    final rng = Random(42);
    final indices = <int>{};
    while (indices.length < 3) {
      indices.add(rng.nextInt(12));
    }
    final sorted = indices.toList()..sort();
    final words = _seed.split(' ');
    for (var j = 0; j < 3; j++) {
      await tester.enterText(
        find.byKey(Key('verify_field_$j')),
        words[sorted[j]],
      );
    }
    await tester.tap(
      find.widgetWithText(FilledButton, 'Verify your backup'),
    );
    await tester.pumpAndSettle();

    // done → finish → confirmSeedBackup + pop(true)
    expect(find.text('Backup complete'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    verify(() => repo.confirmSeedBackup(any())).called(1);
    expect(result, isTrue);
    expect(find.byType(BackupSeedScreen), findsNothing);
  });

  testWidgets('verifica con parole errate mostra errore e resta nello step',
      (tester) async {
    final repo = MockWalletRepository();
    when(() => repo.decryptSeed(any())).thenAnswer((_) async => _seed);
    when(() => repo.confirmSeedBackup(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as WalletRecord).copyWith(
        seedBackupConfirmed: true,
      ),
    );
    final bio = MockBiometricService();
    when(
      () => bio.authenticateForSensitiveAction(reason: any(named: 'reason')),
    ).thenAnswer((_) async => true);

    final wallet = WalletRecord(
      walletId: 'w1',
      encryptedSeed: 'enc',
      publicAddress: 'tb1qtest',
      deviceId: 'd',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      harness(wallet: wallet, repo: repo, bio: bio),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I saved the seed'));
    await tester.pumpAndSettle();

    // Parole sbagliate in tutti e 3 i campi.
    for (var j = 0; j < 3; j++) {
      await tester.enterText(find.byKey(Key('verify_field_$j')), 'wrong');
    }
    await tester.tap(
      find.widgetWithText(FilledButton, 'Verify your backup'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incorrect words. Try again.'), findsOneWidget);
    expect(find.text('Backup complete'), findsNothing);
  });
}
