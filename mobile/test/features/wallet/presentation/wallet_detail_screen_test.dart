import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_snapshot.dart';
import 'package:btc_blake2b_wallet/core/services/balance_cache.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/rbf_params_registry.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/wallet_detail_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/send_screen.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

/// Costruisce uno snapshot di test "fresco" (fetchedAt = adesso).
/// PERCHÉ: il Detail ora legge tutto da WalletSnapshot → i mock del servizio
/// ritornano snapshot, non più singoli valori.
WalletSnapshot _snap({
  int balance = 100000,
  int txCount = 5,
  List<UtxoInfo>? utxos,
  List<TransactionRecord>? transactions,
}) {
  return WalletSnapshot(
    balanceSats: balance,
    txCount: txCount,
    utxos: utxos ?? const [],
    transactions: transactions ?? const [],
    fetchedAt: DateTime.now(),
  );
}

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
    // PERCHÉ: mocktail richiede un fallback per any() su enum non nullable
    // (WalletScriptType usato da fetchWatchOnlySnapshot).
    registerFallbackValue(WalletScriptType.p2wpkh);
  });

  setUp(() {
    // PERCHÉ: la cache condivisa è statica → reset per isolare ogni test
    // (un test che popola la cache non deve inibire il fetch di quello dopo).
    BalanceCache.resetForTest();
  });

  group('WalletDetailScreen', () {
    testWidgets('should render', (tester) async {
      // Ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti)
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

      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();

      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap());
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: cryptoService,
            deviceService: deviceService,
          ),
        ),
      );

      expect(find.byType(WalletDetailScreen), findsOneWidget);
    });

    testWidgets('Wallet Info mostra Nested SegWit (BIP49) per path m/49\'',
        (tester) async {
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

      final wallet = WalletRecord(
        walletId: 'bip49_id',
        encryptedSeed: 'test_seed',
        publicAddress: '3testaddress',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        derivationPath: "m/49'/0'/0'",
        seedBackupConfirmed: true,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap());
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');

      await tester.pumpWidget(
        MaterialApp(
          // PERCHÉ: locale 'it' → etichetta attesa "SegWit annidato (BIP49 P2SH)".
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PERCHÉ: la sezione Wallet Info è in fondo al ListView (lazy) →
      // scroll finché l'etichetta del tipo non è costruita.
      await tester.scrollUntilVisible(
        find.text('SegWit annidato (BIP49 P2SH)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SegWit annidato (BIP49 P2SH)'), findsOneWidget);
    });

    testWidgets('Wallet Info mostra Legacy P2PKH (BIP44) per path m/44\'',
        (tester) async {
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

      final wallet = WalletRecord(
        walletId: 'bip44_id',
        encryptedSeed: 'test_seed',
        publicAddress: '1testaddress',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        derivationPath: "m/44'/0'/0'",
        seedBackupConfirmed: true,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap());
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Legacy P2PKH (BIP44)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Legacy P2PKH (BIP44)'), findsOneWidget);
    });

    // Helper: pompa la schermata con mocks già configurati e apre il flusso
    // seed fino alla visualizzazione (dopo "Sì, mostra").
    Future<void> pumpAndOpenSeed(
      WidgetTester tester, {
      required WalletRecord wallet,
      required MockWalletRepository walletRepository,
      required MockBiometricService biometricService,
      required MockBitcoinService bitcoinService,
      Random? random,
    }) async {
      // PERCHÉ: ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti).
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

      // PERCHÉ: lo snapshot base rende il Detail operativo (fetch unico in
      // initState con cache vuota). I singoli test possono sovrascriverlo.
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap());

      await tester.pumpWidget(
        MaterialApp(
          // PERCHÉ: locale 'it' per testi localizzati deterministici.
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
            random: random,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Espandi "Strumenti Avanzati" (body ListView lazy).
      final listScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Strumenti Avanzati'),
        300,
        scrollable: listScrollable,
      );
      await tester.drag(listScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strumenti Avanzati'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Esporta/Backup Seed'),
        300,
        scrollable: listScrollable,
      );
      await tester.drag(listScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esporta/Backup Seed'));
      await tester.pumpAndSettle();

      // Dialog "Visualizzare seed?" → Sì, mostra
      await tester.tap(find.text('Sì, mostra'));
      await tester.pumpAndSettle();
    }

    // Scrolla fino al finder (per widget sotto la piega nella ListView lazy).
    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      final listScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: listScrollable,
      );
      await tester.drag(listScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
    }

    const bip39Seed =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    testWidgets('verifica backup seed: 3 parole corrette confermano il backup',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: false,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 100000, 'tx_count': 5});
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      when(
        () => bitcoinService.scanDerivedAddressesForUtxos(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => <String, List<UtxoInfo>>{});
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      when(() => walletRepository.confirmSeedBackup(any())).thenAnswer(
        (_) async => wallet.copyWith(seedBackupConfirmed: true),
      );

      await pumpAndOpenSeed(
        tester,
        wallet: wallet,
        walletRepository: walletRepository,
        biometricService: biometricService,
        bitcoinService: bitcoinService,
        random: Random(42),
      );

      // Offerta verifica → Sì, verifica
      expect(
        find.text('Vuoi verificare di aver salvato la seed?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sì, verifica'));
      await tester.pumpAndSettle();

      // Inserisci le 3 parole corrette (stessi indici di Random(42)).
      final rng = Random(42);
      final indices = <int>{};
      while (indices.length < 3) {
        indices.add(rng.nextInt(12));
      }
      final sorted = indices.toList()..sort();
      final words = bip39Seed.split(' ');
      await scrollTo(tester, find.byKey(const Key('verify_field_0')));
      for (var j = 0; j < 3; j++) {
        await tester.enterText(
          find.byKey(Key('verify_field_$j')),
          words[sorted[j]],
        );
      }
      await tester.pumpAndSettle();

      await scrollTo(
        tester,
        find.widgetWithText(FilledButton, 'Verifica il backup'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Verifica il backup'));
      await tester.pumpAndSettle();

      verify(() => walletRepository.confirmSeedBackup(any())).called(1);
      expect(find.text('Backup verificato'), findsOneWidget);
    });

    testWidgets('verifica backup seed: parole errate mostrano errore',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: false,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 100000, 'tx_count': 5});
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      when(
        () => bitcoinService.scanDerivedAddressesForUtxos(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => <String, List<UtxoInfo>>{});
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);

      await pumpAndOpenSeed(
        tester,
        wallet: wallet,
        walletRepository: walletRepository,
        biometricService: biometricService,
        bitcoinService: bitcoinService,
        random: Random(42),
      );
      await tester.tap(find.text('Sì, verifica'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('verify_field_0')));
      for (var j = 0; j < 3; j++) {
        await tester.enterText(find.byKey(Key('verify_field_$j')), 'wrong');
      }
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.widgetWithText(FilledButton, 'Verifica il backup'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Verifica il backup'));
      await tester.pumpAndSettle();

      expect(find.text('Parole non corrette. Riprova.'), findsOneWidget);
      verifyNever(() => walletRepository.confirmSeedBackup(any()));
    });

    testWidgets('verifica backup seed: Non ora nasconde la seed e non conferma',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: false,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 100000, 'tx_count': 5});
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      when(
        () => bitcoinService.scanDerivedAddressesForUtxos(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => <String, List<UtxoInfo>>{});
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);

      await pumpAndOpenSeed(
        tester,
        wallet: wallet,
        walletRepository: walletRepository,
        biometricService: biometricService,
        bitcoinService: bitcoinService,
        random: Random(42),
      );

      // Seed visibile prima della scelta
      await scrollTo(tester, find.textContaining('abandon'));
      expect(find.textContaining('abandon'), findsWidgets);

      await tester.tap(find.text('Non ora'));
      await tester.pumpAndSettle();

      expect(find.textContaining('abandon'), findsNothing);
      verifyNever(() => walletRepository.confirmSeedBackup(any()));
    });

    testWidgets('timer auto-hide: seed nascosta dopo inattività e ripristinata',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: true, // nessuna offerta di verifica
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 100000, 'tx_count': 5});
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      when(
        () => bitcoinService.scanDerivedAddressesForUtxos(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => <String, List<UtxoInfo>>{});
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);

      await pumpAndOpenSeed(
        tester,
        wallet: wallet,
        walletRepository: walletRepository,
        biometricService: biometricService,
        bitcoinService: bitcoinService,
        random: Random(42),
      );

      // Seed visibile
      await scrollTo(tester, find.textContaining('abandon'));
      expect(find.textContaining('abandon'), findsWidgets);

      // Nessuna interazione per 61s → auto-hide
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.textContaining('abandon'), findsNothing);
      expect(find.text('Seed nascosta per sicurezza'), findsOneWidget);

      // "Mostra seed" → ri-autenticazione → seed di nuovo visibile
      await tester.tap(find.text('Mostra seed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('abandon'), findsWidgets);
    });

    testWidgets(
        'lifecycle inactive: seed nascosta quando l\'app perde il focus',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: true,
      );
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();

      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 100000, 'tx_count': 5});
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      when(
        () => bitcoinService.scanDerivedAddressesForUtxos(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => <String, List<UtxoInfo>>{});
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      addTearDown(() {
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });

      await pumpAndOpenSeed(
        tester,
        wallet: wallet,
        walletRepository: walletRepository,
        biometricService: biometricService,
        bitcoinService: bitcoinService,
        random: Random(42),
      );
      await scrollTo(tester, find.textContaining('abandon'));
      expect(find.textContaining('abandon'), findsWidgets);

      // PERCHÉ: inactive (es. app switcher) tiene i frame attivi ed è il caso
      // reale dove uno screenshot catturerebbe la seed; paused è coperto dallo
      // stesso ramo (nasconde la seed in entrambi i casi).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(find.textContaining('abandon'), findsNothing);
      expect(find.text('Seed nascosta per sicurezza'), findsOneWidget);
    });
  });

  group('Coin control (S7)', () {
    // Helper: pompa WalletDetailScreen con UTXO configurabili e locale 'it'.
    // PERCHÉ: il locale 'it' rende deterministici i testi localizzati.
    Future<void> pumpDetail(
      WidgetTester tester, {
      required MockWalletRepository walletRepository,
      required MockBitcoinService bitcoinService,
      required List<UtxoInfo> utxos,
    }) async {
      // PERCHÉ: ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti)
      // come fanno i test esistenti del file.
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

      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: true,
      );
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      // PERCHÉ: lo snapshot porta gli UTXO del coin control (saldo = Σ) e li
      // ordina per valore desc come fa fetchWalletSnapshot nel service reale
      // (la UI e i test assumono quell'ordine).
      final utxoSats = utxos.fold<int>(0, (s, u) => s + u.valueSat);
      final sortedUtxos = [...utxos]
        ..sort((a, b) => b.valueSat.compareTo(a.valueSat));
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer(
        (_) async => _snap(
          balance: utxoSats,
          txCount: utxos.length,
          utxos: sortedUtxos,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: MockBiometricService(),
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Scrolla fino al tile "UTXO" e lo espande.
    Future<void> expandUtxoTile(WidgetTester tester) async {
      final listScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('UTXO'),
        300,
        scrollable: listScrollable,
      );
      await tester.drag(listScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UTXO'));
      await tester.pumpAndSettle();
    }

    testWidgets('lista UTXO renderizza valore, badge pending e conferme',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final utxos = [
        UtxoInfo(txid: 'a' * 64, vout: 0, valueSat: 5000, confirmations: 3),
        UtxoInfo(txid: 'b' * 64, vout: 1, valueSat: 20000, confirmations: 0),
      ];

      await pumpDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
        utxos: utxos,
      );
      await expandUtxoTile(tester);

      // Ordinati per valore desc (20000 prima di 5000)
      expect(find.text('0.00020000 BTC'), findsOneWidget);
      expect(find.text('0.00005000 BTC'), findsOneWidget);
      // Badge conferme e pending (IT)
      expect(find.text('3 conferme'), findsOneWidget);
      expect(find.text('In attesa di conferma'), findsOneWidget);
    });

    testWidgets(
        'checkbox seleziona e contatore si aggiorna; Deseleziona azzera',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final utxos = [
        UtxoInfo(txid: 'a' * 64, vout: 0, valueSat: 5000, confirmations: 3),
        UtxoInfo(txid: 'b' * 64, vout: 1, valueSat: 20000, confirmations: 3),
      ];

      await pumpDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
        utxos: utxos,
      );
      await expandUtxoTile(tester);

      // Contatore iniziale (nessuna selezione)
      expect(find.text('0 selezionati · 0 sat'), findsOneWidget);

      // Seleziona il primo (20000, ordine desc)
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('1 selezionati · 20000 sat'), findsOneWidget);

      // Deseleziona tutto
      await tester.tap(find.text('Deseleziona tutto'));
      await tester.pumpAndSettle();
      expect(find.text('0 selezionati · 0 sat'), findsOneWidget);
    });

    testWidgets('empty state mostra testo localizzato', (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();

      await pumpDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
        utxos: const [],
      );
      await expandUtxoTile(tester);

      expect(find.text('Nessun UTXO spendibile trovato'), findsOneWidget);
    });

    testWidgets('Invia selezionati passa solo il sottoinsieme a SendScreen',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 3, highSatVb: 10),
      );
      final utxos = [
        UtxoInfo(txid: 'a' * 64, vout: 0, valueSat: 5000, confirmations: 3),
        UtxoInfo(txid: 'b' * 64, vout: 1, valueSat: 20000, confirmations: 3),
      ];

      await pumpDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
        utxos: utxos,
      );
      await expandUtxoTile(tester);

      // Seleziona il primo UTXO (20000) e invia
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invia selezionati'));
      await tester.pumpAndSettle();

      // SendScreen deve ricevere SOLO il sottoinsieme selezionato
      final sendScreen = tester.widget<SendScreen>(find.byType(SendScreen));
      expect(sendScreen.initialUtxos, hasLength(1));
      expect(sendScreen.initialUtxos!.single.valueSat, 20000);
    });

    testWidgets('rinomina UTXO: dialog salva il nome e persiste nel wallet',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.updateWallet(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as WalletRecord,
      );
      final utxos = [
        UtxoInfo(txid: 'a' * 64, vout: 0, valueSat: 5000, confirmations: 3),
      ];

      await pumpDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
        utxos: utxos,
      );
      await expandUtxoTile(tester);

      // Apre il dialog di rinomina (locale it → "Rinomina").
      await tester.tap(find.text('Rinomina'));
      await tester.pumpAndSettle();
      expect(find.text('Rinomina UTXO'), findsOneWidget);

      // Inserisce il nome e salva.
      await tester.enterText(find.byType(TextField).last, 'Fondo casa');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      // Il dialog si chiude senza eccezioni e il nome è persistito.
      expect(find.text('Rinomina UTXO'), findsNothing);
      final captured = verify(
        () => walletRepository.updateWallet(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final saved = captured.single as WalletRecord;
      expect(
        saved.utxoLabels['${'a' * 64}:0'],
        'Fondo casa',
      );
      // La riga mostra ora il nome assegnato.
      expect(find.text('Fondo casa'), findsOneWidget);
    });
  });

  group('Dialog Ricevi (gap BIP44)', () {
    const bip39Seed =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    // Helper: pompa la schermata e apre il dialog Ricevi ("Ricevi").
    Future<void> pumpAndOpenReceive(
      WidgetTester tester, {
      required MockWalletRepository walletRepository,
      required MockBitcoinService bitcoinService,
    }) async {
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

      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'first_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
        seedBackupConfirmed: true,
      );
      when(() => bitcoinService.fetchAddressInfo(any()))
          .thenAnswer((_) async => {'balance': 0, 'tx_count': 0});

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: MockBiometricService(),
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap su "Ricevi" (quick action) → apre il dialog.
      final listScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Ricevi'),
        300,
        scrollable: listScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ricevi'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'se il primo indirizzo ha già UTXO mostra il successivo + pulsante copia',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      // UTXO sul primo indirizzo (/0/0) → il dialog deve mostrare /0/1.
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer(
        (_) async => _snap(
          balance: 5000,
          txCount: 1,
          utxos: [
            UtxoInfo(
              txid: 'a' * 64,
              vout: 0,
              valueSat: 5000,
              ownerAddress: 'first_address',
            ),
          ],
        ),
      );
      // Derivazione: indirizzo 0 usato, indirizzo 1 libero.
      when(
        () => bitcoinService.deriveWalletDataFromMnemonic(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer(
        (_) async => WalletDerivationResult(
          publicAddress: 'first_address',
          masterFingerprint: 'ABCDEF01',
          derivationPath: "m/84'/1'/0'",
          xpub: 'xpub_test',
          addresses: const ['first_address', 'second_address'],
          changeAddresses: const ['change_address'],
        ),
      );

      await pumpAndOpenReceive(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      // PERCHÉ: limita i find al dialog — la schermata dietro ha un subtitle
      // con lo stesso publicAddress.
      // QR + indirizzo successivo (non quello con UTXO).
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('second_address'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('first_address'),
        ),
        findsNothing,
      );
      // Pulsante copia presente.
      expect(find.byIcon(Icons.copy), findsWidgets);
    });

    testWidgets('senza UTXO noti mostra il primo indirizzo', (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => bip39Seed);
      // Nessun UTXO → publicAddress (primo indirizzo) resta valido.
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap(balance: 0, txCount: 0));

      await pumpAndOpenReceive(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      expect(find.byType(QrImageView), findsOneWidget);
      // PERCHÉ: cerca SOLO dentro il dialog (lo sfondo ha lo stesso testo).
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('first_address'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.copy), findsWidgets);
    });
  });

  group('Refresh minima (cache condivisa)', () {
    // Helper: wallet di test con publicAddress 'test_address' (chiave cache).
    WalletRecord testWallet() => WalletRecord(
          walletId: 'test_id',
          encryptedSeed: 'test_seed',
          publicAddress: 'test_address',
          deviceId: 'test_device',
          createdAt: DateTime(2024, 1, 1),
          seedBackupConfirmed: true,
        );

    // Pompa la schermata filtrando gli avvisi noti (come gli altri helper).
    Future<void> pumpRefreshDetail(
      WidgetTester tester, {
      required MockWalletRepository walletRepository,
      required MockBitcoinService bitcoinService,
    }) async {
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

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: testWallet(),
            walletRepository: walletRepository,
            biometricService: MockBiometricService(),
            bitcoinService: bitcoinService,
            cryptoService: MockCryptoService(),
            deviceService: MockDeviceService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cache fresca (TTL): nessun fetch all\'apertura',
        (tester) async {
      // Pre-popola la cache con uno snapshot fresco.
      BalanceCache.putSnapshot(
        'test_address',
        _snap(balance: 777000, txCount: 3),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');

      await pumpRefreshDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      // PERCHÉ: snapshot fresco → ZERO richieste di rete all'apertura.
      verifyNever(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      );
      expect(find.text('0.00777000 BTC'), findsOneWidget);
    });

    testWidgets(
        'snapshot parziale (Home, senza storico): completato in background',
        (tester) async {
      // PERCHÉ: la Home all'avvio salva uno snapshot senza storico (lazy) —
      // il Detail lo riconosce incompleto e lo completa senza bloccare l'UI.
      BalanceCache.putSnapshot(
        'test_address',
        WalletSnapshot(
          balanceSats: 777000,
          txCount: 2,
          utxos: const [],
          transactions: null, // storico non ancora caricato
          fetchedAt: DateTime.now(),
        ),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap(balance: 888000, txCount: 4));

      await pumpRefreshDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      // Fetch in background eseguito una volta → snapshot completato.
      verify(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).called(1);
      expect(find.text('0.00888000 BTC'), findsOneWidget);
    });

    testWidgets(
        'cache vecchia (TTL scaduto): mostra subito + aggiorna in background',
        (tester) async {
      BalanceCache.putSnapshot(
        'test_address',
        WalletSnapshot(
          balanceSats: 777000,
          txCount: 3,
          utxos: const [],
          transactions: const [],
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap(balance: 888000, txCount: 4));

      await pumpRefreshDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      // Fetch in background eseguito una volta → saldo aggiornato.
      verify(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).called(1);
      expect(find.text('0.00888000 BTC'), findsOneWidget);
    });

    testWidgets('errore primo caricamento: card errore + retry recupera',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      var calls = 0;
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('rete giù');
        return _snap(balance: 5000, txCount: 1);
      });

      await pumpRefreshDetail(
        tester,
        walletRepository: walletRepository,
        bitcoinService: bitcoinService,
      );

      // Errore visibile al posto del saldo (mai 0 BTC / spinner infinito).
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Riprova → il fetch riesce → saldo visibile.
      await tester.tap(find.widgetWithText(FilledButton, 'Riprova').first);
      await tester.pumpAndSettle();
      expect(find.text('0.00005000 BTC'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets(
      'wallet watch-only: badge visibile, nessun Invia, fetch da xpub senza decryptSeed',
      (tester) async {
        // Ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti),
        // come negli altri test del file.
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details
                  .exceptionAsString()
                  .contains('ListTile background color') ||
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

        final wallet = WalletRecord(
          walletId: 'wo_id',
          encryptedSeed: '',
          publicAddress: 'bc1qwatchfirst',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
          kind: WalletKind.watchOnly,
          accountXpub:
              'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz',
          derivationPath: "m/84'/0'/0'",
        );
        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();

        when(
          () => bitcoinService.fetchWatchOnlySnapshot(
            accountXpub: any(named: 'accountXpub'),
            scriptType: any(named: 'scriptType'),
          ),
        ).thenAnswer((_) async => _snap());
        // decryptSeed NON deve MAI essere chiamato per un watch-only.
        when(() => walletRepository.decryptSeed(any()))
            .thenAnswer((_) async => 'MAI');

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WalletDetailScreen(
              wallet: wallet,
              walletRepository: walletRepository,
              biometricService: biometricService,
              bitcoinService: bitcoinService,
              cryptoService: cryptoService,
              deviceService: deviceService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Badge di sola lettura (nel campo nome).
        expect(find.text('Watch-only'), findsWidgets);
        // Nessun pulsante Invia: un watch-only non può firmare.
        expect(find.text('Send'), findsNothing);
        // Snapshot caricato via fetchWatchOnlySnapshot, MAI via decryptSeed.
        verify(
          () => bitcoinService.fetchWatchOnlySnapshot(
            accountXpub: any(named: 'accountXpub'),
            scriptType: any(named: 'scriptType'),
          ),
        ).called(1);
        verifyNever(() => walletRepository.decryptSeed(any()));
      },
    );

    testWidgets('Aumenta fee: flusso bump completo su tx pending outgoing',
        (tester) async {
      // Ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti).
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
      // // PERCHÉ: il registro RBF è statico per-isolate → reset + setup locale.
      RbfParamsRegistry.resetForTest();
      final wallet = WalletRecord(
        walletId: 'w_bump',
        encryptedSeed: 'seed',
        publicAddress: 'addr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );
      // Simula l'invio avvenuto in questa sessione (incremento B registra i
      // parametri al broadcast) → la tx pending è bumpabile.
      RbfParamsRegistry.register(
        'txbump',
        const RbfTxParams(
          kind: RbfTxKind.send,
          toAddress: 'bc1qdest',
          amountSats: 50000,
          derivationPath: "m/84'/0'/0'",
          originalFeeRateSatVb: 5,
          utxos: [],
        ),
      );
      final txs = [
        const TransactionRecord(
          txid: 'txbump',
          direction: TxDirection.outgoing,
          amountSats: 50000,
          confirmations: 0,
          blockHeight: null,
        ),
      ];

      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();
      var fetches = 0;

      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async {
        fetches++;
        return _snap(transactions: txs);
      });
      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 3, normalSatVb: 12, highSatVb: 30),
      );
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      when(
        () => bitcoinService.bumpFee(
          mnemonic: any(named: 'mnemonic'),
          txid: any(named: 'txid'),
          newFeeRateSatVb: any(named: 'newFeeRateSatVb'),
        ),
      ).thenAnswer(
        (_) async => SendResult(txid: 'newtx', feePaid: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: cryptoService,
            deviceService: deviceService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Espande lo storico e apre il dettaglio della tx outgoing pending.
      // // PERCHÉ: lo storico è in fondo alla pagina scrollabile → il widget
      // va portato in vista prima del tap, altrimenti è off-screen.
      await tester.ensureVisible(find.text('Transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sent · -0.00050000 BTC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sent · -0.00050000 BTC'));
      await tester.pumpAndSettle();

      // Dialog dettaglio → azione RBF disponibile.
      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.text('Increase fee'), findsOneWidget);
      await tester.tap(find.text('Increase fee'));
      await tester.pumpAndSettle();

      // Dialog bump: fee attuale e opzioni valide; conferma (default = 12).
      expect(find.text('Increase transaction fee'), findsOneWidget);
      expect(find.text('Current fee: 5 sat/vB'), findsOneWidget);
      await tester.tap(find.text('Increase fee'));
      await tester.pumpAndSettle();

      // Auth (mock true) → bumpFee con la fee scelta → snackbar + refresh.
      verify(
        () => bitcoinService.bumpFee(
          mnemonic: any(named: 'mnemonic'),
          txid: any(named: 'txid'),
          newFeeRateSatVb: any(named: 'newFeeRateSatVb'),
        ),
      ).called(1);
      expect(find.text('Fee increased — new transaction newtx'), findsOneWidget);
      expect(fetches, greaterThanOrEqualTo(2));
    });

    testWidgets('Aumenta fee: errore bumpFee mostrato come snackbar',
        (tester) async {
      // Ignora gli avvisi noti di ListTile/DecoratedBox (non bloccanti).
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
      RbfParamsRegistry.resetForTest();
      final wallet = WalletRecord(
        walletId: 'w_bump_err',
        encryptedSeed: 'seed',
        publicAddress: 'addr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );
      RbfParamsRegistry.register(
        'txerr',
        const RbfTxParams(
          kind: RbfTxKind.send,
          toAddress: 'bc1qdest',
          amountSats: 50000,
          derivationPath: "m/84'/0'/0'",
          originalFeeRateSatVb: 5,
          utxos: [],
        ),
      );
      final txs = [
        const TransactionRecord(
          txid: 'txerr',
          direction: TxDirection.outgoing,
          amountSats: 50000,
          confirmations: 0,
          blockHeight: null,
        ),
      ];

      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();

      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => _snap(transactions: txs));
      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 3, normalSatVb: 12, highSatVb: 30),
      );
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => true);
      when(() => walletRepository.decryptSeed(any()))
          .thenAnswer((_) async => 'test mnemonic seed phrase');
      when(
        () => bitcoinService.bumpFee(
          mnemonic: any(named: 'mnemonic'),
          txid: any(named: 'txid'),
          newFeeRateSatVb: any(named: 'newFeeRateSatVb'),
        ),
      ).thenThrow(ArgumentError('fee non maggiore'));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletDetailScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: cryptoService,
            deviceService: deviceService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // // PERCHÉ: storico in fondo alla pagina scrollabile → ensureVisible.
      await tester.ensureVisible(find.text('Transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sent · -0.00050000 BTC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sent · -0.00050000 BTC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Increase fee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Increase fee'));
      await tester.pumpAndSettle();

      // ArgError → messaggio localizzato dedicato.
      expect(
        find.text('The new fee must be higher than the current one'),
        findsOneWidget,
      );
    });
  });
}
