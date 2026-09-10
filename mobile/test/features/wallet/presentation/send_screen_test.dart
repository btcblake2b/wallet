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
  });
}
