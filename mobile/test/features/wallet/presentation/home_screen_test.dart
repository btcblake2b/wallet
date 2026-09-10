import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/balance_cache.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/theme_provider.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/home_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_snapshot.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

class MockThemeProvider extends Mock implements ThemeProvider {}

void main() {
  group('HomeScreen', () {
    testWidgets('should render', (tester) async {
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();
      final localeProvider = LocaleProvider();

      when(() => walletRepository.loadWallets()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            walletRepository: walletRepository,
            biometricService: biometricService,
            bitcoinService: bitcoinService,
            cryptoService: cryptoService,
            deviceService: deviceService,
            localeProvider: localeProvider,
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('cache: nessun refetch al reload non forzato', (tester) async {
      // PERCHÉ: i saldi restano in memoria (BalanceCache) — un reload non
      // forzato (es. ritorno dal detail) NON deve rifare richieste di rete.
      BalanceCache.resetForTest();
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();
      final localeProvider = LocaleProvider();

      final wallet = WalletRecord(
        walletId: 'w1',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qtest',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        displayInHomeScreen: true,
      );
      when(() => walletRepository.loadWallets())
          .thenAnswer((_) async => [wallet]);
      when(() => walletRepository.decryptSeed(wallet))
          .thenAnswer((_) async => 'mnemonic seed phrase');
      when(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
          includeHistory: any(named: 'includeHistory'),
        ),
      ).thenAnswer(
        (_) async => WalletSnapshot(
          balanceSats: 50000000,
          txCount: 2,
          utxos: const [],
          transactions: const [],
          fetchedAt: DateTime.now(),
        ),
      );

      Widget buildHome() => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(
              walletRepository: walletRepository,
              biometricService: biometricService,
              bitcoinService: bitcoinService,
              cryptoService: cryptoService,
              deviceService: deviceService,
              localeProvider: localeProvider,
            ),
          );

      // Primo load: fetch una sola volta (cache vuota).
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();
      verify(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
          includeHistory: any(named: 'includeHistory'),
        ),
      ).called(1);

      // Nuova istanza (simula navigazione): cache → nessun nuovo fetch.
      await tester.pumpWidget(buildHome());
      await tester.pumpAndSettle();
      verifyNever(
        () => bitcoinService.fetchWalletSnapshot(
          any(),
          derivationPath: any(named: 'derivationPath'),
          includeHistory: any(named: 'includeHistory'),
        ),
      );
    });

    testWidgets('toggle tema: icona presente e tap attiva il provider',
        (tester) async {
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();
      final localeProvider = LocaleProvider();
      final themeProvider = MockThemeProvider();

      when(() => walletRepository.loadWallets()).thenAnswer((_) async => []);
      when(() => themeProvider.isDark).thenReturn(true);
      when(() => themeProvider.toggle()).thenAnswer((_) async {});

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
            localeProvider: localeProvider,
            themeProvider: themeProvider,
          ),
        ),
      );

      // PERCHÉ (UX): il tema ora sta nel menu overflow "⋮" — si apre il menu
      // e si seleziona la voce con l'icona del tema.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // In dark mode la voce mostra l'icona per passare al chiaro.
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      verify(() => themeProvider.toggle()).called(1);
    });

    testWidgets('main actions expose semantic button labels (a11y)', (
      tester,
    ) async {
      // PERCHÉ (P3.1): verifica che le azioni principali abbiano un NOME
      // ACCESSIBILE (WCAG 4.1.2) — il FAB "Crea Wallet" deve essere
      // raggiungibile via screen reader.
      final walletRepository = MockWalletRepository();
      final biometricService = MockBiometricService();
      final bitcoinService = MockBitcoinService();
      final cryptoService = MockCryptoService();
      final deviceService = MockDeviceService();
      final localeProvider = LocaleProvider();

      when(() => walletRepository.loadWallets()).thenAnswer((_) async => []);

      final handle = tester.ensureSemantics();
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
            localeProvider: localeProvider,
          ),
        ),
      );

      // Apre il menu FAB per esporre le azioni estese (import + create)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Il FAB "Crea Wallet" deve essere raggiungibile via nome accessibile.
      // (può comparire più volte per il merge semantico del FAB extended)
      final createButton = find.bySemanticsLabel('Create wallet');
      expect(
        createButton,
        findsWidgets,
        reason: 'Il FAB "Crea Wallet" deve esporre il nome accessibile',
      );

      handle.dispose();
    });

    testWidgets(
      'REGRESSIONE bottom bar: non crasha su viewport stretto (360x800), toggle FAB senza eccezioni',
      (tester) async {
        // Riproduce lo scenario reale del crash (SM G780G / 360dp, DPR 1.0).
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();
        final localeProvider = LocaleProvider();

        when(() => walletRepository.loadWallets()).thenAnswer((_) async => []);

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
              localeProvider: localeProvider,
            ),
          ),
        );

        // Frame di layout + settle: la bottom bar NON deve produrre
        // "BoxConstraints forces an infinite width" ne' "Cannot hit test".
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'La bottom bar non deve produrre vincoli di larghezza '
              'infinita / box senza size (regressione fix bottom bar)',
        );

        // Menu FAB: apertura e chiusura senza eccezioni.
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(FloatingActionButton, 'Import wallet'),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.widgetWithText(FloatingActionButton, 'Import wallet'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'REGRESSIONE bottom bar: toggle selezione multipla nasconde/ripristina la barra senza eccezioni (viewport stretto)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();
        final localeProvider = LocaleProvider();

        final wallet = WalletRecord(
          walletId: 'wallet-1',
          encryptedSeed: 'encrypted-seed',
          publicAddress: 'tb1qtestaddress',
          deviceId: 'device-1',
          createdAt: DateTime.utc(2026, 1, 1),
          name: 'Test wallet',
        );
        when(() => walletRepository.loadWallets())
            .thenAnswer((_) async => [wallet]);

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
              localeProvider: localeProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Bottom bar visibile prima della selezione (FAB principale).
        expect(find.byType(FloatingActionButton), findsWidgets);

        // La card wallet puo' essere sotto la piega della ListView (viewport
        // 360x800 con disclaimer + saldo totale): scroll fino a renderla visibile.
        await tester.scrollUntilVisible(
          find.text('Test wallet'),
          100,
          scrollable: find.byType(Scrollable).first,
        );

        // Long-press sulla card wallet -> selezione multipla: la bottom bar
        // sparisce senza eccezioni.
        await tester.longPress(find.text('Test wallet'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byType(FloatingActionButton),
          findsNothing,
          reason: 'In selezione multipla la bottom bar deve sparire',
        );

        // Uscita dalla selezione: la bottom bar torna visibile.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(FloatingActionButton), findsWidgets);
      },
    );

    testWidgets(
      'F4: fetch fallito → il totale mostra "non disponibile" (mai 0 finto)',
      (tester) async {
        BalanceCache.resetForTest();
        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();
        final localeProvider = LocaleProvider();

        final wallet = WalletRecord(
          walletId: 'w1',
          encryptedSeed: 'enc',
          publicAddress: 'bc1qtest',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
          displayInHomeScreen: true,
        );
        when(() => walletRepository.loadWallets())
            .thenAnswer((_) async => [wallet]);
        when(() => walletRepository.decryptSeed(wallet))
            .thenAnswer((_) async => 'mnemonic seed phrase');
        // PERCHÉ (F4): API giù → il loader lancia: il wallet NON deve mai
        // comparire con 0.00000000 BTC come saldo confermato.
        when(
          () => bitcoinService.fetchWalletSnapshot(
            any(),
            derivationPath: any(named: 'derivationPath'),
            includeHistory: any(named: 'includeHistory'),
          ),
        ).thenThrow(Exception('API down'));

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
              localeProvider: localeProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Totale "—" + indicatore esplicito; mai 0.00000000 BTC.
        expect(find.text('0.00000000 BTC'), findsNothing);
        expect(find.text('—'), findsOneWidget);
        expect(find.text('Balance unavailable'), findsWidgets);
      },
    );

    testWidgets(
      'F4 non-regressione: saldo 0 reale (API OK) resta 0.00000000 BTC',
      (tester) async {
        BalanceCache.resetForTest();
        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();
        final localeProvider = LocaleProvider();

        final wallet = WalletRecord(
          walletId: 'w1',
          encryptedSeed: 'enc',
          publicAddress: 'bc1qtest',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
          displayInHomeScreen: true,
        );
        when(() => walletRepository.loadWallets())
            .thenAnswer((_) async => [wallet]);
        when(() => walletRepository.decryptSeed(wallet))
            .thenAnswer((_) async => 'mnemonic seed phrase');
        // PERCHÉ (DoD): un wallet VUOTO con API OK ha saldo 0 REALE — deve
        // restare 0, non diventare "non disponibile".
        when(
          () => bitcoinService.fetchWalletSnapshot(
            any(),
            derivationPath: any(named: 'derivationPath'),
            includeHistory: any(named: 'includeHistory'),
          ),
        ).thenAnswer(
          (_) async => WalletSnapshot(
            balanceSats: 0,
            txCount: 0,
            utxos: const [],
            transactions: const [],
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
              localeProvider: localeProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Totale e card wallet mostrano 0 reale; nessun indicatore errore.
        expect(find.text('0.00000000 BTC'), findsWidgets);
        expect(find.text('Balance unavailable'), findsNothing);
        expect(find.text('—'), findsNothing);
      },
    );

    testWidgets(
      'F4 fallimento parziale: il totale mostra — (mai somma parziale)',
      (tester) async {
        BalanceCache.resetForTest();
        final walletRepository = MockWalletRepository();
        final biometricService = MockBiometricService();
        final bitcoinService = MockBitcoinService();
        final cryptoService = MockCryptoService();
        final deviceService = MockDeviceService();
        final localeProvider = LocaleProvider();

        final walletA = WalletRecord(
          walletId: 'wA',
          encryptedSeed: 'enc',
          publicAddress: 'bc1qa',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
          displayInHomeScreen: true,
        );
        final walletB = WalletRecord(
          walletId: 'wB',
          encryptedSeed: 'enc',
          publicAddress: 'bc1qb',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
          displayInHomeScreen: true,
        );
        when(() => walletRepository.loadWallets())
            .thenAnswer((_) async => [walletA, walletB]);
        when(() => walletRepository.decryptSeed(walletA))
            .thenAnswer((_) async => 'mnemonic seed phrase');
        when(() => walletRepository.decryptSeed(walletB))
            .thenAnswer((_) async => 'mnemonic seed phrase');
        // PERCHÉ (F4): A carica 0.5 BTC, B fallisce → il totale NON somma i
        // soli wallet caricati (sarebbe un numero sbagliato come vero).
        var calls = 0;
        when(
          () => bitcoinService.fetchWalletSnapshot(
            any(),
            derivationPath: any(named: 'derivationPath'),
            includeHistory: any(named: 'includeHistory'),
          ),
        ).thenAnswer((_) async {
          calls++;
          if (calls == 2) throw Exception('API down (wallet B)');
          return WalletSnapshot(
            balanceSats: 50000000,
            txCount: 2,
            utxos: const [],
            transactions: const [],
            fetchedAt: DateTime.now(),
          );
        });

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
              localeProvider: localeProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Totale "—" (mai 0.50000000 parziale); la card di A mostra il suo
        // saldo reale, la card di B l'indicatore di non disponibilità.
        expect(find.text('—'), findsOneWidget);
        expect(find.text('Balance unavailable'), findsWidgets);
        expect(find.text('0.50000000 BTC'), findsOneWidget);
        expect(find.text('0.00000000 BTC'), findsNothing);
      },
    );
  });
}
