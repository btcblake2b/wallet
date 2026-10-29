import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/send_output.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';
import 'package:btc_blake2b_wallet/core/services/psbt/psbt_wallet_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/psbt_qr_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/psbt_sign_screen.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/psbt_spend_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

/// Schermate PSBT (P4/I2/I3): creazione con QR, import, riepilogo e firma.
///
/// // PERCHÉ questi test: il percorso PSBT tocca denaro senza passare dal
/// // pulsante "Invia" — qui si verifica che il watch-only NON possa firmare,
/// // che il riepilogo compaia e che una PSBT illeggibile venga rifiutata.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  late BitcoinService bitcoinService;

  setUp(() {
    ExplorerMirrors.resetForTest();    bitcoinService = BitcoinService(
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/tx')) {
          return http.Response('mocktxid0002', 200);
        }
        return http.Response('not found', 404);
      }),
    );
  });

  // PERCHÉ: `decryptSeed(any())` richiede un valore di fallback tipizzato a
  // mocktail, altrimenti il matcher non sa costruire l'argomento in modalità
  // sound null safety.
  setUpAll(() {
    registerFallbackValue(
      WalletRecord(
        walletId: 'fallback',
        encryptedSeed: '',
        publicAddress: 'bc1qfallback',
        deviceId: 'test',
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      );

  Future<
      ({
        WalletRecord hot,
        WalletRecord watchOnly,
        List<UtxoInfo> utxos,
        String destination,
      })> buildFixture() async {
    final derived = await bitcoinService.deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: 2,
    );
    final base = WalletRecord(
      walletId: 'w-psbt-ui',
      encryptedSeed: 'enc',
      publicAddress: derived.publicAddress,
      deviceId: 'test',
      createdAt: DateTime.utc(2026, 10, 26),
      masterFingerprint: derived.masterFingerprint,
      derivationPath: derived.derivationPath,
      kind: WalletKind.hot,
      accountXpub: derived.xpub,
      seedBackupConfirmed: true,
    );
    final utxos = <UtxoInfo>[
      UtxoInfo(
        txid: 'a' * 64,
        vout: 0,
        valueSat: 100000,
        scriptPubKeyType: 'v0_p2wpkh',
        ownerAddress: derived.addresses.first,
        ownerDerivationPath: '${derived.derivationPath}/0/0',
      ),
    ];
    return (
      hot: base,
      watchOnly: base.copyWith(kind: WalletKind.watchOnly, encryptedSeed: ''),
      utxos: utxos,
      destination: derived.addresses[1],
    );
  }

  MockWalletRepository repositoryWith(String seed) {
    final repository = MockWalletRepository();
    when(() => repository.decryptSeed(any())).thenAnswer((_) async => seed);
    return repository;
  }

  MockBiometricService authorizingBiometrics() {
    final biometrics = MockBiometricService();
    when(() => biometrics.canAuthenticate()).thenAnswer((_) async => true);
    when(
      () => biometrics.authenticateForSensitiveAction(
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => true);
    return biometrics;
  }

  testWidgets('spend screen (watch-only): crea la PSBT e mostra il QR',
      (tester) async {
    // PERCHÉ runAsync: la derivazione del wallet usa `compute` (isolate reale),
    // e dentro testWidgets il tempo è finto finché non lo si chiede.
    final f = await tester.runAsync(buildFixture);
    if (f == null) fail('fixture non creata');
    await tester.pumpWidget(
      wrap(
        PsbtSpendScreen(
          wallet: f.watchOnly,
          utxos: f.utxos,
          bitcoinService: bitcoinService,
          walletRepository: repositoryWith(mnemonic),
          biometricService: authorizingBiometrics(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spend with PSBT'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, f.destination);
    await tester.enterText(find.byType(TextFormField).last, '0.0005');
    await tester.pump();

    await tester.tap(find.text('Create PSBT'));
    // La creazione deriva chiavi: qualche pump esplicito (il QR animato usa un
    // Timer periodico, quindi niente pumpAndSettle sulla schermata QR).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(PsbtQrScreen), findsOneWidget);
    expect(find.text('Scan this PSBT'), findsOneWidget);

    // Dispone il timer del QR animato prima della fine del test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sign screen: PSBT illeggibile → errore, nessuna firma',
      (tester) async {
    final f = await tester.runAsync(buildFixture);
    if (f == null) fail('fixture non creata');
    await tester.pumpWidget(
      wrap(
        PsbtSignScreen(
          wallet: f.hot,
          walletRepository: repositoryWith(mnemonic),
          biometricService: authorizingBiometrics(),
          bitcoinService: bitcoinService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'non-una-psbt');
    await tester.pump();

    expect(find.text('Not a valid PSBT'), findsOneWidget);
    expect(find.text('Sign'), findsNothing);
  });

  testWidgets('sign screen: watch-only → il riepilogo c''è, la firma no',
      (tester) async {
    final f = await tester.runAsync(buildFixture);
    if (f == null) fail('fixture non creata');
    final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
    final draft = await psbtService.createForWallet(
      wallet: f.watchOnly,
      utxos: f.utxos,
      outputs: [SendOutput(address: f.destination, amountSats: 50000)],
      feeRateSatVb: 3,
    );

    await tester.pumpWidget(
      wrap(
        PsbtSignScreen(
          wallet: f.watchOnly,
          walletRepository: repositoryWith(mnemonic),
          biometricService: authorizingBiometrics(),
          bitcoinService: bitcoinService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, draft.psbtBase64);
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Inputs: 1'), findsOneWidget);
    expect(find.text('Fee: ${draft.feeSats} sat'), findsOneWidget);

    await tester.tap(find.text('Sign'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text(
        'This wallet has no seed: sign on the device that holds it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign screen: hot → firma e mostra la PSBT firmata',
      (tester) async {
    final f = await tester.runAsync(buildFixture);
    if (f == null) fail('fixture non creata');
    final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
    final draft = await psbtService.createForWallet(
      wallet: f.hot,
      utxos: f.utxos,
      outputs: [SendOutput(address: f.destination, amountSats: 50000)],
      feeRateSatVb: 3,
      mnemonic: mnemonic,
    );

    await tester.pumpWidget(
      wrap(
        PsbtSignScreen(
          wallet: f.hot,
          walletRepository: repositoryWith(mnemonic),
          biometricService: authorizingBiometrics(),
          bitcoinService: bitcoinService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, draft.psbtBase64);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(PsbtQrScreen), findsOneWidget);
    expect(find.text('Signed PSBT'), findsOneWidget);
    expect(find.text('Broadcast'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
