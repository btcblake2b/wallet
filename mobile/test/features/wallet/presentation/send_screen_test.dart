import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bech32/bech32.dart' as bech32;
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/send_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  group('SendScreen', () {
    testWidgets('should render', (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 10000,
          ),
        ),
      );

      expect(find.byType(SendScreen), findsOneWidget);
    });

    testWidgets('should show confirm dialog and abort on cancel',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      // PERCHÉ: genera un indirizzo Bech32 mainnet (bc1) con checksum valido,
      // così la validazione del form passa e possiamo testare il dialog.
      final validAddress = bech32.segwit.encode(
        bech32.Segwit(
          'bc',
          0,
          List<int>.generate(20, (i) => i),
        ),
      );

      final utxo = UtxoInfo(txid: 'txid1', vout: 0, valueSat: 100000);

      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 3, highSatVb: 10),
      );
      when(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer(
        (_) async => SendResult(txid: 'txid_out', feePaid: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 100000,
            initialUtxos: [utxo],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), validAddress);
      await tester.enterText(find.byType(TextFormField).at(1), '0.0005');
      await tester.pump();

      // Tap "Send" → deve apparire il dialog di conferma.
      // PERCHÉ: il pulsante è in fondo alla scroll view e fuori dai 600px
      // dello schermo di test: lo portiamo in vista prima del tap.
      final sendButton = find.widgetWithText(FilledButton, 'Send');
      await tester.ensureVisible(sendButton);
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(find.text('Confirm transaction'), findsOneWidget);

      // Annulla → dialog chiuso, nessun invio.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm transaction'), findsNothing);
      verifyNever(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
        ),
      );
    });

    testWidgets('non firma se l\'autenticazione fallisce (audit A1)',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      when(() => biometricService.canAuthenticate()).thenAnswer(
        (_) async => true,
      );
      when(
        () => biometricService.authenticateForSensitiveAction(
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => false);

      final validAddress = bech32.segwit.encode(
        bech32.Segwit('bc', 0, List<int>.generate(20, (i) => i)),
      );
      final utxo = UtxoInfo(txid: 'txid1', vout: 0, valueSat: 100000);

      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 3, highSatVb: 10),
      );
      when(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
        ),
      ).thenAnswer((_) async => SendResult(txid: 'txid_out', feePaid: 100));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 100000,
            initialUtxos: [utxo],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), validAddress);
      await tester.enterText(find.byType(TextFormField).at(1), '0.0005');
      await tester.pump();

      final sendButton = find.widgetWithText(FilledButton, 'Send');
      await tester.ensureVisible(sendButton);
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Conferma il dialog di riepilogo…
      expect(find.text('Confirm transaction'), findsOneWidget);
      await tester.tap(find.text('Confirm & Send'));
      await tester.pumpAndSettle();

      // …ma l'autenticazione fallisce → nessuna firma/broadcast (audit A1).
      verifyNever(
        () => bitcoinService.buildSignAndSend(
          mnemonic: any(named: 'mnemonic'),
          toAddress: any(named: 'toAddress'),
          amountSats: any(named: 'amountSats'),
          feeRateSatVb: any(named: 'feeRateSatVb'),
          utxos: any(named: 'utxos'),
          derivationPath: any(named: 'derivationPath'),
        ),
      );
    });

    testWidgets('Max button fills amount with max spendable', (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      final utxo = UtxoInfo(txid: 'txid1', vout: 0, valueSat: 100000);

      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 3, highSatVb: 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 100000,
            initialUtxos: [utxo],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PERCHÉ (A4): la label del pulsante Max era buggata (mostrava "Send").
      expect(find.widgetWithText(TextButton, 'Max'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Send'), findsNothing);

      final maxButton = find.widgetWithText(TextButton, 'Max');
      await tester.ensureVisible(maxButton);
      await tester.pumpAndSettle();
      await tester.tap(maxButton);
      await tester.pump();

      // Il campo importo deve contenere un valore numerico positivo (max).
      final amountField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      final amountText = amountField.controller?.text ?? '';
      final parsed = double.tryParse(amountText.replaceAll(',', '.'));
      expect(parsed, isNotNull);
      expect(parsed!, greaterThan(0));
    });

    testWidgets('API fee giù: selettore mostra fallback rete blake2b (config)',
        (tester) async {
      final wallet = WalletRecord(
        walletId: 'test_fb',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();
      final utxo = UtxoInfo(txid: 'txid1', vout: 0, valueSat: 100000);

      when(() => bitcoinService.fetchFeeEstimates())
          .thenThrow(Exception('api down'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 100000,
            initialUtxos: [utxo],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // // PERCHÉ: con l'API giù il selettore usa il fallback mainnet della
      // rete blake2b (1/2/3 dalla config) — non 1/3/10 (testnet) né 3/12/30.
      expect(find.text('1 sat/vB'), findsOneWidget); // low
      expect(find.text('2 sat/vB'), findsOneWidget); // normal
      expect(find.text('3 sat/vB'), findsOneWidget); // high
    });

    testWidgets(
        'UTXO in periodo di attesa: fuori dal disponibile e non selezionabili',
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

      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      final spendable = UtxoInfo(
        txid: 'f' * 64,
        vout: 0,
        valueSat: 100000,
      );
      // PERCHÉ: payout di mining a 600 conferme (maturity 6.480) → in attesa.
      final waiting = UtxoInfo(
        txid: 'd' * 64,
        vout: 1,
        valueSat: 50000,
        confirmations: 600,
        isCoinbase: true,
      );

      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 2, highSatVb: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 100000,
            initialUtxos: [spendable],
            initialBlockedUtxos: [waiting],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Il disponibile è SOLO lo spendibile (100.000 sat, non 150.000).
      expect(find.text('0.00100000 BTC'), findsOneWidget);
      expect(find.text('100000 sat · 1 UTXO'), findsOneWidget);
      // La riga informativa dice dove sono finiti gli altri sat.
      expect(find.text('Waiting period: 0.00050000 BTC'), findsOneWidget);

      // Apri il selettore UTXO.
      await tester.tap(find.text('Waiting period: 0.00050000 BTC'));
      await tester.pumpAndSettle();

      // Badge dedicato + countdown in BLOCCHI (6.480 − 600 = 5.880):
      // una volta nella riga informativa del saldo, una nella riga UTXO.
      expect(find.text('Waiting period'), findsOneWidget);
      expect(find.textContaining('5880 blocks to unlock'), findsNWidgets(2));

      // Riga NON selezionabile: checkbox disabilitata.
      final waitingTile = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('Waiting period'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(waitingTile.onChanged, isNull);
      expect(waitingTile.value, isFalse);
    });

    testWidgets('solo UTXO in periodo di attesa: il form li spiega (A3)',
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

      final wallet = WalletRecord(
        walletId: 'test_id',
        encryptedSeed: 'test_seed',
        publicAddress: 'test_address',
        deviceId: 'test_device',
        createdAt: DateTime(2024, 1, 1),
      );
      final walletRepository = MockWalletRepository();
      final bitcoinService = MockBitcoinService();
      final biometricService = MockBiometricService();

      final waiting = UtxoInfo(
        txid: 'd' * 64,
        vout: 1,
        valueSat: 50000,
        confirmations: 600,
        isCoinbase: true,
      );

      when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
        (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 2, highSatVb: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendScreen(
            wallet: wallet,
            walletRepository: walletRepository,
            bitcoinService: bitcoinService,
            biometricService: biometricService,
            balanceSats: 0,
            // Nessun UTXO spendibile: solo il payout di mining in attesa.
            initialBlockedUtxos: [waiting],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Niente prompt "carica UTXO": il form spiega dove sono i fondi.
      expect(find.text('Waiting period: 0.00050000 BTC'), findsOneWidget);
      expect(find.text('Loading UTXOs'), findsNothing);

      // Il tap su Send lo dice esplicitamente, invece di "nessun UTXO".
      final sendButton = find.widgetWithText(FilledButton, 'Send');
      await tester.ensureVisible(sendButton);
      await tester.pumpAndSettle();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('they cannot be spent yet'), findsOneWidget);
    });
  });
}
