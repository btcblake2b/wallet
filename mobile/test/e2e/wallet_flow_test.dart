import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_snapshot.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/core/utils/connectivity.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/backup_seed_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/home_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/send_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/wallet_detail_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

class MockStorage extends Mock implements FlutterSecureStorage {}

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

  testWidgets(
    'E2E: home → creazione → backup completo → dettaglio → storico → send',
    (tester) async {
      // Ignora gli avvisi noti ListTile/DecoratedBox (non bloccanti) — stesso
      // override usato in wallet_detail_screen_test.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('ListTile background color') ||
            details
                .exceptionAsString()
                .contains('ink splashes may be invisible')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = originalOnError;
      });

      // Disclaimer già accettato + connessione forzata (hook di test).
      final storage = MockStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'true');
      HomeScreen.secureStorageForTest = storage;
      connectivityOnlineForTest = true;
      addTearDown(() {
        HomeScreen.secureStorageForTest = const FlutterSecureStorage();
        connectivityOnlineForTest = false;
      });

      // ── Stato condiviso dei mock ──
      final createdWallets = <WalletRecord>[];

      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();

      when(() => walletRepository.loadWallets())
          .thenAnswer((_) async => List.of(createdWallets));
      when(
        () => walletRepository.createWallet(
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async {
        final wallet = WalletRecord(
          walletId: 'w-e2e',
          encryptedSeed: 'enc',
          publicAddress: 'tb1qteste2e',
          deviceId: 'd',
          createdAt: DateTime(2026, 8, 27),
        );
        createdWallets.add(wallet);
        return wallet;
      });
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => _seed);
      when(() => walletRepository.confirmSeedBackup(any())).thenAnswer(
        (inv) async {
          final w = inv.positionalArguments.first as WalletRecord;
          final updated = w.copyWith(seedBackupConfirmed: true);
          createdWallets
            ..clear()
            ..add(updated);
          return updated;
        },
      );
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      // PERCHÉ: Home/Detail ora leggono un unico snapshot → il mock ritorna
      // uno snapshot completo (saldo + storico) invece dei singoli endpoint.
      final incomingTx = TransactionRecord(
        txid: 'aa' * 32,
        direction: TxDirection.incoming,
        amountSats: 50000,
        feeSats: 2000,
        confirmations: 3,
        blockHeight: 149987,
        timestamp: DateTime(2026, 8, 27, 10, 30),
      );
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer(
        (_) async => WalletSnapshot(
          balanceSats: 50000,
          txCount: 1,
          utxos: const [],
          transactions: [incomingTx],
          fetchedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: cryptoService,
            deviceService: deviceService,
            localeProvider: LocaleProvider(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ── 1. Home vuota: empty state ──
      expect(find.text('No wallets yet'), findsNothing);
      expect(find.text('Create wallet'), findsOneWidget);

      // ── 2. Creazione → selettore tipo → BackupSeedScreen ──
      await tester.ensureVisible(find.text('Create wallet'));
      await tester.tap(find.text('Create wallet'));
      await tester.pumpAndSettle();
      // PERCHÉ (multi-tipo): alla creazione compare il selettore dei 3 tipi;
      // il test sceglie il default Native SegWit (BIP84).
      expect(find.text('Wallet type to create'), findsOneWidget);
      await tester.tap(find.text('Native SegWit (BIP84)'));
      await tester.pumpAndSettle();
      expect(find.byType(BackupSeedScreen), findsOneWidget);
      expect(find.text('Seed backup'), findsOneWidget);

      // ── 3. Backup completo (auth + seed + verifica) ──
      await tester.tap(find.text('Start backup'));
      await tester.pumpAndSettle();

      // Estrai le 12 parole dai chip ("1. abandon", ...).
      final chipWords = <int, String>{};
      final chips = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (w) => w is Text && RegExp(r'^\d+\. ').hasMatch(w.data ?? ''),
            ),
          )
          .toList();
      for (final chip in chips) {
        final parts = chip.data!.split('. ');
        chipWords[int.parse(parts[0]) - 1] = parts[1];
      }
      expect(chipWords.length, 12);

      await tester.tap(find.text('I saved the seed'));
      await tester.pumpAndSettle();

      // Leggi gli indici richiesti dalle label ("Word 5") e riempi i campi.
      for (var j = 0; j < 3; j++) {
        final field =
            tester.widget<TextField>(find.byKey(Key('verify_field_$j')));
        final label = field.decoration?.labelText ?? '';
        final idx = int.parse(RegExp(r'\d+').firstMatch(label)!.group(0)!) - 1;
        await tester.enterText(
          find.byKey(Key('verify_field_$j')),
          chipWords[idx]!,
        );
      }
      await tester.tap(
        find.widgetWithText(FilledButton, 'Verify your backup'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backup complete'), findsOneWidget);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      // ── 4. Home con 1 wallet ──
      expect(find.byType(BackupSeedScreen), findsNothing);
      expect(find.textContaining('tb1qteste2e'), findsWidgets);

      // ── 5. Dettaglio wallet + storico ──
      await tester.tap(find.textContaining('tb1qteste2e').first);
      await tester.pumpAndSettle();
      expect(find.byType(WalletDetailScreen), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      await tester.tap(find.text('Transactions'));
      await tester.pump();
      expect(find.textContaining('Received'), findsOneWidget);
      expect(find.textContaining('+0.00050000'), findsOneWidget);

      // ── 6. Send ──
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.byType(SendScreen), findsOneWidget);
      expect(find.text('Send BTC'), findsOneWidget);
    },
  );
}
