import 'package:btc_blake2b_wallet/core/config/feature_flags.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/merchant/presentation/merchant_charge_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBitcoinService extends Mock implements BitcoinService {}

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockBitcoinService bitcoinService;
  late MockWalletRepository repository;

  final wallet = WalletRecord(
    walletId: 'shop',
    encryptedSeed: 'enc',
    publicAddress: 'bc1qshopaddress0000000000000000000000',
    deviceId: 'dev',
    createdAt: DateTime.utc(2026, 10, 27),
    seedBackupConfirmed: true,
  );

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      );

  setUp(() {
    bitcoinService = MockBitcoinService();
    repository = MockWalletRepository();
    when(
      () => bitcoinService.fetchAddressInfo(any()),
    ).thenAnswer((_) async => {'balance': 0, 'tx_count': 0});
    registerFallbackValue(wallet);
  });

  Future<void> createOnchainCharge(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, '12500');
    await tester.tap(find.text('Create payment request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('rotazione attiva: l\'incasso usa il NUOVO indirizzo', (
    tester,
  ) async {
    // PERCHÉ (ADR 31/10-23): con il service la Cassa non usa più
    // `publicAddress` fisso — ogni incasso ha il suo indirizzo.
    when(
      () => repository.nextReceiveAddress(
        any(),
        rotationEnabled: any(named: 'rotationEnabled'),
        adoptLegacy: any(named: 'adoptLegacy'),
        mnemonic: any(named: 'mnemonic'),
      ),
    ).thenAnswer(
      (_) async => ReceiveAddressResult(
        address: 'bc1qnewshop0000000000000000000000000000',
        index: 4,
        record: wallet,
        persisted: true,
        isFresh: true,
      ),
    );

    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
          receiveAddressService: ReceiveAddressService(
            repository: repository,
            flags: const FeatureFlags(walletIndexRotation: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await createOnchainCharge(tester);

    expect(
      find.textContaining('bitcoin:bc1qnewshop0000000000000000000000000000'),
      findsOneWidget,
    );
    expect(
      find.textContaining('bitcoin:bc1qshopaddress0000000000000000000000'),
      findsNothing,
    );
  });

  testWidgets('indici corrotti: avviso, nessun indirizzo, nessuna richiesta', (
    tester,
  ) async {
    // Un incasso su `/0/0` sarebbe riuso: la schermata blocca e spiega.
    when(
      () => repository.nextReceiveAddress(
        any(),
        rotationEnabled: any(named: 'rotationEnabled'),
        adoptLegacy: any(named: 'adoptLegacy'),
        mnemonic: any(named: 'mnemonic'),
      ),
    ).thenAnswer(
      (invocation) async => throw const CorruptWalletIndicesException('shop'),
    );

    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
          receiveAddressService: ReceiveAddressService(
            repository: repository,
            flags: const FeatureFlags(walletIndexRotation: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await createOnchainCharge(tester);

    final loc = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(loc.indicesCorruptTitle), findsOneWidget);
    expect(find.textContaining('bitcoin:'), findsNothing);
    verifyNever(() => bitcoinService.fetchAddressInfo(any()));
  });

  testWidgets('flag OFF: delega al service con rotationEnabled: false', (
    tester,
  ) async {
    // PERCHÉ (ADR 01/11-26 §2): questo test **documenta un limite noto**, non un
    // comportamento desiderabile. Con la rotazione spenta la Cassa segue la
    // tabella di ADR 7 §2: un wallet legacy mostra `publicAddress` (= `/0/0`),
    // esattamente come la v0.4.0 — incluso il riuso se `/0/0` è già stato usato.
    // La rotazione è la correzione; il flag off è il rollback, con il suo buco.
    var passedRotation = true;
    when(
      () => repository.nextReceiveAddress(
        any(),
        rotationEnabled: any(named: 'rotationEnabled'),
        adoptLegacy: any(named: 'adoptLegacy'),
        mnemonic: any(named: 'mnemonic'),
      ),
    ).thenAnswer((invocation) async {
      passedRotation =
          invocation.namedArguments[#rotationEnabled] as bool? ?? true;
      return ReceiveAddressResult(
        address: wallet.publicAddress,
        index: 0,
        record: wallet,
        persisted: false,
        isFresh: false,
      );
    });

    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: WalletRecord(
            walletId: wallet.walletId,
            encryptedSeed: wallet.encryptedSeed,
            publicAddress: wallet.publicAddress,
            deviceId: wallet.deviceId,
            createdAt: wallet.createdAt,
            seedBackupConfirmed: true,
            indicesState: IndicesState.legacyUninitialized,
          ),
          bitcoinService: bitcoinService,
          receiveAddressService: ReceiveAddressService(
            repository: repository,
            flags: const FeatureFlags(walletIndexRotation: false),
          ),
        ),
      ),
    );
    await tester.pump();
    await createOnchainCharge(tester);

    expect(
      find.textContaining('bitcoin:bc1qshopaddress0000000000000000000000'),
      findsOneWidget,
    );
    // Il flag è arrivato al repository come `false`: nessuna rotazione.
    expect(passedRotation, isFalse);
  });

  testWidgets('senza service: comportamento storico su publicAddress', (
    tester,
  ) async {
    // Il parametro è opzionale: le chiamate esistenti non cambiano.
    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
        ),
      ),
    );
    await tester.pump();
    await createOnchainCharge(tester);

    expect(
      find.textContaining('bitcoin:bc1qshopaddress0000000000000000000000'),
      findsOneWidget,
    );
    verifyNever(
      () => repository.nextReceiveAddress(
        any(),
        rotationEnabled: any(named: 'rotationEnabled'),
        adoptLegacy: any(named: 'adoptLegacy'),
        mnemonic: any(named: 'mnemonic'),
      ),
    );
  });
}
